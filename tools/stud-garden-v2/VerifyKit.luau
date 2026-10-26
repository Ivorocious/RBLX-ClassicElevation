--!strict

local VerifyKit={}

function VerifyKit.Leaf(model: Model,width: number,length: number)
	local polygon={{0,-.5},{.35,-.35},{.5,-.02},{.37,.3},{0,.5},{-.37,.3},{-.5,-.02},{-.35,-.35}}
	local frame=model:GetPivot()
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={model};params.RespectCanCollide=true
	local function inside(x: number,z: number)
		local last=0
		for i,p in polygon do
			local q=polygon[i%#polygon+1]
			local cross=(q[1]-p[1])*(z-p[2])-(q[2]-p[2])*(x-p[1])
			if math.abs(cross)>.00001 then local sign=math.sign(cross); if last~=0 and sign~=last then return false end;last=sign end
		end
		return true
	end
	local report={samples=0,missing=0,overhang=0,heightMismatch=0}
	for ix=-22,22 do for iz=-22,22 do
		local x,z=ix/40+.003,iz/40+.004
		local hit=workspace:Raycast(frame*Vector3.new(x*width,3,z*length),-frame.UpVector*5,params)
		local expected=inside(x,z)
		report.samples+=1
		if expected and not hit then report.missing+=1 end
		if not expected and hit then report.overhang+=1 end
		if hit and math.abs(frame:PointToObjectSpace(hit.Position).Y-.25)>.025 then report.heightMismatch+=1 end
	end end
	return report
end

return VerifyKit
