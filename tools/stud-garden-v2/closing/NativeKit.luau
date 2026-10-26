local Kit = {}
Kit.colors = {
    cream=Color3.fromRGB(255,239,201), dark=Color3.fromRGB(45,62,51),
    timber=Color3.fromRGB(154,97,47), honey=Color3.fromRGB(216,164,90),
    steel=Color3.fromRGB(126,162,177), edge=Color3.fromRGB(65,101,116),
    steelLight=Color3.fromRGB(192,217,218), grass=Color3.fromRGB(101,159,60),
    leaf=Color3.fromRGB(57,114,64), lime=Color3.fromRGB(173,211,95),
    teal=Color3.fromRGB(51,154,157), aqua=Color3.fromRGB(139,222,214),
    pink=Color3.fromRGB(232,139,186), pinkDark=Color3.fromRGB(155,73,133),
    pinkLight=Color3.fromRGB(255,201,216), coral=Color3.fromRGB(226,76,62),
    gold=Color3.fromRGB(255,193,59), soil=Color3.fromRGB(83,55,39),
    terra=Color3.fromRGB(199,109,65), orange=Color3.fromRGB(240,145,51),
}
function Kit.model(parent,name,frame)
    local m=Instance.new("Model")
    m.Name=name
    m.WorldPivot=frame or CFrame.identity
    m:SetAttribute("SGV2Owned",true)
    m:SetAttribute("ClosingRevision","C05")
    m.Parent=parent
    return m
end
function Kit.part(parent,name,frame,size,color,role,shape)
    local p=Instance.new(if shape=="Wedge" then "WedgePart" else "Part")
    p.Name=name; p.Size=size; p.CFrame=frame; p.Color=Kit.colors[color] or color
    p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
    p.CanCollide=role=="Walk" or role=="Blocker" or role=="Refuge"
    p.CanQuery=p.CanCollide; p.CanTouch=role=="Hazard"
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    if shape=="Ball" then p.Shape=Enum.PartType.Ball elseif shape=="Cylinder" then p.Shape=Enum.PartType.Cylinder end
    p:SetAttribute("Role",role or "Decoration")
    p.Parent=parent
    return p
end
function Kit.box(parent,name,frame,position,size,color,role,rotation)
    return Kit.part(parent,name,frame*CFrame.new(position)*(rotation or CFrame.identity),size,color,role)
end
function Kit.rod(parent,name,a,b,radius,color,role,radiusZ)
    local direction=(b-a).Unit
    local reference=if math.abs(direction:Dot(Vector3.yAxis))>.98 then Vector3.zAxis else Vector3.yAxis
    local up=reference:Cross(direction).Unit
    return Kit.part(parent,name,CFrame.fromMatrix((a+b)/2,direction,up,direction:Cross(up)),Vector3.new((b-a).Magnitude,2*radius,2*radius),color,role,"Cylinder")
end
function Kit.scale(model,scale)
    local pivot=model:GetPivot()
    for _,p in model:GetDescendants() do
        if p:IsA("BasePart") then
            local cf=pivot:ToObjectSpace(p.CFrame)
            p.CFrame=pivot*CFrame.new(cf.Position*scale)*cf.Rotation
            p.Size*=scale
        elseif p:IsA("Model") then
            local cf=pivot:ToObjectSpace(p:GetPivot())
            p.WorldPivot=pivot*CFrame.new(cf.Position*scale)*cf.Rotation
        end
    end
    model:SetAttribute("AuthoredScale",scale)
end
function Kit.stud(parent,position,color,radius)
    local p=Kit.rod(parent,"RaisedStud",position,position+Vector3.new(0,.22,0),radius or .65,color)
    p.CastShadow=false
end
function Kit.triangle(parent,name,a,b,c,thickness,color,role)
    local ab,ac,bc=b-a,c-a,c-b
    if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
    elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
    ab,ac,bc=b-a,c-a,c-b
    if ac:Cross(ab).Magnitude<.0001 then return end
    local right=ac:Cross(ab).Unit
    local back=bc.Unit
    local up=bc:Cross(right).Unit
    local height=math.abs(ab:Dot(up))
    for i,r in {{(a+b)/2,right,up,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,up,-back,math.abs(ac:Dot(back))}} do
        if r[5]>.001 then Kit.part(parent,name.."_"..i,CFrame.fromMatrix(r[1],r[2],r[3],r[4]),Vector3.new(thickness,height,r[5]),color,role,"Wedge") end
    end
end
function Kit.quad(parent,name,frame,a,b,c,d,thickness,color,role)
    Kit.triangle(parent,name.."A",frame*a,frame*b,frame*c,thickness,color,role)
    Kit.triangle(parent,name.."B",frame*a,frame*c,frame*d,thickness,color,role)
end
function Kit.label(part,text,color,face)
    local gui=Instance.new("SurfaceGui")
    gui.Name="GardenLabel"; gui.Face=face or Enum.NormalId.Front
    gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=32
    gui.LightInfluence=.25; gui.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(.93,.88); label.Position=UDim2.fromScale(.035,.06)
    label.BackgroundTransparency=1; label.Text=text; label.TextColor3=Kit.colors[color] or color
    label.TextScaled=true; label.Font=Enum.Font.GothamBold; label.Parent=gui
end
function Kit.arrow(parent,position,direction,scale,color)
    local cf=CFrame.lookAt(position,position+Vector3.new(direction.X,0,direction.Z))
    Kit.box(parent,"RouteChevronStem",cf,Vector3.new(0,0,scale*.35),Vector3.new(scale*.36,.055,scale*.9),color)
    Kit.triangle(parent,"RouteChevronHead",cf*Vector3.new(-scale*.55,0,0),cf*Vector3.new(scale*.55,0,0),cf*Vector3.new(0,0,-scale*.65),.055,color,"Decoration")
end
function Kit.leaf(parent,name,frame,length,width,color,role)
    local points={Vector3.new(0,0,0),Vector3.new(-width*.5,.5,-length*.35),Vector3.new(-width*.38,.4,-length*.75),Vector3.new(0,0,-length),Vector3.new(width*.38,.4,-length*.75),Vector3.new(width*.5,.5,-length*.35)}
    local center=Vector3.new(0,.85,-length*.45)
    for i=1,6 do Kit.triangle(parent,name.."Lobe"..i,frame*points[i],frame*points[i%6+1],frame*center,.45,color,role or "Decoration") end
    Kit.rod(parent,name.."Vein",frame*Vector3.new(0,.9,-.5),frame*Vector3.new(0,.55,-length*.88),.18,if color=="pink" then "pinkLight" else "lime")
end
return Kit
