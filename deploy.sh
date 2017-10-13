#!/usr/bin/env bash

ENV=$1

if [ "$2" = "no-cache" ]; then
    NOCACHE=true
fi

AWS_ACCESS_KEY_ID=$(eval "echo \$${ENV}_AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY=$(eval "echo \$${ENV}_AWS_SECRET_ACCESS_KEY")
AWS_S3_BUCKET=$(eval "echo \$${ENV}_S3_BUCKET")

configure_aws_cli() {
	aws --version
	aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
	aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
	aws configure set default.output json
	echo "Configured AWS CLI."
}

deploy_s3bucket() {
	if [ "$NOCACHE" = "true" ]; then
		echo "Deploying without cache-control"
		aws s3 sync --dryrun ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET} --cache-control private,no-store,no-cache,must-revalidate,max-age=0 --exclude "*.txt" --exclude "*.js" --exclude "*.css"
		result=`aws s3 sync ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET}  --cache-control private,no-store,no-cache,must-revalidate,max-age=0 --exclude "*.txt" --exclude "*.js" --exclude "*.css"`
	else
		echo "Deploying with cache-control"
		aws s3 sync --dryrun ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET} --cache-control max-age=0,s-maxage=86400 --exclude "*.txt" --exclude "*.js" --exclude "*.css"
		result=`aws s3 sync ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET}  --cache-control max-age=0,s-maxage=86400 --exclude "*.txt" --exclude "*.js" --exclude "*.css"`
	fi

	if [ $? -eq 0 ]; then
		echo "All html, font, image and media files are Deployed without gzip encoding!"
	else
		echo "Deployment Failed  - $result"
		exit 1
	fi

	if [ "$NOCACHE" = "true" ]; then
		echo "Deploying without cache-control"
		aws s3 sync --dryrun ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET} --cache-control private,no-store,no-cache,must-revalidate,max-age=0 --exclude "*" --include "*.txt" --include "*.js" --include "*.css" --content-encoding gzip
		result=`aws s3 sync ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET}  --cache-control private,no-store,no-cache,must-revalidate,max-age=0 --exclude "*" --include "*.txt" --include "*.js" --include "*.css" --content-encoding gzip`
	else
		echo "Deploying with cache-control"
		aws s3 sync --dryrun ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET} --cache-control max-age=0,s-maxage=86400 --exclude "*" --include "*.txt" --include "*.js" --include "*.css" --content-encoding gzip
		result=`aws s3 sync ${HOME}/${CIRCLE_PROJECT_REPONAME}/dist s3://${AWS_S3_BUCKET}  --cache-control max-age=0,s-maxage=86400 --exclude "*" --include "*.txt" --include "*.js" --include "*.css" --content-encoding gzip`
	fi

	if [ $? -eq 0 ]; then
		echo "All css, js, and map files are Deployed! with gzip"
	else
		echo "Deployment Failed  - $result"
		exit 1
	fi	

}

echo -e "application/font-woff\t\t\t\twoff2" >> /etc/mime.types
echo -e "application/font-sfnt\t\t\t\tttf" >> /etc/mime.types
echo -e "application/json\t\t\t\tmap" >> /etc/mime.types

cat /etc/mime.types  | grep -i woff
cat /etc/mime.types  | grep -i ico
cat /etc/mime.types  | grep -i map
cat /etc/mime.types  | grep -i ttf

configure_aws_cli
deploy_s3bucket
