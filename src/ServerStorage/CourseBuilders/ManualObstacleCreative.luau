--!strict

return function(h)
    local V = Vector3.new
    local steel = Color3.fromRGB(46, 54, 65)
    local brass = Color3.fromRGB(231, 153, 55)
    local cream = Color3.fromRGB(230, 216, 183)
    local teal = Color3.fromRGB(55, 155, 157)
    local red = Color3.fromRGB(245, 43, 48)
    local function frame(m, z, height, width)
        for _, x in {-width/2, width/2} do
            h.block(m, "Support", V(1,height,1), V(x,1+height/2,z), steel)
        end
        h.block(m, "Crossbeam", V(width+1,1,1), V(0,height+1,z), brass)
    end
    local function ends(m, width)
        h.pad(m, "Entry", V(0,2.5,-14), V(width or 10,1,5))
        h.pad(m, "Exit", V(0,2.5,14), V(width or 10,1,5))
    end
    local function slider(m, name, size, position, axis, period, distance, phase)
        local p = h.movingTrap(m,name,size,position,"Slide",axis,period)
        p:SetAttribute("MotionDistance",distance)
        p:SetAttribute("MotionPhase",phase or 0)
        return p
    end
    return {
        {name="31_PistonPresses", title="31  PISTON PRESSES", difficulty="Timing", instructions="Watch the presses rise, then cross one bay at a time. MotionPhase offsets the three presses.", build=function(m)
            h.deck(m,V(12,1,32))
            for i=0,2 do
                local z=-9+i*9
                frame(m,z,13,13)
                slider(m,"Press_"..i,V(11,2.5,3),V(0,7,z),"Y",6,5,i*120)
            end
        end},
        {name="32_ClockworkCrossing", title="32  CLOCKWORK CROSSING", difficulty="Timing + balance", instructions="Stay on the four spokes and jump the rotating clock hands. The dark hub is a safe waiting island.", build=function(m)
            h.block(m,"DangerFloor",V(30,.5,30),V(0,-1,0),red,"Kill")
            h.pad(m,"NorthSouthSpoke",V(0,2.5,0),V(5,1,30))
            h.pad(m,"EastWestSpoke",V(0,2.5,0),V(30,1,5))
            h.block(m,"SafeHub",V(7,3,7),V(0,3.5,0),steel)
            h.movingTrap(m,"MinuteHand",V(28,.65,.65),V(0,3.7,0),"Spin","Y",12)
            local second=h.movingTrap(m,"HourHand",V(20,.65,.65),V(0,3.7,0),"Spin","Y",18)
            second.CFrame *= CFrame.Angles(0,math.pi/2,0)
            for _,x in {-13,13} do for _,z in {-13,13} do h.block(m,"ClockPillar",V(1,3,1),V(x,1,z),brass) end end
        end},
        {name="33_CargoShuttle", title="33  CARGO SHUTTLE", difficulty="Timing", instructions="Cross the cargo tracks between passing red loads. Raised teal islands provide waiting space between tracks.", build=function(m)
            h.deck(m,V(28,1,32))
            for i=0,2 do
                local z=-9+i*9
                h.block(m,"Track_"..i,V(28,.12,.6),V(0,1.06,z),steel)
                slider(m,"Cargo_"..i,V(6,5,4),V(0,3.5,z),"X",5+i,10,i*90)
            end
            for _,z in {-4.5,4.5} do h.pad(m,"WaitingIsland",V(0,1.3,z),V(8,.6,3)) end
        end},
        {name="34_RisingShutterVault", title="34  SHUTTER VAULT", difficulty="Timing", instructions="Pass underneath each rising shutter, using the middle chamber to wait. Opposite phases alternate the openings.", build=function(m)
            h.deck(m,V(12,1,32))
            for i,z in {-7,7} do
                frame(m,z,15,13)
                slider(m,"Shutter_"..i,V(12,7,1),V(0,9,z),"Y",7,4.5,(i-1)*180)
            end
            for _,x in {-6.5,6.5} do h.block(m,"ChamberRail",V(1,3,12),V(x,2.5,0),steel) end
        end},
        {name="35_SpiralChimney", title="35  SPIRAL CHIMNEY", difficulty="Climbing", instructions="Climb clockwise around the chimney. Move the whole set; each landing rises 1.8 studs. Do not fill the gaps with a broad floor.", build=function(m)
            h.block(m,"Chimney",V(5,18,5),V(0,9,0),steel)
            for i=0,7 do
                local angle=i*math.pi/2
                local p=h.pad(m,"Ledge_"..(i+1),V(math.sin(angle)*5.5,2.5+i*1.8,math.cos(angle)*5.5),V(6,1,4))
                p.CFrame *= CFrame.Angles(0,angle,0)
            end
            h.block(m,"ChimneyCap",V(6,1,6),V(0,18.5,0),brass)
        end},
        {name="36_CanalMooringHops", title="36  CANAL MOORINGS", difficulty="Precision", instructions="Hop between alternating round bollard caps over the red canal. Caps are safe; adjust their spacing to tune difficulty.", build=function(m)
            h.block(m,"CanalHazard",V(19,.6,32),V(0,-1,0),red,"Kill")
            ends(m,12)
            for i=0,3 do
                local x,z=if i%2==0 then -3 else 3,-9+i*6
                local post=h.block(m,"BollardStem_"..i,V(4,2,2),V(x,1,z),steel)
                post.Shape=Enum.PartType.Cylinder; post.CFrame *= CFrame.Angles(0,0,math.pi/2)
                local cap=h.pad(m,"BollardCap_"..i,V(x,3.25,z),V(.75,4.5,4.5))
                cap.Shape=Enum.PartType.Cylinder; cap.CFrame *= CFrame.Angles(0,0,math.pi/2)
            end
        end},
        {name="37_SwitchbackPipewalk", title="37  PIPEWALK", difficulty="Balance", instructions="Follow the narrow route around the pipe elbows. The cream end platforms are safe; do not add a floor under the route.", build=function(m)
            ends(m,8)
            h.block(m,"DangerFloor",V(22,.5,24),V(0,-1,0),red,"Kill")
            for i=0,2 do
                local z=-8+i*8
                h.pad(m,"CrossPipe_"..i,V(0,2.5,z),V(14,1.2,2.2))
                if i<2 then h.pad(m,"ReturnPipe_"..i,V(if i%2==0 then 6 else -6,2.5,z+4),V(2.2,1.2,8)) end
                for _,x in {-6,6} do h.block(m,"PipeJoint",V(2.8,1.5,2.8),V(x,2.5,z),brass) end
            end
        end},
        {name="38_CrumbleStairChoice", title="38  CHOOSE YOUR STAIRS", difficulty="Route choice", instructions="Left: six broad, slower-crumbling steps. Right: four smaller, faster steps. Both meet the raised exit; choose a route before jumping.", build=function(m)
            h.pad(m,"Entry",V(0,2.5,-14),V(16,1,5))
            h.pad(m,"Exit",V(0,10,14),V(16,1,5))
            for i=0,5 do
                local p=h.crumble(m,"WideStep_"..i,V(-4,3+i*1.2,-9+i*4),V(6,1,3.5))
                p:SetAttribute("CrumbleDelay",1.1)
            end
            for i=0,3 do
                local p=h.crumble(m,"ExpertStep_"..i,V(5,4+i*1.8,-8+i*6),V(3.5,1,3.5))
                p:SetAttribute("CrumbleDelay",.5)
            end
        end},
        {name="39_FallingPianoKeys", title="39  FALLING PIANO", difficulty="Keep moving", instructions="Run along the piano keys before they fall. Raised dark keys are safe resting spots. Orange keys reset after 2.5 seconds.", build=function(m)
            ends(m,10)
            for i=0,6 do h.crumble(m,"PianoKey_"..i,V(0,2.5,-9+i*3),V(10,1,2.7)) end
            for i,z in {-6,3,9} do h.block(m,"SafeBlackKey_"..i,V(3,1.2,1.5),V(if i%2==0 then 3 else -3,3.6,z),steel) end
        end},
        {name="40_RooftopSkylights", title="40  ROOFTOP SKYLIGHTS", difficulty="Precision + crumble", instructions="Jump between skylight panes. Brass frames are safe but narrow; orange glass collapses on contact. Place above a fall zone.", build=function(m)
            ends(m,10)
            for i=0,2 do
                local x,z=if i%2==0 then -3 else 3,-8+i*8
                h.crumble(m,"SkylightGlass_"..i,V(x,3+i*.75,z),V(5,1,4))
                for _,dx in {-3,3} do h.block(m,"SideFrame",V(.7,1.3,5),V(x+dx,3+i*.75,z),brass) end
                for _,dz in {-2.3,2.3} do h.block(m,"EndFrame",V(6.7,1.3,.7),V(x,3+i*.75,z+dz),brass) end
            end
        end},
        {name="41_KeyholeHops", title="41  KEYHOLE HOPS", difficulty="Jump accuracy", instructions="Jump through three offset framed openings. The lower red thresholds require a jump; overhead openings have standing clearance.", build=function(m)
            h.deck(m,V(20,1,34))
            for i=0,2 do
                local x,z=if i%2==0 then -3 else 3,-10+i*10
                for _,dx in {-4,4} do h.block(m,"ArchSide",V(1.5,11,1.5),V(x+dx,6.5,z),steel) end
                h.block(m,"ArchCrown",V(9.5,1.5,1.5),V(x,12,z),brass)
                h.block(m,"Threshold",V(6.5,1.2,1),V(x,1.6,z),red,"Kill")
            end
        end},
        {name="42_ScissorCrossing", title="42  SCISSOR CROSSING", difficulty="Timing", instructions="Time the opening between paired swinging blades. Wait outside the brass supports; red blades do not push your character.", build=function(m)
            h.deck(m,V(16,1,32))
            for i,z in {-7,7} do
                frame(m,z,12,17)
                for side,x in {-5.5,5.5} do
                    local blade=h.movingTrap(m,"Blade_"..i.."_"..side,V(1,16,1),V(x,7,z),"Swing","Z",8)
                    blade:SetAttribute("MotionAngle",35)
                    blade:SetAttribute("MotionPhase",if side==1 then 0 else 180)
                end
            end
        end},
    }
end
