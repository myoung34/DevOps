#!/bin/sh

if [[ -z "${AWS_DEFAULT_REGION}" ]]; then
  EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
  EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
  export AWS_DEFAULT_REGION=$EC2_REGION
fi

while [[ true ]]; do
  /usr/local/bin/custodian run \
    --output-dir=/tmp/output \
    /tmp/custodian.yml
  sleep 300
done
