from pathlib import Path
import html
import re

root = Path('docs/artifacts/stud-garden-v2/closing-20261005')
old = (root / 'CLOSING_PREVIEW.html').read_text(encoding='utf-8')
style = re.search(r'<style>(.*?)</style>', old, re.S).group(1)
views = [
    ('03-native-trowel-approach.jpg', 'Formed trowel and separator', 'Actual avatar on the hollow grip during native movement checks.'),
    ('native-07-start-and-shop.jpg', 'Start and raised shop', 'Fenced start, two opening choices and the raised shop.'),
    ('native-08-cultivated-crops.jpg', 'Cultivated crops', 'Carrot and berry pots, planted produce, bamboo and the sprinkler approach.'),
    ('native-04-strange-grove.jpg', 'Pink and aqua grove', 'Branching flower cups, hanging pods, roots and the fruit encounter.'),
    ('native-05-beanstalk-entrance.jpg', 'Beanstalk entrance', 'Twisting stems, broad overhead leaves and the smaller playable route.'),
    ('native-11-beanstalk-expert-choice.jpg', 'Expert choice: current defect', 'The installed label is too small. This is a required repair, not an accepted final sign.'),
    ('native-13-market-cargo-and-stalls.jpg', 'Harvest market', 'Loaded wagons, stalls, bunting, fork and ordered table route.'),
    ('native-15-loaded-wheelbarrow.jpg', 'Loaded wheelbarrow', 'Native tub, handles, wheel and produce; the moved bunting mast clears it.'),
    ('native-18-final-basket-to-shovel.jpg', 'Basket and final shovel', 'The basket exit and genuine grip contact passed a connected normal-movement test.'),
    ('fixed-11-beanstalk-expert-choice.jpg', 'Temporary label preview only', 'Scaling was tested in Play and discarded on Stop. The post overlaps the lower text; the prepared repair also shortens five posts. No permanent repair has been applied.'),
]
cards = []
for number, (name, title, caption) in enumerate(views, 1):
    image = root / 'c05-offline/native-views' / name
    assert image.is_file(), image
    link = image.relative_to(root).as_posix()
    cards.append(f'<figure><a href="{link}"><img src="{link}" alt="{html.escape(title)}" loading="lazy" width="1884" height="1080"></a><figcaption><span class="num">{number:02}</span><div><h2>{html.escape(title)}</h2><p>{html.escape(caption)}</p></div></figcaption></figure>')
document = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Stud Garden native checks</title><style>{style}</style></head><body><header><div class="eyebrow">Stud Garden / Native Studio evidence</div><h1>Installed and tested.<br>Sign repair pending.</h1><span class="status">C05 INSTALLED · CLOSING ACCEPTANCE INCOMPLETE</span><p>Native views of the installed course. Ten thorn recoveries, nine ordered checkpoint probes, both timed encounters, 32 selected jumps and connected expert/basket segments have evidence. Full-course completion, twenty racers, device performance and target times remain unverified.</p><nav><a href="NATIVE_VALIDATION.md">Checks and limits</a><a href="c06-native/REPAIR_PROPOSAL.json">Exact remaining repair</a><a href="CLOSING_PREVIEW.html">Offline design views</a><a href="index.html">Owner references</a></nav></header><main><div class="grid">{''.join(cards)}</div></main><footer><p>C05 native geometry95c3533b, content1c417357. Clean views temporarily hide the race HUD for visual inspection; this does not prove moving-camera or human route comprehension. The last image is explicitly a discarded Play-only preview. Automatic approval review rejected the durable 33-label/five-post/status repair before execution.</p></footer></body></html>'''
(root / 'NATIVE_PREVIEW.html').write_text(document, encoding='utf-8')
old = old.replace('C05 OFFLINE PREVIEW · NATIVE INSTALLATION HELD', 'C05 OFFLINE DESIGN VIEWS · NOW INSTALLED; NATIVE SIGN REPAIR PENDING')
old = old.replace('Live Studio still contains the earlier C01 calibration.', 'C05 is now installed. Native testing found a sign-scaling defect; see the native evidence and exact remaining repair.')
old = old.replace('<nav aria-label="Review documents">', '<nav aria-label="Review documents"><a href="NATIVE_PREVIEW.html">Native Studio views and checks ↗</a>')
old = old.replace('The full C05 remains offline.', 'This is the offline design reconstruction; installed C05 has separate native evidence.')
old = old.replace('The narrow takeoff rail still needs an avatar test.', 'The connected basket exit now has a normal-avatar native test.')
(root / 'CLOSING_PREVIEW.html').write_text(old, encoding='utf-8')
print('Saved native gallery with ten verified image links; updated offline-gallery status.')
