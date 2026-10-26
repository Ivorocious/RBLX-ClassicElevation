--!nonstrict
local Oracle={Unit="GrandRearCentralPinnacle",Asset="MC_TL_GrandPinnacle",Library="TL01",Part="MC_TL_GrandPinnacle__StoneLight",Material="StoneLight"}
local function vector(value)
	if typeof(value)=="Vector3" then return value end
	assert(type(value)=="table" and #value==3,"Explicit part scale must be one XYZ array")
	for _,number in value do assert(type(number)=="number" and number==number and math.abs(number)<math.huge,"Part scale must be finite") end
	return Vector3.new(table.unpack(value))
end
local function near(a,b)return math.abs(a-b)<=1e-6 end
function Oracle.ValidatePlan(plan)
	local report={pass=false,units=0,parts=0,failures={},field="partLocalScaleOverrides",sizeOnly=true,CFChanged=false}
	for _,data in plan do
		if data.partLocalPositionOverrides or data.partFrameOverrides or data.partSizeOverrides then table.insert(report.failures,"Unsupported extra part adjustment on "..data.name) end
		if data.partLocalScaleOverrides then
			report.units+=1
			if data.name~=Oracle.Unit or data.asset~=Oracle.Asset or data.library~=Oracle.Library then table.insert(report.failures,"Unapproved override unit "..data.name) end
			for name,value in data.partLocalScaleOverrides do
				report.parts+=1;local ok,scale=pcall(vector,value)
				if name~=Oracle.Part or not ok or not near(scale.X,1) or not near(scale.Y,1) or not near(scale.Z,1.04) then
					table.insert(report.failures,"Unapproved override part/factor "..data.name.."/"..name)
				end
			end
		end
	end
	if report.units~=1 or report.parts~=1 then table.insert(report.failures,"Exactly one approved material-part adjustment is required") end
	report.pass=#report.failures==0
	return report
end
function Oracle.Expected(data,part,expectedFrame,expectedSize)
	local overrides=data.partLocalScaleOverrides
	if not overrides then return expectedFrame,expectedSize end
	assert(data.name==Oracle.Unit and data.asset==Oracle.Asset and data.library==Oracle.Library,"Unapproved adjusted unit")
	local adjustment=overrides[part.Name]
	if not adjustment then return expectedFrame,expectedSize end
	assert(part.Name==Oracle.Part and part:GetAttribute("SourceMaterial")==Oracle.Material,"Only the proved StoneLight material part can change")
	local scale=vector(adjustment)
	assert(near(scale.X,1) and near(scale.Y,1) and near(scale.Z,1.04),"Only the explicit four percent native-Z depth relief is approved")
	return expectedFrame,expectedSize*scale
end
return Oracle
