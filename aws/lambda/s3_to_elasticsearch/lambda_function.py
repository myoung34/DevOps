# -*- coding: utf-8 -*-
import sys
sys.path.insert(0, './dist')
import json
import urllib
import boto3
import base64
import zlib
import os
import ast
import boto3
import botocore
import logging
import botocore.vendored.requests as requests
from datetime import datetime
from elasticsearch import Elasticsearch
from stratatilities.auth import get_vault_client, read_vault_secret
from time import sleep


ES_HOST = os.environ.get('ES_HOST', None)
ES_PORT = os.environ.get('ES_PORT', None)
ES_PROTOCOL = os.environ.get('ES_PROTOCOL', 'https')
ES_AUTH_ENABLED = ast.literal_eval(os.environ.get('ES_AUTH_ENABLED', 'True'))
ES_AUTH = None
if ES_AUTH_ENABLED:
    vault_client = get_vault_client()
    ES_HOST = os.environ.get('ES_HOST', read_vault_secret(vault_client, 'secret/base/ELASTICSEARCH_HOST'))
    ES_PORT = os.environ.get('ES_PORT', read_vault_secret(vault_client, 'secret/base/ELASTICSEARCH_PORT'))
    ES_USER = read_vault_secret(vault_client, 'secret/ops/s3_to_elasticsearch_lambda/ELASTICSEARCH_USER')
    ES_PASSWORD = read_vault_secret(vault_client, 'secret/ops/s3_to_elasticsearch_lambda/ELASTICSEARCH_PASSWORD')
    ES_AUTH = (ES_USER, ES_PASSWORD)

es_client = Elasticsearch(
    [f'{ES_HOST}'],
    http_auth=ES_AUTH,
    scheme=ES_PROTOCOL,
    port=ES_PORT,
)


def lambda_handler(event, context):
    print('[Debug] Base64 encoded payload: {}'.format(base64.b64encode(json.dumps(event).encode('ascii'))))

    s3_client = boto3.client('s3', endpoint_url=os.environ.get('ENDPOINT_URL'))

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    sleep(3)
    response = s3_client.get_object(Bucket=bucket, Key=key)
    body = response['Body']
    data = body.read()

    try:
        data = zlib.decompress(data, 16 + zlib.MAX_WBITS)
        print('Detected gzipped content')
    except zlib.error:
        print('Content couldn\'t be ungzipped, assuming plain text')

    date = datetime.now().strftime('%Y.%m.%d')

    doc = {
        'source': 's3',
        'message': data.decode("utf-8"),
        'key': key,
        'bucket': bucket,
        '@timestamp': datetime.now(),
    }
    print(es_client.index(index=f'logstash-{date}', doc_type='doc', body=doc))
