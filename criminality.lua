local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    SilentAim = {
        Enabled = false,
        FOV = 150,
        HitChance = 100,
        TargetPart = "Head",
        WallCheck = true,
        TeamCheck = false,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
    },
    ESP = {
        Enabled = false,
        CornerBox = true,
        BoxOutline = true,
        Skeleton = true,
        HealthBar = true,
        Name = true,
        Distance = true,
        Tool = true,
        Tracer = true,
        TeamCheck = false,
        MaxDistance = 2000,
        BoxColor = Color3.fromRGB(255, 255, 255),
        SkeletonColor = Color3.fromRGB(200, 200, 200),
        TracerColor = Color3.fromRGB(255, 255, 255),
        NameColor = Color3.fromRGB(255, 255, 255),
        HealthBarColorLow = Color3.fromRGB(255, 0, 0),
        HealthBarColorHigh = Color3.fromRGB(0, 255, 0),
        DistanceColor = Color3.fromRGB(0, 255, 255),
        ToolColor = Color3.fromRGB(255, 255, 0),
        BoxThickness = 1.5,
        SkeletonThickness = 1,
        TracerThickness = 1.5,
        NameSize = 14,
        DistanceSize = 13,
        ToolSize = 13,
        TracerOrigin = "Bottom",
        ShowHealthText = false,
        ShowMaxHealth = false,
        HealthBarPosition = "Left",
        BoxFilled = false,
        BoxFillTransparency = 0.3,
        BoxFillColor = Color3.fromRGB(255, 255, 255),
    },
    Aimbot = {
        Enabled = false,
        Smoothness = 0.15,
        Prediction = 0.165,
        FOV = 200,
        TargetPart = "Head",
        WallCheck = true,
        TeamCheck = false,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
        Key = "MB2",
        Mode = "Hold",
        Active = false,
    },
    Speedhack = {
        Enabled = false,
        Speed = 80,
    },
    Spinbot = {
        Enabled = false,
        Speed = 30,
        AutoShoot = true,
    },
    MeleeAura = {
        Enabled = false,
        Range = 8,
    },
    DealerESP = {
        Enabled = false,
    },
    InstantReload = {
        Enabled = false,
    },
    InfiniteStamina = {
        Enabled = false,
    },
    FullBright = {
        Enabled = false,
    },
    ChatEnabler = {
        Enabled = false,
    },
    InstantEquip = {
        Enabled = false,
    },
    TriggerBot = {
        Enabled = false,
        TeamCheck = false,
        CheckDowned = true,
        CheckForceField = true,
        Key = "MB2",
        Method = "Hold",
        ClickMs = 100,
        Parts = { Head = true, HumanoidRootPart = true, LeftHand = false, RightHand = false, LeftLeg = false, RightLeg = false },
        FriendCheck = false,
        EnemyCheck = false,
        FriendList = {},
    },
    BulletTracer = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 0),
        Thickness = 1.5,
        Lifetime = 0.35,
    }
}

local ESPObjects = {}
local DealerESPObjects = {}
local Connections = {}
local SilentAimTarget = nil
local AimbotTarget = nil
local MeleeAuraConnection = nil
local InstantReloadConnection = nil
local InfiniteStaminaConnection = nil
local DealerESPConnection = nil
local FullBrightConnection = nil
local InstantEquipConnection = nil
local TriggerBotConnection = nil
local TriggerInputBegan = nil
local TriggerInputEnded = nil
local TriggerActiveState = false
local TriggerLastClick = 0
local BulletTracerConnection = nil
local OriginalLightingSettings = nil
local BulletTracerLines = {}

local function GetChar(p) return p and p.Character end
local function GetRoot(p)
    local c = GetChar(p)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function GetHum(p)
    local c = GetChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function IsAlive(p)
    local h = GetHum(p)
    return h and h.Health > 0
end
local function IsDowned(p)
    local c = GetChar(p)
    if not c then return false end
    local h = GetHum(p)
    if h and h.Health <= 15 then return true end
    local s = c:FindFirstChild("CharStats")
    if s then
        local d = s:FindFirstChild("Downed")
        if d and typeof(d.Value) == "boolean" then return d.Value end
    end
    return false
end
local function HasForceField(p)
    local c = GetChar(p)
    return c and c:FindFirstChildOfClass("ForceField") ~= nil
end
local function IsTeam(p) return p.Team == LocalPlayer.Team end

local function SaveLightingSettings()
    if OriginalLightingSettings then return end
    OriginalLightingSettings = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
end

local function SetFullBright(enabled)
    Settings.FullBright.Enabled = enabled
    if FullBrightConnection then
        FullBrightConnection:Disconnect()
        FullBrightConnection = nil
    end

    SaveLightingSettings()
    if enabled then
        FullBrightConnection = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.ClockTime = 12
            Lighting.ColorShift_Top = Color3.new(1, 1, 1)
            Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0
        end)
    else
        Lighting.Brightness = OriginalLightingSettings and OriginalLightingSettings.Brightness or Lighting.Brightness
        Lighting.Ambient = OriginalLightingSettings and OriginalLightingSettings.Ambient or Lighting.Ambient
        Lighting.OutdoorAmbient = OriginalLightingSettings and OriginalLightingSettings.OutdoorAmbient or Lighting.OutdoorAmbient
        Lighting.ClockTime = OriginalLightingSettings and OriginalLightingSettings.ClockTime or Lighting.ClockTime
        Lighting.ColorShift_Top = OriginalLightingSettings and OriginalLightingSettings.ColorShift_Top or Lighting.ColorShift_Top
        Lighting.ColorShift_Bottom = OriginalLightingSettings and OriginalLightingSettings.ColorShift_Bottom or Lighting.ColorShift_Bottom
        Lighting.GlobalShadows = OriginalLightingSettings and OriginalLightingSettings.GlobalShadows or Lighting.GlobalShadows
        Lighting.ExposureCompensation = OriginalLightingSettings and OriginalLightingSettings.ExposureCompensation or Lighting.ExposureCompensation
    end
end

local function SetChatEnabler(enabled)
    Settings.ChatEnabler.Enabled = enabled
    if enabled then
        pcall(function()
            TextChatService.ChatInputBarConfiguration.Enabled = true
            TextChatService.ChatInputBarConfiguration.Visible = true
        end)
    end
end

local function SetInstantEquip(enabled)
    Settings.InstantEquip.Enabled = enabled
    if InstantEquipConnection then
        InstantEquipConnection:Disconnect()
        InstantEquipConnection = nil
    end
    if enabled then
        InstantEquipConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if not hum or not backpack then return end

            if char:FindFirstChildOfClass("Tool") then return end
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function() hum:EquipTool(tool) end)
                    break
                end
            end
        end)
    end
