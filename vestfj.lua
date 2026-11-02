-- dan_ffa_cheat.lua
-- UI: Linoria v2.0
-- Logic: Aimbot, Silent Aim, Triggerbot

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    AimEnabled = false,
    AimMode = "Mouse",
    TargetPart = "Head",
    AirTargetPart = "Head",
    Sensitivity = 1,
    Smoothing = 0.2,
    Prediction = 0.1,
    StickyTarget = false,
    DisableOnKill = false,
    SilentEnabled = false,
    TriggerbotEnabled = false,
    TriggerbotDelay = 0.05,
    VisualsEnabled = false
}

local CurrentTarget = nil
local LockedTarget = nil

-- Core Functions

local function getCharacter(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        return player.Character
    end
    return nil
end

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if player.Team == LocalPlayer.Team then return false end
    local char = getCharacter(player)
    if not char then return false end
    return true
end

local function getTarget()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    if Settings.StickyTarget and LockedTarget then
        if isValidTarget(LockedTarget) then
            return LockedTarget
        else
            LockedTarget = nil
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local char = player.Character
            local hum = char:FindFirstChild("Humanoid")
            local partName = Settings.TargetPart
            
            if hum and hum.FloorMaterial == Enum.Material.Air then
                partName = Settings.AirTargetPart
            end
            
            local targetPart = char:FindFirstChild(partName)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = {
                            player = player,
                            part = targetPart,
                            screenPos = Vector2.new(screenPos.X, screenPos.Y),
                            char = char,
                            hum = hum
                        }
                    end
                end
            end
        end
    end
    
    if Settings.StickyTarget and closest then
        LockedTarget = closest.player
    end
    
    return closest
end

local function getPredictedPosition(targetPart)
    if not targetPart then return Vector3.zero end
    local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero
    return targetPart.Position + (velocity * Settings.Prediction)
end

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if not Settings.AimEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    
    local target = getTarget()
    if not target then return end
    
    local aimPos = getPredictedPosition(target.part)
    
    if Settings.AimMode == "Mouse" then
        local screenPos = Camera:WorldToViewportPoint(aimPos)
        if screenPos.Z > 0 then
            local deltaX = screenPos.X - Mouse.X
            local deltaY = screenPos.Y - Mouse.Y
            local smoothFactor = 1 - Settings.Smoothing
            
            mousemoverel(deltaX * smoothFactor * Settings.Sensitivity, deltaY * smoothFactor * Settings.Sensitivity)
        end
    elseif Settings.AimMode == "Camera" then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos), Settings.Smoothing)
    end
end)

-- Silent Aim (Namecall)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if Settings.SilentEnabled and method == "FireServer" then
        local args = {...}
        local target = getTarget()
        
        if target then
            -- Generic remote hook. Adjust based on Dan FFA's remote names.
            -- Common Dan FFA combat remote: "Fire" or "WeaponFire"
            if self.Name == "Fire" or self.Name == "WeaponFire" or self.Name == "GunClient" then
                for i, v in pairs(args) do
                    if typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = target.part
                        break
                    elseif typeof(v) == "Vector3" then
                        args[i] = target.part.Position
                        break
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- Triggerbot
local lastTrigger = 0
RunService.Heartbeat:Connect(function()
    if not Settings.TriggerbotEnabled then return end
    if tick() - lastTrigger < Settings.TriggerbotDelay then return end
    
    local target = getTarget()
    if not target then return end
    
    local screenPos = Camera:WorldToViewportPoint(target.part.Position)
    if screenPos.Z > 0 then
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        
        if (mousePos - targetPos).Magnitude < 20 then
            mouse1click()
            lastTrigger = tick()
        end
    end
end)

-- UI Construction

