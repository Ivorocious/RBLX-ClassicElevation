--!nonstrict
local v = Vector3.new
return {
	MC_TL_GrandPinnacle = {parts=3, triangles=284, center=v(0,56,0), size=v(24,112,20), occupied={
		{low=v(-12,0,-10), high=v(12,8,10)},
		{low=v(-10,8,-8), high=v(10,46,8.04)},
		{low=v(-11.5,46,-9), high=v(11.5,50,9)},
		{low=v(-8,50,-7), high=v(8,70,7.04)},
		{low=v(-9,70,-8), high=v(9,103,8)},
		{low=v(-1.5,103,-1.5), high=v(1.5,112,1.5)},
	}},
	MC_TL_FlankPinnacle = {parts=3, triangles=180, center=v(0,31,0), size=v(12,62,12), occupied={
		{low=v(-6,0,-6), high=v(6,4,6)},
		{low=v(-5,4,-5), high=v(5,32,5.04)},
		{low=v(-6,32,-6), high=v(6,59,6)},
		{low=v(-.35,59,-.35), high=v(.35,62,.35)},
	}},
	MC_TL_SteppedButtress = {parts=3, triangles=96, center=v(0,78,6), size=v(8,156,12), occupied={
		{low=v(-4,0,0), high=v(4,26,12)},
		{low=v(-4,26,0), high=v(4,33,12)},
		{low=v(-3,33,0), high=v(3,116,8)},
		{low=v(-3,116,0), high=v(3,126,8)},
		{low=v(-2.3,126,0), high=v(2.3,156,5)},
	}},
}
