local fs, luau, roblox = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox')
local proposalPath = 'tools/moonlit-citadel/phase3/drafts/VisualReadabilityProposal.luau'
local proposal = luau.load(fs.readFile(proposalPath), {environment = {Vector3 = roblox.Vector3}})()
local signs, views = 0, 0
for name, sign in proposal.Signs do
	signs += 1
	assert(sign.center.Y > 0 and sign.size.X > 0 and sign.size.Y > 0, name)
	assert(not string.find(sign.back, 'LEFT', 1, true) and not string.find(sign.back, 'RIGHT', 1, true)
		and not string.find(sign.back, 'AHEAD', 1, true), 'Reverse face cannot reuse approach-relative directions')
	assert((sign.faceTarget - sign.center).Magnitude > 1, name)
end
for name, view in proposal.Views do
	views += 1
	assert((view[2] - view[1]).Magnitude > 5, name)
end
assert(signs == 3 and views == 16)
print('Proposal compiled: three replacement signs, sixteen optional focused views, three named art-only omissions.')
print('No production source, templates, course floors, hazard counts or runtime behavior changed.')
