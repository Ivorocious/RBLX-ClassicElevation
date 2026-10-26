"""Upload the six authorized original sky textures with resumable receipts."""
import importlib.util
import json
from pathlib import Path
import sys
import uuid

ROOT = Path(__file__).resolve().parents[4]
spec = importlib.util.spec_from_file_location('moonlit_model_upload', ROOT / 'tools/upload_roblox_model.py')
uploader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(uploader)


def main():
    directory = ROOT / 'assets/moonlit_citadel/phase3/rework-20261012/sky04'
    manifest = json.loads((directory / 'manifest.json').read_text(encoding='utf-8'))
    key = uploader.read_key()
    completed = []
    for row in manifest['faces']:
        path = ROOT / row['file']
        content = path.read_bytes()
        assert content.startswith(b'\x89PNG\r\n\x1a\n') and len(content) < 2_000_000
        assert uploader.hashlib.sha256(content).hexdigest() == row['sha256']
        metadata = {'assetType': 'Image', 'displayName': 'Moonlit Citadel RW02 ' + row['property'],
                    'description': 'Original quiet night cubemap texture for Moonlit Citadel.',
                    'creationContext': {'creator': {'userId': '86069177'}}}
        identity = {'sha256': row['sha256'], 'request': metadata}
        boundary = 'MoonlitSky' + uuid.uuid4().hex
        body = (f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'.encode()
                + json.dumps(metadata).encode()
                + f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="sky.png"\r\nContent-Type: image/png\r\n\r\n'.encode()
                + content + f'\r\n--{boundary}--\r\n'.encode())
        receipt = uploader.upload(identity, body, 'multipart/form-data; boundary=' + boundary,
                                  directory / (path.stem + '.upload.json'), key, wait_seconds=30)
        status = {'property': row['property'], 'state': receipt['state'], 'assetId': receipt.get('assetId')}
        completed.append(status)
        print(json.dumps(status), flush=True)
    (directory / 'upload_summary.json').write_text(json.dumps(completed, indent=2) + '\n', encoding='utf-8')
    return 0 if all(row['state'] == 'complete' for row in completed) else 2


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except uploader.UploadError as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
