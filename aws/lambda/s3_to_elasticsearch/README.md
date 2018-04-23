S3 to Elasticsearch
===========================================================

This lambda is triggered by S3 events to fork them into ELK

## To Test

```
make test
```

## To Deploy

```
# verify changes look as expected
make plan

# actually do the deploy if the previous plan seems fine
make deploy
```