end

local function SetTriggerBot(enabled)
    Settings.TriggerBot.Enabled = enabled
    if TriggerBotConnection then
        TriggerBotConnection:Disconnect()
        TriggerBotConnection = nil
    end
    if enabled then
        if TriggerInputBegan then TriggerInputBegan:Disconnect(); TriggerInputBegan = nil end
        if TriggerInputEnded then TriggerInputEnded:Disconnect(); TriggerInputEnded = nil end

        TriggerInputBegan = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if MatchesTriggerKey(input) then
                if Settings.TriggerBot.Method == "Hold" then
                    TriggerActiveState = true
                else
                    TriggerActiveState = not TriggerActiveState
                end
            end
            if Settings.TriggerBot.Method == "Click" and input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                TriggerLastClick = os.clock()
            end
        end)

        TriggerInputEnded = UserInputService.InputEnded:Connect(function(input)
            if MatchesTriggerKey(input) and Settings.TriggerBot.Method == "Hold" then
                TriggerActiveState = false
            end
        end)

        TriggerBotConnection = RunService.Heartbeat:Connect(function()
            if not Settings.TriggerBot.Enabled then return end
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end

            if Settings.TriggerBot.Method == "Hold" and not TriggerActiveState then return end

            local mousePos = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {char, Camera}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
            local hitPart = result and result.Instance
            if not hitPart then return end

            if not Settings.TriggerBot.Parts[hitPart.Name] then return end

            local model = hitPart and hitPart:FindFirstAncestorOfClass("Model")
            local targetPlayer = model and Players:GetPlayerFromCharacter(model)
            if not targetPlayer or targetPlayer == LocalPlayer then return end

            
            if Settings.TriggerBot.TeamCheck and IsTeam(targetPlayer) then return end
            if Settings.TriggerBot.FriendCheck then
                for _, name in ipairs(Settings.TriggerBot.FriendList or {}) do
                    if name and name ~= "" and string.lower(name) == string.lower(targetPlayer.Name) then
                        return
                    end
                end
            end
            if Settings.TriggerBot.EnemyCheck and IsTeam(targetPlayer) then return end

            if Settings.TriggerBot.CheckDowned and IsDowned(targetPlayer) then return end
            if Settings.TriggerBot.CheckForceField and HasForceField(targetPlayer) then return end
            if not IsAlive(targetPlayer) then return end

            -- click method respects ClickMs
            if Settings.TriggerBot.Method == "Click" then
                if os.clock() - TriggerLastClick < (Settings.TriggerBot.ClickMs or 100) / 1000 then return end
                TriggerLastClick = os.clock()
            end

            pcall(function() tool:Activate() end)
        end)
    end
end

local function SetBulletTracer(enabled)
    Settings.BulletTracer.Enabled = enabled
    if BulletTracerConnection then
        BulletTracerConnection:Disconnect()
        BulletTracerConnection = nil
    end

    if enabled then
        BulletTracerConnection = RunService.Heartbeat:Connect(function()
            if not Settings.BulletTracer.Enabled then return end
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end

            local mousePos = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local origin = Camera.CFrame.Position
            local endPos = origin + ray.Direction * 2000
            local line = Drawing.new("Line")
            line.From = Vector2.new(mousePos.X, mousePos.Y)
            line.To = Vector2.new(mousePos.X + 4, mousePos.Y + 4)
            line.Color = Settings.BulletTracer.Color
            line.Thickness = Settings.BulletTracer.Thickness
            line.Transparency = 1
            line.Visible = true
            table.insert(BulletTracerLines, {Line = line, Time = os.clock()})
        end)
    else
        for _, entry in ipairs(BulletTracerLines) do
            pcall(function() entry.Line:Remove() end)
        end
        BulletTracerLines = {}
    end
end

local function IsVisible(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local dir = targetPart.Position - origin
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local r = Workspace:Raycast(origin, dir, rp)
    if r then return r.Instance:IsDescendantOf(targetPart.Parent) end
    return true
end

local function GetDistance(pos)
    local r = GetRoot(LocalPlayer)
    if not r then return math.huge end
    return (pos - r.Position).Magnitude
end

local function GetClosestPlayer(cfg)
    local closest, shortest = nil, cfg.FOV or math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if cfg.TeamCheck and IsTeam(plr) then continue end
        if not IsAlive(plr) then continue end
        if cfg.CheckDowned and IsDowned(plr) then continue end
        if cfg.CheckForceField and HasForceField(plr) then continue end

        local part = GetChar(plr) and GetChar(plr):FindFirstChild(cfg.TargetPart)
        if not part then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d2 > shortest then continue end
        if cfg.WallCheck and not IsVisible(part) then continue end

        closest = plr
        shortest = d2
    end
    return closest
end

local function NewDrawing(t, props)
    local d = Drawing.new(t)
    for k, v in pairs(props or {}) do d[k] = v end
    return d
end

local function GetTool(character)
    local c = character or LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Tool")
end

local function FindValueByName(parent, names)
    if not parent then return nil end
    for _, name in ipairs(names or {}) do
        local child = parent:FindFirstChild(name)
        if child and child:IsA("ValueBase") then
            return child
        end
    end
    return nil
end

local function GetSkeletonPairs(char)
    if char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("LeftUpperArm")) then
        return {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        }
    end

    return {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Left Arm", "Left Leg"}, {"Right Arm", "Right Leg"},
    }
end

local function HideAllESP(data)
    for k, v in pairs(data) do
        if k == "Corner" or k == "CornerOutline" or k == "Skeleton" then
            for _, line in pairs(v) do line.Visible = false end
        elseif k == "BoxFill" then
            v.Visible = false
        else
            v.Visible = false
        end
    end
end

