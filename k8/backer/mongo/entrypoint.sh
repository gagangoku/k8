#!/bin/bash
# Copied from https://github.com/birotaio/mongodb-gcs-backup

#echo "sleeping"
#sleep infinity
#exit 1

set -x
set -e

set -o pipefail
set -o errexit
set -o errtrace
set -o nounset
# set -o xtrace

echo "Starting backup script"
date

BACKUP_DIR=${BACKUP_DIR:-/tmp}
BOTO_CONFIG_PATH=${BOTO_CONFIG_PATH:-/root/.boto}
GCS_BUCKET=${GCS_BUCKET:-}
GCS_KEY_FILE_PATH=${GCS_KEY_FILE_PATH:-}

MONGODB_HOST=${MONGODB_HOST:-}
MONGODB_PORT=${MONGODB_PORT:-}
MONGODB_DB=${MONGODB_DB:-}

SLACK_CHANNEL=${SLACK_CHANNEL:-}
SLACK_TOKEN=${SLACK_TOKEN:-}


backup() {
    mkdir -p $BACKUP_DIR
    date=$(date "+%Y-%m-%dT%H%M%SZ")
    archive_name="$BACKUP_DIR/mongo-backup-$date.tar.gz"

    cmd="mongodump --host=$MONGODB_HOST --port=$MONGODB_PORT --db=$MONGODB_DB --gzip --archive=$archive_name"
    echo "starting to backup Mongo"
    eval "$cmd"
}

upload_to_gcs() {
    if [[ $GCS_KEY_FILE_PATH != "" ]]
    then
    cat <<EOF > $BOTO_CONFIG_PATH
[Credentials]
gs_service_key_file = $GCS_KEY_FILE_PATH
[Boto]
https_validate_certificates = True
[GoogleCompute]
[GSUtil]
content_language = en
default_api_version = 2
[OAuth2]
EOF
    fi
    echo "uploading backup archive to GCS bucket=$GCS_BUCKET"
    gsutil cp $archive_name $GCS_BUCKET
    send_slack_message "Mongo backup done :smile: : $archive_name"
}

send_slack_message() {
    local message=${1}
    echo 'Sending to '${SLACK_CHANNEL}'...'
    curl -X POST https://slack.com/api/chat.postMessage -H "Content-type: application/json" -H "Authorization: Bearer $SLACK_TOKEN" -d"{'channel': '$SLACK_CHANNEL', 'text': '$message'}"
    echo
}

err() {
    err_msg="Something went wrong on line $(caller)"
    echo $err_msg >&2
    send_slack_message "Error while performing mongo backup :cry: : $err_msg"
}

cleanup() {
    rm $archive_name
}

trap err ERR
backup
upload_to_gcs
cleanup
echo "mongo backup done!"
