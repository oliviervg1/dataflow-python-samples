#!/usr/bin/env bash

set -e

GCP_PROJECT="data-ingestion-and-storage"
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
    --runner DirectRunner \
    --project ${GCP_PROJECT} \
    --temp_location gs://${DF_GCS_BUCKET}/temp/ \
    --save_main_session true \
    --input projects/${GCP_PROJECT}/subscriptions/${INPUT_PUBSUB_TOPIC} \
    --instance ${OUTPUT_BT_INSTANCE} \
    --table ${OUTPUT_BT_TABLE} \
    --requirements_file requirements.txt \
    --streaming