local function UpdateDealerESP(enabled)
    Settings.DealerESP.Enabled = enabled
    if not enabled then
        for _, highlight in pairs(DealerESPObjects) do
            pcall(function() highlight:Destroy() end)
        end
        DealerESPObjects = {}
        return
    end

    local seen = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(obj.Name)
        if name:find("dealer", 1, true) or name:find("shop", 1, true) or name:find("vendor", 1, true) then
            local target = obj:IsA("Model") and obj or obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if target then
                local highlight = DealerESPObjects[target]
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "DealerESP"
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = target.Parent or game.CoreGui
                    DealerESPObjects[target] = highlight
                end
                highlight.Adornee = target
                highlight.FillColor = Color3.fromRGB(255, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                highlight.Enabled = true
                seen[target] = true
            end
        end
    end

    for target, highlight in pairs(DealerESPObjects) do
        if not seen[target] then
            pcall(function() highlight:Destroy() end)
            DealerESPObjects[target] = nil
        end
    end
end

local function SetDealerESP(enabled)
    if DealerESPConnection then
        DealerESPConnection:Disconnect()
        DealerESPConnection = nil
    end
    if enabled then
        UpdateDealerESP(true)
        DealerESPConnection = RunService.RenderStepped:Connect(function()
            UpdateDealerESP(true)
        end)
    else
        UpdateDealerESP(false)
    end
end

local function SetMeleeAura(enabled)
    Settings.MeleeAura.Enabled = enabled
    if MeleeAuraConnection then
        MeleeAuraConnection:Disconnect()
        MeleeAuraConnection = nil
    end
    if enabled then
        MeleeAuraConnection = RunService.Heartbeat:Connect(function()
            local me = LocalPlayer.Character
            local root = me and me:FindFirstChild("HumanoidRootPart")
            local tool = GetTool(me)
            if not root or not tool then return end

            local toolName = string.lower(tool.Name)
            local isMelee = toolName:find("knife", 1, true) or toolName:find("bat", 1, true) or toolName:find("sword", 1, true) or toolName:find("axe", 1, true) or toolName:find("crowbar", 1, true) or toolName:find("machete", 1, true) or toolName:find("shiv", 1, true) or toolName:find("katana", 1, true) or toolName:find("shovel", 1, true)
            if not isMelee then return end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                local targetChar = GetChar(plr)
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if not targetRoot or not IsAlive(plr) then continue end
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist <= Settings.MeleeAura.Range then
                    pcall(function() tool:Activate() end)
                    break
                end
            end
        end)
    end
end

local function SetInstantReload(enabled)
    Settings.InstantReload.Enabled = enabled
    if InstantReloadConnection then
        InstantReloadConnection:Disconnect()
        InstantReloadConnection = nil
    end
    if enabled then
        InstantReloadConnection = RunService.Heartbeat:Connect(function()
            local tool = GetTool(LocalPlayer.Character)
            if not tool then return end
            local ammo = FindValueByName(tool, {"SERVER_StoredAmmo", "Ammo", "CurrentAmmo", "Clip", "AmmoValue", "AmmoCount"})
            if ammo then
                local maxAmmo = FindValueByName(tool, {"MaxAmmo", "MaxAmmoValue", "MaxAmmoCount", "AmmoMax", "Capacity", "ClipSize"})
                if maxAmmo then
                    ammo.Value = maxAmmo.Value
                else
                    ammo.Value = math.max(ammo.Value, 30)
                end
            end
        end)
    end
end

local function SetInfiniteStamina(enabled)
    Settings.InfiniteStamina.Enabled = enabled
    if InfiniteStaminaConnection then
        InfiniteStaminaConnection:Disconnect()
        InfiniteStaminaConnection = nil
    end
    if enabled then
        InfiniteStaminaConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local stats = char and char:FindFirstChild("CharStats")
            local stamina = FindValueByName(stats, {"Stamina", "Energy", "Sprint", "Fatigue"})
            if stamina then
                local maxStamina = FindValueByName(stats, {"MaxStamina", "MaxEnergy", "MaxSprint", "MaxFatigue"})
                if maxStamina then
                    stamina.Value = maxStamina.Value
                else
                    stamina.Value = 100
                end
            end
        end)
    end
end

