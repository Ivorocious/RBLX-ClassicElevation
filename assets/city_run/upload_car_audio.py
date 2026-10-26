"""Upload only the prepared C17 market-car WAV cues through the shared receipt pipeline."""

import argparse
import hashlib
import json
from pathlib import Path
import sys
import uuid
import wave


OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from upload_roblox_model import UploadError, read_key, upload


CUES = {
    "car_engine_rev.wav": {
        "displayName": "CityRun_C17_CarEngineRev",
        "description": "Original synthesized City Run C17 market-car engine rev loop.",
    },
    "car_tire_roll.wav": {
        "displayName": "CityRun_C17_CarTireRoll",
        "description": "Original synthesized City Run C17 market-car tire and road loop.",
    },
}


def prepare(file, user_id):
    file = file.resolve()
    if file.parent != OUT.resolve() or file.name not in CUES:
        raise UploadError("Choose one of the two prepared C17 car WAV cues in assets/city_run.")
    with wave.open(str(file), "rb") as stream:
        if stream.getnchannels() != 1 or stream.getsampwidth() != 2 or stream.getframerate() != 24_000:
            raise UploadError("C17 car audio must be mono, 16-bit, and 24 kHz.")
        if stream.getnframes() / stream.getframerate() > 7.0:
            raise UploadError("C17 car audio must be no longer than seven seconds.")
    content = file.read_bytes()
    if not content or len(content) > 1_000_000 or not user_id.isdecimal() or int(user_id) <= 0:
        raise UploadError("Invalid audio or creator.")
    cue = CUES[file.name]
    metadata = {
        "assetType": "Audio",
        "displayName": cue["displayName"],
        "description": cue["description"],
        "creationContext": {"creator": {"userId": user_id}},
    }
    identity = {"sha256": hashlib.sha256(content).hexdigest(), "request": metadata}
    boundary = "CityRunC17CarAudio" + uuid.uuid4().hex
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n"
        "Content-Type: application/json\r\n\r\n"
    ).encode() + json.dumps(metadata).encode() + (
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; "
        "filename=\"cue.wav\"\r\nContent-Type: audio/wav\r\n\r\n"
    ).encode() + content + f"\r\n--{boundary}--\r\n".encode()
    return identity, body, "multipart/form-data; boundary=" + boundary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    parser.add_argument("--user-id", required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--upload", action="store_true", help="Send to Roblox; otherwise validate locally only.")
    args = parser.parse_args()
    try:
        identity, body, content_type = prepare(args.file, args.user_id)
        if args.upload:
            result = upload(identity, body, content_type, args.receipt, read_key())
            print(json.dumps({"state": result["state"], "assetId": result.get("assetId"), "receipt": str(args.receipt)}, indent=2))
        else:
            print(json.dumps({"state": "dry-run", "file": str(args.file.resolve()), **identity}, indent=2))
        return 0
    except (UploadError, OSError, ValueError, wave.Error) as error:
        print(str(error) if isinstance(error, UploadError) else "Local file or audio format error.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
