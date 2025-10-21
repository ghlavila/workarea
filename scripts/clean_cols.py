import argparse
import pandas as pd
import re
from datetime import datetime

def clean_dollar(value):
    # Remove dollar sign and commas
    return re.sub(r'[^\d.]', '', value)

def format_date(value):
    # Convert date from MM/DD/YYYY to YYYYMMDD
    return datetime.strptime(value, '%m/%d/%Y').strftime('%Y%m%d')

def process_csv(file_path, date_column, dollar_column):
    # Read the CSV file
    df = pd.read_csv(file_path)

    # Process the date column if specified
    if date_column:
        if date_column not in df.columns:
            print(f"Column '{date_column}' not found in the CSV file.")
        else:
            df[date_column] = df[date_column].apply(format_date)

    # Process the dollar column if specified
    if dollar_column:
        if dollar_column not in df.columns:
            print(f"Column '{dollar_column}' not found in the CSV file.")
        else:
            df[dollar_column] = df[dollar_column].apply(clean_dollar)

    # Print the processed DataFrame
    print(df)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a CSV file.')
    parser.add_argument('file_path', type=str, help='Path to the CSV file')
    parser.add_argument('--clean-date-col', type=str, help='Name of the column to clean dates')
    parser.add_argument('--clean-dollar-col', type=str, help='Name of the column to clean dollar values')

    args = parser.parse_args()

    process_csv(args.file_path, args.clean_date_col, args.clean_dollar_col)