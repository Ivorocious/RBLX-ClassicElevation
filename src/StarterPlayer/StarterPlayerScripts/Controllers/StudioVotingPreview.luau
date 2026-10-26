--!strict
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Artwork = require(ReplicatedStorage.Config.VotingArtwork)
local View = require(script.Parent.GalleryVotingView)
local Preview = {}
local screen: ScreenGui? = nil
local ui: any = nil
local state: any = {phase="Voting",catalog={},picks={},search="",timeLeft=42,duration=45,confirmed=false}
local warming = false

function Preview.Preload()
    if warming or not RunService:IsStudio() or not RunService:IsClient() then return end
    warming = true
    task.spawn(function()
        local images = {Artwork.Clock,Artwork.SelectionBadge}
        for _,map in ipairs(Artwork.Reference) do table.insert(images,Artwork.Image(map.id)) end
        pcall(function() ContentProvider:PreloadAsync(images) end)
    end)
end

local function render()
    if ui and screen then
        screen:SetAttribute("LocalConfirmation",state.confirmed)
        View.Render(ui,state)
    end
end

function Preview.Close()
    if screen then
        screen.Enabled = false
    end
end

function Preview.Open(_maps: any): boolean
    if not RunService:IsStudio() or not RunService:IsClient() then return false end
    local catalog = {}
    -- Sample maps are presentation fixtures, never entries in the server's course catalog.
    for _,map in ipairs(Artwork.Reference) do
        table.insert(catalog,{id=map.id,name=map.name,image=Artwork.Image(map.id),placeholder=true})
    end
    state.catalog = catalog
    if not screen then
        local gui = Instance.new("ScreenGui")
        gui.Name,gui.ResetOnSpawn,gui.DisplayOrder = "StudioVotingPreview",false,110
        gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui:SetAttribute("PreviewOnly",true)
        gui:SetAttribute("SampleMapCount",#catalog)
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        screen = gui
        ui = View.Create(gui,{
            Hide=Preview.Close,
            Search=function(query: string) state.search=query; render() end,
            Select=function(id: string)
                -- One opening course, like the live ballot.
                state.picks = if state.picks[1] == id then {} else {id}
                state.confirmed = false
                render()
            end,
            Remove=function(id: string)
                local index = table.find(state.picks,id)
                if index then table.remove(state.picks,index); state.confirmed=false; render() end
            end,
            Confirm=function()
                if #state.picks ~= 1 then return end
                state.confirmed = true
                render()
            end,
        })
        gui.Destroying:Connect(function() screen,ui=nil,nil end)
    end
    (screen :: ScreenGui).Enabled = true
    render()
    return true
end

return Preview
