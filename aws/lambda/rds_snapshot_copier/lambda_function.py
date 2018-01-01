#!/bin/env python3
# -*- coding: utf-8 -*-
# pylint: disable=superfluous-parens
import boto3
import re
from operator import itemgetter
from datetime import datetime, timezone
from botocore.exceptions import ClientError  # noqa: F401

rds_client = boto3.client('rds')


def lambda_handler(event, context):
    print('Creating snapshots')
    for db_instance in [instance for instance in rds_client.describe_db_instances()['DBInstances']]:
        automated_snapshots = [s for s in rds_client.describe_db_snapshots(DBInstanceIdentifier=db_instance['DBInstanceIdentifier'])['DBSnapshots'] if (s['SnapshotType'] == 'automated' and s['Status'] == 'available')]
        manual_snapshots = [s for s in rds_client.describe_db_snapshots(DBInstanceIdentifier=db_instance['DBInstanceIdentifier'])['DBSnapshots'] if (s['SnapshotType'] != 'automated' and s['Status'] == 'available')]
        latest_automated_snapshot = sorted(automated_snapshots, key=itemgetter('SnapshotCreateTime'), reverse=True)[0]
        identifier = re.search('.+?:(.*)', latest_automated_snapshot['DBSnapshotIdentifier']).group(1)
        print('creating {} from'.format(identifier, latest_automated_snapshot['DBSnapshotIdentifier']))
        try:
            rds_client.copy_db_snapshot(
                SourceDBSnapshotIdentifier=latest_automated_snapshot['DBSnapshotIdentifier'],
                TargetDBSnapshotIdentifier='manual-{}'.format(identifier),
                Tags=[
                    {
                        'Key': 'Source',
                        'Value': db_instance['DBInstanceIdentifier'],
                    },
                    {
                        'Key': 'Managed_by',
                        'Value': 'lambda:rds_snapshot_copier',
                    },
                ],
                CopyTags=True,
            )
        except rds_client.exceptions.DBSnapshotAlreadyExistsFault:
            print('Skipping already created snapshot')
            pass

        print('Cleaning old snapshots')
        manual_snapshots = [s for s in rds_client.describe_db_snapshots(DBInstanceIdentifier=db_instance['DBInstanceIdentifier'])['DBSnapshots'] if (s['SnapshotType'] != 'automated' and s['Status'] == 'available')]
        for snapshot in manual_snapshots:
            tags = rds_client.list_tags_for_resource(ResourceName=snapshot['DBSnapshotArn'])['TagList']
            if (len(tags) > 0 and "lambda:rds_snapshot_copier" in [tag['Value'] for tag in tags]):
                if ((datetime.now(timezone.utc) - snapshot['SnapshotCreateTime']).days > 7):
                    print('removing snapshot with identifier {}'.format(snapshot['DBSnapshotIdentifier']))
                    rds_client.delete_db_snapshot(DBSnapshotIdentifier=snapshot['DBSnapshotIdentifier'])


if __name__ == "__main__":
    lambda_handler(None, None)
