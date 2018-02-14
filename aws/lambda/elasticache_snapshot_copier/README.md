Elasticache Snapshot Copier
===================

This runs in lambda and copies automatic Elasticache snapshots so that theyre safe from terraform


## To Test

```
export AWS_ACCESS_KEY_ID=your_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key

docker-compose run lambda
```

## To Deploy

```
# ensure you're using python 3.6 (pyenv should respect .python-version)
make install

# verify changes look as expected
make plan

# actually do the deploy if the previous plan seems fine
make deploy
```
