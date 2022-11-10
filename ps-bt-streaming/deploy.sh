#!/usr/bin/env bash

set -e

GCP_PROJECT="data-ingestion-and-storage"
REGION="us-central1"
SERVICE_ACCOUNT="dataflow@data-ingestion-and-storage.iam.gserviceaccount.com"
SHARED_VPC="https://www.googleapis.com/compute/v1/projects/networking-351216/regions/us-central1/subnetworks/default"
DF_GCS_BUCKET="ovg-dataflow"

INPUT_PUBSUB_TOPIC="dataflow"
OUTPUT_BT_INSTANCE="ovg-bt-demo"
OUTPUT_BT_TABLE="messages"

# Setup gcloud
gcloud config set project ${GCP_PROJECT}

# Create Pub/Sub topic
gcloud pubsub topics create ${INPUT_PUBSUB_TOPIC} \
    || echo 'Topic already exists!'

# Create Pub/Sub subscription
gcloud pubsub subscriptions create ${INPUT_PUBSUB_TOPIC} \
    --topic projects/${GCP_PROJECT}/topics/${INPUT_PUBSUB_TOPIC} \
    || echo 'Subscription already exists!'

# Start / update pipeline
python src/ps_bt_streaming.py \
    --job_name ps-bt-streaming \
    --runner DataflowRunner \
    --project ${GCP_PROJECT} \
    --region ${REGION} \
    --service_account_email ${SERVICE_ACCOUNT} \
    --subnetwork ${SHARED_VPC} \
    --no_use_public_ips \
    --temp_location gs://${DF_GCS_BUCKET}/temp/ \
    --staging_location gs://${DF_GCS_BUCKET}/staging/ \
    --save_main_session true \
    --input projects/${GCP_PROJECT}/subscriptions/${INPUT_PUBSUB_TOPIC} \
    --instance ${OUTPUT_BT_INSTANCE} \
    --table ${OUTPUT_BT_TABLE} \
    --requirements_file requirements.txt \
    --streaming \
    --dataflow_service_options=enable_prime \
    --dataflow_service_options=enable_hot_key_logging \
    --dataflow_service_options=enable_google_cloud_profiler \
    --enable_streaming_engine true \
    --prebuild_sdk_container_engine=cloud_build