local function InitESP()
    local conn = RunService.RenderStepped:Connect(function()
        if not Settings.ESP.Enabled then
            for _, data in pairs(ESPObjects) do
                HideAllESP(data)
            end
            return
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end

            local char = GetChar(plr)
            local root = GetRoot(plr)
            local hum = GetHum(plr)
            local head = char and char:FindFirstChild("Head")

            if not char or not root or not hum or hum.Health <= 0 then
                if ESPObjects[plr] then HideAllESP(ESPObjects[plr]) end
                continue
            end

            if Settings.ESP.TeamCheck and IsTeam(plr) then
                if ESPObjects[plr] then HideAllESP(ESPObjects[plr]) end
                continue
            end

            local dist = GetDistance(root.Position)
            if dist > Settings.ESP.MaxDistance then
                if ESPObjects[plr] then HideAllESP(ESPObjects[plr]) end
                continue
            end

            if not ESPObjects[plr] then
                ESPObjects[plr] = {
                    Corner = {},
                    CornerOutline = {},
                    BoxFill = NewDrawing("Square", {Filled = true, Transparency = Settings.ESP.BoxFillTransparency, Visible = false}),
                    HealthBar = NewDrawing("Line", {Thickness = 2, Visible = false}),
                    HealthBarOutline = NewDrawing("Line", {Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false}),
                    Name = NewDrawing("Text", {Size = Settings.ESP.NameSize, Center = true, Outline = true, Font = 2, Visible = false}),
                    Distance = NewDrawing("Text", {Size = Settings.ESP.DistanceSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.DistanceColor, Visible = false}),
                    Tool = NewDrawing("Text", {Size = Settings.ESP.ToolSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.ToolColor, Visible = false}),
                    Tracer = NewDrawing("Line", {Thickness = Settings.ESP.TracerThickness, Visible = false}),
                    Skeleton = {},
                }
                for i = 1, 8 do
                    ESPObjects[plr].Corner[i] = NewDrawing("Line", {Thickness = Settings.ESP.BoxThickness, Visible = false})
                    ESPObjects[plr].CornerOutline[i] = NewDrawing("Line", {Thickness = Settings.ESP.BoxThickness + 2, Color = Color3.new(0, 0, 0), Visible = false})
                end
                for i = 1, 20 do
                    ESPObjects[plr].Skeleton[i] = NewDrawing("Line", {Thickness = Settings.ESP.SkeletonThickness, Visible = false})
                end
            end

            local data = ESPObjects[plr]
            local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos, headVisible = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
            local legPos, legVisible = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

            if not onScreen or not headVisible or not legVisible or not headPos then
                HideAllESP(data)
                continue
            end

            local h = math.max(20, math.abs(legPos.Y - headPos.Y))
            local w = math.max(20, h / 2)
            local pos = Vector2.new(headPos.X - w / 2, headPos.Y)
            local color = Settings.ESP.BoxColor

            if Settings.ESP.CornerBox then
                local cs = math.min(w, h) * 0.25
                local c, co = data.Corner, data.CornerOutline
                local corners = {
                    {pos, pos + Vector2.new(cs, 0)},
                    {pos, pos + Vector2.new(0, cs)},
                    {pos + Vector2.new(w, 0), pos + Vector2.new(w - cs, 0)},
                    {pos + Vector2.new(w, 0), pos + Vector2.new(w, cs)},
                    {pos + Vector2.new(0, h), pos + Vector2.new(cs, h)},
                    {pos + Vector2.new(0, h), pos + Vector2.new(0, h - cs)},
                    {pos + Vector2.new(w, h), pos + Vector2.new(w - cs, h)},
                    {pos + Vector2.new(w, h), pos + Vector2.new(w, h - cs)},
                }
                for i = 1, 8 do
                    c[i].From = corners[i][1]; c[i].To = corners[i][2]; c[i].Color = color; c[i].Thickness = Settings.ESP.BoxThickness; c[i].Visible = true
                    co[i].From = corners[i][1]; co[i].To = corners[i][2]; co[i].Thickness = Settings.ESP.BoxThickness + 2; co[i].Visible = true
                end
            else
                for i = 1, 8 do data.Corner[i].Visible = false; data.CornerOutline[i].Visible = false end
            end

            if Settings.ESP.BoxFilled then
                data.BoxFill.Size = Vector2.new(w, h)
                data.BoxFill.Position = pos
                data.BoxFill.Color = Settings.ESP.BoxFillColor
                data.BoxFill.Transparency = Settings.ESP.BoxFillTransparency
                data.BoxFill.Visible = true
            else
                data.BoxFill.Visible = false
            end

            if Settings.ESP.HealthBar then
                local maxHealth = hum.MaxHealth > 0 and hum.MaxHealth or 100
                local hp = math.clamp(hum.Health / maxHealth, 0, 1)
                local bh = math.max(2, h * hp)
                local bx, by
                if Settings.ESP.HealthBarPosition == "Right" then
                    bx = pos.X + w + 6
                    by = pos.Y
                else
                    bx = pos.X - 8
                    by = pos.Y
                end
                data.HealthBarOutline.From = Vector2.new(bx, by)
                data.HealthBarOutline.To = Vector2.new(bx, by + h)
                data.HealthBarOutline.Visible = true
                data.HealthBar.From = Vector2.new(bx, by + h - bh)
                data.HealthBar.To = Vector2.new(bx, by + h)
                data.HealthBar.Color = Settings.ESP.HealthBarColorLow:Lerp(Settings.ESP.HealthBarColorHigh, hp)
                data.HealthBar.Visible = true
            else
                data.HealthBar.Visible = false; data.HealthBarOutline.Visible = false
            end

            if Settings.ESP.Name then
                local nameText = plr.Name
                if Settings.ESP.ShowHealthText then
                    if Settings.ESP.ShowMaxHealth then
                        nameText = string.format("%s [%s/%sHP]", plr.Name, math.floor(hum.Health), math.floor(hum.MaxHealth))
                    else
                        nameText = string.format("%s [%sHP]", plr.Name, math.floor(hum.Health))
                    end
                end
                data.Name.Text = nameText
                data.Name.Position = Vector2.new(pos.X + w / 2, pos.Y - 20)
                data.Name.Color = Settings.ESP.NameColor
                data.Name.Size = Settings.ESP.NameSize
                data.Name.Visible = true
            else
                data.Name.Visible = false
            end

            if Settings.ESP.Distance then
                data.Distance.Text = string.format("[%dm]", math.floor(dist))
                data.Distance.Position = Vector2.new(pos.X + w / 2, pos.Y + h + 2)
                data.Distance.Color = Settings.ESP.DistanceColor
                data.Distance.Size = Settings.ESP.DistanceSize
                data.Distance.Visible = true
            else
                data.Distance.Visible = false
            end

            if Settings.ESP.Tool then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    data.Tool.Text = string.format("[%s]", tool.Name)
                    data.Tool.Position = Vector2.new(pos.X + w / 2, pos.Y + h + 16)
                    data.Tool.Color = Settings.ESP.ToolColor
                    data.Tool.Size = Settings.ESP.ToolSize
                    data.Tool.Visible = true
                else
                    data.Tool.Visible = false
                end
            else
                data.Tool.Visible = false
            end

            if Settings.ESP.Tracer then
                local origin
                if Settings.ESP.TracerOrigin == "Bottom" then
                    origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Settings.ESP.TracerOrigin == "Top" then
                    origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
                elseif Settings.ESP.TracerOrigin == "Center" then
                    origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                elseif Settings.ESP.TracerOrigin == "Mouse" then
                    origin = UserInputService:GetMouseLocation()
                else
                    origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                end
                data.Tracer.From = origin
                data.Tracer.To = Vector2.new(sp.X, sp.Y)
                data.Tracer.Color = Settings.ESP.TracerColor
                data.Tracer.Thickness = Settings.ESP.TracerThickness
                data.Tracer.Visible = true
            else
                data.Tracer.Visible = false
            end

            if Settings.ESP.Skeleton then
                local map = GetSkeletonPairs(char)
                local idx = 1
                for _, pair in ipairs(map) do
                    local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                    local line = data.Skeleton[idx]
                    if line and p1 and p2 then
                        local s1, v1 = Camera:WorldToViewportPoint(p1.Position)
                        local s2, v2 = Camera:WorldToViewportPoint(p2.Position)
                        if v1 and v2 then
                            line.From = Vector2.new(s1.X, s1.Y)
                            line.To = Vector2.new(s2.X, s2.Y)
                            line.Color = Settings.ESP.SkeletonColor
                            line.Thickness = Settings.ESP.SkeletonThickness
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    elseif line then
                        line.Visible = false
                    end
                    idx += 1
                end
                for i = idx, #data.Skeleton do
                    if data.Skeleton[i] then data.Skeleton[i].Visible = false end
                end
            else
                for _, line in pairs(data.Skeleton) do line.Visible = false end
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if ESPObjects[plr] then
            local d = ESPObjects[plr]
            for k, v in pairs(d) do
                if k == "Corner" or k == "CornerOutline" or k == "Skeleton" then
                    for _, line in pairs(v) do pcall(function() line:Remove() end) end
                else
                    pcall(function() v:Remove() end)
                end
            end
            ESPObjects[plr] = nil
        end
    end)

    table.insert(Connections, conn)
end

