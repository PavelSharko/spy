import json
import os
import sys
import re
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 upload_apk.py <path_to_apk>")
        sys.exit(1)

    apk_path = sys.argv[1]
    if not os.path.exists(apk_path):
        print(f"Error: file not found: {apk_path}")
        sys.exit(1)

    # Resolve token path relative to script or cwd
    token_path = 'token.json'
    if not os.path.exists(token_path):
        token_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'token.json')
    
    if not os.path.exists(token_path):
        print("Error: token.json not found!")
        sys.exit(1)

    # Load credentials
    with open(token_path, 'r') as f:
        token_data = json.load(f)

    creds = Credentials(
        token=token_data.get('access_token'),
        refresh_token=token_data.get('refresh_token'),
        token_uri=token_data.get('token_uri'),
        client_id=token_data.get('client_id'),
        client_secret=token_data.get('client_secret'),
        scopes=token_data.get('scopes')
    )

    print("Authenticating with Google Drive...")
    service = build('drive', 'v3', credentials=creds)

    # 1. Find or create 'test_apks' folder
    print("Searching for 'test_apks' folder...")
    query = "name = 'test_apks' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
    results = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    items = results.get('files', [])

    if not items:
        print("Folder 'test_apks' not found. Creating it...")
        file_metadata = {
            'name': 'test_apks',
            'mimeType': 'application/vnd.google-apps.folder'
        }
        folder = service.files().create(body=file_metadata, fields='id').execute()
        folder_id = folder.get('id')
        print(f"Created 'test_apks' folder with ID: {folder_id}")
    else:
        folder_id = items[0]['id']
        print(f"Found 'test_apks' folder with ID: {folder_id}")

    # 2. List files in folder to determine the next build number
    print("Listing files in 'test_apks' to find the next build number...")
    query = f"'{folder_id}' in parents and trashed = false"
    results = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    files = results.get('files', [])

    build_numbers = []
    for file in files:
        name = file['name']
        match = re.match(r'spy_(\d+)\.apk', name)
        if match:
            build_numbers.append(int(match.group(1)))

    next_build = max(build_numbers) + 1 if build_numbers else 1
    new_filename = f"spy_{next_build}.apk"
    print(f"Next build number determined: {next_build} -> {new_filename}")

    # 3. Upload file
    print(f"Uploading {apk_path} as {new_filename} to Google Drive...")
    file_metadata = {
        'name': new_filename,
        'parents': [folder_id]
    }
    
    media = MediaFileUpload(
        apk_path,
        mimetype='application/vnd.android.package-archive',
        resumable=True
    )
    
    file_upload = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id'
    )
    
    response = None
    while response is None:
        status, response = file_upload.next_chunk()
        if status:
            print(f"Upload progress: {int(status.progress() * 100)}%")

    print(f"Successfully uploaded {new_filename}! File ID: {response.get('id')}")

if __name__ == '__main__':
    main()
