local candidate = workspace.KeyboardCircuit_P1_C08
local player = game:GetService("Players"):GetPlayerByUserId(86069177)
local character = player.Character
local root, head = character.HumanoidRootPart, character.Head
local humanoid = character.Humanoid
local drop = candidate.S02_ThockySwitchworks.H04_FallingKeyFoundry.Drop1
local body, plunger = drop.Contact, drop.Plunger
root:SetNetworkOwner(nil)
local began = os.clock()
repeat task.wait(.01) until drop:GetAttribute("CycleState") == "Return" and candidate:GetAttribute("KCElapsed") % 6.6 > 2.48 and candidate:GetAttribute("KCElapsed") % 6.6 < 2.60 or os.clock()-began > 7.2
assert(drop:GetAttribute("CycleState") == "Return", "Returning phase was not reached")
local diagnosticBefore = game:GetService("HttpService"):JSONDecode(candidate:GetAttribute("KCServerDiagnostics"))
local headOffsetY = head.Position.Y-root.Position.Y
local bodyBottom = body.Position.Y-body.Size.Y/2
local target = Vector3.new(body.Position.X, bodyBottom-headOffsetY-head.Size.Y/2+.8, body.Position.Z)
local oldRoot = root.Position
root.CFrame = CFrame.new(target)
root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
local params = OverlapParams.new()
params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {character}
local function overlapping(part)
 local result = {}
 for _, hit in workspace:GetPartBoundsInBox(part.CFrame, part.Size, params) do table.insert(result, {name=hit.Name, accessory=hit:FindFirstAncestorWhichIsA("Accessory")~=nil}) end
 return result
end
local function vector(v) return {v.X,v.Y,v.Z} end
local setup = {phase=candidate:GetAttribute("KCElapsed")%6.6,state=drop:GetAttribute("CycleState"),
 bodyPosition=vector(body.Position),bodySize=vector(body.Size),headPosition=vector(head.Position),headSize=vector(head.Size),
 stagedRoot=vector(root.Position),overlapBody=overlapping(body),overlapPlunger=overlapping(plunger),headOverlapDepth=.8}
local headPresent = false
for _,hit in setup.overlapBody do if hit.name == "Head" and not hit.accessory then headPresent=true end end
task.wait(.35)
local diagnosticAfter = game:GetService("HttpService"):JSONDecode(candidate:GetAttribute("KCServerDiagnostics"))
local newRecoveries = {}
for i=#diagnosticBefore.recoveries+1,#diagnosticAfter.recoveries do table.insert(newRecoveries,diagnosticAfter.recoveries[i]) end
local passed = headPresent and #setup.overlapPlunger==0 and diagnosticAfter.runtime.contacts > diagnosticBefore.runtime.contacts
 and (root.Position-target).Magnitude>20 and #newRecoveries>0 and newRecoveries[#newRecoveries].reason=="FoundryContact"
root:SetNetworkOwnershipAuto()
local record = {label="Corrected native returning-key Head/CollisionPart overlap, C08",
 participant=player.UserId,realServer=game:GetService("RunService"):IsServer(),actualHeadOverlap=headPresent,passed=passed,
 previousSafeRoot=vector(oldRoot),setup=setup,afterRoot=vector(root.Position),
 before=diagnosticBefore,after=diagnosticAfter,newRecoveries=newRecoveries,
 limitation="Controlled instantaneous placement into the returning contact shape; not an ordinary movement traversal or every avatar scale."}
shared.KC08CorrectedHeadContact=record
return record