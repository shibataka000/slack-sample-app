.PHONY: default deploy destroy package

ZIPFILE = $(shell pwd)/terraform/project.zip

default: deploy

deploy: package
	cd terraform; terraform apply -auto-approve

destroy:
	cd terraform; terraform destroy -force

package:
	zip -rq $(ZIPFILE) handler
	cd venv/lib/python3.6/site-packages; zip -rq $(ZIPFILE) *
