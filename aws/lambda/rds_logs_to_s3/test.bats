#!/usr/bin/env bats

function setup() {
  export S3BUCKET=somebucket
  export HOSTNAME=$HOSTNAME
  docker-compose up -d localstack
  sleep 5
  aws s3 mb s3://somebucket --endpoint http://localhost:4572
}

function teardown() {
  docker-compose down
}

@test "pulls all logs into s3" {
  docker-compose run lambda
  files_in_s3=$(aws s3 ls s3://somebucket/ --endpoint http://localhost:4572 --recursive | wc -l)
  [[ $files_in_s3 -ge 1 ]]

  docker-compose run lambda
  new_files_in_s3=$(aws s3 ls s3://somebucket/ --endpoint http://localhost:4572 --recursive | wc -l)
  [[ $new_files_in_s3 -ge 1 ]]
  [[ $files_in_s3 -eq $new_files_in_s3 ]]
}
