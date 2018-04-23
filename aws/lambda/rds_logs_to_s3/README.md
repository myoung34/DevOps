RDS Logs to S3
===========================================================

This lambda runs on a timer to move logs into S3 from RDS

Make sure you [enable user logging first via this guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.PostgreSQL.html)

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
