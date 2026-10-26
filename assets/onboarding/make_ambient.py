"""Generate the original, seamless arrival pad and optionally upload it once."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import uuid
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools"))
from upload_roblox_model import read_key, upload

parser = argparse.ArgumentParser()
parser.add_argument("--upload", action="store_true")
args = parser.parse_args()
rate, seconds = 44100, 32
t = np.arange(rate * seconds) / rate
signal = np.zeros_like(t)
for index, frequency in enumerate((130.8128, 195.9977, 261.6256, 329.6276, 391.9954)):
    frequency = round(frequency * seconds) / seconds
    swell = 0.6 + 0.4 * np.cos(2 * np.pi * t / seconds + index * 0.6)
    signal += np.sin(2 * np.pi * frequency * t) * swell * (0.065 / (1 + index * 0.4))
for start, frequency in ((2, 783.99), (10, 659.25), (18, 587.33), (26, 523.25)):
    local = t - start
    envelope = np.where((local >= 0) & (local < 5), np.sin(np.pi * np.clip(local, 0, 5) / 5) ** 2, 0)
    signal += np.sin(2 * np.pi * frequency * local) * envelope * 0.012
signal *= 0.32 / max(np.abs(signal).max(), 0.001)
path = HERE / "arrival_ambient.wav"
with wave.open(str(path), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(rate)
    output.writeframes((signal * 32767).astype("<i2").tobytes())
if args.upload:
    content = path.read_bytes()
    metadata = {"assetType": "Audio", "displayName": "Classic Elevation - Quiet Orbit",
                "description": "Original synthesized 32-second seamless ambient pad for the arrival screen.",
                "creationContext": {"creator": {"userId": "86069177"}}}
    identity = {"sha256": hashlib.sha256(content).hexdigest(), "request": metadata}
    boundary = "ArrivalAudio" + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'.encode()
            + json.dumps(metadata).encode()
            + f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="arrival.wav"\r\nContent-Type: audio/wav\r\n\r\n'.encode()
            + content + f'\r\n--{boundary}--\r\n'.encode())
    receipt = upload(identity, body, "multipart/form-data; boundary=" + boundary, HERE / "audio-receipt.json", read_key())
    print(json.dumps({"state": receipt["state"], "assetId": receipt.get("assetId")}))
else:
    print(path)
