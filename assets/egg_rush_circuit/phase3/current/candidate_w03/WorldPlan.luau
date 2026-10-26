--!nonstrict
local V = Vector3.new
local Plan = {
 Revision = "ER_P3_W03",
 Origin = V(1544, 311, -1134),
 Placements = {},
 Native = {},
 Palette = {
  cream = Color3.fromRGB(255, 240, 202),
  coral = Color3.fromRGB(246, 125, 96),
  mint = Color3.fromRGB(104, 205, 176),
  honey = Color3.fromRGB(185, 123, 67),
  violet = Color3.fromRGB(173, 117, 207),
  rock = Color3.fromRGB(128, 132, 143),
  shadow = Color3.fromRGB(80, 88, 99),
  garden = Color3.fromRGB(90, 155, 111),
  glass = Color3.fromRGB(141, 205, 210),
 },
 UnitSizes = {
  WorkshopBay = V(28, 28, 22), WorkshopArch = V(28, 28, 10),
  HallBay = V(36, 48, 28), HallCrown = V(36, 12, 28),
  HoneyFrame = V(22, 28, 8), IncubatorTank = V(22, 30, 22),
  TerraceBase = V(40, 14, 40), TerraceCorner = V(40, 14, 40),
  RookeryPlinth = V(72, 26, 60), ServiceCanopy = V(44, 18, 32),
  NurseryPavilion = V(30, 26, 30), SortingDrum = V(28, 22, 22),
  ShellReturnArch = V(36, 32, 14), GardenCluster = V(32, 14, 28),
  ShellRoof = V(32, 14, 28),
 },
 Districts = {
  {Id="Nursery", Name="Nursery Courts", Focus=V(-54, 12, 138), Description="Low side nurseries and a broad cream intake gallery frame the original start and finish."},
  {Id="Sorting", Name="Sorting and Loading Works", Focus=V(-184, 18, -31), Description="Two roofed loading courts and sorting drums serve the six accepted rolling eggs."},
  {Id="Shellworks", Name="Shellworks", Focus=V(-45, 29, -169), Description="A connected coral workshop skyline rises behind the open shell crossing."},
  {Id="Incubation", Name="Incubation Hall", Focus=V(-4, 20, -42), Description="A monumental mint tank and a complete low central hall anchor the inner void; a service wing frames both tray rides."},
  {Id="Rookery", Name="Guardian Rookery", Focus=V(137, 34, 29), Description="The accepted giant chicken has a deep foundation and an eastern aviary roofline."},
  {Id="Return", Name="Shell-spill Gardens", Focus=V(117, 9, 143), Description="Shell-shaped roofs, gardens and nursery annexes close the descending return at its original destination."},
 },
 ProtectedZones = {
  {Id="GrandArcade", Min=V(-48.5,38.7,152.5), Max=V(64.5,89.8,251.5)},
  {Id="Lobby", Min=V(-67,43,208), Max=V(83,157,360)},
  {Id="Gallery", Min=V(179.5,56,87), Max=V(324.5,78,217)},
 },
 Roles = {
  UnreachableArchitecture = "Finished closed architecture beyond open horizontal gaps or far above the accepted route; never a new landing.",
  BelowCourseFoundation = "Lower structural mass; no new contact surface or catch floor.",
  DistantLandscape = "Outer low landscape outside racing and recovery corridors.",
  Landmark = "A prominent isolated visual anchor; no route contact.",
  OverheadService = "Services above standing, jump and camera corridors; no new route.",
 },
}

local function frame(x, y, z, yaw)
 return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

-- All frames use the unit's bottom center. Size is the complete final bounding size.
local function unit(district, id, kind, x, y, z, sx, sy, sz, color, role, yaw)
 table.insert(Plan.Placements, {
  District=district, Id=id, Type=kind, Frame=frame(x,y,z,yaw), Size=V(sx,sy,sz),
  Color=color, Role=role or "UnreachableArchitecture",
 })
end

local function block(district, id, x, y, z, sx, sy, sz, color, role, yaw)
 table.insert(Plan.Native, {
  District=district, Id=id, Type="Block", Frame=frame(x,y,z,yaw), Size=V(sx,sy,sz),
  Color=color, Role=role or "BelowCourseFoundation",
 })
