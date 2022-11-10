import argparse
import logging

import apache_beam as beam

from apache_beam.options.pipeline_options import PipelineOptions


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--input',
        dest='input',
        required=True,
        help='Input Pub/Sub subscription.'
    )
    parser.add_argument(
        '--output',
        dest='output',
        required=True,
        help='Output BigQuery table.'
    )
    known_args, pipeline_args = parser.parse_known_args(argv)

    pipeline_options = PipelineOptions(pipeline_args)
    p = beam.Pipeline(options=pipeline_options)

    processed_records = (
        p
        | 'Read from Pub/Sub' >> beam.io.ReadFromPubSub(subscription=known_args.input)
        | 'Parse messages' >> beam.Map(lambda x: {'message': x.decode('utf-8')})
        | 'Stream to BigQuery' >> beam.io.WriteToBigQuery(
            known_args.output,
            insert_retry_strategy='RETRY_ON_TRANSIENT_ERROR',
            create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
            write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND
        )
    )

    result = p.run()
    return result


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run()
