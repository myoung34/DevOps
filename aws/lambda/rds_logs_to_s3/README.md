RDS Logs to S3
===========================================================

This lambda runs on a timer to move logs into S3 from RDS

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
