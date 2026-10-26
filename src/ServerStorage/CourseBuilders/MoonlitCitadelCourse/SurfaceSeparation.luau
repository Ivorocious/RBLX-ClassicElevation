--!nonstrict
local Separation = {}
local WINDOW_STONE = Vector3.new(24, 57.981651306152344, 1.8199999332427979)
local windows = {
    KeepLancet2Face1MC_WindowFrame=true, WestHighWarmLancetMC_WindowFrame=true,
    WestMiddleWarmLancetMC_WindowFrame=true, UpperMachineWarmLancet1MC_WindowFrame=true,
    UpperMachineWarmLancet2MC_WindowFrame=true, UpperKeepWarmLancet1MC_WindowFrame=true,
    UpperKeepWarmLancet2MC_WindowFrame=true, GalleryInteriorQuietLancet1MC_WindowFrame=true,
    GalleryInteriorQuietLancet2MC_WindowFrame=true, GalleryInteriorQuietLancet3MC_WindowFrame=true,
    KeepRoofQuietWestWindowMC_WindowFrame=true,
}
local wheels = {LowerWheelSupportLeft=true,LowerWheelSupportRight=true,UpperWheelSupportLeft=true,UpperWheelSupportRight=true}

local function close(a,b)
    return math.abs(a.X-b.X)<.003 and math.abs(a.Y-b.Y)<.003 and math.abs(a.Z-b.Z)<.003
end

local function visual(part,asset,material)
    assert(part:IsA("MeshPart") and part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,
        "Surface correction requires an anchored visual-only mesh")
    assert(part:GetAttribute("SourceAsset")==asset and part:GetAttribute("SourceMaterial")==material,
        "Surface correction asset/material differs")
end