end

local function foundation(district, id, x, z, sx, sz, top)
 block(district,id.."_Footing",x,-64,z,sx+4,6,sz+4,"shadow")
 block(district,id.."_Stem",x,-58,z,sx,top+58,sz,"rock")
 block(district,id.."_Collar",x,top-3,z,sx+2,3,sz+2,"honey")
end

local function lowland(district,id,x,z,sx,sz,top,yaw)
 unit(district,id,"TerraceBase",x,-68,z,sx,top+68,sz,"rock","DistantLandscape",yaw)
end

-- The south gallery stops at Z144; the unrelated Grand Arcade begins at Z152.5.
unit("Nursery","FinishIntakeGallery","HallBay",8,-14,140,112,60,8,"cream")
unit("Nursery","FinishGalleryCrown","ShellRoof",-57,112,131,108,16,30,"mint")
unit("Nursery","WestNursery","NurseryPavilion",-94,-14,157,42,40,38,"cream")
unit("Nursery","WestNurseryPorch","WorkshopArch",-94,-12,135,34,32,8,"coral")
unit("Nursery","NurseryWestWing","NurseryPavilion",-144,-18,129,36,42,36,"cream",nil,-90)
unit("Nursery","NurseryWestRoof","ShellRoof",-144,24,129,38,12,38,"mint",nil,-90)
unit("Nursery","WestGardenCourt","GardenCluster",-140,-38,159,40,18,32,"garden","DistantLandscape")
unit("Nursery","WestNurseryGarden","GardenCluster",-104,-38,187,43,18,22,"garden","DistantLandscape")
unit("Nursery","NurseryMintService","SortingDrum",-64,-18,143,20,44,16,"mint")
foundation("Nursery","GalleryFoundation",-28,140,184,8,-14)
foundation("Nursery","WestNurseryFoundation",-94,157,42,38,-14)
foundation("Nursery","WestWingFoundation",-144,129,36,36,-18)
lowland("Nursery","NurseryOuterBank",-117,160,112,68,-44)
lowland("Nursery","FinishLowerBank",0,140,74,38,-48)

-- Deep western and recessed eastern vaulted halls replace the projecting office screen.
block("Nursery","GalleryLowerWestWing",-81,-14,140,78,60,8,"cream","UnreachableArchitecture")
block("Nursery","GalleryLowerWestWindow",-84,4,135.6,50,26,.5,"glass","UnreachableArchitecture")
block("Nursery","GalleryLowerCoralCoping",-28,46,140,186,2,10,"coral","UnreachableArchitecture")
unit("Nursery","UpperWestHatcheryHall","HallBay",-57,46,131,106,66,28,"cream")
unit("Nursery","UpperEastHatcheryHall","HallBay",29,46,138,70,84,14,"cream")
unit("Nursery","UpperEastVault","ShellRoof",29,130,138,72,14,16,"coral")
block("Nursery","WestHallRearService",-57,70,145.35,62,22,.5,"mint","UnreachableArchitecture")
block("Nursery","EastHallRearService",29,82,145.35,42,24,.5,"mint","UnreachableArchitecture")

-- Long loading sheds give each egg band a working district rather than six isolated props.
for index, z in ipairs({18,-30,-78}) do
 unit("Sorting","LoadingHall"..index,"WorkshopBay",-195,-18,z,38,58,40,"cream",nil,-90)
 unit("Sorting","LoadingRoof"..index,"ShellRoof",-195,40,z,40,12,42,"coral",nil,-90)
 foundation("Sorting","LoadingFoundation"..index,-195,z,40,38,-18)
end
for index, z in ipairs({-6,-53}) do
 unit("Sorting","EggLoadingCanopy"..index,"ServiceCanopy",-180,-8,z,34,40,30,"honey",nil,90)
 unit("Sorting","SortingDrum"..index,"SortingDrum",-216,-22,z,25,44,25,if index==1 then "coral" else "mint")
 unit("Sorting","SortingGarden"..index,"GardenCluster",-221,-43,z+22,26,19,22,"garden","DistantLandscape")