local function InitSilentAim()
    local fovCircle = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Transparency = 1, Visible = false, Color = Color3.fromRGB(255, 255, 255), NumSides = 64})
    Settings.SilentAim.FOVCircle = fovCircle

    local loop = RunService.Heartbeat:Connect(function()
        if Settings.SilentAim.Enabled then
            SilentAimTarget = GetClosestPlayer(Settings.SilentAim)
        else
            SilentAimTarget = nil
        end

        fovCircle.Visible = Settings.SilentAim.Enabled and Settings.SilentAim.ShowFOV
        if fovCircle.Visible then
            fovCircle.Radius = Settings.SilentAim.FOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end)
    table.insert(Connections, loop)

    local ok1, visEvent = pcall(function() return ReplicatedStorage:WaitForChild("Events2", 5):WaitForChild("Visualize", 5) end)
    local ok2, dmgEvent = pcall(function() return ReplicatedStorage:WaitForChild("Events", 5):WaitForChild("ZFKLF__H", 5) end)

    if ok1 and ok2 and visEvent and dmgEvent then
        local conn = visEvent.Event:Connect(function(_, shotCode, _, gun, _, startPos, bulletsPerShot)
            if not Settings.SilentAim.Enabled or not gun or not SilentAimTarget or not SilentAimTarget.Character then return end
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if not tool or gun ~= tool then return end
            if Settings.SilentAim.HitChance < 100 and math.random(1, 100) > Settings.SilentAim.HitChance then return end

            local part = SilentAimTarget.Character:FindFirstChild(Settings.SilentAim.TargetPart)
            if not part then return end

            local hitPos = part.Position
            local bullets = {}
            local count = type(bulletsPerShot) == "table" and #bulletsPerShot or 1
            for i = 1, math.clamp(count, 1, 100) do
                bullets[i] = CFrame.new(startPos, hitPos).LookVector
            end

            task.wait(0.005)
            for idx, dir in pairs(bullets) do
                pcall(function() dmgEvent:FireServer("🧈", gun, shotCode, idx, part, hitPos, dir) end)
            end

            pcall(function()
                if gun:FindFirstChild("Hitmarker") then gun.Hitmarker:Fire(part) end
            end)
        end)
        table.insert(Connections, conn)
    end
end

local function MatchesAimbotKey(input)
    local key = Settings.Aimbot.Key
    if type(key) ~= "string" then return false end
    local normalized = string.upper(key)

    if normalized == "MB1" or normalized == "MOUSEBUTTON1" then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    end
    if normalized == "MB2" or normalized == "MOUSEBUTTON2" then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end

    if input.KeyCode then
        return string.upper(input.KeyCode.Name) == normalized
    end

    return false
end

local function MatchesKey(input, key)
    if type(key) ~= "string" then return false end
    local normalized = string.upper(key)

    if normalized == "MB1" or normalized == "MOUSEBUTTON1" then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    end
    if normalized == "MB2" or normalized == "MOUSEBUTTON2" then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end

    if input.KeyCode then
        return string.upper(input.KeyCode.Name) == normalized
    end

    return false
end

local function MatchesTriggerKey(input)
    return MatchesKey(input, Settings.TriggerBot.Key)
end

local function InitAimbot()
    local fovCircle = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Transparency = 0.5, Visible = false, Color = Color3.fromRGB(255, 255, 255), NumSides = 64})
    Settings.Aimbot.FOVCircle = fovCircle

    local inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if MatchesAimbotKey(input) then
            if Settings.Aimbot.Mode == "Hold" then
                Settings.Aimbot.Active = true
            else
                Settings.Aimbot.Active = not Settings.Aimbot.Active
            end
        end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if Settings.Aimbot.Mode == "Hold" and MatchesAimbotKey(input) then
            Settings.Aimbot.Active = false
            AimbotTarget = nil
        end
    end)

    local loop = RunService.RenderStepped:Connect(function()
        fovCircle.Visible = Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV
        if fovCircle.Visible then
            fovCircle.Radius = Settings.Aimbot.FOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end

        if not Settings.Aimbot.Enabled or not Settings.Aimbot.Active then
            AimbotTarget = nil
            return
        end

        if not AimbotTarget or not AimbotTarget.Character or not IsAlive(AimbotTarget) or
           (Settings.Aimbot.CheckDowned and IsDowned(AimbotTarget)) or
           (Settings.Aimbot.CheckForceField and HasForceField(AimbotTarget)) then
            AimbotTarget = GetClosestPlayer(Settings.Aimbot)
        end

        if AimbotTarget and AimbotTarget.Character then
            local part = AimbotTarget.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            if part then
                local aimPos = part.Position
                local hrp = AimbotTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    aimPos = aimPos + (hrp.Velocity * Settings.Aimbot.Prediction)
                end

                local current = Camera.CFrame
                local target = CFrame.new(current.Position, aimPos)
                local smooth = math.clamp(Settings.Aimbot.Smoothness, 0.01, 1)
                Camera.CFrame = current:Lerp(target, smooth)
            end
        end
    end)

    table.insert(Connections, inputBegan)
    table.insert(Connections, inputEnded)
    table.insert(Connections, loop)
end

local SpeedConnection = nil
local function SetSpeedhack(enabled)
    Settings.Speedhack.Enabled = enabled
    if SpeedConnection then SpeedConnection:Disconnect(); SpeedConnection = nil end
    if enabled then
        SpeedConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end

            if dir.Magnitude > 0 then
                dir = Vector3.new(dir.X, 0, dir.Z).Unit
                root.Velocity = Vector3.new(
                    dir.X * Settings.Speedhack.Speed,
                    root.Velocity.Y,
                    dir.Z * Settings.Speedhack.Speed
                )
            end
        end)
    end
end

local SpinConnection = nil
local function SetSpinbot(enabled)
    Settings.Spinbot.Enabled = enabled
    if SpinConnection then SpinConnection:Disconnect(); SpinConnection = nil end
    if enabled then
        SpinConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)

            if Settings.Spinbot.AutoShoot and SilentAimTarget then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
            end
        end)
    end
end

