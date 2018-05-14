install:
	if [ ! -d venv ]; then virtualenv venv; fi
	. venv/bin/activate
	pip3 install -r requirements.txt -t dist >/dev/null
	rm -rf venv

zip: install
	rm -rf lambda_s3_to_elasticsearch.zip
	zip -r lambda_s3_to_elasticsearch.zip lambda_function.py dist >/dev/null

test: zip
	bats test.bats

clean:
	rm -rf venv dist
