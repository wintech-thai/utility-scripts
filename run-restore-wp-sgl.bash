#!/usr/bin/bash

export NAMESPACE=web-sgl
export S3_FILE=sgl/wp-backup-gke-20261006220007.zip

export S3_KEY=<YOUR_S3_KEY>
export S3_SECRET=<YOUR_S3_SECRET>
export S3_BUCKET=<YOUR_S3_BUCKET>

export S3_URL=https://storage.googleapis.com
export WP_APP_POD=$(kubectl get pods -n ${NAMESPACE} -o name | grep wordpress | sed 's|pod/||')
export WP_MYSQL_POD=$(kubectl get pods -n ${NAMESPACE} -o name | grep mysql | sed 's|pod/||')
export APP_DATA_PATH=/bitnami/wordpress

ruby restore-wordpress.rb
