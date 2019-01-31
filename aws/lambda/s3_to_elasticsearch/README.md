S3 to Elasticsearch
===========================================================

This lambda is triggered by S3 events to fork them into ELK

## To Test

```
make test
```

## To Deploy

```
make zip
terraform apply -auto-approve
```
