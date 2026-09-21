import json
import requests
from urllib.parse import urlparse

API_URL = 'https://placeholder.com'
OUTPUT_FILE_PATH = 'input_data'
TIMEOUT = 30


def validate_url(url):
    parsed_url = urlparse(url)
    if not parsed_url.scheme or not parsed_url.netloc:
        raise ValueError(f'Input API URL is invalid: {url}')


def fetch_api_data(base_url):

    validate_url(base_url)

    output_data = []
    page = 1
    previous_page = 0

    while True:
        try:
            response = requests.get(base_url, params={'page': page}, timeout=TIMEOUT)
            response.raise_for_status()
        except requests.RequestException as exc:
            raise RuntimeError(f'API request failed for page {page}: {exc}') from exc

        try:
            payload = response.json()
        except ValueError as exc:
            raise ValueError(f'Invalid JSON read from API at page {page}') from exc

        if not isinstance(payload, dict):
            raise ValueError(f'Payload not a dictionary as expected\nPayload type: {type(payload).__name__}')

        records = payload.get('results')
        if records is None:
            records = payload.get('items', [])

        if not records:
            print(f'No records found on page {page}\nStopping pagination')
            break

        output_data.extend(records)

        total_pages = payload.get('total_pages')
        if total_pages is not None and page >= total_pages:
            break

        if page == previous_page:
            raise RuntimeError(f'Pagination is not advancing from page {page}')
        previous_page = page
        page += 1

    return output_data


if __name__ == '__main__':
    data = fetch_api_data(API_URL)
    if not data:
        print(f'No data retrieved from the API')

    output_file_name = 'ticket-orders.json'
    with open(f'{OUTPUT_FILE_PATH}/{output_file_name}', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

    print(f'Data successfully read from API endpoint and saved to {OUTPUT_FILE_PATH}/{output_file_name}\n{len(data)} rows processed')
