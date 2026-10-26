--!strict

local VerifyPot={}

function VerifyPot.Run(pot: Model)
	local frame=pot:GetPivot()
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={pot}
	params.RespectCanCollide=true
	local report={rimSamples=0,sideSamples=0,unsupported=0,invisibleOverhang=0,heightMismatch=0,sideMismatch=0}
	for degree=0,359,2 do
		local a=math.rad(degree)
		local factor=math.cos(math.pi/12)/math.cos(math.rad(degree%30-15))
		local inner,outer=6*factor,12*factor
		for _,radius in {inner-0.2,inner+0.2,9,outer-0.2,outer+0.2} do
			local point=frame*Vector3.new(radius*math.cos(a),10,radius*math.sin(a))
			local hit=workspace:Raycast(point,-frame.UpVector*5,params)
			local expected=radius>inner and radius<outer
			report.rimSamples+=1
			if expected and not hit then report.unsupported+=1
			elseif not expected and hit then report.invisibleOverhang+=1
			elseif hit and math.abs(frame:PointToObjectSpace(hit.Position).Y-6.4)>0.03 then report.heightMismatch+=1 end
		end
	end
	for degree=0,359,5 do
		local a=math.rad(degree)
		local unit=Vector3.new(math.cos(a),0,math.sin(a))
		local factor=math.cos(math.pi/12)/math.cos(math.rad(degree%30-15))
		for _,y in {0.8,1.5,3.7,5} do
			local radius=(7.8+(y-0.4)/5.1*2.5)*factor
			local hit=workspace:Raycast(frame*(Vector3.yAxis*y+unit*15),frame:VectorToWorldSpace(-unit*12),params)
			report.sideSamples+=1
			if not hit or math.abs((frame:PointToObjectSpace(hit.Position)-Vector3.yAxis*y).Magnitude-radius)>0.09 then report.sideMismatch+=1 end
		end
	end
	return report
end

return VerifyPot
