include scripts/makefile/Makefile.init

###############
## Constants ##
###############
BUILD_FOLDER = build
REQUIRED_BUILD_DEPENDENCIES = yarn
REQUIRED_RUNTIME_DEPENDENCIES = node

##############################
## Dependency Check Targets ##
##############################
check: check-runtime-deps check-build-deps # Checks if runtime and build requirements are available

check-runtime-deps:
	$(foreach exec,${REQUIRED_RUNTIME_DEPENDENCIES},\
	$(if $(shell which ${exec}),@echo -e "${exec} is installed",$(error "No ${exec} in PATH")))

check-build-deps:
	$(foreach exec,${REQUIRED_BUILD_DEPENDENCIES},\
	$(if $(shell which ${exec}),@echo -e "${exec} is installed",$(error "No ${exec} in PATH")))

##########################
# Variable Check Targets #
##########################
check-version: # Checks for the presence of the $version variable
ifeq ("${version}", "")
	$(error "Variable 'version' was not provided")
endif


################################
# CloudFront Logs Lambda Build #
################################
install-cloudfront-logs-lambda: # Installs CloudFront Logs Lambda Dependencies
	yarn --cwd modules/cloudfront-logs/lambda install

build-cloudfront-logs-lambda:
	yarn --cwd modules/cloudfront-logs/lambda build


###########################
## Example Build Targets ##
###########################
example-clean: # Cleans the example Next.js application build outputs
	rm -rf ${BUILD_FOLDER} || exit 0
	mkdir -p ${BUILD_FOLDER}

example-install: check # Installs the dependencies for the example project
	yarn --cwd example install

example-build: example-clean # Builds the example Next.js application
	yarn --cwd example package
	cp -r example/.open-next/* ${BUILD_FOLDER}
	for f in ${BUILD_FOLDER}/*; do cd $$f; zip -rq $$f.zip . && cd -; rm -rf $$f; done

tag-release: check-version build-cloudfront-logs-lambda
	git add .
	git commit --allow-empty -m "Release ${version}"
	git push

	git tag ${version}
	git push --tags
