"""Hash the recoverable art files and check the local review gallery's links."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/artifacts/stud-garden-v2'
PHASE = BASE / 'phase3'
files = set()
for folder in ('f03', 'f04'):
    for path in (PHASE / folder).rglob('*'):
        if path.is_file() and path.suffix in {'.py','.luau','.json','.md','.png','.fbx','.blend','.rbxm'}:
            files.add(path)
for pattern in ('F03_*.md','F04_*.md'):
    for path in (PHASE / 'reviews').glob(pattern):
        files.add(path)
for relative in ('phase2/round3/offline-r305/geometry.json',
                 'phase2/round3/native/sgv2-r305-course-native.rbxm',
                 'phase3-showcase-20261004/refinement-20261005/bigger-plants-studs-v1.png',
                 'phase3-showcase-20261004/refinement-20261005/four-views/StudGarden-BigPlants-Studs-Reference.blend',
                 'phase3-showcase-20261004/refinement-20261005/four-views/build_consistent_views.py',
                 'phase3-showcase-20261004/refinement-20261005/four-views/manifest.json',
                 'phase3/IDEATION_PHASE3_BRIEF_20261005.json', 'phase3/PHASE3_STATUS.md',
                 'phase3/FINAL_REVIEW_SUMMARY.json', 'phase3/index.html'):
    files.add(BASE / relative)
records = []
for path in sorted(files):
    assert path.is_file(), path
    records.append(dict(path=path.relative_to(BASE).as_posix(), bytes=path.stat().st_size,
                        sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
summary=json.loads((PHASE/'FINAL_REVIEW_SUMMARY.json').read_text())
assert len(summary['reviews'])==3 and all(r['score']>8.5 for r in summary['reviews'])
assert summary['artBuildAndStaticReviewComplete'] and not summary['requiredStaticCorrectionsRemaining']
result = dict(status='F04 art build and independent static review complete; gameplay acceptance remains open',
    nativeCandidate='SGV2_Phase3_F04', nativeFingerprint='75cbafea', previousFingerprint='470ecc4d',
    originalFingerprint='d17688b8', reviews=summary['reviews'],
    f04UploadApproved=True, f04Uploaded=True, f04NativeInstalled=True,
    f04NativeSampledContactVerified=True, artBuildAndStaticReviewComplete=True,
    fullGameplayAcceptance=False, historicalEvidence=summary['historicalEvidence'], files=records)
(PHASE / 'delivery-manifest.json').write_text(json.dumps(result, indent=2))


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        self.links += [value for key, value in attrs if key in ('href','src')]


parser = Links()
parser.feed((PHASE / 'index.html').read_text(encoding='utf-8'))
missing = []
for link in parser.links:
    local = unquote(link.split('#')[0])
    if local and not (PHASE / local).exists():
        missing.append(link)
assert not missing, missing
validation = dict(fileCount=len(records), hashedBytes=sum(r['bytes'] for r in records),
    galleryLocalLinks=len(parser.links), missingGalleryTargets=missing,
    f04FbxBytes=(PHASE/'f04/SGV2_Phase3_F04_Knots.fbx').stat().st_size,
    uploadReceiptExists=(PHASE/'f04/upload-receipt.json').exists())
assert validation['uploadReceiptExists']
native=json.loads((PHASE/'f04/native-checks.json').read_text())
readback=json.loads((PHASE/'f04/native/offline-file-readback.json').read_text())
archive=PHASE/'f04/native/sgv2-phase3-f04-native.rbxm'
file_check=json.loads((PHASE/'f04/native/file-check.json').read_text())
assert native['fingerprint']==readback['fingerprint']==dict(hash='75cbafea',parts=4964)
assert not native['sourcePropertyMismatches'] and native['contactRays']['misses']==0
assert file_check['sha256']==hashlib.sha256(archive.read_bytes()).hexdigest()
validation.update(finalFingerprint='75cbafea',finalScores=[r['score'] for r in summary['reviews']],
    nativeArchiveHashMatches=True,nativeArchiveReadbackMatches=True,
    historicalStatusFieldsExplicitlyLabeled=True)
(PHASE / 'delivery-validation.json').write_text(json.dumps(validation, indent=2))
print(json.dumps(validation))