local Window = Library:CreateWindow({
    Title = "Aimbot",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Aimbot = Window:AddTab("Aimbot"),
    Silent = Window:AddTab("Silent"),
    Triggerbot = Window:AddTab("Triggerbot"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings"),
    Configs = Window:AddTab("Configs")
}

-- Aimbot Tab
local AimbotGroup = Tabs.Aimbot:AddLeftGroupbox("Target selection and mouse assistance")

AimbotGroup:AddToggle("AimEnabled", {Text = "Enabled", Default = false}):OnChanged(function(Value)
    Settings.AimEnabled = Value
end)

AimbotGroup:AddDropdown("AimMode", {Values = {"Mouse", "Camera"}, Default = "Mouse", Text = "Aim Mode"}):OnChanged(function(Value)
    Settings.AimMode = Value
end)

AimbotGroup:AddDropdown("TargetPart", {Values = {"Head", "Torso", "HumanoidRootPart"}, Default = "Head", Text = "Target Part"}):OnChanged(function(Value)
    Settings.TargetPart = Value
end)

AimbotGroup:AddDropdown("AirTargetPart", {Values = {"Head", "Torso", "HumanoidRootPart"}, Default = "Head", Text = "Air Target Part"}):OnChanged(function(Value)
    Settings.AirTargetPart = Value
end)

AimbotGroup:AddSlider("Sensitivity", {Text = "Sensitivity", Min = 0, Max = 5, Default = 1, Rounding = 2}):OnChanged(function(Value)
    Settings.Sensitivity = Value
end)

AimbotGroup:AddSlider("Smoothing", {Text = "Smoothing", Min = 0, Max = 1, Default = 0.2, Rounding = 2}):OnChanged(function(Value)
    Settings.Smoothing = Value
end)

AimbotGroup:AddSlider("Prediction", {Text = "Prediction", Min = 0, Max = 1, Default = 0.1, Rounding = 2}):OnChanged(function(Value)
    Settings.Prediction = Value
end)

AimbotGroup:AddToggle("StickyTarget", {Text = "Sticky Target", Default = false}):OnChanged(function(Value)
    Settings.StickyTarget = Value
end)

AimbotGroup:AddToggle("DisableOnKill", {Text = "Disable On Kill", Default = false}):OnChanged(function(Value)
    Settings.DisableOnKill = Value
end)

-- Silent Tab
local SilentGroup = Tabs.Silent:AddLeftGroupbox("Silent Aim")

SilentGroup:AddToggle("SilentEnabled", {Text = "Enabled", Default = false}):OnChanged(function(Value)
    Settings.SilentEnabled = Value
end)

-- Triggerbot Tab
local TriggerGroup = Tabs.Triggerbot:AddLeftGroupbox("Triggerbot")

TriggerGroup:AddToggle("TriggerbotEnabled", {Text = "Enabled", Default = false}):OnChanged(function(Value)
    Settings.TriggerbotEnabled = Value
end)

TriggerGroup:AddSlider("TriggerbotDelay", {Text = "Delay", Min = 0, Max = 0.5, Default = 0.05, Rounding = 2, Suffix = "s"}):OnChanged(function(Value)
    Settings.TriggerbotDelay = Value
end)

-- Visuals Tab
local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

VisualsGroup:AddToggle("VisualsEnabled", {Text = "Enabled", Default = false}):OnChanged(function(Value)
    Settings.VisualsEnabled = Value
end)

-- Handle kill event for DisableOnKill
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Died:Connect(function()
        if Settings.DisableOnKill then
            Settings.AimEnabled = false
            Settings.SilentEnabled = false
            Settings.TriggerbotEnabled = false
            Toggles.AimEnabled:SetValue(false)
            Toggles.SilentEnabled:SetValue(false)
            Toggles.TriggerbotEnabled:SetValue(false)
        end
    end)
end)

-- Configs
Tabs.Configs:AddLeftGroupbox("Config"):AddButton("Save", function()
    SaveManager:Save("DanFFA_Config")
end)

Tabs.Configs:AddLeftGroupbox("Config"):AddButton("Load", function()
    SaveManager:Load("DanFFA_Config")
end)
