--!strict

return function(h)
	local V = Vector3.new
	local steel = Color3.fromRGB(46, 54, 65)
	local brass = Color3.fromRGB(231, 153, 55)
	local red = Color3.fromRGB(245, 43, 48)
	local cyan = Color3.fromRGB(98, 204, 229)
	local violet = Color3.fromRGB(167, 133, 235)
	local function decoration(m, name, size, position, color)
		local part = h.block(m, name, size, position, color)
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		return part
	end
	local function ends(m, width, height)
		h.pad(m, "Entry", V(0, 2.5, -17), V(width or 10, 1, 6))
		h.pad(m, "Exit", V(0, height or 2.5, 17), V(width or 10, 1, 6))
	end
	local function danger(m, width)
		h.block(m, "DangerFloor", V(width or 30, .5, 34), V(0, -2, 0), red, "Kill")
	end
	local function arch(m, name, z, width, height)
		for side, x in {-width / 2, width / 2} do
			h.block(m, name .. "Post" .. side, V(1, height, 1), V(x, height / 2, z), steel)
		end
		h.block(m, name .. "Crown", V(width + 1, 1, 1), V(0, height, z), brass)
	end
	local function hinge(m, name, size, position, pivot, axis, period, angle, phase)
		local part = h.movingTrap(m, name, size, position, if angle then "Swing" else "Spin", axis, period)
		part:SetAttribute("MotionPivotOffset", pivot - position)
		if angle then part:SetAttribute("MotionAngle", angle) end
		part:SetAttribute("MotionPhase", phase or 0)
		return part
	end
	local function hammer(m, name, z, height, phase)
		local head = hinge(m, name, V(4, 3, 2.5), V(0, height, z), V(0, height + 9, z), "Z", 7, 55, phase)
		local rod = decoration(m, name .. "Rod", V(.6, 9, .6), V(0, height + 4.5, z), brass)
		rod:SetAttribute("MotionFollows", head.Name)
		arch(m, name, z, 22, height + 9)
	end
	local function satellite(m, name, radius, height, period, phase)
		local ball = hinge(m, name, V(3, 3, 3), V(radius, height, 0), V(0, height, 0), "Y", period, nil, phase)
		ball.Shape = Enum.PartType.Ball
		decoration(m, name .. "Axle", V(1, 2, 1), V(0, height, 0), brass)
	end
	local function pulse(m, name, position, size, offset, period, solid)
		local part = h.block(m, name, size or V(7, 1, 5), position, cyan)
		part:SetAttribute("KitPhase", "Pulse")
		part:SetAttribute("PhasePeriod", period or 8)
		part:SetAttribute("PhaseSolidTime", solid or 5)
		part:SetAttribute("PhaseWarningTime", 1.2)
		part:SetAttribute("PhaseOffset", offset or 0)
		for side, x in {-part.Size.X / 2, part.Size.X / 2} do
			decoration(m, name .. "Outline" .. side, V(.14, .14, part.Size.Z), position + V(x, .55, 0), violet)
		end
		return part
	end
	local function landing(m, name, x, y, z, width, depth)
		return h.pad(m, name, V(x, y, z), V(width or 6, 1, depth or 5))
	end
	return {
		{name="43_HammerArcade", title="43  HAMMER ARCADE", category="Hinged machinery", difficulty="Timing", instructions="Cross three top-hinged hammers. Wait between arches; each hammer has a different starting phase. Brass rods are decoration.", build=function(m)
			h.deck(m, V(18, 1, 36))
			for i=0,2 do hammer(m, "Hammer_" .. i, -10+i*10, 4, i*120) end
			for _,z in {-15,-5,5,15} do landing(m,"WaitingBay",0,1.3,z,9,3) end
		end},
		{name="44_SatelliteCauseway", title="44  SATELLITE CAUSEWAY", category="Hinged machinery", difficulty="Orbit timing", instructions="Two red satellites circle the central hub. Cross their orbit along the narrow causeway; the raised middle island is permanent.", build=function(m)
			danger(m,30); ends(m,10)
			landing(m,"Causeway",0,2.5,0,5,29)
			landing(m,"SafeHub",0,4,0,8,8)
			satellite(m,"SatelliteA",10,4,11,0)
			satellite(m,"SatelliteB",10,4,11,180)
		end},
		{name="45_RotatingDoorway", title="45  ROTATING DOORWAY", category="Hinged machinery", difficulty="Opening timing", instructions="A rectangular red doorway rotates around its centre. Cross the opening when the low edge clears your body; the deck stays still.", build=function(m)
			h.deck(m,V(18,1,34)); arch(m,"Frame",2,19,17)
			local pivot=V(0,7,0)
			for i,y in {1,13} do hinge(m,"HorizontalEdge_"..i,V(13,1,1),V(0,y,0),pivot,"Z",12) end
			for i,x in {-6,6} do hinge(m,"VerticalEdge_"..i,V(1,11,1),V(x,7,0),pivot,"Z",12) end
		end},
		{name="46_CrescentSweep", title="46  CRESCENT SWEEP", category="Hinged machinery", difficulty="Balance + timing", instructions="Follow the crescent of broad stepping caps around the brass pivot. Jump the swinging radial arm; the end caps sit outside its main sweep.", build=function(m)
			danger(m,32)
			for i,angle in {-140,-100,-60,-20,20,60} do
				local a=math.rad(angle)
				local cap=landing(m,if i==1 then "Entry" elseif i==6 then "Exit" else "Cap_"..i,math.cos(a)*11,2.5,math.sin(a)*11,6,6)
				cap.Shape=Enum.PartType.Cylinder; cap.Size=V(1,6,6); cap.CFrame*=CFrame.Angles(0,0,math.pi/2)
			end
			h.block(m,"Pivot",V(2,3,2),V(0,1.5,0),brass)
			hinge(m,"CrescentArm",V(14,.7,.8),V(7,3.8,0),V(0,3.8,0),"Y",9,100)
		end},
		{name="47_FoldingFanGates", title="47  FOLDING FAN GATES", category="Hinged machinery", difficulty="Gate timing", instructions="Paired red doors fold around their outer hinges. Pass each bay when both leaves swing away; the middle bay gives room to wait.", build=function(m)
			h.deck(m,V(16,1,36))
			for i,z in {-8,8} do
				arch(m,"Gate_"..i,z,17,10)
				for side,x in {-4,4} do hinge(m,"Fan_"..i.."_"..side,V(8,7,1),V(x,4.5,z),V(x*2,4.5,z),"Y",9,85,if side==1 then (i-1)*90 else 180+(i-1)*90) end
			end
		end},
		{name="48_OrbitalJumpRope", title="48  ORBITAL JUMP ROPE", category="Hinged machinery", difficulty="Jump rhythm", instructions="The red rope circles an overhead axle instead of spinning on the floor. Jump it at the bottom of the circle, or cross while it is overhead.", build=function(m)
			h.deck(m,V(20,1,34)); arch(m,"RopeFrame",0,23,10)
			local rope=hinge(m,"Rope",V(20,.8,.8),V(0,2,0),V(0,10,0),"X",10)
			for i,x in {-10,10} do
				local arm=decoration(m,"RopeArm_"..i,V(.5,8,.5),V(x,6,0),brass)
				arm:SetAttribute("MotionFollows",rope.Name)
			end
		end},
		{name="49_PulseSteppingStones", title="49  PULSE STONES", category="Timed platforms", difficulty="Learn the warning", instructions="Cyan is solid, amber warns, and the purple ghost cannot hold you. Cross in two bursts, waiting on the permanent centre island.", build=function(m)
			danger(m,18); ends(m,10)
			landing(m,"PermanentIsland",0,2.5,0,9,5)
			for i,z in {-11,-5.5,5.5,11} do pulse(m,"Pulse_"..i,V(0,2.5,z),V(7,1,5),0,8,5) end
		end},
		{name="50_AlternatingArchipelago", title="50  ALTERNATING ISLES", category="Timed platforms", difficulty="Route choice", instructions="Left and right islands take turns disappearing. Pick the solid lane at the entry, or switch at the permanent middle island.", build=function(m)
			danger(m,26); ends(m,24)
			landing(m,"MiddleIsland",0,2.5,0,19,4)
			for side,x in {-6,6} do for i,z in {-11,-5.5,5.5,11} do pulse(m,"Lane_"..side.."_"..i,V(x,2.5,z),V(6,1,5),(side-1)*180,10,4) end end
		end},
		{name="51_HeartbeatCauseway", title="51  HEARTBEAT CAUSEWAY", category="Timed platforms", difficulty="Follow the wave", instructions="The warning travels down seven tiles. Follow the returning cyan tiles. Small permanent side bays let you pause halfway through.", build=function(m)
			danger(m,25); ends(m,10)
			for i=0,6 do pulse(m,"Beat_"..i,V(0,2.5,-10.5+i*3.5),V(9,1,3.1),(360-i*35)%360,8,5) end
			landing(m,"LeftRest",-7,2.5,-3.5,4,5); landing(m,"RightRest",7,2.5,3.5,4,5)
		end},
		{name="52_VanishingStaircase", title="52  VANISHING STAIRS", category="Timed platforms", difficulty="Climb with a rhythm", instructions="Six fading steps climb to a raised exit. Use the two permanent side balconies to wait for the next solid section.", build=function(m)
			danger(m,24); ends(m,10,12)
			for i=0,5 do pulse(m,"Step_"..i,V(0,3+i*1.5,-12+i*4.8),V(8,1,4.2),(360-i*35)%360,10,7) end
			landing(m,"RestA",7,6,-2.4,5,5); landing(m,"RestB",-7,9,7.2,5,5)
		end},
		{name="53_SwitchboardCrossing", title="53  SWITCHBOARD", category="Timed platforms", difficulty="Read the grid", instructions="Cross a three-by-three grid whose colours alternate. The raised centre square is always solid. Choose a side square before the warning ends.", build=function(m)
			danger(m,26); ends(m,10)
			for x=-1,1 do for z=-1,1 do
				if x==0 and z==0 then landing(m,"PermanentCentre",0,3.5,0,6,6)
				else pulse(m,"Square_"..x.."_"..z,V(x*7,2.5,z*7),V(6,1,6),if (x+z)%2==0 then 0 else 180,10,4) end
			end end
			landing(m,"EntryLink",0,2.5,-12,6,4); landing(m,"ExitLink",0,2.5,12,6,4)
		end},
		{name="54_GhostLattice", title="54  GHOST LATTICE", category="Timed platforms", difficulty="Balance + planning", instructions="Follow the fading zigzag beams. Every corner is a permanent waiting pad; check the next beam before leaving it.", build=function(m)
			danger(m,28)
			local points={V(-8,2.5,-12),V(8,2.5,-12),V(8,2.5,0),V(-8,2.5,0),V(-8,2.5,12),V(8,2.5,12)}
			for i,p in points do
				landing(m,"Corner_"..i,p.X,p.Y,p.Z,4.5,4.5)
				if i<#points then
					local q=points[i+1]; local alongX=math.abs(q.X-p.X)>1
					pulse(m,"Beam_"..i,(p+q)/2,if alongX then V(12,1,2.8) else V(2.8,1,8),(i-1)*60,9,6)
				end
			end
			landing(m,"Entry",-8,2.5,-17,7,5); landing(m,"Exit",8,2.5,17,7,5)
		end},
		{name="55_TwistedTrestles", title="55  TWISTED TRESTLES", category="Sculpted routes", difficulty="Sloped landings", instructions="Jump between five alternating tilted trestles. Their centres line up, but the high edge switches sides. Teal surfaces are safe.", build=function(m)
			danger(m,24); ends(m,12,4)
			for i=0,4 do
				local beam=landing(m,"Trestle_"..i,0,4,-12+i*6,17,3.8)
				beam.CFrame*=CFrame.Angles(0,0,math.rad(if i%2==0 then 17 else -17))
				for side,x in {-7,7} do decoration(m,"Brace_"..i.."_"..side,V(.7,5,.7),V(x,1,-12+i*6),steel) end
			end
		end},
		{name="56_BrokenAqueduct", title="56  BROKEN AQUEDUCT", category="Sculpted routes", difficulty="Curved ascent", instructions="Follow the broken aqueduct as it curves and climbs. Broad caps are the route; the lower arch braces are decorative and do not catch falls.", build=function(m)
			danger(m,34)
			local points={V(-10,2.5,-14),V(-10,4,-8),V(-7,5.5,-2),V(-2,7,3),V(4,8.5,7),V(9,10,12),V(9,10,17)}
			for i,p in points do
				landing(m,if i==1 then "Entry" elseif i==#points then "Exit" else "AqueductCap_"..i,p.X,p.Y,p.Z,7,5)
				h.block(m,"Pier_"..i,V(2,p.Y,2),V(p.X,p.Y/2-.5,p.Z),steel)
				if i<#points then
					local q=points[i+1]; local brace=decoration(m,"ArchBrace_"..i,V(.7,.7,(q-p).Magnitude),((p+q)/2)-V(0,2,0),brass)
					brace.CFrame=CFrame.lookAt(brace.Position,q-V(0,2,0))
				end
			end
		end},
		{name="57_OverUnderKnot", title="57  OVER UNDER KNOT", category="Sculpted routes", difficulty="Spatial climbing", instructions="Walk along the continuous lower underpass, then climb around the knot. Upper crossings leave standing headroom; save your jumps for the rising outer steps.", build=function(m)
			danger(m,32)
			local points={V(0,2.5,-17),V(0,2.5,-10),V(0,2.5,-3),V(0,2.5,4),V(7,4,5),V(11,5.5,0),V(7,7.5,-5),V(0,10.5,-5),V(-7,12,-5),V(-11,13.5,0),V(-7,15,5),V(0,16.5,5),V(0,16.5,11),V(0,16.5,17)}
			for i,p in points do
				local tile=landing(m,if i==1 then "Entry" elseif i==#points then "Exit" else "KnotStep_"..i,p.X,p.Y,p.Z,5.5,5.5)
				if i>7 then tile.Color=brass end
			end
			for i,z in {-6.5,.5} do landing(m,"UnderpassLink_"..i,0,2.5,z,5.5,7) end
		end},
		{name="58_CompassSpiral", title="58  COMPASS SPIRAL", category="Sculpted routes", difficulty="Turning ascent", instructions="Climb eight compass points around the red needle. Keep moving around the outside; the centre needle is a hazard, not a shortcut.", build=function(m)
			danger(m,32)
			h.block(m,"CompassNeedle",V(2,23,2),V(0,9.5,0),red,"Kill")
			for i=0,7 do
				local a=i*math.pi/4
				local p=landing(m,if i==0 then "Entry" elseif i==7 then "Exit" else "CompassPoint_"..i,math.sin(a)*10,2.5+i*1.5,-math.cos(a)*10,6,6)
				p.CFrame*=CFrame.Angles(0,-a,0)
				decoration(m,"CompassSpoke_"..i,V(.4,.25,8),V(math.sin(a)*5,-.5,-math.cos(a)*5),brass).CFrame=CFrame.new(math.sin(a)*5,-.5,-math.cos(a)*5)*CFrame.Angles(0,-a,0)
			end
		end},
		{name="59_CantileverCanyon", title="59  CANTILEVER CANYON", category="Sculpted routes", difficulty="Wall-to-wall jumps", instructions="Climb alternating ledges projecting from opposite canyon walls. Jump across the open middle. The walls keep the route enclosed without an overhead ceiling.", build=function(m)
			danger(m,24); ends(m,18,12)
			for side,x in {-11,11} do h.block(m,"CanyonWall_"..side,V(1,17,34),V(x,6.5,0),steel) end
			for i=0,5 do
				local x=if i%2==0 then -5.5 else 5.5
				landing(m,"Cantilever_"..i,x,3+i*1.5,-12+i*4.8,9,4.5)
				decoration(m,"Bracket_"..i,V(8,.6,1),V(x,1.5+i*1.5,-12+i*4.8),brass)
			end
		end},
		{name="60_SplitLevelBraid", title="60  SPLIT LEVEL BRAID", category="Sculpted routes", difficulty="Two routes", instructions="Choose an early climb over the crossing or the lower path with a late climb. The two routes cross at different heights and meet at the raised exit.", build=function(m)
			danger(m,30); ends(m,24,10)
			local upper={V(-7,5,-12),V(-6,8,-7),V(-3,11,-2),V(3,11,3),V(7,10,9),V(7,10,13)}
			local lower={V(7,2.5,-12),V(6,2.5,-7),V(3,2.5,-2),V(-3,2.5,3),V(-7,5,8),V(-7,8.5,13)}
			for lane,points in {upper,lower} do for i,p in points do
				local part=landing(m,"Braid_"..lane.."_"..i,p.X,p.Y,p.Z,6,5)
				if lane==1 then part.Color=brass end
			end end
		end},
		{name="61_HourglassCrossing", title="61  HOURGLASS CROSSING", category="Combined challenges", difficulty="Crumble + timing", instructions="Wide ends narrow into a permanent central island. Cross orange tiles before they fall, timing the two hinged sweepers from a safe end or the centre.", build=function(m)
			danger(m,28); ends(m,20)
			landing(m,"WaistIsland",0,6,0,7,5)
			for i,z in {-11,-5.5,5.5,11} do h.crumble(m,"HourglassTile_"..i,V(0,2.5,z),V(if math.abs(z)>8 then 15 else 8,1,5)) end
			for i,z in {-8,8} do hinge(m,"Sweep_"..i,V(14,.7,.8),V(0,3.8,z),V(if i==1 then -7 else 7,3.8,z),"Y",10,65,(i-1)*180) end
		end},
		{name="62_EclipseChamber", title="62  ECLIPSE CHAMBER", category="Combined challenges", difficulty="Orbit + fading route", instructions="Time both the satellite orbit and the fading bridge. The centre island stays solid; wait there for a clear orbit and cyan exit tiles.", build=function(m)
			danger(m,32); ends(m,10)
			landing(m,"EclipseIsland",0,4,0,8,7)
			for i,z in {-11,-5.5,5.5,11} do pulse(m,"EclipseTile_"..i,V(0,2.5,z),V(7,1,5),if z<0 then 0 else 180,10,5) end
			satellite(m,"EclipseOrb",10,4,13,90)
		end},
		{name="63_ShuffleVault", title="63  SHUFFLE VAULT", category="Combined challenges", difficulty="Lane changes", instructions="Three fading lanes lead past a sliding red shutter. Use the permanent crosswise waiting bays to change lanes before each crossing.", build=function(m)
			danger(m,30); ends(m,26)
			for lane,x in {-8,0,8} do for row,z in {-10,0,10} do pulse(m,"Shuffle_"..lane.."_"..row,V(x,2.5,z),V(6,1,5),(lane-1)*120,10,6) end end
			for i,z in {-5,5} do landing(m,"WaitingBay_"..i,0,2.5,z,24,4) end
			local gate=h.movingTrap(m,"ShufflingGate",V(5,7,1),V(0,6,0),"Slide","X",8)
			gate:SetAttribute("MotionDistance",10)
			arch(m,"Vault",0,28,11)
		end},
		{name="64_TidalLock", title="64  TIDAL LOCK", category="Combined challenges", difficulty="Two clocks", instructions="Fading approach pads lead into a permanent lock chamber. Wait inside for the rising red gate, then check the exit pads before jumping out.", build=function(m)
			danger(m,22); ends(m,12,3.5)
			h.deck(m,V(12,1,12))
			for i,z in {-11,11} do pulse(m,"LockApproach_"..i,V(0,3.5,z),V(10,1,6),(i-1)*180,11,7) end
			local gate=h.movingTrap(m,"TidalGate",V(12,7,1),V(0,8,0),"Slide","Y",9)
			gate:SetAttribute("MotionDistance",5)
			arch(m,"Lock",0,14,17)
		end},
		{name="65_DominoStairSprint", title="65  DOMINO STAIR SPRINT", category="Combined challenges", difficulty="Climb + keep moving", instructions="Climb wide orange domino steps before they collapse. The side balcony is permanent; wait there to read the top-hinged hammer before the last steps.", build=function(m)
			danger(m,30); ends(m,12,10)
			for i=0,5 do
				local tile=h.crumble(m,"Domino_"..i,V(0,3+i*1.2,-12+i*4.8),V(10,1,4.2))
				tile:SetAttribute("CrumbleDelay",.9)
				for mark=-1,1 do decoration(m,"DominoPip_"..i.."_"..mark,V(.55,.08,.55),V(mark*2,3.54+i*1.2,-12+i*4.8),steel) end
			end
			landing(m,"ReadingBalcony",8,6.6,0,5,5)
			hammer(m,"DominoHammer",7.2,9,90)
		end},
		{name="66_ClockworkGauntlet", title="66  CLOCKWORK GAUNTLET", category="Combined challenges", difficulty="Three linked rhythms", instructions="A short combined test: hinged entry sweep, fading middle pads, and crumbling exit. Pause on the permanent middle island to read the next rhythm.", build=function(m)
			danger(m,30); ends(m,12)
			landing(m,"EntryApron",0,2.5,-11,14,5)
			hinge(m,"EntrySweep",V(14,.7,.8),V(0,3.8,-10),V(-7,3.8,-10),"Y",9,65)
			pulse(m,"MiddlePulseA",V(0,2.5,-5.5),V(8,1,5),0,8,5)
			landing(m,"ReadingIsland",0,6,0,11,5)
			pulse(m,"MiddlePulseB",V(0,2.5,5.5),V(8,1,5),180,8,5)
			for i,z in {10,13.5} do h.crumble(m,"ExitTile_"..i,V(0,2.5,z),V(9,1,3)) end
		end},
	}
end