local Window = WindUI:CreateWindow({
    Title = "Criminality Lite",
    Icon = "crosshair",
    Folder = "CriminalityLite",
    OpenButton = {
        Title = "Open Criminality Lite",
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#FF4757"), Color3.fromHex("#FF6B81")),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

local CombatSection = Window:Section({ Title = "Combat" })
local VisualSection = Window:Section({ Title = "Visual" })
local MiscSection = Window:Section({ Title = "Misc" })
local SettingsSection = Window:Section({ Title = "Settings" })

local CombatTab = CombatSection:Tab({
    Title = "Combat",
    Icon = "sword",
    IconColor = Color3.fromHex("#FF4757"),
})

CombatTab:Toggle({
    Flag = "SilentAimToggle",
    Title = "Silent Aim",
    Desc = "Redirects bullets to target",
    Default = false,
    Callback = function(v)
        Settings.SilentAim.Enabled = v
    end
})

CombatTab:Toggle({
    Flag = "SilentAimShowFOV",
    Title = "Show FOV Circle",
    Default = true,
    Callback = function(v)
        Settings.SilentAim.ShowFOV = v
    end
})

CombatTab:Slider({
    Flag = "SilentAimFOV",
    Title = "Silent Aim FOV",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 150 },
    Callback = function(v)
        Settings.SilentAim.FOV = v
    end
})

CombatTab:Slider({
    Flag = "SilentAimHitChance",
    Title = "Hit Chance",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 100 },
    Callback = function(v)
        Settings.SilentAim.HitChance = v
    end
})

CombatTab:Dropdown({
    Flag = "SilentAimTargetPart",
    Title = "Target Part",
    Values = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" },
    Value = "Head",
    Callback = function(v)
        Settings.SilentAim.TargetPart = v
    end
})

CombatTab:Toggle({
    Flag = "SilentAimWallCheck",
    Title = "Wall Check",
    Default = true,
    Callback = function(v)
        Settings.SilentAim.WallCheck = v
    end
})

CombatTab:Toggle({
    Flag = "SilentAimTeamCheck",
    Title = "Team Check",
    Default = false,
    Callback = function(v)
        Settings.SilentAim.TeamCheck = v
    end
})

CombatTab:Toggle({
    Flag = "SilentAimDowned",
    Title = "Ignore Downed",
    Default = true,
    Callback = function(v)
        Settings.SilentAim.CheckDowned = v
    end
})

CombatTab:Space()

CombatTab:Toggle({
    Flag = "AimbotToggle",
    Title = "Aimbot",
    Desc = "Smooth aim with prediction",
    Default = false,
    Callback = function(v)
        Settings.Aimbot.Enabled = v
    end
})

CombatTab:Toggle({
    Flag = "AimbotShowFOV",
    Title = "Show Aimbot FOV",
    Default = true,
    Callback = function(v)
        Settings.Aimbot.ShowFOV = v
    end
})

CombatTab:Slider({
    Flag = "AimbotFOV",
    Title = "Aimbot FOV",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 200 },
    Callback = function(v)
        Settings.Aimbot.FOV = v
    end
})

CombatTab:Slider({
    Flag = "AimbotSmooth",
    Title = "Smoothness",
    Step = 0.01,
    Value = { Min = 0.01, Max = 1, Default = 0.15 },
    Callback = function(v)
        Settings.Aimbot.Smoothness = v
    end
})

CombatTab:Slider({
    Flag = "AimbotPrediction",
    Title = "Prediction",
    Step = 0.001,
    Value = { Min = 0, Max = 0.5, Default = 0.165 },
    Callback = function(v)
        Settings.Aimbot.Prediction = v
    end
})

CombatTab:Dropdown({
    Flag = "AimbotTargetPart",
    Title = "Aimbot Target Part",
    Values = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" },
    Value = "Head",
    Callback = function(v)
        Settings.Aimbot.TargetPart = v
    end
})

CombatTab:Keybind({
    Flag = "AimbotKey",
    Title = "Aimbot Key",
    Desc = "Set the key for aimbot hold/toggle",
    Value = "MB2",
    Callback = function(v)
        Settings.Aimbot.Key = v or "MB2"
    end
})

CombatTab:Dropdown({
    Flag = "AimbotMode",
    Title = "Aimbot Mode",
    Values = { "Hold", "Toggle" },
    Value = "Hold",
    Callback = function(v)
        Settings.Aimbot.Mode = v
    end
})

CombatTab:Toggle({
    Flag = "AimbotWallCheck",
    Title = "Aimbot Wall Check",
    Default = true,
    Callback = function(v)
        Settings.Aimbot.WallCheck = v
    end
})

CombatTab:Toggle({
    Flag = "AimbotTeamCheck",
    Title = "Aimbot Team Check",
    Default = false,
    Callback = function(v)
        Settings.Aimbot.TeamCheck = v
    end
})

CombatTab:Space()

CombatTab:Toggle({
    Flag = "TriggerBotToggle",
    Title = "Trigger Bot",
    Desc = "Auto-activate weapon on target",
    Default = false,
    Callback = function(v)
        SetTriggerBot(v)
    end
})

CombatTab:Keybind({
    Flag = "TriggerKey",
    Title = "Trigger Key",
    Desc = "Keybind to activate/hold trigger",
    Value = "MB2",
    Callback = function(v)
        Settings.TriggerBot.Key = v or "MB2"
    end
})

CombatTab:Dropdown({
    Flag = "TriggerMethod",
    Title = "Trigger Method",
    Values = { "Hold", "Click" },
    Value = "Hold",
    Callback = function(v)
        Settings.TriggerBot.Method = v
    end
})

CombatTab:Slider({
    Flag = "TriggerClickMs",
    Title = "Click Ms",
    Step = 1,
    Value = { Min = 10, Max = 1000, Default = 100 },
    Callback = function(v)
        Settings.TriggerBot.ClickMs = v
    end
})

CombatTab:Space()

CombatTab:Toggle({ Flag = "TriggerPartHead", Title = "Part: Head", Default = true, Callback = function(v) Settings.TriggerBot.Parts.Head = v end })
CombatTab:Toggle({ Flag = "TriggerPartHRP", Title = "Part: HumanoidRootPart", Default = true, Callback = function(v) Settings.TriggerBot.Parts.HumanoidRootPart = v end })
CombatTab:Toggle({ Flag = "TriggerPartLHand", Title = "Part: LeftHand", Default = false, Callback = function(v) Settings.TriggerBot.Parts.LeftHand = v end })
CombatTab:Toggle({ Flag = "TriggerPartRHand", Title = "Part: RightHand", Default = false, Callback = function(v) Settings.TriggerBot.Parts.RightHand = v end })
CombatTab:Toggle({ Flag = "TriggerPartLLeg", Title = "Part: LeftLeg", Default = false, Callback = function(v) Settings.TriggerBot.Parts.LeftLeg = v end })
CombatTab:Toggle({ Flag = "TriggerPartRLeg", Title = "Part: RightLeg", Default = false, Callback = function(v) Settings.TriggerBot.Parts.RightLeg = v end })

CombatTab:Space()

CombatTab:Toggle({ Flag = "TriggerFriendCheck", Title = "Friend Check", Default = false, Callback = function(v) Settings.TriggerBot.FriendCheck = v end })
CombatTab:Toggle({ Flag = "TriggerEnemyCheck", Title = "Enemy Check", Default = false, Callback = function(v) Settings.TriggerBot.EnemyCheck = v end })

