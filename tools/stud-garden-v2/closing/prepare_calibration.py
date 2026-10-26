"""Freeze the course-local calibration against its verified native baseline."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/'tools/stud-garden-v2/closing'
OUT=ROOT/'docs/artifacts/stud-garden-v2/closing-20261005/calibration'
OUT.mkdir(exist_ok=True)
code='''assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Requires intended Edit place")
local root=assert(workspace:FindFirstChild("SGV2_Phase3_F04"))
local fingerprint=(function()
'''+(SOURCE.parent/'Fingerprint.luau').read_text()+'''
end)()
assert(fingerprint(root).hash=="be6da39a","Course geometry changed since backup")
assert((root:GetPivot().Position-Vector3.new(1563,257,-1053)).Magnitude<.01,"Owner placement changed")
assert(root.CourseInfo:GetAttribute("Enabled")==false,"Expected disabled candidate")
'''
for name in ['NativeKit','ToolFamily','RoutePresentation','Calibrate']:
    code+=f'local {name}=(function()\n'+(SOURCE/(name+'.luau')).read_text()+'\nend)()\n'
code+='''local result=Calibrate(root,NativeKit,ToolFamily(NativeKit),RoutePresentation(NativeKit))
result.fingerprint=fingerprint(root)
return result
'''
(OUT/'install-sample.luau').write_text(code)
print(json.dumps({'scriptBytes':len(code.encode())}))
