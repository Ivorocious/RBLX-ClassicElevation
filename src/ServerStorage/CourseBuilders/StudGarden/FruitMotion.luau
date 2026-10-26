--!strict

local FruitMotion={}

function FruitMotion.Position(alpha: number,index: number,catchDrop: number?): Vector3
	local progress=math.clamp((alpha-(index-1)*.12)/.76,0,1)
	local x=-17+38*progress
	local fall=(catchDrop or 0)*math.clamp((x-13.6)/7.4,0,1)
	return Vector3.new(x,2.8-fall,(index-2)*8)
end

function FruitMotion.Segments(first: number,last: number,index: number,catchDrop: number?): {Vector3}
	local points={FruitMotion.Position(first,index,catchDrop)}
	local corner=(index-1)*.12+.76*(13.6+17)/38
	if (catchDrop or 0)>0 and first<corner and last>corner then table.insert(points,FruitMotion.Position(corner,index,catchDrop)) end
	table.insert(points,FruitMotion.Position(last,index,catchDrop))
	return points
end

function FruitMotion.SweepTouchesBody(first: Vector3,last: Vector3,radius: number,frame: CFrame,size: Vector3): boolean
	local a=frame:PointToObjectSpace(first)
	local direction=frame:VectorToObjectSpace(last-first)
	local half=size/2
	local starts,steps,extents={a.X,a.Y,a.Z},{direction.X,direction.Y,direction.Z},{half.X,half.Y,half.Z}
	local breaks={0,1}
	for axis=1,3 do
		if math.abs(steps[axis])>.000001 then
			for _,side in {-1,1} do
				local t=(side*extents[axis]-starts[axis])/steps[axis]
				if t>0 and t<1 then table.insert(breaks,t) end
			end
		end
	end
	table.sort(breaks)
	-- Between face crossings, squared distance to the body box is a quadratic.
	for i=1,#breaks-1 do
		local low,high=breaks[i],breaks[i+1]
		local mid=(low+high)/2
		local quadratic,linear=0,0
		for axis=1,3 do
			local value=starts[axis]+steps[axis]*mid
			if math.abs(value)>extents[axis] then
				local offset=starts[axis]-math.sign(value)*extents[axis]
				quadratic+=steps[axis]^2;linear+=steps[axis]*offset
			end
		end
		local t=if quadratic>0 then math.clamp(-linear/quadratic,low,high) else mid
		local distanceSquared=0
		for axis=1,3 do distanceSquared+=math.max(0,math.abs(starts[axis]+steps[axis]*t)-extents[axis])^2 end
		if distanceSquared<=radius^2 then return true end
	end
	return false
end

return FruitMotion
