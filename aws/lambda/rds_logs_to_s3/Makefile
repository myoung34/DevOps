zip:
	rm -rf lambda_rds_logs_to_s3.zip
	zip -r lambda_rds_logs_to_s3.zip lambda_function.py

test:
	bats test.bats

clean:
	git status . | grep Untracked -A 1000 | xargs rm -rf
