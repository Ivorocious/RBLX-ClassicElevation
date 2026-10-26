--!strict
local Motion = {}
local V, CF = Vector3.new, CFrame.new
local UP = Vector3.yAxis

Motion.Shoulder = V(18,25,0)
Motion.BeakTip = V(0,-2,-10)
Motion.HeadNeck = V(0,-5,3)
Motion.LinkLength = 6
Motion.HomeHead = CF(27,31,0)*CFrame.Angles(0,-math.pi/2,0)

local shoulderAngle = math.atan2(Motion.Shoulder.Y,Motion.Shoulder.X)
local homeNeck = Motion.HomeHead:PointToWorldSpace(Motion.HeadNeck)
local homePitchOffset = shoulderAngle-math.atan2(homeNeck.Y,homeNeck.X)

local function smooth(value: number): number
 return value*value*value*(value*(value*6-15)+10)
end

local function targetYaw(rootFrame: CFrame, target: Vector3): number
 local at=rootFrame:PointToObjectSpace(target)
 return -math.atan2(at.Z,at.X)
end

local function shortTurn(from: number, to: number): number
 return math.atan2(math.sin(to-from),math.cos(to-from))
end

local function footFrame(rootFrame: CFrame, fromYaw: number, toYaw: number, sample: {state: string, alpha: number}, side: number): (CFrame, number)
 local yaw,lift=toYaw,0
 if sample.state=="Rest" then
  local start=if side<0 then .18 else .56
  local step=math.clamp((sample.alpha-start)/.36,0,1)
  yaw=fromYaw+shortTurn(fromYaw,toYaw)*smooth(step)
  lift=1.5*math.sin(math.pi*smooth(step))
 end
 return rootFrame*CFrame.Angles(0,yaw,0)*CF(0,lift,side*8),lift
end

local function headFrame(rootFrame: CFrame, target: Vector3, rise: number, angle: number): CFrame
 local up=rootFrame.UpVector
 local delta=target-rootFrame.Position
 local horizontal=delta-up*delta:Dot(up)
 local direction=horizontal.Unit*math.cos(math.rad(angle))-up*math.sin(math.rad(angle))
 local rotation=CFrame.lookAt(Vector3.zero,direction,up).Rotation
 return CF(target+up*rise-rotation:VectorToWorldSpace(Motion.BeakTip))*rotation
end

function Motion.StrikeFrame(rootFrame: CFrame, target: Vector3): CFrame
 return headFrame(rootFrame,target,0,55)
end

function Motion.AttentionFrame(rootFrame: CFrame, target: Vector3): CFrame
 return rootFrame*CFrame.Angles(0,targetYaw(rootFrame,target),0)*Motion.HomeHead
end

function Motion.Elbow(anchor: Vector3, endpoint: Vector3, planeNormal: Vector3): Vector3
 local span=endpoint-anchor
 local direction=span.Unit
 local bend=planeNormal:Cross(direction)
 assert(span.Magnitude<Motion.LinkLength*2 and bend.Magnitude>.01,string.format("Chicken pose exceeds the short neck (span %.4f, bend %.4f)",span.Magnitude,bend.Magnitude))
 return (anchor+endpoint)/2+bend.Unit*math.sqrt(Motion.LinkLength^2-span.Magnitude^2/4)
end

-- The body is authored facing local +X; the separate head faces local -Z.
function Motion.Pose(rootFrame: CFrame, target: Vector3, sample: {state: string, alpha: number}, context: {previousTarget: Vector3}?)
 local fromTarget=if context then context.previousTarget else target
 local fromYaw,toYaw=targetYaw(rootFrame,fromTarget),targetYaw(rootFrame,target)
 local attention=Motion.AttentionFrame(rootFrame,target)
 local strike=Motion.StrikeFrame(rootFrame,target)
 local aim=headFrame(rootFrame,target,10,20)
 local head=attention
 local bodyLag,settle=0,0
 if sample.state=="Rest" then
  local alpha=sample.alpha
  local envelope=math.sin(math.pi*alpha)^2
  local turn=shortTurn(fromYaw,toYaw)
  local lookYaw=fromYaw+turn*smooth(math.min(alpha/.9,1))+math.rad(2)*math.sin(2*math.pi*alpha)*envelope
  local breath=.25*math.sin(2*math.pi*alpha)*envelope
  head=rootFrame*CFrame.Angles(0,lookYaw,0)*CF(0,breath,0)*Motion.HomeHead
   *CFrame.Angles(math.rad(1.5)*math.sin(2*math.pi*alpha)*envelope,0,math.rad(1)*math.sin(4*math.pi*alpha)*envelope)
  bodyLag=-math.clamp(turn,-math.rad(5),math.rad(5))*envelope
 elseif sample.state=="Warning" then
  head=attention:Lerp(aim,smooth(sample.alpha))+rootFrame.UpVector*(.65*math.sin(math.pi*sample.alpha)^2)
 elseif sample.state=="Pecking" then head=aim:Lerp(strike,smooth(sample.alpha))
 elseif sample.state=="Impact" then head=strike
  settle=math.rad(.6)*math.sin(math.pi*sample.alpha)^2
 elseif sample.state=="Recovering" then
  if sample.alpha<.55 then head=strike:Lerp(aim,smooth(sample.alpha/.55))
  else head=aim:Lerp(attention,smooth((sample.alpha-.55)/.45))end
 end

 local endpoint=head:PointToWorldSpace(Motion.HeadNeck)
 local localEnd=rootFrame:PointToObjectSpace(endpoint)
 local horizontal=V(localEnd.X,0,localEnd.Z)
 local forward=horizontal.Unit
 local yaw=CFrame.fromMatrix(Vector3.zero,forward,UP,forward:Cross(UP))*CFrame.Angles(0,bodyLag,0)
 local pitch=math.clamp(shoulderAngle-math.atan2(localEnd.Y,horizontal.Magnitude)-homePitchOffset+settle,0,math.rad(32))
 local body=rootFrame*yaw*CFrame.Angles(0,0,-pitch)
 local shoulder=body:PointToWorldSpace(Motion.Shoulder)
 local elbow=Motion.Elbow(shoulder,endpoint,body.ZVector)
 local left,leftLift=footFrame(rootFrame,fromYaw,toYaw,sample,-1)
 local right,rightLift=footFrame(rootFrame,fromYaw,toYaw,sample,1)
 return {
  body=body,head=head,
  lower=CFrame.lookAt((shoulder+elbow)/2,elbow)*CFrame.Angles(-math.pi/2,0,0),
  upper=CFrame.lookAt((elbow+endpoint)/2,endpoint)*CFrame.Angles(-math.pi/2,0,0),
  shoulder=shoulder,elbow=elbow,headNeck=endpoint,
  bodyPitchDegrees=math.deg(pitch),
  footLeft=left,footRight=right,footLeftLift=leftLift,footRightLift=rightLift,
 }
end

return Motion
