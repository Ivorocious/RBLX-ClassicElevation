--!nonstrict
local V = Vector3.new
local Plan = {
 Revision = "ER_P3_W05",
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
  {Id="Nursery", Name="Nursery Courts", Focus=V(-54, 12, 138), Description="A central intake and two lower working wings frame the original start and finish."},
  {Id="Sorting", Name="Sorting and Loading Works", Focus=V(-184, 18, -31), Description="Three low loading sheds, two narrow covered links and sorting drums serve the six accepted rolling eggs."},
  {Id="Shellworks", Name="Shellworks", Focus=V(-45, 29, -169), Description="A connected coral workshop skyline rises behind the open shell crossing."},
  {Id="Incubation", Name="Incubation Hall", Focus=V(-4, 20, -42), Description="A monumental mint tank and a low central hall anchor the inner void; a smaller service wing frames both tray rides."},
  {Id="Rookery", Name="Guardian Rookery", Focus=V(137, 34, 29), Description="The accepted giant chicken rises above a quiet line of separated aviary buildings."},
  {Id="Return", Name="Shell-spill Gardens", Focus=V(117, 9, 143), Description="A planted roof terrace and low nursery annex close the descending return at its original destination."},
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
 block(district,id.."_Stem",x,-58,z,sx,top+55,sz,"rock")
 block(district,id.."_Collar",x,top-3,z,sx+2,3,sz+2,"honey")
end

local function lowland(district,id,x,z,sx,sz,top,yaw)
 unit(district,id,"TerraceBase",x,-68,z,sx,top+68,sz,"rock","DistantLandscape",yaw)
end

-- The low intake stays below the neighboring Arcade; the tall halls stand back to the west.
unit("Nursery","FinishIntakeGallery","HallBay",8,-26,172,56,48,26,"cream")
unit("Nursery","IntakeWestWing","WorkshopBay",-45,-26,174,48,42,26,"cream")
unit("Nursery","IntakeEastWing","WorkshopBay",60,-26,174,48,42,26,"cream")
unit("Nursery","FinishGalleryCrown","ShellRoof",-110,58,190,76,14,38,"mint")
unit("Nursery","WestNursery","NurseryPavilion",-94,-14,143,42,40,28,"cream")
unit("Nursery","WestNurseryPorch","WorkshopArch",-94,-12,125,34,32,8,"coral")
unit("Nursery","NurseryWestWing","NurseryPavilion",-159,-18,136,36,42,36,"cream",nil,-90)
unit("Nursery","NurseryWestRoof","ShellRoof",-159,24,136,38,12,38,"mint",nil,-90)
unit("Nursery","WestGardenCourt","GardenCluster",-132,-44,163,34,16,26,"garden","DistantLandscape")
unit("Nursery","WestNurseryGarden","GardenCluster",-104,-44,174,36,18,20,"garden","DistantLandscape")
unit("Nursery","NurseryMintService","SortingDrum",-129,-18,140,18,26,16,"mint")
foundation("Nursery","GalleryFoundation",7.5,173,153,28,-26)
foundation("Nursery","WestNurseryFoundation",-94,143,42,28,-14)
foundation("Nursery","WestNurseryPorchFoundation",-94,125,34,8,-12)
foundation("Nursery","WestWingFoundation",-159,136,36,36,-18)
foundation("Nursery","NurseryServiceFoundation",-129,140,18,16,-18)
lowland("Nursery","NurseryOuterBank",-117,160,112,68,-44)
lowland("Nursery","FinishLowerBank",0,168,74,38,-48)

-- Deep western and recessed eastern vaulted halls replace the projecting office screen.
unit("Nursery","UpperWestHatcheryHall","HallBay",-110,-26,190,74,84,36,"cream")
unit("Nursery","UpperEastHatcheryHall","HallBay",-178,-26,190,52,90,36,"cream")
unit("Nursery","UpperEastVault","ShellRoof",-178,64,190,54,14,38,"coral")
block("Nursery","WestHallRearService",-110,20,206.9,44,20,.5,"mint","UnreachableArchitecture")
block("Nursery","EastHallRearService",-178,24,206.9,32,22,.5,"mint","UnreachableArchitecture")
foundation("Nursery","WestVaultFoundation",-110,190,74,36,-26)
foundation("Nursery","RearVaultFoundation",-178,190,52,36,-26)

-- Long loading sheds give each egg band a working district rather than six isolated props.
for index, z in ipairs({18,-30,-78}) do
 unit("Sorting","LoadingHall"..index,"WorkshopBay",-195,-18,z,38,36,40,"cream",nil,-90)
 unit("Sorting","LoadingRoof"..index,"ShellRoof",-195,18,z,40,12,42,"coral",nil,-90)
 foundation("Sorting","LoadingFoundation"..index,-195,z,40,38,-18)
end
for index, z in ipairs({-6,-53}) do
 unit("Sorting","EggLoadingCanopy"..index,"ServiceCanopy",-180,-18,z,14,24,30,"honey",nil,90)
 unit("Sorting","SortingDrum"..index,"SortingDrum",-229,-22,z,25,30,25,if index==1 then "coral" else "mint")
 local gardenZ=if index==1 then 16 else -70
 unit("Sorting","SortingGarden"..index,"GardenCluster",-211,-44,gardenZ,22,16,20,"garden","DistantLandscape")
 foundation("Sorting","CanopyFoundation"..index,-180,z,30,14,-18)
 foundation("Sorting","SorterFoundation"..index,-229,z,25,25,-22)
end
unit("Sorting","LoadingSouthGate","ShellReturnArch",-183,-16,59,40,50,16,"honey",nil,-90)
unit("Sorting","LoadingNorthGate","WorkshopArch",-186,-12,-116,34,40,12,"coral",nil,-90)
foundation("Sorting","LoadingSouthGateFoundation",-183,59,16,40,-16)
foundation("Sorting","LoadingNorthGateFoundation",-186,-116,12,34,-12)
lowland("Sorting","LoadingLowlandA",-201,17,74,90,-44)
lowland("Sorting","LoadingLowlandB",-201,-73,74,92,-44)

for index, x in ipairs({-108,-76,-44,-12,20,52}) do
 local height=if index==3 or index==4 then 40 else 32
 unit("Shellworks","Workshop"..index,"WorkshopBay",x,-10,-177,32,height,32,"cream",nil,180)
 unit("Shellworks","WorkshopRoof"..index,"ShellRoof",x,height-10,-177,32,10,32,"coral",nil,180)
end
foundation("Shellworks","WorkshopRunFoundation",-28,-177,192,32,-10)
unit("Shellworks","ShellworksWestTower","HallBay",-144,-16,-170,30,65,36,"cream",nil,180)
unit("Shellworks","ShellworksTowerCrown","HallCrown",-144,49,-170,32,12,38,"mint",nil,180)
unit("Shellworks","ShellworksRoofMonitor","HoneyFrame",-28,38,-177,36,14,12,"honey")
unit("Shellworks","ShellworksEastTower","HallBay",96,-10,-166,40,64,40,"cream",nil,180)
unit("Shellworks","ShellworksEastCrown","HallCrown",96,54,-166,42,12,42,"coral",nil,180)
foundation("Shellworks","ShellworksWestFoundation",-144,-170,30,36,-16)
foundation("Shellworks","ShellworksEastFoundation",96,-166,40,40,-10)
lowland("Shellworks","WorkshopRearBank",-35,-189,246,68,-46)

-- The inner hall is separated from every route by an open moat; it never fills jump gaps.
unit("Incubation","CentralIncubationHall","HallBay",-4,-36,6,76,32,68,"cream","Landmark")
unit("Incubation","CentralHallCornice","HallCrown",-4,-4,6,78,4,70,"honey","Landmark")
unit("Incubation","MonumentalIncubator","IncubatorTank",-4,-18,-48,36,72,36,"mint","Landmark")
unit("Incubation","TankWestService","WorkshopBay",-41,-29,-50,28,28,30,"cream")
unit("Incubation","TankEastService","WorkshopBay",33,-29,-50,28,28,30,"cream")
foundation("Incubation","CentralHallFoundation",-4,6,76,68,-36)
foundation("Incubation","TankFoundation",-4,-48,38,38,-18)
foundation("Incubation","TankWestServiceFoundation",-41,-50,28,30,-29)
foundation("Incubation","TankEastServiceFoundation",33,-50,28,30,-29)
lowland("Incubation","CentralLowland",-4,-1,132,124,-48)

unit("Incubation","TrayServiceHall","HallBay",173,-10,-71,30,54,48,"cream",nil,90)
unit("Incubation","TrayServiceCrown","HallCrown",173,44,-71,32,10,50,"mint",nil,90)
unit("Incubation","TrayServiceNorth","WorkshopBay",121,-12,-119,36,40,32,"cream",nil,180)
unit("Incubation","TrayServiceNorthRoof","ShellRoof",121,28,-119,38,12,34,"coral",nil,180)
foundation("Incubation","TrayServiceFoundation",173,-71,48,30,-10)
foundation("Incubation","TrayNorthFoundation",121,-119,36,32,-12)
lowland("Incubation","TrayOuterBank",169,-101,64,104,-44)

-- Only the narrow new stem sits inside the already accepted roost rock footprint.
unit("Rookery","GuardianRoostStem","RookeryPlinth",91,-45,40,34,48,26,"rock","BelowCourseFoundation")
unit("Rookery","EasternRookeryHall","HallBay",205,-16,-5,38,54,64,"cream",nil,90)
unit("Rookery","RookeryHallCrown","HallCrown",205,38,-5,40,12,66,"coral",nil,90)
unit("Rookery","NorthRookeryWing","WorkshopBay",198,-18,-48,34,40,30,"cream",nil,90)
unit("Rookery","NorthRookeryRoof","ShellRoof",198,22,-48,36,12,32,"mint",nil,90)
unit("Rookery","RookeryGardenNorth","GardenCluster",214,-44,-12,28,18,28,"garden","DistantLandscape")
unit("Rookery","RookeryGardenEast","GardenCluster",220,-44,20,24,18,28,"garden","DistantLandscape")
unit("Rookery","RookeryGardenSouth","GardenCluster",48,-2,58,30,18,22,"garden","Landmark")
unit("Rookery","InnerGardenFoundation","TerraceBase",48,-64,58,30,62,22,"rock","BelowCourseFoundation")
foundation("Rookery","RookeryHallFoundation",205,-5,64,38,-16)
foundation("Rookery","RookeryWingFoundation",198,-48,30,34,-18)
lowland("Rookery","RookeryEastBank",208,8,86,112,-44)

unit("Return","ReturnNursery","HallBay",125,-16,221,72,72,38,"cream")
unit("Return","ReturnOuterAnnex","HallBay",203,-12,52,50,52,48,"cream",nil,90)
unit("Return","ReturnAnnexVault","ShellRoof",203,40,52,52,12,50,"coral",nil,90)
unit("Return","ShellReturnGate","ShellReturnArch",151,-18,155,30,54,14,"coral")
unit("Return","ReturnGardenSouth","GardenCluster",125,61,221,62,16,28,"garden","UnreachableArchitecture")
unit("Return","ReturnGardenEast","GardenCluster",152,4,118,34,20,34,"garden","UnreachableArchitecture")
unit("Return","GardenBankFoundation","TerraceBase",152,-58,118,46,62,48,"rock","BelowCourseFoundation")
block("Return","RoofGardenPlanter",125,56,221,72,5,36,"honey","UnreachableArchitecture")
block("Return","ReturnHallRearService",125,18,238.7,44,20,.5,"mint","UnreachableArchitecture")
foundation("Return","ReturnNurseryFoundation",125,221,72,38,-16)
foundation("Return","ReturnAnnexFoundation",203,52,48,50,-12)
foundation("Return","ShellReturnGateFoundation",151,155,30,14,-18)
lowland("Return","ReturnLowland",119,160,106,88,-44)

return Plan
