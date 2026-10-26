"""Upload only the selected six faces, preserving an operation receipt per image."""
import importlib.util
import json
from pathlib import Path
import sys
import uuid

ROOT = Path(__file__).resolve().parents[3]
DIRECTORY = ROOT / 'assets/sky/moonlit-citadel-20261021/violet-veil-S04-C01'
spec = importlib.util.spec_from_file_location('sky_image_upload', ROOT / 'tools/upload_roblox_model.py')
uploader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(uploader)


def main():
    manifest_path = DIRECTORY / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    assert len(manifest['faces']) == 6 and manifest['candidate'] == 'D/S04-C01 Violet Veil'
    key = uploader.read_key()
    completed = []
    for row in manifest['faces']:
        path = ROOT / row['file']
        content = path.read_bytes()
        assert content.startswith(b'\x89PNG\r\n\x1a\n') and 0 < len(content) < 2_000_000
        assert uploader.hashlib.sha256(content).hexdigest() == row['sha256']
        metadata = {'assetType': 'Image', 'displayName': 'Moonlit Violet Veil S04 C01 ' + row['property'],
                    'description': 'Owner-selected Moonlit Citadel night sky; original ImageGen art and spherical projection.',
                    'creationContext': {'creator': {'userId': '86069177'}}}
        identity = {'sha256': row['sha256'], 'request': metadata}
        boundary = 'MoonlitVioletSky' + uuid.uuid4().hex
        body = (f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'.encode()
                + json.dumps(metadata).encode()
                + f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="sky.png"\r\nContent-Type: image/png\r\n\r\n'.encode()
                + content + f'\r\n--{boundary}--\r\n'.encode())
        receipt_path = DIRECTORY / (path.stem + '.upload.json')
        receipt = uploader.upload(identity, body, 'multipart/form-data; boundary=' + boundary,
                                  receipt_path, key, wait_seconds=30)
        status = {'property': row['property'], 'state': receipt['state'],
                  'assetId': receipt.get('assetId'), 'operation': receipt.get('operation')}
        completed.append(status)
        print(json.dumps(status), flush=True)
        if receipt['state'] != 'complete':
            break
        row.update(assetId=receipt['assetId'], receipt=receipt_path.relative_to(ROOT).as_posix(),
                   operation=receipt['operation'])
        manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (DIRECTORY / 'upload-summary.json').write_text(json.dumps(completed, indent=2) + '\n', encoding='utf-8')
    return 0 if len(completed) == 6 and all(r['state'] == 'complete' for r in completed) else 2


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except uploader.UploadError as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
