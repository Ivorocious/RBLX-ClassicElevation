from pathlib import Path
import hashlib
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[3]
source = root / 'docs/artifacts/moonlit-citadel/phase2-blueprint-r06.drawio'
target = source.with_name('phase2-blueprint-r07.drawio')
before = hashlib.sha256(source.read_bytes()).hexdigest()
tree = ET.parse(source)
changes = {
    'h1_intro': 'H1 / STONE-ARCH CLIMB\nSeparated causeways / hurdle jumps\nAlternating side-opening gates',
    'arch_n': 'NORMAL / E1\nBroad outer causeways\n5.5-stud gaps / hurdle jumps',
    'arch_e': 'EXPERT / E1\n4-stud rises / directional landings\n3.5-stud rail / gate and hurdles',
    'lantern_n': 'NORMAL / E2\nSeparated gap approach\n14-stud refuges / timed swings\nAll 3 lantern bands',
    'lantern_e': 'EXPERT / E2\n3.5-stud timed knife landings\nOffset raised exits / rail hurdles\nAll 3 lantern bands',
    'counter_n': 'NORMAL / E3\n8-stud outer jump gallery\nRear boarding at +106\nFull upper ride to +140',
    'counter_e': 'EXPERT / E3\nStaggered +4 brace rises\nBoard +126 / leave near +132\nPrecision exit / mirrored bays',
    'finish': 'S4 / CROWN APPROACH + FINISH\nSeparated jump causeways / hurdle\nCrown terrace / +150 studs',
    'timing_total': 'CP01 > CP02 > CP03 > CP04 and all three signatures retained. Current native proof: Normal finish; Expert prefix plus both repaired brace/upper exits. This is not a fresh all-eight sweep.',
    'band4': 'CROWN  +140 to +150\nSeparated causeways / floor hurdle / finish',
    'band1': 'STONE ARCHES  +12 to +52\nCP01 +28 / hurdles and alternating gates',
    'band0': 'GATE COURT  +0 to +12\nRising floors / one supported hurdle',
    'height_note': 'Playable rise: 150 studs. Current contact positions are in INTEGRATED_LAYOUT.json; Build04 supplies the exact native contacts. Relative arrangement only; scenery and moving sweeps extend beyond floors.',
    'actions': 'WHAT RACERS DO\nSeparated gap jumps > hurdle jumps and alternating side gates > rising arch turns > 3 timed lantern crossings > lower lift > outer gallery or precision brace > upper lift > crown jumps.\n63 Normal / 59 Expert authored jump nodes, plus lift boarding and departure. Expert costs include narrow rails, +4 rises and aimed landings.',
    'recovery': 'RECOVERY\nArch catch +16 > fixed return > CP01 +28.\nLift catch +98 > fixed return > CP04 +106.\nExisting invisible sky/fall limit Y277 still handles falling.\n21 visible red units are on-course hurdles and gates; no red carpets under gaps or shafts.',
    'distances': 'CURRENT ROUTE FACTS\n63 Normal / 59 Expert authored jump nodes.\nNormal fixed-goal travel about 2096 studs.\nExpert branches shorten travel while adding narrow landings, +4 rises, timed transfers and precision exits.\nLift travel and human completion times are separate. Final route offsets are in INTEGRATED_LAYOUT.json.',
    'rewards': 'EXPERT TRADEOFF\nE1: short inner climb with rises, turns and narrow hurdle rails.\nE2: direct timed knife landings with raised offset exits.\nE3: late boarding and early exit through staggered braces.\nLocal gallery cuts and skilled moving-rail phase cuts remain; not every contact is compulsory.',
    'repairs': 'R07 REPAIRS\nRemove red fall collectors; retain invisible recovery.\nReplace broad skippable islands with separated gameplay contacts.\nWiden matching visible boarding wall to 48 studs.\nStagger brace tiers and raise post-lift landing to clear jumps.\n7 arrows / 3 significant boards; E1 sign moved away from first landing.',
    'claims': 'EVIDENCE BOUNDARIES\nActual native Normal finish, unchanged Expert prefix, both final upper Expert exits, seven physical hazard/recovery cases and four negative shortcut attempts.\nThree independent Sol6.1 ExtraHigh scores: challenge 8.6, gameplay 8.7, clarity 8.6.\nNo continuous final Expert finish or all-eight sweep. Human fun/navigation/pacing, owner acceptance, 20 racers and device FPS remain open.',
    'provenance': 'CANDIDATE / MC_P2_C01_R07 Build04\nNative SHA256: 410dcf2e617e2506a8d7e8c746b9d74293f3339a1742922f220812f1bed80cc2\nPacket SHA256: 99c33abd38c7058a01301ff887e1cccd3f34b540690ead07dd0ec2ed458ad2ed',
}
for diagram in tree.getroot().findall('diagram'):
    diagram.set('name', diagram.get('name', '').replace('R06', 'R07'))
    for cell in diagram.iter('mxCell'):
        key = cell.get('id')
        value = cell.get('value')
        if key in changes:
            cell.set('value', changes[key])
        elif value:
            cell.set('value', value.replace('R06', 'R07').replace('Native07', 'Build04'))
ET.indent(tree, space='  ')
tree.write(target, encoding='utf-8', xml_declaration=True)
assert hashlib.sha256(source.read_bytes()).hexdigest() == before
assert len(ET.parse(target).getroot().findall('diagram')) == 3
print(f'{target}: 3 native diagrams; R06 source preserved')
