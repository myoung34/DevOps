install:
	if [ ! -d venv ]; then virtualenv venv; fi
	. venv/bin/activate
	pip3 install -r requirements.txt -t . >/dev/null
	rm -rf venv

zip: install
	rm -rf lambda_s3_to_elasticsearch.zip
	zip -r lambda_s3_to_elasticsearch.zip -x@exclude.lst . >/dev/null

test: zip
	bats test.bats

clean:
	rm -rf venv
	git status . | grep Untracked -A 1000 | xargs rm -rf
