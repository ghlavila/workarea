#!/usr/bin/python3
import pandas as pd
import logging
from pathlib import Path
import sys
import argparse
from datetime import datetime
import boto3
import io
from urllib.parse import urlparse
import re
import os

class ExcelConverter:
    def __init__(self, log_dir="logs", chunk_size=10000):
        """Initialize converter with logging setup and S3 client"""
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        self.chunk_size = chunk_size
        self.s3_client = boto3.client('s3')
        
        # Setup logging
        log_file = self.log_dir / f"excel_conversion_{datetime.now().strftime('%Y%m%d')}.log"
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def parse_s3_path(self, s3_path):
        """Parse S3 path into bucket and key"""
        parsed = urlparse(s3_path)
        if parsed.scheme != 's3':
            raise ValueError(f"Invalid S3 path: {s3_path}. Must start with 's3://'")
        
        bucket = parsed.netloc
        key = parsed.path.lstrip('/')
        return bucket, key

    def clean_column_name(self, column_name):
        """
        Clean column name by:
        1. Converting to lowercase
        2. Converting dashes to underscores
        3. Removing special characters
        4. Converting spaces to underscores
        5. Removing multiple underscores
        """
        # Convert to string in case of numeric column names
        column_name = str(column_name)
        
        # Convert to lowercase
        cleaned = column_name.lower()
        
        # Convert dashes to underscores
        cleaned = cleaned.replace('-', '_')
        
        # Remove special characters and convert spaces to underscores
        cleaned = re.sub(r'[^a-z0-9\s]', '', cleaned)
        cleaned = cleaned.replace(' ', '_')
        
        # Remove multiple underscores
        cleaned = re.sub(r'_+', '_', cleaned)
        
        # Strip leading/trailing underscores
        cleaned = cleaned.strip('_')
        
        # Ensure the column name isn't empty
        if not cleaned:
            cleaned = 'column'
            
        return cleaned

    def clean_chunk(self, df, first_chunk=False):
        """Clean a chunk of data"""
        # Clean column names if this is the first chunk
        if first_chunk:
            # Clean column names and handle duplicates
            new_columns = []
            seen_columns = set()
            
            for col in df.columns:
                cleaned_col = self.clean_column_name(col)
                
                # Handle duplicate column names
                base_col = cleaned_col
                counter = 1
                while cleaned_col in seen_columns:
                    cleaned_col = f"{base_col}_{counter}"
                    counter += 1
                
                new_columns.append(cleaned_col)
                seen_columns.add(cleaned_col)
            
            df.columns = new_columns
        
        # Replace problematic characters
        df = df.replace({
            '\n': ' ',      # Replace newlines with spaces
            '\r': ' ',      # Replace carriage returns
            '\t': ' ',      # Replace tabs
            '\xa0': ' ',    # Replace non-breaking spaces
            '\u200b': ''    # Remove zero-width spaces
        }, regex=True)
        
        # Remove any leading/trailing whitespace
        df = df.apply(lambda x: x.str.strip() if x.dtype == "object" else x)
        
        return df

    def clean_filename(self, filename):
        """
        Clean filename by removing special characters and converting spaces to underscores
        Example: "My File (2024).xlsx" -> "My_File_2024.xlsx"
        """
        # Get the base name and extension separately
        base, ext = os.path.splitext(filename)
        
        # Remove special characters and convert spaces to underscores
        cleaned = re.sub(r'[^a-zA-Z0-9\s]', '', base)
        cleaned = cleaned.replace(' ', '_')
        
        # Remove multiple underscores
        cleaned = re.sub(r'_+', '_', cleaned)
        
        # Strip leading/trailing underscores
        cleaned = cleaned.strip('_')
        
        return f"{cleaned}{ext}"

    def generate_output_path(self, input_s3_path, output_s3_path=None):
        """
        Generate output S3 path based on input path and optional output path
        
        If output_s3_path is:
        - None: use input bucket/path with transformed filename
        - Path ending with '/': use provided path with transformed input filename
        - Full path with filename: use as-is
        """
        input_bucket, input_key = self.parse_s3_path(input_s3_path)
        input_dir, input_filename = os.path.split(input_key)
        
        # If no output path specified, use input path with transformed filename
        if output_s3_path is None:
            base_filename = os.path.splitext(input_filename)[0]
            cleaned_filename = self.clean_filename(base_filename) + '.csv'
            output_key = os.path.join(input_dir, cleaned_filename) if input_dir else cleaned_filename
            return f"s3://{input_bucket}/{output_key}"
        
        # Parse output path
        output_bucket, output_key = self.parse_s3_path(output_s3_path)
        
        # Check if output path ends with '/' or doesn't include a filename
        if output_key.endswith('/') or '.' not in os.path.basename(output_key):
            # Use transformed input filename with provided path
            base_filename = os.path.splitext(input_filename)[0]
            cleaned_filename = self.clean_filename(base_filename) + '.csv'
            output_key = output_key.rstrip('/') + '/' + cleaned_filename
        
        return f"s3://{output_bucket}/{output_key}"

    def convert_excel_to_csv(self, input_s3_path, output_s3_path=None, sheet_name=0):
        """Convert Excel file to CSV using S3 streaming"""
        try:
            # Generate output path based on input and output paths
            final_output_path = self.generate_output_path(input_s3_path, output_s3_path)
            self.logger.info(f"Final output path: {final_output_path}")
            
            # Parse S3 paths
            input_bucket, input_key = self.parse_s3_path(input_s3_path)
            output_bucket, output_key = self.parse_s3_path(final_output_path)
            
            self.logger.info(f"Starting conversion of s3://{input_bucket}/{input_key}")
            self.logger.info(f"Output will be saved to s3://{output_bucket}/{output_key}")

            # Download Excel file to memory buffer
            excel_buffer = io.BytesIO()
            try:
                self.s3_client.download_fileobj(input_bucket, input_key, excel_buffer)
                excel_buffer.seek(0)
            except Exception as e:
                error_msg = f"Failed to download Excel file from S3: {str(e)}"
                self.logger.error(error_msg)
                raise Exception(error_msg)

            # Initialize Excel reader
            try:
                xl = pd.ExcelFile(excel_buffer, engine='openpyxl')
            except Exception as e:
                self.logger.warning(f"openpyxl engine failed: {str(e)}")
                self.logger.info("Trying xlrd engine...")
                try:
                    excel_buffer.seek(0)
                    xl = pd.ExcelFile(excel_buffer, engine='xlrd')
                except Exception as e2:
                    error_msg = f"Both engines failed. Error: {str(e2)}"
                    self.logger.error(error_msg)
                    raise Exception(error_msg)

            # Define constants for S3 upload
            rows_processed = 0
            min_part_size = 5 * 1024 * 1024  # 5MB minimum part size for multipart uploads
            buffer_size = 10 * 1024 * 1024  # 10MB buffer for collecting chunks before upload
            current_buffer = io.BytesIO()
            buffer_has_header = False
            is_first_chunk = True
            
            # Initialize multipart upload
            mpu = self.s3_client.create_multipart_upload(
                Bucket=output_bucket,
                Key=output_key
            )
            
            try:
                parts = []
                part_number = 1
                
                # Process in chunks
                self.logger.info("Starting chunk processing...")
                
                for chunk_start in range(0, sys.maxsize, self.chunk_size):
                    # Read chunk
                    df_chunk = pd.read_excel(
                        xl,
                        sheet_name=sheet_name,
                        skiprows=chunk_start if chunk_start > 0 else None,
                        nrows=self.chunk_size,
                        na_filter=False,
                        dtype=str,
                        keep_default_na=False
                    )
                    
                    # If chunk is empty, we've reached the end
                    if df_chunk.empty:
                        break
                    
                    # Clean the chunk (pass first_chunk flag)
                    df_chunk = self.clean_chunk(df_chunk, first_chunk=is_first_chunk)
                    
                    # Convert chunk to CSV
                    chunk_buffer = io.StringIO()
                    df_chunk.to_csv(
                        chunk_buffer,
                        index=False,
                        header=(is_first_chunk),  # Only write header for first chunk
                        encoding='utf-8',
                        quoting=1,
                        escapechar='\\',
                        date_format='%Y-%m-%d %H:%M:%S'
                    )
                    
                    # Get chunk data as bytes
                    chunk_bytes = chunk_buffer.getvalue().encode('utf-8')
                    chunk_buffer.close()
                    
                    # Add to current buffer
                    current_buffer.write(chunk_bytes)
                    current_buffer.flush()
                    
                    # If this is the first chunk, we have the header now
                    if is_first_chunk:
                        buffer_has_header = True
                        is_first_chunk = False
                    
                    # Get current buffer position to check size
                    current_buffer.seek(0, 2)  # Move to end
                    buffer_size_bytes = current_buffer.tell()
                    current_buffer.seek(0)  # Reset to beginning
                    
                    # If buffer is large enough, upload as a part
                    if buffer_size_bytes >= min_part_size:
                        # Upload buffer as a part
                        part = self.s3_client.upload_part(
                            Bucket=output_bucket,
                            Key=output_key,
                            PartNumber=part_number,
                            UploadId=mpu['UploadId'],
                            Body=current_buffer.read()
                        )
                        
                        parts.append({
                            'PartNumber': part_number,
                            'ETag': part['ETag']
                        })
                        
                        self.logger.info(f"Uploaded part {part_number} ({buffer_size_bytes} bytes)")
                        part_number += 1
                        
                        # Reset buffer for next batch
                        current_buffer = io.BytesIO()
                        buffer_has_header = False  # Header was in the first batch
                    
                    rows_processed += len(df_chunk)
                    self.logger.info(f"Processed chunk: rows {chunk_start} to {chunk_start + len(df_chunk)}")
                
                # Handle any remaining data in the buffer
                current_buffer.seek(0, 2)  # Move to end
                final_buffer_size = current_buffer.tell()
                current_buffer.seek(0)  # Reset to beginning
                
                if final_buffer_size > 0:
                    if len(parts) == 0:
                        # If we have no parts yet and only this small buffer,
                        # use put_object instead of multipart to avoid the EntityTooSmall error
                        self.logger.info(f"Small file detected ({final_buffer_size} bytes), using put_object instead of multipart")
                        
                        # Abort the multipart upload since we won't use it
                        self.s3_client.abort_multipart_upload(
                            Bucket=output_bucket,
                            Key=output_key,
                            UploadId=mpu['UploadId']
                        )
                        
                        # Use put_object for the entire content
                        self.s3_client.put_object(
                            Bucket=output_bucket,
                            Key=output_key,
                            Body=current_buffer.read()
                        )
                    else:
                        # We already have some parts, so add the last buffer as the final part
                        # even if it's smaller than min_part_size (allowed for the final part)
                        part = self.s3_client.upload_part(
                            Bucket=output_bucket,
                            Key=output_key,
                            PartNumber=part_number,
                            UploadId=mpu['UploadId'],
                            Body=current_buffer.read()
                        )
                        
                        parts.append({
                            'PartNumber': part_number,
                            'ETag': part['ETag']
                        })
                        
                        self.logger.info(f"Uploaded final part {part_number} ({final_buffer_size} bytes)")
                        
                        # Complete the multipart upload
                        self.s3_client.complete_multipart_upload(
                            Bucket=output_bucket,
                            Key=output_key,
                            UploadId=mpu['UploadId'],
                            MultipartUpload={'Parts': parts}
                        )
                else:
                    # If we have parts but no remaining data, just complete the upload
                    if len(parts) > 0:
                        self.s3_client.complete_multipart_upload(
                            Bucket=output_bucket,
                            Key=output_key,
                            UploadId=mpu['UploadId'],
                            MultipartUpload={'Parts': parts}
                        )
                
                self.logger.info("Successfully converted Excel to CSV")
                self.logger.info(f"Total rows processed: {rows_processed}")
                return True
                
            except Exception as e:
                # Abort multipart upload if it was initialized
                if 'mpu' in locals():
                    try:
                        self.s3_client.abort_multipart_upload(
                            Bucket=output_bucket,
                            Key=output_key,
                            UploadId=mpu['UploadId']
                        )
                    except Exception as abort_e:
                        self.logger.warning(f"Failed to abort multipart upload: {str(abort_e)}")
                
                error_msg = f"Failed to upload CSV to S3: {str(e)}"
                self.logger.error(error_msg)
                raise Exception(error_msg)

        except Exception as e:
            error_msg = f"Failed to convert to CSV: {str(e)}"
            self.logger.error(error_msg)
            raise Exception(error_msg)
        
        finally:
            # Clean up
            if 'excel_buffer' in locals():
                excel_buffer.close()
            if 'current_buffer' in locals():
                current_buffer.close()
            if 'xl' in locals():
                xl.close()

def main():
    parser = argparse.ArgumentParser(description='Convert Excel file to CSV')
    parser.add_argument('--input-s3-path', required=True, 
                      help='S3 path to input Excel file (s3://bucket/path/to/file.xlsx)')
    parser.add_argument('--output-s3-path',
                      help='Optional: S3 path for output CSV file. If not provided, will use cleaned input filename')
    parser.add_argument('--sheet-name', default=0,
                      help='Sheet name or index (default: 0)')
    parser.add_argument('--log-dir', default='logs',
                      help='Directory for log files')
    parser.add_argument('--chunk-size', type=int, default=10000,
                      help='Number of rows to process at once')
    
    args = parser.parse_args()
    
    try:
        converter = ExcelConverter(log_dir=args.log_dir, chunk_size=args.chunk_size)
        converter.convert_excel_to_csv(
            args.input_s3_path,
            args.output_s3_path,
            sheet_name=args.sheet_name
        )
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()