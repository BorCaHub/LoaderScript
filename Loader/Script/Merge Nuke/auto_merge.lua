--[[
    BorcaHub // Merge Nuke - Auto Merge
    Automatically merges nukes when they are ready
]]

local AutoMerge = {
    Enabled = false,
    Loop = nil,
    MergeDelay = 0.5,
    MergedCount = 0
}

local _plr = game:GetService("Players").LocalPlayer
local _rs = game:GetService("RunService")

-- Find mergeable nukes
local function findMergeableNukes()
    local mergeable = {}
    
    -- Try to find nuke objects in workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("nuke") or obj.Name:lower():find("merge") then
            -- Check if it's mergeable (has merge button or similar)
            if obj:FindFirstChild("Merge") or obj:FindFirstChild("MergeButton") or obj:FindFirstChild("ClickDetector") then
                table.insert(mergeable, obj)
            end
        end
    end
    
    return mergeable
end

-- Merge a nuke
local function mergeNuke(nuke)
    pcall(function()
        -- Try different methods to trigger merge
        if nuke:FindFirstChild("Merge") and nuke.Merge:IsA("ClickDetector") then
            fireclickdetector(nuke.Merge)
        elseif nuke:FindFirstChild("MergeButton") and nuke.MergeButton:IsA("GuiButton") then
            nuke.MergeButton:Click()
        elseif nuke:FindFirstChild("ClickDetector") then
            fireclickdetector(nuke.ClickDetector)
        elseif nuke:IsA("ClickDetector") then
            fireclickdetector(nuke)
        elseif nuke:IsA("GuiButton") then
            nuke:Click()
        end
    end)
end

-- Main auto merge loop
function AutoMerge.Start()
    if AutoMerge.Enabled then
        warn("[BorcaHub] Auto Merge already running!")
        return false
    end
    
    AutoMerge.Enabled = true
    AutoMerge.MergedCount = 0
    
    warn("[BorcaHub] Auto Merge started!")
    
    AutoMerge.Loop = _rs.Heartbeat:Connect(function()
        if not AutoMerge.Enabled then
            return
        end
        
        local nukes = findMergeableNukes()
        
        for _, nuke in ipairs(nukes) do
            if AutoMerge.Enabled then
                mergeNuke(nuke)
                AutoMerge.MergedCount = AutoMerge.MergedCount + 1
                task.wait(AutoMerge.MergeDelay)
            end
        end
    end)
    
    return true
end

function AutoMerge.Stop()
    if not AutoMerge.Enabled then
        return false
    end
    
    AutoMerge.Enabled = false
    
    if AutoMerge.Loop then
        AutoMerge.Loop:Disconnect()
        AutoMerge.Loop = nil
    end
    
    warn("[BorcaHub] Auto Merge stopped! Total merged: " .. AutoMerge.MergedCount)
    return true
end

function AutoMerge.GetInfo()
    return {
        Enabled = AutoMerge.Enabled,
        MergedCount = AutoMerge.MergedCount,
        MergeDelay = AutoMerge.MergeDelay
    }
end

function AutoMerge.SetDelay(delay)
    AutoMerge.MergeDelay = delay or 0.5
end

return AutoMerge
