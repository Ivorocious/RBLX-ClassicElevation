local fs,luau=require("@lune/fs"),require("@lune/luau")
local raw=fs.readFile("tools/moonlit-citadel/phase3/repair-20261019/art/CheckArtProposal.luau")
raw=raw:gsub("art/proposal01/proposed%-actual%-part%-bounds.json","art/proposal02/proposed-actual-part-bounds.json")
return luau.load(raw,{debugName="FocusedArtProposal02"})()