CombatTab:Input({ Flag = "TriggerFriendList", Title = "Friend List (comma-separated)", Value = "", Callback = function(v)
    local list = {}
    for name in string.gmatch(v or "", '([^,]+)') do
        name = name:gsub("^%s+",""):gsub("%s+$","")
        if name ~= "" then table.insert(list, name) end
    end
    Settings.TriggerBot.FriendList = list
end })

CombatTab:Toggle({
    Flag = "BulletTracerToggle",
    Title = "Bullet Tracer",
    Desc = "Draws simple bullet trail visuals",
    Default = false,
    Callback = function(v)
        SetBulletTracer(v)
    end
})

CombatTab:Toggle({
    Flag = "SpinbotToggle",
    Title = "Spinbot",
    Desc = "Auto-spin + auto-shoot",
    Default = false,
    Callback = function(v)
        SetSpinbot(v)
    end
})

CombatTab:Slider({
    Flag = "SpinbotSpeed",
    Title = "Spin Speed",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 30 },
    Callback = function(v)
        Settings.Spinbot.Speed = v
    end
})

CombatTab:Toggle({
    Flag = "SpinbotAutoShoot",
    Title = "Auto Shoot",
    Default = true,
    Callback = function(v)
        Settings.Spinbot.AutoShoot = v
    end
})

local VisualTab = VisualSection:Tab({
    Title = "Visual",
    Icon = "eye",
    IconColor = Color3.fromHex("#2ED573"),
})

VisualTab:Toggle({
    Flag = "ESPToggle",
    Title = "ESP",
    Desc = "Master ESP switch",
    Default = false,
    Callback = function(v)
        Settings.ESP.Enabled = v
    end
})

VisualTab:Toggle({
    Flag = "FullBrightToggle",
    Title = "Full Bright",
    Default = false,
    Callback = function(v)
        SetFullBright(v)
    end
})

VisualTab:Toggle({
    Flag = "ESPCornerBox",
    Title = "Corner Box",
    Default = true,
    Callback = function(v)
        Settings.ESP.CornerBox = v
    end
})

VisualTab:Toggle({
    Flag = "ESPBoxOutline",
    Title = "Box Outline",
    Default = true,
    Callback = function(v)
        Settings.ESP.BoxOutline = v
    end
})

VisualTab:Toggle({
    Flag = "ESPBoxFilled",
    Title = "Box Fill",
    Default = false,
    Callback = function(v)
        Settings.ESP.BoxFilled = v
    end
})

VisualTab:Slider({
    Flag = "ESPBoxThickness",
    Title = "Box Thickness",
    Step = 0.5,
    Value = { Min = 0.5, Max = 5, Default = 1.5 },
    Callback = function(v)
        Settings.ESP.BoxThickness = v
    end
})

VisualTab:Slider({
    Flag = "ESPBoxFillTransparency",
    Title = "Fill Transparency",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.3 },
    Callback = function(v)
        Settings.ESP.BoxFillTransparency = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPBoxColor",
    Title = "Box Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.BoxColor = c
    end
})

VisualTab:Colorpicker({
    Flag = "ESPBoxFillColor",
    Title = "Fill Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.BoxFillColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPSkeleton",
    Title = "Skeleton",
    Default = true,
    Callback = function(v)
        Settings.ESP.Skeleton = v
    end
})

VisualTab:Slider({
    Flag = "ESPSkeletonThickness",
    Title = "Skeleton Thickness",
    Step = 0.5,
    Value = { Min = 0.5, Max = 5, Default = 1 },
    Callback = function(v)
        Settings.ESP.SkeletonThickness = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPSkeletonColor",
    Title = "Skeleton Color",
    Default = Color3.fromRGB(200, 200, 200),
    Callback = function(c)
        Settings.ESP.SkeletonColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPHealthBar",
    Title = "Health Bar",
    Default = true,
    Callback = function(v)
        Settings.ESP.HealthBar = v
    end
})

VisualTab:Dropdown({
    Flag = "ESPHealthBarPosition",
    Title = "Health Bar Position",
    Values = { "Left", "Right" },
    Value = "Left",
    Callback = function(v)
        Settings.ESP.HealthBarPosition = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPHealthBarColorLow",
    Title = "Health Color (Low)",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.ESP.HealthBarColorLow = c
    end
})

VisualTab:Colorpicker({
    Flag = "ESPHealthBarColorHigh",
    Title = "Health Color (High)",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(c)
        Settings.ESP.HealthBarColorHigh = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPName",
    Title = "Name",
    Default = true,
    Callback = function(v)
        Settings.ESP.Name = v
    end
})

VisualTab:Toggle({
    Flag = "ESPShowHealthText",
    Title = "Show Health in Name",
    Default = false,
    Callback = function(v)
        Settings.ESP.ShowHealthText = v
    end
})

VisualTab:Toggle({
    Flag = "ESPShowMaxHealth",
    Title = "Show Max Health",
    Default = false,
    Callback = function(v)
        Settings.ESP.ShowMaxHealth = v
    end
})

VisualTab:Slider({
    Flag = "ESPNameSize",
    Title = "Name Size",
    Step = 1,
    Value = { Min = 8, Max = 24, Default = 14 },
    Callback = function(v)
        Settings.ESP.NameSize = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPNameColor",
    Title = "Name Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.NameColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPDistance",
    Title = "Distance",
    Default = true,
    Callback = function(v)
        Settings.ESP.Distance = v
    end
})

VisualTab:Slider({
    Flag = "ESPDistanceSize",
    Title = "Distance Size",
    Step = 1,
    Value = { Min = 8, Max = 24, Default = 13 },
    Callback = function(v)
        Settings.ESP.DistanceSize = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPDistanceColor",
    Title = "Distance Color",
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(c)
        Settings.ESP.DistanceColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPTool",
    Title = "Tool",
    Default = true,
    Callback = function(v)
        Settings.ESP.Tool = v
    end
})

VisualTab:Slider({
    Flag = "ESPToolSize",
    Title = "Tool Size",
    Step = 1,
    Value = { Min = 8, Max = 24, Default = 13 },
    Callback = function(v)
        Settings.ESP.ToolSize = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPToolColor",
    Title = "Tool Color",
    Default = Color3.fromRGB(255, 255, 0),
    Callback = function(c)
        Settings.ESP.ToolColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "ESPTracer",
    Title = "Tracer",
    Default = true,
    Callback = function(v)
        Settings.ESP.Tracer = v
    end
})

