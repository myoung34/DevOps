#!/bin/env python3
# -*- coding: utf-8 -*-
# pylint: disable=superfluous-parens
import boto3
import re
from operator import itemgetter
from datetime import datetime, timezone
from botocore.exceptions import ClientError  # noqa: F401

redshift_client = boto3.client('redshift')


def lambda_handler(event, context):
    for cluster in [instance for instance in redshift_client.describe_clusters()['Clusters']]:
        print('Creating snapshots for cluster {}'.format(cluster['ClusterIdentifier']))
        automated_snapshots = [s for s in redshift_client.describe_cluster_snapshots(ClusterIdentifier=cluster['ClusterIdentifier'])['Snapshots'] if (s['SnapshotType'] == 'automated' and s['Status'] == 'available')]
        sorted_automated_snapshots = sorted(automated_snapshots, key=itemgetter('SnapshotCreateTime'), reverse=True)
        if (len(sorted_automated_snapshots) > 0):
            latest_automated_snapshot = sorted_automated_snapshots[0]
            identifier = re.search('.+?:(.*)', latest_automated_snapshot['SnapshotIdentifier']).group(1)
            print('creating {} from {}'.format(identifier, latest_automated_snapshot['SnapshotIdentifier']))
            try:
                create_response = redshift_client.copy_cluster_snapshot(
                    SourceSnapshotIdentifier=latest_automated_snapshot['SnapshotIdentifier'],
                    TargetSnapshotIdentifier='manual-{}'.format(identifier),
                )['Snapshot']
                redshift_client.create_tags(
                    ResourceName='arn:aws:redshift:{}:{}:snapshot:{}/{}'.format(
                        create_response['AvailabilityZone'][:-1],
                        create_response['OwnerAccount'],
                        create_response['ClusterIdentifier'],
                        'manual-{}'.format(identifier)
                    ),
                    Tags=[{
                        'Key': 'Managed_by',
                        'Value': 'lambda:redshift_snapshot_copier'
                    }]
                )
            except redshift_client.exceptions.ClusterSnapshotQuotaExceededFault:
                pass
            except redshift_client.exceptions.ClientError as e:
                if ('Cannot create more than' in str(e)):
                    pass
                elif ('has already been copied' in str(e)):
                    print('Skipping already created snapshot')
                    pass
                else:
                    raise(e)
        else:
            print('No automated snaphots found for cluster {}'.format(cluster['ClusterIdentifier']))

        print('Clearing old snapshots for cluster {}'.format(cluster['ClusterIdentifier']))
        manual_snapshots = [s for s in redshift_client.describe_cluster_snapshots(ClusterIdentifier=cluster['ClusterIdentifier'])['Snapshots'] if (s['SnapshotType'] != 'automated' and s['Status'] == 'available')]
        for snapshot in manual_snapshots:
            match = re.search('^(manual-).*', snapshot['SnapshotIdentifier'])
            if (match is not None and match.group(1) is not None):
                response = redshift_client.describe_tags(
                    ResourceName='arn:aws:redshift:{}:{}:snapshot:{}/{}'.format(
                        snapshot['AvailabilityZone'][:-1],
                        snapshot['OwnerAccount'],
                        snapshot['ClusterIdentifier'],
                        snapshot['SnapshotIdentifier']
                    ),
                    TagKeys=[
                        'Managed_by',
                    ],
                    TagValues=[
                        'lambda:redshift_snapshot_copier',
                    ]
                )['TaggedResources']

                if ((len(response) > 0) and (datetime.now(timezone.utc) - snapshot['SnapshotCreateTime']).days > 7):
                    print('removing snapshot with identifier {}'.format(snapshot['SnapshotIdentifier']))
                    redshift_client.delete_cluster_snapshot(SnapshotIdentifier=snapshot['SnapshotIdentifier'])


if __name__ == "__main__":
    lambda_handler(None, None)
