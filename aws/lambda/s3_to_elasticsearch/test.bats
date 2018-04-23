#!/usr/bin/env bats 

function setup() {
  docker-compose down
  export S3BUCKET=somebucket
  export HOSTNAME=$HOSTNAME
  docker-compose up -d localstack
  docker-compose up -d elasticsearch
  sleep 30
  aws s3 mb s3://somebucket --endpoint http://localhost:4572
  echo something >foo
  gzip foo
  aws s3 cp foo.gz s3://somebucket  --endpoint http://localhost:4572
}

function teardown() {
  docker-compose down
  rm foo.gz
  unset VAULT_TOKEN
  unset AWS_LAMBDA_EVENT_BODY
}

@test "reads file from s3 into elasticsearch" {
  [[ $(aws s3 ls s3://somebucket/ --endpoint http://localhost:4572 --recursive | wc -l) -eq 1 ]]

  export AWS_LAMBDA_EVENT_BODY=$(cat resources/event.json | tr -d '\n' | sed 's/#/\\#/g')
  docker-compose run lambda
  sleep 10
  index="logstash-$(date +%Y.%m.%d)"
  data=$(curl -s "http://localhost:9200/${index}/_search?pretty=true&q=*:*" | jq .hits.hits[]._source)
  [[ $(echo $data | jq -r .source) == "s3" ]]
  [[ $(echo $data | jq -r .key) == "foo.gz" ]]
  [[ $(echo $data | jq -r .bucket) == "somebucket" ]]
  [[ $(echo $data | jq -r .message) == "something" ]]
}