end
unit("Sorting","LoadingSouthGate","ShellReturnArch",-183,-16,59,40,50,16,"honey",nil,-90)
unit("Sorting","LoadingNorthGate","WorkshopArch",-186,-12,-110,34,52,12,"coral",nil,-90)
lowland("Sorting","LoadingLowlandA",-201,17,74,90,-44)
lowland("Sorting","LoadingLowlandB",-201,-73,74,92,-44)

for index, x in ipairs({-108,-76,-44,-12,20,52}) do
 local height=if index==3 or index==4 then 54 else 44
 unit("Shellworks","Workshop"..index,"WorkshopBay",x,-10,-177,32,height,32,"cream",nil,180)
 unit("Shellworks","WorkshopRoof"..index,"ShellRoof",x,height-10,-177,34,10,34,"coral",nil,180)
 foundation("Shellworks","WorkshopFoundation"..index,x,-177,32,32,-10)
end
unit("Shellworks","ShellworksWestTower","HallBay",-144,-16,-170,30,65,36,"cream",nil,180)
unit("Shellworks","ShellworksTowerCrown","HallCrown",-144,49,-170,32,12,38,"mint",nil,180)
unit("Shellworks","ShellworksRoofMonitor","HoneyFrame",-28,52,-177,36,14,12,"honey")
unit("Shellworks","ShellworksEastTower","HallBay",88,-10,-166,40,64,40,"cream",nil,180)
unit("Shellworks","ShellworksEastCrown","HallCrown",88,54,-166,42,12,42,"coral",nil,180)
lowland("Shellworks","WorkshopRearBank",-35,-189,246,68,-46)

-- The inner hall is separated from every route by an open moat; it never fills jump gaps.
unit("Incubation","CentralIncubationHall","HallBay",-4,-36,6,76,32,68,"cream","Landmark")
unit("Incubation","CentralHallCornice","HallCrown",-4,-4,6,78,4,70,"honey","Landmark")
unit("Incubation","MonumentalIncubator","IncubatorTank",-4,-18,-42,36,72,36,"mint","Landmark")
unit("Incubation","TankWestService","WorkshopBay",-41,-29,-39,28,28,30,"cream")
unit("Incubation","TankEastService","WorkshopBay",33,-29,-39,28,28,30,"cream")
unit("Incubation","TankFrontArcade","WorkshopArch",-4,-31,-10,44,22,8,"honey","Landmark",180)
foundation("Incubation","CentralHallFoundation",-4,6,76,68,-36)
foundation("Incubation","TankFoundation",-4,-42,38,38,-18)
lowland("Incubation","CentralLowland",-4,-1,132,124,-48)

unit("Incubation","TrayServiceHall","HallBay",155,-10,-71,30,78,48,"cream",nil,90)
unit("Incubation","TrayServiceCrown","HallCrown",155,68,-71,32,10,50,"mint",nil,90)
unit("Incubation","TrayServiceNorth","WorkshopBay",121,-12,-119,36,50,32,"cream",nil,180)
unit("Incubation","TrayServiceNorthRoof","ShellRoof",121,38,-119,38,12,34,"coral",nil,180)
unit("Incubation","TrayUpperDrum","SortingDrum",155,68,-71,22,28,22,"mint","Landmark")
foundation("Incubation","TrayServiceFoundation",155,-71,48,30,-10)
foundation("Incubation","TrayNorthFoundation",121,-119,36,32,-12)
lowland("Incubation","TrayOuterBank",169,-101,64,104,-44)