VisualTab:Dropdown({
    Flag = "ESPTracerOrigin",
    Title = "Tracer Origin",
    Values = { "Bottom", "Top", "Center", "Mouse" },
    Value = "Bottom",
    Callback = function(v)
        Settings.ESP.TracerOrigin = v
    end
})

VisualTab:Slider({
    Flag = "ESPTracerThickness",
    Title = "Tracer Thickness",
    Step = 0.5,
    Value = { Min = 0.5, Max = 5, Default = 1.5 },
    Callback = function(v)
        Settings.ESP.TracerThickness = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPTracerColor",
    Title = "Tracer Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.TracerColor = c
    end
})

VisualTab:Space()

VisualTab:Toggle({
    Flag = "DealerESPToggle",
    Title = "Dealer ESP",
    Default = false,
    Callback = function(v)
        SetDealerESP(v)
    end
})

VisualTab:Toggle({
    Flag = "ESPTeamCheck",
    Title = "Team Check",
    Default = false,
    Callback = function(v)
        Settings.ESP.TeamCheck = v
    end
})

VisualTab:Slider({
    Flag = "ESPMaxDistance",
    Title = "Max Distance",
    Step = 10,
    Value = { Min = 100, Max = 5000, Default = 2000 },
    Callback = function(v)
        Settings.ESP.MaxDistance = v
    end
})

local MiscTab = MiscSection:Tab({
    Title = "Misc",
    Icon = "zap",
    IconColor = Color3.fromHex("#FFA502"),
})

MiscTab:Toggle({
    Flag = "SpeedhackToggle",
    Title = "Speedhack",
    Desc = "Velocity method (no kick)",
    Default = false,
    Callback = function(v)
        SetSpeedhack(v)
    end
})

MiscTab:Toggle({
    Flag = "MeleeAuraToggle",
    Title = "Melee Aura",
    Desc = "Auto-attack nearby melee targets",
    Default = false,
    Callback = function(v)
        SetMeleeAura(v)
    end
})

MiscTab:Toggle({
    Flag = "ChatEnablerToggle",
    Title = "Chat Enabler",
    Default = false,
    Callback = function(v)
        SetChatEnabler(v)
    end
})

MiscTab:Toggle({
    Flag = "InstantEquipToggle",
    Title = "Instant Equip",
    Default = false,
    Callback = function(v)
        SetInstantEquip(v)
    end
})

MiscTab:Slider({
    Flag = "MeleeAuraRange",
    Title = "Melee Aura Radius",
    Min = 2,
    Max = 25,
    Default = 8,
    Callback = function(v)
        Settings.MeleeAura.Range = v
    end
})

MiscTab:Toggle({
    Flag = "InstantReloadToggle",
    Title = "Instant Reload",
    Desc = "Keep equipped weapon ammo full",
    Default = false,
    Callback = function(v)
        SetInstantReload(v)
    end
})

MiscTab:Toggle({
    Flag = "InfiniteStaminaToggle",
    Title = "Infinite Stamina",
    Desc = "Keeps stamina values full",
    Default = false,
    Callback = function(v)
        SetInfiniteStamina(v)
    end
})

MiscTab:Slider({
    Flag = "SpeedhackSpeed",
    Title = "Speed",
    Step = 1,
    Value = { Min = 20, Max = 200, Default = 80 },
    Callback = function(v)
        Settings.Speedhack.Speed = v
    end
})

local SettingsTab = SettingsSection:Tab({
    Title = "Settings",
    Icon = "settings",
    IconColor = Color3.fromHex("#747D8C"),
})

local ConfigManager = Window.ConfigManager

SettingsTab:Input({
    Flag = "ConfigName",
    Title = "Config Name",
    Value = "default",
    Callback = function(v)
        Window.CurrentConfig = ConfigManager:Config(v)
    end
})

SettingsTab:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        if Window.CurrentConfig and Window.CurrentConfig:Save() then
            WindUI:Notify({ Title = "Config Saved", Content = "Configuration saved successfully!", Icon = "check" })
        end
    end
})

SettingsTab:Button({
    Title = "Load Config",
    Icon = "refresh-cw",
    Callback = function()
        if Window.CurrentConfig and Window.CurrentConfig:Load() then
            WindUI:Notify({ Title = "Config Loaded", Content = "Configuration loaded successfully!", Icon = "check" })
        end
    end
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Unload Script",
    Icon = "trash",
    Color = Color3.fromHex("#FF4757"),
    Callback = function()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        if SpeedConnection then SpeedConnection:Disconnect() end
        if SpinConnection then SpinConnection:Disconnect() end
        if MeleeAuraConnection then MeleeAuraConnection:Disconnect() end
        if InstantReloadConnection then InstantReloadConnection:Disconnect() end
        if InfiniteStaminaConnection then InfiniteStaminaConnection:Disconnect() end
        if DealerESPConnection then DealerESPConnection:Disconnect() end
        if FullBrightConnection then FullBrightConnection:Disconnect() end
        if InstantEquipConnection then InstantEquipConnection:Disconnect() end
        if TriggerBotConnection then TriggerBotConnection:Disconnect() end
        if BulletTracerConnection then BulletTracerConnection:Disconnect() end
        if OriginalLightingSettings then
            Lighting.Brightness = OriginalLightingSettings.Brightness
            Lighting.Ambient = OriginalLightingSettings.Ambient
            Lighting.OutdoorAmbient = OriginalLightingSettings.OutdoorAmbient
            Lighting.ClockTime = OriginalLightingSettings.ClockTime
            Lighting.ColorShift_Top = OriginalLightingSettings.ColorShift_Top
            Lighting.ColorShift_Bottom = OriginalLightingSettings.ColorShift_Bottom
            Lighting.GlobalShadows = OriginalLightingSettings.GlobalShadows
            Lighting.ExposureCompensation = OriginalLightingSettings.ExposureCompensation
        end
        for _, highlight in pairs(DealerESPObjects) do pcall(function() highlight:Destroy() end) end
        for _, entry in ipairs(BulletTracerLines) do pcall(function() entry.Line:Remove() end) end
        BulletTracerLines = {}
        for plr, data in pairs(ESPObjects) do
            for k, v in pairs(data) do
                if k == "Corner" or k == "CornerOutline" or k == "Skeleton" then
                    for _, line in pairs(v) do pcall(function() line:Remove() end) end
                else
                    pcall(function() v:Remove() end)
                end
            end
        end
        Window:Destroy()
    end
})

InitESP()
InitSilentAim()
InitAimbot()

WindUI:Notify({
    Title = "Criminality Lite",
    Content = "Loaded successfully!",
    Icon = "check",
    Duration = 5,
})