function Separation.ApplyFloorSkins(course)
    assert(course:IsA("Model") and course:GetAttribute("CourseId")=="moonlit_citadel")
    local obstacles=assert(course:FindFirstChild("Obstacles"))
    local targets={}
    for _,part in obstacles:GetDescendants() do
        if not part:IsA("MeshPart") or part.Name~="MC_FloorStone__Floor" then continue end
        visual(part,"MC_FloorStone","Floor")
        assert(part.Parent.Name=="StoneSkin")
        local contact=assert(part.Parent.Parent:FindFirstChild("Contact"))
        assert(contact:IsA("BasePart") and contact:GetAttribute("MCWalkable")==true)
        assert(math.abs(part.Size.X-contact.Size.X)<.003 and math.abs(part.Size.Z-contact.Size.Z*.995)<.003,
            "Floor correction expects the original skin width/depth exactly once: "..part:GetFullName().." "..tostring(part.Size).." contact="..tostring(contact.Size))
        assert(part.Size.X>.18 and part.Size.Z>.18)
        table.insert(targets,part)
    end
    assert(#targets==135,"Current Moonlit recipe requires exactly135 floor skins")
    for _,part in targets do part.Size-=Vector3.new(.08,0,.08) end
    return #targets
end

-- Call once after placement/scaling and before appearance; no template is changed.
function Separation.ApplyWorldUnit(model,data)
    assert(model:IsA("Model") and model.Name==data.name)
    local changes={}
    local function queue(material,baseSize,delta,shift,baseCentre)
        local part=assert(model:FindFirstChild(data.asset.."__"..material,true))
        visual(part,data.asset,material)
        assert(close(part.Size,baseSize*data.scale),"World correction expects the original material size exactly once")
        if baseCentre then
            assert(close(model.WorldPivot:PointToObjectSpace(part.CFrame.Position),baseCentre*data.scale),
                "World correction expects the original material seat exactly once")
        end
        local target=part.Size+(delta or Vector3.zero)
        assert(math.min(target.X,target.Y,target.Z)>.001)
        table.insert(changes,{part=part,size=if delta then target else nil,frame=if shift then part.CFrame+shift else nil})
    end
    if data.asset=="MC_WindowFrame" and windows[data.name] then
        queue("Stone",WINDOW_STONE,Vector3.new(-.12,-.12,0))
    elseif data.asset=="MC_ER_LanternBracket" and wheels[data.name] then
        assert(model.WorldPivot.LookVector:Dot(Vector3.new(0,0,-1))>.99999)
        queue("Iron",Vector3.new(4,18,24),nil,Vector3.new(0,0,.06),Vector3.new(0,-7,12))
    elseif data.asset=="MC_AR_MasonryMass" then
        queue("Stone",Vector3.new(24,21.62,12),Vector3.new(-.08,0,-.08),
            if data.name=="UpperMachineWindowBay1" then Vector3.new(.08,0,0) else nil)
    elseif data.asset=="MC_ER_CrownBaseShell" and data.name=="CrownBaseUnifiedShell" then
        queue("StoneLight",Vector3.new(76,23.800003051757812,41),nil,Vector3.new(0,0,.08),Vector3.new(-8,137.7,-27.5))
        local dark=assert(model:FindFirstChild("MC_ER_CrownBaseShell__StoneDark",true))
        assert(math.abs(dark.CFrame.RightVector:Dot(Vector3.xAxis))>.99999,"Crown side trim requires its proved native X axis")
        queue("StoneDark",Vector3.new(75.71199798583984,19.197509765625,40.41154098510742),Vector3.new(.12,0,0))
    elseif data.asset=="MC_ER_RaisedCourt" and data.name=="NorthWestRaisedCourt" then
        queue("StoneLight",Vector3.new(98,4,78),nil,Vector3.new(0,0,.06),Vector3.new(0,68,0))
    elseif data.asset=="MC_DT_ChimneyVent" then
        queue("StoneLight",Vector3.new(3.2335785351478763,7.83,3.2335785351478763),nil,Vector3.new(0,.06,0),Vector3.new(0,4.425,0))
    elseif data.asset=="MC_AR_GalleryRoof46" and (data.name=="JunctionEastSeatedRoof" or data.name=="JunctionWestSeatedRoof") then
        queue("SlateBand",Vector3.new(48.18,9.04,25.2),nil,Vector3.new(.06,0,0),Vector3.new(0,4.25,-11))
    end
    for _,change in changes do
        if change.size then change.part.Size=change.size end
        if change.frame then change.part.CFrame=change.frame end
    end
    return #changes
end

function Separation.ApplyRouteCosmetics(course)
    assert(course:IsA("Model") and course:GetAttribute("CourseId")=="moonlit_citadel")
    local targets={}
    local function queue(part,asset,material,size,centre,shift)
        visual(part,asset,material)
        assert(close(part.Size,size) and close(part.Parent.WorldPivot:PointToObjectSpace(part.CFrame.Position),centre),
            "Route cosmetic correction expects the measured original seat exactly once")
        table.insert(targets,{part=part,frame=part.CFrame+shift})
    end
    for _,part in course.Obstacles:GetDescendants() do
        if not part:IsA("MeshPart") then continue end
        local asset,material=part:GetAttribute("SourceAsset"),part:GetAttribute("SourceMaterial")
        local parent=part.Parent
        if asset=="MC_CarIronBrass" and material=="Brass" and parent.Name=="MC_CarIronBrass" then
            queue(part,asset,material,Vector3.new(13.99000072479248,3.252500057220459,11.989999771118164),
                Vector3.new(0,1.37375,0),Vector3.new(0,0,.06))
        elseif asset=="MC_WeightIron" and parent.Name=="MC_WeightIron" then
            if material=="Iron" then queue(part,asset,material,Vector3.new(4,7.94,.16000008583068848),Vector3.new(0,0,1.28),Vector3.new(.06,0,0))
            elseif material=="Brass" then queue(part,asset,material,Vector3.new(3.75,7.825,.22999989986419678),Vector3.new(0,0,1.3),Vector3.new(0,0,.06)) end
        elseif asset=="MC_GuideIron" and material=="Brass" and parent.Parent.Name=="GalleryExpertShortcut_LiftNeedle1_Red40"
            and (parent.Name=="IronBrassPost-1" or parent.Name=="IronBrassPost1") then
            queue(part,asset,material,Vector3.new(.406000018119812,.2472115457057953,.07000000029802322),
                Vector3.new(0,0,.215576171875),Vector3.new(0,-.06,0))
        end
    end
    assert(#targets==14,"Current Moonlit recipe requires exactly14 cosmetic car/weight/post parts")
    for _,change in targets do change.part.CFrame=change.frame end
    return #targets
end

return Separation
