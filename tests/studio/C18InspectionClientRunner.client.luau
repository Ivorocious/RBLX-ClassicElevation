--!strict
-- Studio-only manual command bridge for C18 inspection verification.
-- Set ReplicatedStorage attribute C18InspectionTest=true before this LocalScript starts.
-- Send JSON requests through PlayerGui.C18InspectionTestCommand.Value; read event log in Result.Value.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

if not RunService:IsStudio() or ReplicatedStorage:GetAttribute("C18InspectionTest") ~= true then return end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("RequestCityRunInspection") :: RemoteEvent
local state = remotes:WaitForChild("CityRunInspectionState") :: RemoteEvent

local command = Instance.new("StringValue")
command.Name = "C18InspectionTestCommand"
command.Parent = playerGui
local result = Instance.new("StringValue")
result.Name = "C18InspectionTestResult"
result.Value = "[]"
result.Parent = playerGui
local events: { any } = {}
local lastCommand = ""

local function log(kind: string, data: any)
    table.insert(events, { kind = kind, at = os.clock(), data = data })
    result.Value = HttpService:JSONEncode(events)
end

state.OnClientEvent:Connect(function(payload)
    log("State", payload)
end)

command:GetPropertyChangedSignal("Value"):Connect(function()
    local encoded = command.Value
    if encoded == "" or encoded == lastCommand then return end
    lastCommand = encoded
    local ok, payload = pcall(HttpService.JSONDecode, HttpService, encoded)
    if not ok or typeof(payload) ~= "table" then
        log("Error", "Command must be a JSON object")
        return
    end
    local action = payload.action
    if action ~= "State" and action ~= "UnlimitedTime" and action ~= "Switch" and action ~= "Jump" then
        log("Error", "Unsupported action")
        return
    end
    if action == "Switch" and payload.variant ~= "Original" and payload.variant ~= "Optimized" then
        log("Error", "Switch variant must be Original or Optimized")
        return
    end
    if action == "UnlimitedTime" and typeof(payload.enabled) ~= "boolean" then
        log("Error", "UnlimitedTime enabled must be boolean")
        return
    end
    if action == "Jump" and (typeof(payload.checkpointIndex) ~= "number" or payload.checkpointIndex % 1 ~= 0) then
        log("Error", "Jump checkpointIndex must be an integer")
        return
    end
    request:FireServer(payload)
    log("Request", payload)
end)

request:FireServer({ action = "State" })
log("Request", { action = "State" })
