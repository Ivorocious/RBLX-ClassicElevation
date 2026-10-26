"""Use the existing receipt/credential pipeline for this course's prepared WAV cues."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import uuid
import wave

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"tools"))
from upload_roblox_model import UploadError, read_key, upload


def prepare(file,user_id,name):
    if file.parent!=Path(__file__).resolve().parent or file.name not in {"crossing_bell.wav","traffic_engine.wav","swing_air.wav"}:
        raise UploadError("Choose one of the three prepared City Run cues.")
    with wave.open(str(file),"rb") as stream:
        if stream.getnchannels()!=1 or stream.getframerate()>48000 or stream.getnframes()/stream.getframerate()>7:
            raise UploadError("Unexpected City Run audio format.")
    content=file.read_bytes()
    if not content or len(content)>1_000_000 or not user_id.isdecimal() or int(user_id)<=0:
        raise UploadError("Invalid audio or creator.")
    metadata={"assetType":"Audio","displayName":name,"description":"Original synthesized City Run hazard sound effect.","creationContext":{"creator":{"userId":user_id}}}
    identity={"sha256":hashlib.sha256(content).hexdigest(),"request":metadata}
    boundary="CityRunAudio"+uuid.uuid4().hex
    body=(f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'.encode()
        +json.dumps(metadata).encode()+f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="cue.wav"\r\nContent-Type: audio/wav\r\n\r\n'.encode()
        +content+f'\r\n--{boundary}--\r\n'.encode())
    return identity,body,"multipart/form-data; boundary="+boundary


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("file",type=Path);p.add_argument("--user-id",required=True);p.add_argument("--name",required=True)
    p.add_argument("--receipt",type=Path,required=True);p.add_argument("--upload",action="store_true");a=p.parse_args()
    try:
        identity,body,content_type=prepare(a.file.resolve(),a.user_id,a.name)
        if a.upload:print(json.dumps(upload(identity,body,content_type,a.receipt,read_key()),indent=2))
        else:print(json.dumps({"status":"validated-local-only",**identity},indent=2))
    except (UploadError,OSError,wave.Error) as error:
        print(str(error),file=sys.stderr);sys.exit(1)
