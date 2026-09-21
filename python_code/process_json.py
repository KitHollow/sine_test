import json
from pathlib import Path
import pandas as pd
from pandas import json_normalize as json_normalise
import re
import warnings

def camel_to_snake_case(column_name):
    ''' Function to convert from camelCase to snake_case '''
    return re.sub(r'(?<!^)(?=[A-Z])', '_', column_name).lower()


def enforce_schema(dataframe: pd.DataFrame, schema: dict) -> pd.DataFrame:
    ''' Function to enforce schema with expect columns and data types '''

    is_columns_missing = set(schema) - set(dataframe.columns)
    if is_columns_missing:
        raise ValueError(f'Columns are missing from expected schema: {sorted(is_columns_missing)}')

    for column, output_type in schema.items():
        if column not in dataframe.columns:
            continue

        if output_type == 'integer':
            try:
                dataframe[column] = pd.to_numeric(dataframe[column], errors='raise').astype('Int64')
            except Exception as exc:
                raise ValueError(f'Cannot convert {column} as int')
        elif output_type == 'float':
            try:
                dataframe[column] = pd.to_numeric(dataframe[column], errors='raise').astype('float64')
            except Exception as exc:
                            raise ValueError(f'Cannot convert {column} as float')
        elif output_type == 'string':
                dataframe[column] = dataframe[column].astype(str)
        elif output_type == 'datetime':
            try:
                dataframe[column] = pd.to_datetime(dataframe[column], errors='raise')
            except Exception as exc:
                            raise ValueError(f'Cannot convert {column} as datetime')
        elif output_type == 'boolean':
            try:
                dataframe[column] = dataframe[column].astype('boolean')
            except Exception as exc:
                            raise ValueError(f'Cannot convert {column} as bool')
        else:
            raise ValueError(f'Unsupported type: {output_type}')

    return dataframe


OUTPUT_FILE_PATH = 'output_data'
Path(OUTPUT_FILE_PATH).mkdir(parents=True, exist_ok=True)
OUTPUT_SCHEMA = {
    'order_id': 'integer',
    'booker_id': 'integer',
    'product_type': 'string',
    'sales_channel': 'string',
    'ticket_count': 'integer',
    'pricing_currency': 'string',
    'pricing_average_ticket_price': 'float',
    'pricing_total_gross': 'float',
    'customer_country': 'string',
    'customer_region': 'string',
    'customer_city': 'string',
    'customer_postal_code': 'string',
    'performance_show_name': 'string',
    'performance_starts_at': 'datetime',
    'purchase_purchased_at': 'datetime',
    'purchase_lead_time_days': 'integer',
    'purchase_weeks_prior_to_performance': 'integer',
}

json_file_path = 'input_data/ticket-orders.json'
file_path = Path(json_file_path)
if not file_path.exists():
    raise FileNotFoundError(f'Input file was not found at" {file_path}')

with file_path.open('r', encoding='utf-8') as f:
    payload = json.load(f)
if not isinstance(payload, dict):
    raise TypeError('Payload not JSON dict as expected')

records = payload.get('data')
if not isinstance(records, list):
    raise ValueError('Data is not a list of records as expected')

output_dataframe = json_normalise(records)
if output_dataframe.empty:
    warnings.warn(
        'No records were produced after normalisation: output dataframe is empty',
        UserWarning
    )

output_dataframe.columns = [camel_to_snake_case(column).replace('.', '_') for column in output_dataframe.columns]
output_dataframe = enforce_schema(output_dataframe, OUTPUT_SCHEMA)

output_file_name = 'ticket_orders'
output_dataframe.to_parquet(f'{OUTPUT_FILE_PATH}/{output_file_name}.parquet')
output_dataframe.to_csv(f'{OUTPUT_FILE_PATH}/{output_file_name}.csv')

print(f'JSON file parsed into Parquet with no issues')
