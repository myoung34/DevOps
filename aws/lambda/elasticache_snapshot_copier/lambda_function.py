#!/bin/env python3
# -*- coding: utf-8 -*-
# pylint: disable=superfluous-parens
import boto3
import re
import time
from datetime import datetime, timezone
from botocore.exceptions import ClientError  # noqa: F401

elasticache_client = boto3.client('elasticache')
account_id = boto3.client('sts').get_caller_identity().get('Account')


def lambda_handler(event, context):
    for elasticache_instance in [instance for instance in elasticache_client.describe_cache_clusters()['CacheClusters']]:
        print('Creating {} snapshots'.format(elasticache_instance['CacheClusterId']))
        automated_snapshots = [s for s in elasticache_client.describe_snapshots(CacheClusterId=elasticache_instance['CacheClusterId'])['Snapshots'] if (s['SnapshotSource'] != 'manual' and s['SnapshotStatus'] == 'available')]
        manual_snapshots = [s for s in elasticache_client.describe_snapshots(CacheClusterId=elasticache_instance['CacheClusterId'])['Snapshots'] if (s['SnapshotSource'] == 'manual' and s['SnapshotStatus'] == 'available')]
        try:
            latest_automated_snapshot = sorted(automated_snapshots, key=lambda x: (x['NodeSnapshots'][0]['SnapshotCreateTime']), reverse=True)[0]
        except IndexError:
            break
        identifier = 'manual-{}'.format(re.search('.+?\.(.*)', latest_automated_snapshot['SnapshotName']).group(1))
        print('creating {} from'.format(identifier, latest_automated_snapshot['SnapshotName']))
        try:
            response = elasticache_client.copy_snapshot(
                SourceSnapshotName=latest_automated_snapshot['SnapshotName'],
                TargetSnapshotName=identifier,
            )
            while elasticache_client.describe_snapshots(SnapshotName=identifier)['Snapshots'][0]['SnapshotStatus'] != 'available':
                print('Waiting for snapshot to be available...')
                time.sleep(10)

            region = re.search('([a-z]{2}-[a-z]+-[0-9]).*', response['Snapshot']['PreferredAvailabilityZone']).group(1)
            elasticache_client.add_tags_to_resource(
                ResourceName='arn:aws:elasticache:{}:{}:snapshot:{}'.format(region, account_id, identifier),
                Tags=[
                    {
                        'Key': 'Source',
                        'Value': elasticache_instance['CacheClusterId'],
                    },
                    {
                        'Key': 'Managed_by',
                        'Value': 'lambda:elasticache_snapshot_copier',
                    },
                ],
            )
        except elasticache_client.exceptions.SnapshotAlreadyExistsFault:
            print('Skipping already created snapshot')
            pass

        print('Cleaning {} snapshots'.format(elasticache_instance['CacheClusterId']))
        manual_snapshots = [s for s in elasticache_client.describe_snapshots(CacheClusterId=elasticache_instance['CacheClusterId'])['Snapshots'] if (s['SnapshotSource'] == 'manual' and s['SnapshotStatus'] == 'available')]
        for snapshot in manual_snapshots:
            region = re.search('([a-z]{2}-[a-z]+-[0-9]).*', snapshot['PreferredAvailabilityZone']).group(1)
            snap_arn = 'arn:aws:elasticache:{}:{}:snapshot:{}'.format(region, account_id, snapshot['SnapshotName'])
            tags = elasticache_client.list_tags_for_resource(ResourceName=snap_arn)['TagList']
            if (len(tags) > 0 and "lambda:elasticache_snapshot_copier" in [tag['Value'] for tag in tags]):
                if ((datetime.now(timezone.utc) - snapshot['NodeSnapshots'][0]['SnapshotCreateTime']).days > 7):
                    print('removing snapshot with name {}'.format(snapshot['SnapshotName']))
                    elasticache_client.delete_snapshot(SnapshotName=snapshot['SnapshotName'])


if __name__ == "__main__":
    lambda_handler(None, None)
