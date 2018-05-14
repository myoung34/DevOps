# -*- coding: utf-8 -*-
import os, boto3, botocore


S3BUCKET = os.environ.get('S3BUCKET', None)
S3PREFIX = os.environ.get('S3PREFIX', 'rds/')
LASTRECEIVEDFILENAME = os.environ.get('LASTRECEIVEDFILENAME', '.timestamp')


def lambda_handler(event, context):
    log_file_data = ""
    rds_client = boto3.client('rds')
    s3_client = boto3.client('s3', endpoint_url=os.environ.get('ENDPOINT_URL'))
    for db_instance in [instance for instance in rds_client.describe_db_instances()['DBInstances']]:
        db_name = db_instance['DBInstanceIdentifier']
        last_received_file = S3PREFIX + db_name + '/' + LASTRECEIVEDFILENAME
        first_run = False
        print('Inspecting logs for {}'.format(db_name))

        db_logs = rds_client.describe_db_log_files(DBInstanceIdentifier=db_name)
        last_written_time = 0
        last_written_this_run = 0
        try:
            s3_response = s3_client.get_object(Bucket=S3BUCKET, Key=last_received_file)
        except botocore.exceptions.ClientError as e:
            error_code = int(e.response['ResponseMetadata']['HTTPStatusCode'])
            if error_code == 404:
                print("It appears this is the first log import, all files will be retrieved from RDS")
                first_run = True
            else:
                raise e

        if not first_run:
            last_written_time = int(s3_response['Body'].read(s3_response['ContentLength']))
            print("Found marker from last log download, retrieving log files with lastWritten time after %s" % str(last_written_time))
        for db_log in db_logs['DescribeDBLogFiles']:
            if (int(db_log['LastWritten']) > last_written_time) or first_run:
                print("Downloading log file: %s found and with LastWritten value of: %s " % (db_log['LogFileName'], db_log['LastWritten']))
                if int(db_log['LastWritten']) > last_written_this_run:
                    last_written_this_run = int(db_log['LastWritten'])
                log_file = rds_client.download_db_log_file_portion(DBInstanceIdentifier=db_name, LogFileName=db_log['LogFileName'], Marker='0')
                log_file_data = log_file['LogFileData']
                while log_file['AdditionalDataPending']:
                    log_file = rds_client.download_db_log_file_portion(DBInstanceIdentifier=db_name, LogFileName=db_log['LogFileName'], Marker=log_file['Marker'])
                    log_file_data += log_file['LogFileData']
                byteData = str.encode(log_file_data)
                object_name = S3PREFIX + db_name + '/' + db_log['LogFileName']
                print(object_name)
                s3_response = s3_client.put_object(Bucket=S3BUCKET, Key=object_name, Body=byteData)
                print("Writing log file %s to S3 bucket %s" % (object_name, S3BUCKET))
        s3_response = s3_client.put_object(Bucket=S3BUCKET, Key=last_received_file, Body=str.encode(str(last_written_this_run)))
        print("Wrote new Last Written Marker to %s in Bucket %s" % (last_received_file, S3BUCKET))
        print("Log file export complete")
