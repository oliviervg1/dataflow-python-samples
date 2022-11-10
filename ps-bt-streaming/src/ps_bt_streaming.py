import argparse
import logging
import random

import apache_beam as beam

from apache_beam.io.gcp.bigtableio import WriteToBigTable
from apache_beam.options.pipeline_options import PipelineOptions

from google.cloud.bigtable import row


def convert_to_directrow(message):
    decoded_message = message.decode('utf-8')

    row_key = f'key#{random.randint(0, 10)}'
    direct_row = row.DirectRow(row_key=row_key)
    direct_row.set_cell(
        'cf1', 'cq1', decoded_message
    )
    return direct_row


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--input',
        dest='input',
        required=True,
        help='Input Pub/Sub subscription.'
    )
    parser.add_argument(
        '--instance',
        dest='instance',
        required=True,
        help='Output BigTable instance.'
    )
    parser.add_argument(
        '--table',
        dest='table',
        required=True,
        help='Output BigTable table.'
    )
    known_args, pipeline_args = parser.parse_known_args(argv)

    pipeline_options = PipelineOptions(pipeline_args)
    p = beam.Pipeline(options=pipeline_options)

    processed_records = (
        p
        | 'Read from Pub/Sub' >> beam.io.ReadFromPubSub(subscription=known_args.input)
        | 'Convert to DirectRow' >> beam.Map(convert_to_directrow)
        | 'Stream to BigTable' >> WriteToBigTable(
            project_id=pipeline_options.get_all_options()['project'],
            instance_id=known_args.instance,
            table_id=known_args.table
        )
    )

    result = p.run()
    return result


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    result = run()
    result.wait_until_finish()
