# -*- coding: utf-8 -*-
import json
import urllib
import boto3
import base64
import zlib
import os
import ast
from datetime import datetime
from elasticsearch import Elasticsearch

ES_HOST = os.environ.get('ES_HOST', 'localhost')
ES_PORT = os.environ.get('ES_PORT', '9200')
ES_PROTOCOL = os.environ.get('ES_PROTOCOL', 'https')
ES_AUTH_ENABLED = ast.literal_eval(os.environ.get('ES_AUTH_ENABLED', 'True'))
ES_AUTH = None 
ES_INDEX = os.environ.get('ES_INDEX', 'logstash-{}'.format(datetime.now().strftime('%Y.%m.%d')))
if ES_AUTH_ENABLED:
    ES_USER = os.environ.get('ES_USER', None)
    ES_PASSWORD = os.environ.get('ES_PASSWORD', None)
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
    response = s3_client.get_object(Bucket=bucket, Key=key)
    body = response['Body']
    data = body.read()

    try:
        data = zlib.decompress(data, 16 + zlib.MAX_WBITS)
        print('Detected gzipped content')
    except zlib.error:
        print('Content couldn\'t be ungzipped, assuming plain text')

    doc = {
        'source': 's3',
        'message': data.decode("utf-8"),
        'key': key,
        'bucket': bucket,
        '@timestamp': datetime.now(),
    }
    print(es_client.index(index=ES_INDEX, doc_type='doc', body=doc))
