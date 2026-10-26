"""Upload an FBX through Open Cloud; keep a receipt to avoid duplicate uploads."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
API = 'https://apis.roblox.com/assets/v1/'


class UploadError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def api_request(method, path, key, data=None, content_type=None):
    if path != 'assets' and not re.fullmatch(r'operations/[A-Za-z0-9_-]+', path):
        raise UploadError('Invalid operation path; refusing request.')
    headers = {'x-api-key': key}
    if content_type:
        headers['Content-Type'] = content_type
    request = urllib.request.Request(API + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=45) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        raise UploadError(f'Roblox returned HTTP {error.code}; check key permissions and upload status.') from None
    except (OSError, ValueError) as error:
        raise UploadError('Request failed or returned invalid data; no automatic upload retry.') from None
    if not isinstance(result, dict):
        raise UploadError('Unexpected response from Roblox.')
    return result


def read_key():
    key = os.environ.get('ROBLOX_OPEN_CLOUD_API_KEY', '').strip()
    if not key and (ROOT / '.tools/roblox-upload-key.dpapi').exists():
        process = subprocess.run(
            [shutil.which('pwsh.exe') or 'powershell.exe', '-NoProfile', '-NonInteractive', '-File',
             str(ROOT / 'tools/set_roblox_upload_key.ps1'), '-ReadKey'],
            capture_output=True, text=True, check=False,
        )
        if process.returncode:
            raise UploadError('Cannot decrypt the upload key. Run the setup script as this Windows user.')
        key = process.stdout.strip()
    if not key:
        raise UploadError('No upload key. Run tools/set_roblox_upload_key.ps1 locally first.')
    if '\n' in key or '\r' in key:
        raise UploadError('Invalid key format.')
    return key


def prepare(file, user_id, name):
    if file.suffix.lower() != '.fbx' or not file.is_file():
        raise UploadError('Provide an existing .fbx file.')
    if not 0 < file.stat().st_size <= 20_000_000:
        raise UploadError('FBX must be nonempty and no larger than 20 MB.')
    if not re.fullmatch(r'[1-9][0-9]*', user_id) or not name.strip():
        raise UploadError('A positive user ID and nonempty asset name are required.')
    content = file.read_bytes()
    metadata = {
        'assetType': 'Model', 'displayName': name,
        'description': 'Blender model uploaded through the Project Classic Elevation asset workflow.',
        'creationContext': {'creator': {'userId': user_id}},
    }
    identity = {'sha256': hashlib.sha256(content).hexdigest(), 'request': metadata}
    boundary = 'RobloxModel' + uuid.uuid4().hex
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\n'
        'Content-Type: application/json\r\n\r\n'
    ).encode() + json.dumps(metadata).encode() + (
        f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; '
        'filename="model.fbx"\r\nContent-Type: model/fbx\r\n\r\n'
    ).encode() + content + f'\r\n--{boundary}--\r\n'.encode()
    return identity, body, f'multipart/form-data; boundary={boundary}'


def save_receipt(path, receipt):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def upload(identity, body, content_type, receipt_path, key, wait_seconds=60):
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    receipt = dict(identity, state='submitting')
    try:
        # Reserve before POST so an interrupted/uncertain request is never blindly repeated.
        with receipt_path.open('x', encoding='utf-8') as file:
            json.dump(receipt, file)
    except FileExistsError:
        receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        if any(receipt.get(field) != value for field, value in identity.items()):
            raise UploadError('Receipt belongs to different input; choose another receipt file.')
        if receipt.get('state') == 'complete':
            return receipt
        if not receipt.get('operation'):
            raise UploadError('Previous submission has an unknown outcome. Check Roblox before any new upload.')
    else:
        result = api_request('POST', 'assets', key, body, content_type)
        operation = result.get('path', '')
        if not re.fullmatch(r'operations/[A-Za-z0-9_-]+', operation):
            raise UploadError('Upload response has no valid operation ID; check Roblox before retrying.')
        receipt.update(state='pending', operation=operation)
        save_receipt(receipt_path, receipt)

    deadline = time.monotonic() + wait_seconds
    while True:
        result = api_request('GET', receipt['operation'], key)
        if result.get('error'):
            receipt['state'] = 'failed'
            save_receipt(receipt_path, receipt)
            raise UploadError('Roblox reported upload processing failure; inspect the operation in Roblox.')
        if result.get('done'):
            asset_id = str(result.get('response', {}).get('assetId', ''))
            if not re.fullmatch(r'[1-9][0-9]*', asset_id):
                raise UploadError('Completed operation has no valid asset ID.')
            receipt.update(state='complete', assetId=asset_id)
            save_receipt(receipt_path, receipt)
            return receipt
        if time.monotonic() >= deadline:
            return receipt
        time.sleep(3)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('file', type=Path)
    parser.add_argument('--user-id', required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--receipt', type=Path, required=True)
    parser.add_argument('--upload', action='store_true', help='Send to Roblox; otherwise validate locally only.')
    args = parser.parse_args()
    try:
        identity, body, content_type = prepare(args.file, args.user_id, args.name)
        if args.upload:
            result = upload(identity, body, content_type, args.receipt, read_key())
            print(json.dumps({'state': result['state'], 'assetId': result.get('assetId'),
                              'receipt': str(args.receipt)}, indent=2))
        else:
            print(json.dumps({'state': 'dry-run', 'file': str(args.file), **identity}, indent=2))
        return 0
    except (UploadError, OSError, ValueError):
        # Do not include server bodies or subprocess output, which may contain credentials.
        error = sys.exc_info()[1]
        print(str(error) if isinstance(error, UploadError) else 'Local file or receipt error.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