-- Only the narrow new stem sits inside the already accepted roost rock footprint.
unit("Rookery","GuardianRoostStem","RookeryPlinth",91,-45,40,34,48,26,"rock","BelowCourseFoundation")
unit("Rookery","EasternRookeryHall","HallBay",205,-16,11,38,84,64,"cream",nil,90)
unit("Rookery","RookeryHallCrown","HallCrown",205,68,11,40,12,66,"coral",nil,90)
unit("Rookery","NorthRookeryWing","WorkshopBay",198,-18,-37,34,60,30,"cream",nil,90)
unit("Rookery","NorthRookeryRoof","ShellRoof",198,42,-37,36,12,32,"mint",nil,90)
unit("Rookery","RookeryGardenNorth","GardenCluster",217,-42,-33,34,20,36,"garden","DistantLandscape")
unit("Rookery","RookeryGardenEast","GardenCluster",231,-42,13,30,20,46,"garden","DistantLandscape")
unit("Rookery","RookeryGardenSouth","GardenCluster",48,-2,66,30,18,22,"garden","Landmark")
unit("Rookery","InnerGardenFoundation","TerraceBase",48,-64,66,30,62,22,"rock","BelowCourseFoundation")
foundation("Rookery","RookeryHallFoundation",205,11,64,38,-16)
foundation("Rookery","RookeryWingFoundation",198,-37,30,34,-18)
lowland("Rookery","RookeryEastBank",208,8,86,112,-44)

unit("Return","ReturnNursery","HallBay",105,-16,185,72,108,38,"cream")
unit("Return","ReturnNurseryShellRoof","ShellRoof",105,92,185,74,12,40,"mint")
unit("Return","ReturnOuterAnnex","HallBay",191,-12,52,50,74,48,"cream",nil,90)
unit("Return","ReturnAnnexVault","ShellRoof",191,62,52,52,12,50,"coral",nil,90)
unit("Return","ShellReturnGate","ShellReturnArch",151,-18,155,30,54,14,"coral")
unit("Return","ReturnGardenSouth","GardenCluster",108,107,188,75,32,30,"garden","UnreachableArchitecture")
unit("Return","ReturnGardenEast","GardenCluster",152,4,118,48,26,50,"garden","UnreachableArchitecture")
unit("Return","GardenBankFoundation","TerraceBase",152,-58,118,46,62,48,"rock","BelowCourseFoundation")
unit("Return","ReturnShellRooflet","ShellRoof",91,-33,170,23,12,26,"cream","DistantLandscape",35)
block("Return","RoofGardenPlanter",108,102,188,77,5,34,"honey","UnreachableArchitecture")
block("Return","ReturnHallRearService",105,28,204.35,44,36,.5,"mint","UnreachableArchitecture")
foundation("Return","ReturnNurseryFoundation",105,185,72,38,-16)
foundation("Return","ReturnAnnexFoundation",191,52,48,50,-12)
lowland("Return","ReturnLowland",119,160,106,88,-44)

-- Recessed service trunks visually connect the facility without adding a walkable ring.
block("Incubation","TankRearServiceTrunk",-4,-37,-95,10,9,76,"mint")
block("Incubation","ShellworksServiceTrunk",49,-37,-143,116,9,10,"mint")
block("Incubation","RookeryServiceTrunk",155,-37,-15,10,9,88,"mint")
block("Return","NurseryServiceTrunk",118,-38,145,8,8,38,"mint")

for index, x in ipairs({-104,-48,8,60}) do
 block("Nursery","FinishGalleryPier"..index,x,-14,138,3,61,4,"honey","UnreachableArchitecture")
 block("Nursery","FinishGalleryRoofSeam"..index,x,47,140,2,2,10,"cream","UnreachableArchitecture")
end
for index, z in ipairs({48,3,-42,-87}) do
 block("Sorting","LoadingFrontColumn"..index,-171,-18,z,3,49,4,"honey","UnreachableArchitecture")
 block("Sorting","LoadingRearColumn"..index,-215,-18,z,3,49,4,"honey","UnreachableArchitecture")
end
for index, x in ipairs({-123,-91,-59,-27,5,37,67}) do
 block("Shellworks","RooflinePilaster"..index,x,-10,-158,3,46,4,"honey","UnreachableArchitecture")
end
for index, z in ipairs({-94,-70,-46}) do
 block("Incubation","TrayServiceButtress"..index,130,-10,z,4,78,5,"honey","UnreachableArchitecture")
end
for index, z in ipairs({-15,9,33}) do
 block("Rookery","AviaryButtress"..index,171,-16,z,4,84,6,"honey","UnreachableArchitecture")
end

return Plan
