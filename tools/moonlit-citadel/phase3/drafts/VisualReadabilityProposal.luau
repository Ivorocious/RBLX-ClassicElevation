--!nonstrict
-- Course-local art and inspection data only; the lead integrates this into a fresh candidate.
local v = Vector3.new

return {
	OmitArchSupports = {
		ArchNormal_ArchSupport_3 = true,
		ArchNormal_ArchSupport_5 = true,
		ArchNormal_ArchSupport_9 = true,
	},
	Signs = {
		E1_StoneArch = {
			center = v(-146, 32.4, -127), faceTarget = v(-149, 32.4, -108), size = v(11, 3.4, .15),
			front = '<font color="#F2E19B">NORMAL: LEFT · WEST ARCADES</font>\n'
				.. '<font color="#CDA7F4">EXPERT: RIGHT · RISING RAILS</font>',
			back = '<font color="#F2E19B">NORMAL · WEST ARCADES</font>\n'
				.. '<font color="#CDA7F4">EXPERT · RISING RAILS</font>',
		},
		E2_Lantern = {
			center = v(-24, 56.4, 114.5), faceTarget = v(-50, 56.4, 108), size = v(11, 3.4, .15),
			front = '<font color="#F2E19B">NORMAL: LEFT · WIDE GALLERY</font>\n'
				.. '<font color="#CDA7F4">EXPERT: AHEAD · NARROW RAILS</font>',
			back = '<font color="#F2E19B">NORMAL · WIDE GALLERY</font>\n'
				.. '<font color="#CDA7F4">EXPERT · NARROW RAILS</font>',
		},
		E3_UpperLift = {
			center = v(112, 110.4, -94.55), faceTarget = v(112, 110.4, -83), size = v(12, 3.4, .15),
			front = '<font color="#F2E19B">NORMAL: RIGHT · EAST GALLERY</font>\n'
				.. '<font color="#CDA7F4">EXPERT: BOTH SIDES · STEPS</font>',
			back = '<font color="#F2E19B">NORMAL · EAST GALLERY</font>\n'
				.. '<font color="#CDA7F4">EXPERT · SIDE STEPS</font>',
		},
	},
	Views = {
		E1Arrival = {v(-161, 35, -91), v(-144, 29.5, -112)},
		E1NormalFork = {v(-141, 35, -107), v(-177, 29.5, -142)},
		E1ExpertFork = {v(-147, 35, -111), v(-129, 30.5, -99)},
		E1ExpertLanding = {v(-130, 35, -122), v(-129, 33, -91)},
		E1ExpertReverse = {v(-120, 43, -77), v(-129, 33, -103)},
		E2Arrival = {v(-44, 59, 122), v(-39, 54, 100)},
		E2Fork = {v(-56, 59, 108), v(-24, 54, 102)},
		E2ExpertLanding = {v(-44, 59, 104), v(-16, 55, 104)},
		E2NormalLanding = {v(-44, 59, 96), v(-44, 53, 66)},
		E2Reverse = {v(-18, 61, 102), v(-47, 54, 108)},
		E3Bay1Arrival = {v(103, 113, -72), v(117, 109, -85)},
		E3Bay2Arrival = {v(121, 113, -72), v(136, 109, -81)},
		E3NormalCommit = {v(124, 113, -87), v(142, 108, -68)},
		E3ExpertRightLanding = {v(129, 113, -80), v(146, 115, -87)},
		E3ExpertLeftLanding = {v(95, 113, -80), v(78, 115, -87)},
		E3Reverse = {v(141, 118, -78), v(117, 109, -86)},
	},
}
