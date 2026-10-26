"""Check C15 train warning, full-tail clearance, and five-coach envelope."""
import math
import re
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SOURCE=(ROOT/'src/ReplicatedStorage/Config/CityRunTuning.luau').read_text()
TRAIN=SOURCE.split('["train"]=',1)[1].split('["movement"]=',1)[0]
def number(name):
    return float(re.search(r'\["'+name+r'"\]=(-?[\d.]+)',TRAIN).group(1))
SIZE=list(map(float,re.search(r'\["size"\]=\{([^}]+)',TRAIN).group(1).split(',')))
class TrainContract(unittest.TestCase):
    def test_warning_and_clearance_before_nose(self):
        nose_arrival=(205-6-number('startX')-SIZE[0]/2)/number('speed')
        self.assertGreaterEqual(nose_arrival,number('warningTime')+number('clearanceTime'))
    def test_reopens_only_after_last_coach(self):
        clear_phase=(205+6+SIZE[0]/2-number('startX'))/number('speed')
        for dt in [-.001,0,.001]:
            x=number('startX')+(clear_phase+dt)*number('speed')
            self.assertEqual(x-SIZE[0]/2>211,dt>0)
        self.assertLess(clear_phase,(number('endX')-number('startX'))/number('speed'))
    def test_all_five_coaches_covered(self):
        # Blender contract: five centers at 43 studs; 42.5 stud coach envelope.
        for index in range(5):
            center=(index-2)*43
            self.assertGreaterEqual(center-42.5/2,-SIZE[0]/2)
            self.assertLessEqual(center+42.5/2,SIZE[0]/2)
        self.assertGreaterEqual(SIZE[1],13.1)
        self.assertGreaterEqual(SIZE[2],12)
    def test_rail_height_covered(self):
        self.assertLessEqual(number('bodyCenterY')-SIZE[1]/2,80.65+.001)
        self.assertGreaterEqual(number('bodyCenterY')+SIZE[1]/2,93.75-.001)
if __name__=='__main__':unittest.main()
