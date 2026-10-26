--!strict
local Players = game:GetService("Players")
local Progress = require(game:GetService("ReplicatedStorage").Shared.VisitProgress)
local Service = {}
local visits: {[number]: any} = {}
local started = false

local function get(player: Player): any
	local visit = visits[player.UserId]
	if not visit then visit = Progress.New(); visits[player.UserId] = visit end
	return visit
end

function Service.Init(_context: any) end
function Service.Start()
	if started then return end
	started = true
	Players.PlayerRemoving:Connect(function(player) visits[player.UserId] = nil end)
end
function Service.EnterRace(player: Player, raceId: string, courseInfo: any): boolean
	return Progress.Enter(get(player), raceId, courseInfo)
end
function Service.ResolveRace(player: Player, result: any, raceInfo: any): boolean
	if type(result) ~= "table" or result.userId ~= player.UserId then return false end
	return Progress.Resolve(get(player), result, raceInfo)
end
function Service.GetSnapshot(player: Player, courseInfo: any?): any
	return Progress.Snapshot(get(player), courseInfo)
end
function Service.GetTarget(player: Player, courseInfo: any): any
	return Progress.Target(get(player), courseInfo)
end
function Service.GetFinishTicket(player: Player, result: any, raceInfo: any): any
	if type(result) ~= "table" or result.userId ~= player.UserId or type(raceInfo) ~= "table" then return nil end
	Service.ResolveRace(player, result, raceInfo)
	return Progress.Ticket(get(player), raceInfo.raceId)
end
return Service
