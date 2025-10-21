#!/usr/bin/env python3

import argparse
import os
import sys
import dropbox
from pathlib import Path

def download_file(dbx, dropbox_path, local_path):
    """Download a single file from Dropbox"""
    try:
        print(f"Downloading {dropbox_path} to {local_path}")
        
        # Ensure local directory exists
        local_dir = Path(local_path).parent
        local_dir.mkdir(parents=True, exist_ok=True)
        
        # Download file
        dbx.files_download_to_file(local_path, dropbox_path)
        print(f"Successfully downloaded {dropbox_path}")
        return True
        
    except dropbox.exceptions.ApiError as e:
        print(f"Error downloading {dropbox_path}: {e}")
        return False

def download_folder(dbx, dropbox_folder, local_folder):
    """Download all files from a Dropbox folder"""
    try:
        print(f"Listing files in {dropbox_folder}")
        
        # List all files in the folder
        result = dbx.files_list_folder(dropbox_folder, recursive=True)
        files = result.entries
        
        # Handle pagination if there are more files
        while result.has_more:
            result = dbx.files_list_folder_continue(result.cursor)
            files.extend(result.entries)
        
        # Download each file
        success_count = 0
        for entry in files:
            if isinstance(entry, dropbox.files.FileMetadata):
                # Calculate local path
                relative_path = entry.path_display[len(dropbox_folder):].lstrip('/')
                local_path = os.path.join(local_folder, relative_path)
                
                if download_file(dbx, entry.path_display, local_path):
                    success_count += 1
        
        print(f"Downloaded {success_count} files to {local_folder}")
        return success_count > 0
        
    except dropbox.exceptions.ApiError as e:
        print(f"Error listing folder {dropbox_folder}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Download files from Dropbox to local directory')
    parser.add_argument('source', help='Dropbox path (file or folder)')
    parser.add_argument('destination', help='Local destination path')
    parser.add_argument('--token', help='Dropbox access token (or set DROPBOX_ACCESS_TOKEN env var)')
    parser.add_argument('--folder', action='store_true', help='Download entire folder instead of single file')
    
    args = parser.parse_args()
    
    # Get access token
    token = args.token or os.getenv('DROPBOX_ACCESS_TOKEN')
    if not token:
        print("Error: Dropbox access token required. Use --token or set DROPBOX_ACCESS_TOKEN environment variable")
        sys.exit(1)
    
    # Initialize Dropbox client
    try:
        dbx = dropbox.Dropbox(token)
        # Test connection
        dbx.users_get_current_account()
        print("Connected to Dropbox successfully")
    except Exception as e:
        print(f"Error connecting to Dropbox: {e}")
        sys.exit(1)
    
    # Download files
    if args.folder:
        success = download_folder(dbx, args.source, args.destination)
    else:
        success = download_file(dbx, args.source, args.destination)
    
    if not success:
        print("Download failed")
        sys.exit(1)
    
    print("Download completed successfully")

if __name__ == "__main__":
    main()