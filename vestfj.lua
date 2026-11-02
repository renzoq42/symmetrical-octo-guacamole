-- dan_ffa_cheat.lua
-- Requires Rayfield UI (https://sirius.menu/rayfield)
-- Loadstring environment: Roblox Executor

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CheatSettings = {
    AimEnabled = false,
    SilentEnabled = false,
    TriggerbotEnabled = false,
    AimMode = "Mouse", -- Mouse, Camera
    TargetPart = "Head",
    AirTargetPart = "Head",
    Sensitivity = 0.5,
    Smoothing = 0.2,
    Prediction = 0.1,
    StickyTarget = false,
    DisableOnKill = false
}

-- Core Logic

local function getTarget()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            if char then
                local partName = char.Humanoid and char.Humanoid.FloorMaterial == Enum.Material.Air and CheatSettings.AirTargetPart or CheatSettings.TargetPart
                local targetPart = char:FindFirstChild(partName)
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closest = {part = targetPart, pos = screenPos, char = char}
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function prediction(targetPart, velocity)
    if not targetPart or not velocity then return targetPart.Position end
    return targetPart.Position + (velocity * CheatSettings.Prediction)
end

-- Aimbot (Mouse/Camera)
RunService.RenderStepped:Connect(function()
    if not CheatSettings.AimEnabled then return end
    if not game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    
    local target = getTarget()
    if target then
        local aimPos = prediction(target.part, target.part.Velocity)
        
        if CheatSettings.AimMode == "Mouse" then
            local screenPos = Camera:WorldToViewportPoint(aimPos)
            local deltaX = screenPos.X - Mouse.X
            local deltaY = screenPos.Y - Mouse.Y
            
            -- Apply smoothing and sensitivity
            local smoothFactor = 1 - CheatSettings.Smoothing
            mousemoverel(deltaX * smoothFactor * CheatSettings.Sensitivity, deltaY * smoothFactor * CheatSettings.Sensitivity)
            
        elseif CheatSettings.AimMode == "Camera" then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos), CheatSettings.Smoothing)
        end
    end
end)

-- Silent Aim (Namecall Hook)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if CheatSettings.SilentEnabled and method == "FireServer" and self.Name == "Fire" or self.Name == "GunClient" then -- Adjust for Dan FFA remote
        local args = {...}
        local target = getTarget()
        if target then
            -- Overwrite hit part argument (Depends on remote structure)
            -- Typically args[1] is hit part, args[2] is position
            if type(args[1]) == "Instance" then
                args[1] = target.part
            elseif type(args[1]) == "Vector3" then
                args[1] = prediction(target.part, target.part.Velocity)
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if not CheatSettings.TriggerbotEnabled then return end
    local target = getTarget()
    if target then
        local screenPos = Camera:WorldToViewportPoint(target.part.Position)
        if screenPos.Z > 0 then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            if (mousePos - targetPos).Magnitude < 15 then
                -- Simulate click
                mouse1click()
            end
        end
    end
end)

-- UI Implementation
local Window = Rayfield:CreateWindow({
    Name = "Aimbot",
    LoadingTitle = "Aimbot",
    LoadingSubtitle = "Target selection and mouse assistance",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DanFFA",
        FileName = "Config"
    }
})

local MainTab = Window:CreateTab("Aimbot", nil)
local VisualsTab = Window:CreateTab("Visuals", nil)
local SettingsTab = Window:CreateTab("Settings", nil)
local ConfigTab = Window:CreateTab("Configs", nil)

-- Main Tab
MainTab:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "AimEnabled",
    Callback = function(Value) CheatSettings.AimEnabled = Value end,
})

MainTab:CreateDropdown({
    Name = "Aim Mode",
    Options = {"Mouse", "Camera"},
    CurrentOption = {"Mouse"},
    Flag = "AimMode",
    Callback = function(Option) CheatSettings.AimMode = Option[1] end,
})

MainTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    Flag = "TargetPart",
    Callback = function(Option) CheatSettings.TargetPart = Option[1] end,
})

MainTab:CreateDropdown({
    Name = "Air Target Part",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    Flag = "AirTargetPart",
    Callback = function(Option) CheatSettings.AirTargetPart = Option[1] end,
})

MainTab:CreateSlider({
    Name = "Sensitivity",
    Range = {0, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 0.5,
    Flag = "Sensitivity",
    Callback = function(Value) CheatSettings.Sensitivity = Value end,
})

MainTab:CreateSlider({
    Name = "Smoothing",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.2,
    Flag = "Smoothing",
    Callback = function(Value) CheatSettings.Smoothing = Value end,
})

MainTab:CreateSlider({
    Name = "Prediction",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.1,
    Flag = "Prediction",
    Callback = function(Value) CheatSettings.Prediction = Value end,
})

MainTab:CreateToggle({
    Name = "Sticky Target",
    CurrentValue = false,
    Flag = "StickyTarget",
    Callback = function(Value) CheatSettings.StickyTarget = Value end,
})

MainTab:CreateToggle({
    Name = "Disable On Kill",
    CurrentValue = false,
    Flag = "DisableOnKill",
    Callback = function(Value) CheatSettings.DisableOnKill = Value end,
})

-- Silent Aim Tab
local SilentTab = Window:CreateTab("Silent", nil)
SilentTab:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "SilentEnabled",
    Callback = function(Value) CheatSettings.SilentEnabled = Value end,
})

-- Triggerbot Tab
local TriggerTab = Window:CreateTab("Triggerbot", nil)
TriggerTab:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "TriggerbotEnabled",
    Callback = function(Value) CheatSettings.TriggerbotEnabled = Value end,
})
