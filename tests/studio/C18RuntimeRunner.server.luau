--!strict
-- Runs only when manually inserted as an ordinary Server Script for the Studio inspection source.
-- It never uses Workspace.RaceCourse; CityRunC18Runtime clones the immutable Optimized template.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if not RunService:IsStudio() then return end

local sources = ServerStorage:FindFirstChild("CityRunInspectionSources")
if sources == nil or not sources:IsA("Folder") or sources:GetAttribute("RunRuntimeAudit") ~= true then return end

local existingReport = ServerStorage:FindFirstChild("C18RuntimeTestResult")
local report: StringValue
if existingReport == nil then
    report = Instance.new("StringValue")
    report.Name = "C18RuntimeTestResult"
    report.Parent = ServerStorage
else
    assert(existingReport:IsA("StringValue"), "ServerStorage.C18RuntimeTestResult must be a StringValue")
    report = existingReport
end

local function writeResult(payload: { [string]: any })
    report.Value = HttpService:JSONEncode(payload)
end

local ok, result = xpcall(function()
    local player = Players:GetPlayers()[1]
    if player == nil then player = Players.PlayerAdded:Wait() end
    assert(player.Parent == Players, "Studio test player did not join")

    local optimized = sources:FindFirstChild("Optimized")
    assert(optimized and optimized:IsA("Model"), "Missing CityRunInspectionSources.Optimized")
    local template = optimized:FindFirstChild("RaceCourse")
    assert(template and template:IsA("Model"), "Missing immutable Optimized.RaceCourse template")

    local harness = ServerStorage:FindFirstChild("CityRunC18Runtime", true)
    if harness == nil then harness = script.Parent:FindFirstChild("CityRunC18Runtime") end
    assert(harness and harness:IsA("ModuleScript"), "Insert CityRunC18Runtime as a ModuleScript beside this runner or under ServerStorage")

    return require(harness).Run(template)
end, debug.traceback)

if ok then
    writeResult({ passed = true, result = result })
else
    writeResult({ passed = false, error = tostring(result) })
end