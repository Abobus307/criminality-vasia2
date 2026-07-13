local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    SilentAim = {
        Enabled = false,
        FOV = 150,
        HitChance = 100,
        TargetPart = "Head",
        WallCheck = true,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
    },
    ESP = {
        Enabled = false,
        CornerBox = true,
        BoxFilled = false,
        BoxFillTransparency = 0.3,
        BoxFillColor = Color3.fromRGB(255, 255, 255),
        BoxColor = Color3.fromRGB(255, 255, 255),
        BoxThickness = 1.5,
        Skeleton = true,
        SkeletonColor = Color3.fromRGB(200, 200, 200),
        SkeletonThickness = 1,
        HealthBar = true,
        HealthBarPosition = "Left",
        HealthBarColorLow = Color3.fromRGB(255, 0, 0),
        HealthBarColorHigh = Color3.fromRGB(0, 255, 0),
        Name = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 14,
        ShowHealthText = false,
        ShowMaxHealth = false,
        Distance = true,
        DistanceColor = Color3.fromRGB(0, 255, 255),
        DistanceSize = 13,
        Tool = true,
        ToolColor = Color3.fromRGB(255, 255, 0),
        ToolSize = 13,
        Tracer = true,
        TracerOrigin = "Bottom",
        TracerColor = Color3.fromRGB(255, 255, 255),
        TracerThickness = 1.5,
        MaxDistance = 2000,
    },
    Aimbot = {
        Enabled = false,
        FOV = 200,
        TargetPart = "Head",
        WallCheck = true,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
        Key = "MB2",
        Mode = "Hold",
        Active = false,
        PredictMovement = true,
        PredictionVelocity = 16,
        NotifyTarget = true,
    },
    AutoShoot = {
        Enabled = false,
    },
    Chams = {
        Enabled = false,
        FillColor = Color3.fromRGB(255, 0, 0),
        OutlineColor = Color3.fromRGB(255, 255, 255),
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        DepthMode = "AlwaysOnTop",
    },
    Speedhack = {
        Enabled = false,
        Speed = 80,
    },
    Spinbot = {
        Enabled = false,
        Speed = 30,
    },
    TriggerBot = {
        Enabled = false,
        Held = false,
        TeamCheck = false,
        FriendCheck = false,
        EnemyCheck = false,
        CheckDown = true,
        CheckForceField = true,
        WallCheck = true,
        Part = {"Head", "HumanoidRootPart", "Left Hand", "Right Hand", "Left Leg", "Right Leg"},
        Method = "Hold",
        ClickMs = 40,
        LastClick = 0,
    },
    BulletTracer = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Thick = 0.1,
        Life = 2,
        Trans = 0.65,
        Design = "Classic",
    },
    InfStamina = {
        Enabled = false,
    },
}

local ESPObjects = {}
local ChamsObjects = {}
local Connections = {}
local ActiveConnections = {}
local SilentAimTarget = nil
local AimbotTarget = nil
local StaminaStateTables = {}
local BulletBeamStyles = {
    Classic = {id = "rbxassetid://446111271", len = 1, spd = 1},
    Rainbow = {id = "rbxassetid://2490624870", len = 3, spd = 2},
}
local BulletTracerConnections = {}

local function GetCharacter(player)
    return player and player.Character
end

local function GetRootPart(player)
    local character = GetCharacter(player)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function GetHumanoid(player)
    local character = GetCharacter(player)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    local humanoid = GetHumanoid(player)
    return humanoid and humanoid.Health > 0
end

local function IsDowned(player)
    local character = GetCharacter(player)
    if not character then return false end
    local humanoid = GetHumanoid(player)
    if humanoid and humanoid.Health <= 15 then return true end
    local stats = character:FindFirstChild("CharStats")
    if stats then
        local downed = stats:FindFirstChild("Downed")
        if downed and typeof(downed.Value) == "boolean" then
            return downed.Value
        end
    end
    return false
end

local function HasForceField(player)
    local character = GetCharacter(player)
    return character and character:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsVisible(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function GetDistanceTo(position)
    local root = GetRootPart(LocalPlayer)
    if not root then return math.huge end
    return (position - root.Position).Magnitude
end

local function GetClosestPlayer(config)
    local closest = nil
    local shortest = config.FOV or math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        local skip = false
        if player == LocalPlayer then skip = true end
        if not skip and not IsAlive(player) then skip = true end
        if not skip and config.CheckDowned and IsDowned(player) then skip = true end
        if not skip and config.CheckForceField and HasForceField(player) then skip = true end

        if not skip then
            local character = GetCharacter(player)
            if not character then skip = true end
            if not skip then
                local part = character:FindFirstChild(config.TargetPart)
                if not part then skip = true end
                if not skip then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if not onScreen then skip = true end
                    if not skip then
                        local distance2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if distance2D > shortest then skip = true end
                        if not skip and config.WallCheck and not IsVisible(part) then skip = true end
                        if not skip then
                            closest = player
                            shortest = distance2D
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function NewDrawing(class, properties)
    local drawing = Drawing.new(class)
    for key, value in pairs(properties or {}) do
        drawing[key] = value
    end
    return drawing
end

local function RemoveDrawing(drawing)
    pcall(function() drawing:Remove() end)
end

local function HideESP(data)
    for key, value in pairs(data) do
        if key == "Corner" or key == "CornerOutline" or key == "Skeleton" then
            for _, line in pairs(value) do
                line.Visible = false
            end
        else
            value.Visible = false
        end
    end
end

local function RemoveESP(player)
    local data = ESPObjects[player]
    if not data then return end
    for key, value in pairs(data) do
        if key == "Corner" or key == "CornerOutline" or key == "Skeleton" then
            for _, line in pairs(value) do
                RemoveDrawing(line)
            end
        else
            RemoveDrawing(value)
        end
    end
    ESPObjects[player] = nil
end

local function CreateESPObject(player)
    if ESPObjects[player] then return ESPObjects[player] end
    local data = {
        Corner = {},
        CornerOutline = {},
        BoxFill = NewDrawing("Square", {Filled = true, Transparency = Settings.ESP.BoxFillTransparency, Visible = false}),
        HealthBar = NewDrawing("Line", {Thickness = 3, Visible = false}),
        HealthBarOutline = NewDrawing("Line", {Thickness = 5, Color = Color3.new(0, 0, 0), Visible = false}),
        Name = NewDrawing("Text", {Size = Settings.ESP.NameSize, Center = true, Outline = true, Font = 2, Visible = false}),
        Distance = NewDrawing("Text", {Size = Settings.ESP.DistanceSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.DistanceColor, Visible = false}),
        Tool = NewDrawing("Text", {Size = Settings.ESP.ToolSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.ToolColor, Visible = false}),
        Tracer = NewDrawing("Line", {Thickness = Settings.ESP.TracerThickness, Visible = false}),
        Skeleton = {},
    }
    for i = 1, 8 do
        data.Corner[i] = NewDrawing("Line", {Thickness = Settings.ESP.BoxThickness, Visible = false})
        data.CornerOutline[i] = NewDrawing("Line", {Thickness = Settings.ESP.BoxThickness + 2, Color = Color3.new(0, 0, 0), Visible = false})
    end
    for i = 1, 20 do
        data.Skeleton[i] = NewDrawing("Line", {Thickness = Settings.ESP.SkeletonThickness, Visible = false})
    end
    ESPObjects[player] = data
    return data
end

local function UpdateESP(player)
    local data = ESPObjects[player]
    if not data then return end

    local character = GetCharacter(player)
    local root = GetRootPart(player)
    local humanoid = GetHumanoid(player)
    local head = character and character:FindFirstChild("Head")

    if not character or not root or not humanoid or humanoid.Health <= 0 then
        HideESP(data)
        return
    end

    local distance = GetDistanceTo(root.Position)
    if distance > Settings.ESP.MaxDistance then
        HideESP(data)
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

    if not onScreen or not headPos then
        HideESP(data)
        return
    end

    local height = math.abs(legPos.Y - headPos.Y)
    local width = height / 2
    local position = Vector2.new(headPos.X - width / 2, headPos.Y)
    local color = Settings.ESP.BoxColor

    if Settings.ESP.CornerBox then
        local cornerSize = math.min(width, height) * 0.25
        local corners = {
            {position, position + Vector2.new(cornerSize, 0)},
            {position, position + Vector2.new(0, cornerSize)},
            {position + Vector2.new(width, 0), position + Vector2.new(width - cornerSize, 0)},
            {position + Vector2.new(width, 0), position + Vector2.new(width, cornerSize)},
            {position + Vector2.new(0, height), position + Vector2.new(cornerSize, height)},
            {position + Vector2.new(0, height), position + Vector2.new(0, height - cornerSize)},
            {position + Vector2.new(width, height), position + Vector2.new(width - cornerSize, height)},
            {position + Vector2.new(width, height), position + Vector2.new(width, height - cornerSize)},
        }
        for i = 1, 8 do
            data.Corner[i].From = corners[i][1]
            data.Corner[i].To = corners[i][2]
            data.Corner[i].Color = color
            data.Corner[i].Thickness = Settings.ESP.BoxThickness
            data.Corner[i].Visible = true
            data.CornerOutline[i].From = corners[i][1]
            data.CornerOutline[i].To = corners[i][2]
            data.CornerOutline[i].Thickness = Settings.ESP.BoxThickness + 2
            data.CornerOutline[i].Visible = true
        end
    else
        for i = 1, 8 do
            data.Corner[i].Visible = false
            data.CornerOutline[i].Visible = false
        end
    end

    if Settings.ESP.BoxFilled then
        data.BoxFill.Size = Vector2.new(width, height)
        data.BoxFill.Position = position
        data.BoxFill.Color = Settings.ESP.BoxFillColor
        data.BoxFill.Transparency = Settings.ESP.BoxFillTransparency
        data.BoxFill.Visible = true
    else
        data.BoxFill.Visible = false
    end

    if Settings.ESP.HealthBar then
        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barHeight = height * healthPercent
        local barX, barY
        if Settings.ESP.HealthBarPosition == "Left" then
            barX = position.X - 6
            barY = position.Y
        elseif Settings.ESP.HealthBarPosition == "Right" then
            barX = position.X + width + 6
            barY = position.Y
        else
            barX = position.X - 6
            barY = position.Y
        end
        data.HealthBarOutline.From = Vector2.new(barX, barY)
        data.HealthBarOutline.To = Vector2.new(barX, barY + height)
        data.HealthBarOutline.Visible = true
        data.HealthBar.From = Vector2.new(barX, barY + height - barHeight)
        data.HealthBar.To = Vector2.new(barX, barY + height)
        data.HealthBar.Color = Settings.ESP.HealthBarColorLow:Lerp(Settings.ESP.HealthBarColorHigh, healthPercent)
        data.HealthBar.Visible = true
    else
        data.HealthBar.Visible = false
        data.HealthBarOutline.Visible = false
    end

    if Settings.ESP.Name then
        local nameText = player.Name
        if Settings.ESP.ShowHealthText then
            if Settings.ESP.ShowMaxHealth then
                nameText = string.format("%s [%s/%sHP]", player.Name, math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
            else
                nameText = string.format("%s [%sHP]", player.Name, math.floor(humanoid.Health))
            end
        end
        data.Name.Text = nameText
        data.Name.Position = Vector2.new(position.X + width / 2, position.Y - 20)
        data.Name.Color = Settings.ESP.NameColor
        data.Name.Size = Settings.ESP.NameSize
        data.Name.Visible = true
    else
        data.Name.Visible = false
    end

    if Settings.ESP.Distance then
        data.Distance.Text = string.format("[%dm]", math.floor(distance))
        data.Distance.Position = Vector2.new(position.X + width / 2, position.Y + height + 2)
        data.Distance.Color = Settings.ESP.DistanceColor
        data.Distance.Size = Settings.ESP.DistanceSize
        data.Distance.Visible = true
    else
        data.Distance.Visible = false
    end

    if Settings.ESP.Tool then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            data.Tool.Text = string.format("[%s]", tool.Name)
            data.Tool.Position = Vector2.new(position.X + width / 2, position.Y + height + 16)
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
        data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        data.Tracer.Color = Settings.ESP.TracerColor
        data.Tracer.Thickness = Settings.ESP.TracerThickness
        data.Tracer.Visible = true
    else
        data.Tracer.Visible = false
    end

    if Settings.ESP.Skeleton then
        local isR15 = character:FindFirstChild("UpperTorso") ~= nil
        local map
        if isR15 then
            map = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"},
            }
        else
            map = {
                {"Head", "Torso"},
                {"Torso", "Left Arm"},
                {"Torso", "Right Arm"},
                {"Torso", "Left Leg"},
                {"Torso", "Right Leg"},
            }
        end
        local index = 1
        for _, pair in ipairs(map) do
            local part1 = character:FindFirstChild(pair[1])
            local part2 = character:FindFirstChild(pair[2])
            local line = data.Skeleton[index]
            if line and part1 and part2 then
                local pos1, visible1 = Camera:WorldToViewportPoint(part1.Position)
                local pos2, visible2 = Camera:WorldToViewportPoint(part2.Position)
                if visible1 and visible2 then
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    line.Color = Settings.ESP.SkeletonColor
                    line.Thickness = Settings.ESP.SkeletonThickness
                    line.Visible = true
                else
                    line.Visible = false
                end
            elseif line then
                line.Visible = false
            end
            index = index + 1
        end
        for i = index, #data.Skeleton do
            if data.Skeleton[i] then
                data.Skeleton[i].Visible = false
            end
        end
    else
        for _, line in pairs(data.Skeleton) do
            line.Visible = false
        end
    end
end

local function InitESP()
    local connection = RunService.RenderStepped:Connect(function()
        if not Settings.ESP.Enabled then
            for _, data in pairs(ESPObjects) do
                HideESP(data)
            end
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESPObject(player)
                UpdateESP(player)
            end
        end
    end)
    table.insert(Connections, connection)
end

local function RemoveChams(player)
    local highlight = ChamsObjects[player]
    if highlight then
        pcall(function() highlight:Destroy() end)
        ChamsObjects[player] = nil
    end
end

local function ApplyChams(player)
    if not Settings.Chams.Enabled then
        RemoveChams(player)
        return
    end
    local character = GetCharacter(player)
    if not character then
        RemoveChams(player)
        return
    end
    local root = GetRootPart(player)
    if root then
        local dist = GetDistanceTo(root.Position)
        if dist > Settings.ESP.MaxDistance then
            RemoveChams(player)
            return
        end
    end
    local highlight = ChamsObjects[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "CL_Chams"
        ChamsObjects[player] = highlight
        highlight.Parent = game.CoreGui
    end
    highlight.Adornee = character
    highlight.FillColor = Settings.Chams.FillColor
    highlight.OutlineColor = Settings.Chams.OutlineColor
    highlight.FillTransparency = Settings.Chams.FillTransparency
    highlight.OutlineTransparency = Settings.Chams.OutlineTransparency
    highlight.DepthMode = Settings.Chams.DepthMode == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end

local function UpdateAllChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ApplyChams(player)
        end
    end
end

local function SetupChamsForPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function()
        if Settings.Chams.Enabled then
            ApplyChams(player)
        end
    end)
    player.CharacterRemoving:Connect(function()
        RemoveChams(player)
    end)
    if GetCharacter(player) and Settings.Chams.Enabled then
        ApplyChams(player)
    end
end

local function InitChams()
    for _, player in ipairs(Players:GetPlayers()) do
        SetupChamsForPlayer(player)
    end
    Players.PlayerAdded:Connect(SetupChamsForPlayer)

    local chamsDistanceConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Chams.Enabled then
            for player, _ in pairs(ChamsObjects) do
                RemoveChams(player)
            end
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = GetCharacter(player)
                if not character then
                    RemoveChams(player)
                else
                    local root = GetRootPart(player)
                    if root then
                        local dist = GetDistanceTo(root.Position)
                        if dist > Settings.ESP.MaxDistance then
                            RemoveChams(player)
                        elseif not ChamsObjects[player] then
                            ApplyChams(player)
                        end
                    end
                end
            end
        end
    end)
    table.insert(Connections, chamsDistanceConnection)
end

local function InitSilentAim()
    local fovCircle = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Transparency = 1, Visible = false, Color = Color3.fromRGB(255, 255, 255), NumSides = 64})
    Settings.SilentAim.FOVCircle = fovCircle

    local connection = RunService.Heartbeat:Connect(function()
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
    table.insert(Connections, connection)

    local ok1, visEvent = pcall(function() return ReplicatedStorage:WaitForChild("Events2", 5):WaitForChild("Visualize", 5) end)
    local ok2, dmgEvent = pcall(function() return ReplicatedStorage:WaitForChild("Events", 5):WaitForChild("ZFKLF__H", 5) end)

    if ok1 and ok2 and visEvent and dmgEvent then
        local eventConnection = visEvent.Event:Connect(function(_, shotCode, _, gun, _, startPos, bulletsPerShot)
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
                pcall(function() dmgEvent:FireServer("", gun, shotCode, idx, part, hitPos, dir) end)
            end

            pcall(function()
                if gun:FindFirstChild("Hitmarker") then gun.Hitmarker:Fire(part) end
            end)
        end)
        table.insert(Connections, eventConnection)
    end
end

local function InitAimbot()
    local fovCircle = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Transparency = 0.5, Visible = false, Color = Color3.fromRGB(255, 255, 255), NumSides = 64})
    Settings.Aimbot.FOVCircle = fovCircle

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function GetNearestTarget()
        local closest = nil
        local shortest = math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            local skip = false
            if player == LocalPlayer then skip = true end
            if not skip and not IsAlive(player) then skip = true end
            if not skip and Settings.Aimbot.CheckDowned and IsDowned(player) then skip = true end
            if not skip and Settings.Aimbot.CheckForceField and HasForceField(player) then skip = true end

            if not skip then
                local character = GetCharacter(player)
                if not character then skip = true end
                if not skip then
                    local part = character:FindFirstChild(Settings.Aimbot.TargetPart)
                    if not part then skip = true end
                    if not skip then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if not onScreen then skip = true end
                        if not skip then
                            local distance2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if distance2D > Settings.Aimbot.FOV then skip = true end
                            if not skip and Settings.Aimbot.WallCheck and not IsVisible(part) then skip = true end
                            if not skip then
                                local dist3D = GetDistanceTo(part.Position)
                                if dist3D < shortest then
                                    closest = player
                                    shortest = dist3D
                                end
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not Settings.Aimbot.Enabled then return end
        local key = Settings.Aimbot.Key
        local match = false
        if key == "MB1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            match = true
        elseif key == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            match = true
        elseif input.KeyCode == Enum.KeyCode[key] then
            match = true
        end
        if match then
            if Settings.Aimbot.Mode == "Hold" then
                Settings.Aimbot.Active = true
            else
                Settings.Aimbot.Active = not Settings.Aimbot.Active
            end
            if Settings.Aimbot.Active then
                AimbotTarget = GetNearestTarget()
                if AimbotTarget and Settings.Aimbot.NotifyTarget then
                    WindUI:Notify({
                        Title = "Aimlock Target",
                        Content = "Locked onto: " .. tostring(AimbotTarget.Name),
                        Icon = "lucide:target",
                        Duration = 3
                    })
                end
            end
        end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if Settings.Aimbot.Mode == "Hold" then
            local key = Settings.Aimbot.Key
            local match = false
            if key == "MB1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
                match = true
            elseif key == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2 then
                match = true
            elseif input.KeyCode == Enum.KeyCode[key] then
                match = true
            end
            if match then
                Settings.Aimbot.Active = false
                AimbotTarget = nil
            end
        end
    end)

    local connection = RunService.RenderStepped:Connect(function()
        fovCircle.Visible = Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV
        if fovCircle.Visible then
            fovCircle.Radius = Settings.Aimbot.FOV
            fovCircle.Position = center
        end

        if not Settings.Aimbot.Enabled or not Settings.Aimbot.Active then
            return
        end

        if not AimbotTarget or not AimbotTarget.Character or not IsAlive(AimbotTarget) or
            (Settings.Aimbot.CheckDowned and IsDowned(AimbotTarget)) or
            (Settings.Aimbot.CheckForceField and HasForceField(AimbotTarget)) then
            AimbotTarget = nil
            return
        end

        if AimbotTarget and AimbotTarget.Character then
            local part = AimbotTarget.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            if part then
                local aimPos = part.Position
                if Settings.Aimbot.PredictMovement then
                    aimPos = aimPos + part.Velocity / Settings.Aimbot.PredictionVelocity
                end
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
            end
        end
    end)

    table.insert(Connections, inputBegan)
    table.insert(Connections, inputEnded)
    table.insert(Connections, connection)
end

local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local function TriggerBotClick()
    if Settings.TriggerBot.Method == "Hold" and mouse1press and mouse1release then
        pcall(mouse1press)
        task.wait(Settings.TriggerBot.ClickMs / 1000)
        pcall(mouse1release)
        return
    end
    if mouse1click then
        pcall(mouse1click)
        return
    end
    if mouse1press and mouse1release then
        pcall(mouse1press)
        pcall(mouse1release)
        return
    end
    if VirtualInputManager then
        local p = UserInputService:GetMouseLocation()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
            task.wait(Settings.TriggerBot.Method == "Hold" and Settings.TriggerBot.ClickMs / 1000 or 0)
            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
        end)
    end
end

local function TriggerBotTarget()
    local center = Camera.ViewportSize * 0.5
    local ray = Camera:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        GetCharacter(LocalPlayer),
        Camera,
    }
    params.IgnoreWater = true
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
    if not result or not result.Instance then
        return
    end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    local player = model and Players:GetPlayerFromCharacter(model)
    if not player then
        return
    end
    if player == LocalPlayer then return end
    if not IsAlive(player) then return end
    if Settings.TriggerBot.CheckDown and IsDowned(player) then return end
    if Settings.TriggerBot.CheckForceField and HasForceField(player) then return end
    if Settings.TriggerBot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return end
    if Settings.TriggerBot.WallCheck and not IsVisible(result.Instance) then return end
    
    local selectedParts = Settings.TriggerBot.Part
    if type(selectedParts) == "table" then
        local selected = false
        for _, partName in pairs(selectedParts) do
            if partName == result.Instance.Name then
                selected = true
                break
            end
        end
        if not selected then return end
    elseif selectedParts ~= result.Instance.Name then
        return
    end
    
    if tick() - Settings.TriggerBot.LastClick < Settings.TriggerBot.ClickMs / 1000 then
        return
    end
    Settings.TriggerBot.LastClick = tick()
    TriggerBotClick()
end

local function InitTriggerBot()
    local connection = RunService.RenderStepped:Connect(function()
        if Settings.TriggerBot.Enabled and Settings.TriggerBot.Held then
            TriggerBotTarget()
        end
    end)
    table.insert(Connections, connection)
end

local function CreateBulletBeam(origin, destination)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    
    local attachment0 = Instance.new("Attachment")
    local attachment1 = Instance.new("Attachment")
    attachment0.Position = origin
    attachment1.Position = destination
    attachment0.Parent = terrain
    attachment1.Parent = terrain
    
    local beam = Instance.new("Beam")
    local style = BulletBeamStyles[Settings.BulletTracer.Design] or BulletBeamStyles.Classic
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Color = ColorSequence.new(Settings.BulletTracer.Color)
    beam.Width0 = Settings.BulletTracer.Thick
    beam.Width1 = Settings.BulletTracer.Thick * 0.4
    beam.Texture = style.id
    beam.TextureLength = style.len
    beam.TextureSpeed = style.spd
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, Settings.BulletTracer.Trans * 0.4),
        NumberSequenceKeypoint.new(0.5, Settings.BulletTracer.Trans),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.FaceCamera = true
    beam.LightEmission = 0.6
    beam.LightInfluence = 0.1
    beam.Parent = terrain
    
    task.delay(Settings.BulletTracer.Life, function()
        pcall(function() beam:Destroy() end)
        pcall(function() attachment0:Destroy() end)
        pcall(function() attachment1:Destroy() end)
    end)
end

local function TraceBulletDirections(tool, directions, fallbackOrigin)
    if not Settings.BulletTracer.Enabled or type(directions) ~= "table" then return end
    local character = GetCharacter(LocalPlayer)
    if not character or character:FindFirstChildOfClass("Tool") ~= tool then return end
    
    local muzzle = tool and (tool:FindFirstChild("Muzzle", true) or tool:FindFirstChild("FirePoint", true))
    if not muzzle then
        local weaponHandle = tool and tool:FindFirstChild("WeaponHandle", true)
        muzzle = weaponHandle and (weaponHandle:FindFirstChild("Muzzle", true) or weaponHandle:FindFirstChild("FirePoint", true))
    end
    
    local origin
    if muzzle then
        if muzzle:IsA("Attachment") then
            origin = muzzle.WorldPosition
        elseif muzzle:IsA("BasePart") then
            origin = muzzle.Position
        end
    end
    if not origin and typeof(fallbackOrigin) == "Vector3" then
        origin = fallbackOrigin
    end
    origin = origin or Camera.CFrame.Position
    
    for _, direction in pairs(directions) do
        if typeof(direction) == "Vector3" and direction.Magnitude > 0 then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {Camera, character, tool}
            raycastParams.IgnoreWater = true
            local result = Workspace:Raycast(origin, direction.Unit * 1000, raycastParams)
            CreateBulletBeam(origin, result and result.Position or origin + direction.Unit * 500)
        end
    end
end

local function ClearBulletTracerConnections()
    for _, connection in ipairs(BulletTracerConnections) do
        pcall(connection.Disconnect, connection)
    end
    BulletTracerConnections = {}
end

local function SetupBulletTracerConnections()
    ClearBulletTracerConnections()
    local events2 = ReplicatedStorage:FindFirstChild("Events2")
    local visualize = events2 and events2:FindFirstChild("Visualize")
    if visualize and visualize.Event then
        BulletTracerConnections[#BulletTracerConnections + 1] = visualize.Event:Connect(function(arg1, arg2, arg3, tool, arg5, origin, directions)
            TraceBulletDirections(tool, directions, origin)
        end)
    end
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local function attachRemote(remote)
            if not remote:IsA("RemoteEvent") or remote.Name == "ZFKLF__H" then return end
            BulletTracerConnections[#BulletTracerConnections + 1] = remote.OnClientEvent:Connect(function(...)
                local args = {...}
                local tool = args[3]
                local directions = args[6]
                if typeof(tool) == "Instance" and tool:IsA("Tool") and type(directions) == "table" then
                    TraceBulletDirections(tool, directions, args[5])
                end
            end)
        end
        for _, remote in ipairs(events:GetChildren()) do
            attachRemote(remote)
        end
        BulletTracerConnections[#BulletTracerConnections + 1] = events.ChildAdded:Connect(attachRemote)
    end
end

local function InitBulletTracers()
    SetupBulletTracerConnections()
end

local function InitInfiniteStamina()
    if getgc then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "S") then
                    StaminaStateTables[#StaminaStateTables + 1] = obj
                end
            end
        end)
    end
    
    local connection = RunService.Heartbeat:Connect(function()
        if Settings.InfStamina.Enabled then
            for _, staminaTable in ipairs(StaminaStateTables) do
                staminaTable.S = 100
            end
        end
    end)
    table.insert(Connections, connection)
end

local function SetAutoShoot(enabled)
    Settings.AutoShoot.Enabled = enabled
    if ActiveConnections.AutoShoot then
        ActiveConnections.AutoShoot:Disconnect()
        ActiveConnections.AutoShoot = nil
    end
    if enabled then
        ActiveConnections.AutoShoot = RunService.Heartbeat:Connect(function()
            if not Settings.Aimbot.Enabled then return end
            if not AimbotTarget or not AimbotTarget.Character or not IsAlive(AimbotTarget) then return end
            local character = LocalPlayer.Character
            if not character then return end
            local tool = character:FindFirstChildOfClass("Tool")
            if not tool then return end
            pcall(function() tool:Activate() end)
        end)
    end
end

local function SetSpeedhack(enabled)
    Settings.Speedhack.Enabled = enabled
    if ActiveConnections.Speedhack then
        ActiveConnections.Speedhack:Disconnect()
        ActiveConnections.Speedhack = nil
    end
    if enabled then
        ActiveConnections.Speedhack = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local direction = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
            if direction.Magnitude > 0 then
                direction = Vector3.new(direction.X, 0, direction.Z).Unit
                root.Velocity = Vector3.new(
                    direction.X * Settings.Speedhack.Speed,
                    root.Velocity.Y,
                    direction.Z * Settings.Speedhack.Speed
                )
            end
        end)
    end
end

local function SetSpinbot(enabled)
    Settings.Spinbot.Enabled = enabled
    if ActiveConnections.Spinbot then
        ActiveConnections.Spinbot:Disconnect()
        ActiveConnections.Spinbot = nil
    end
    if enabled then
        ActiveConnections.Spinbot = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)
        end)
    end
end

local Window = WindUI:CreateWindow({
    Title = "Criminality Lite",
    Icon = "lucide:crosshair",
    Author = "by CriminalityLite",
    Folder = "CriminalityLite",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.G,
    Size = UDim2.fromOffset(560, 440),
    Transparent = true,
    Resizable = true,
    SideBarWidth = 180
})

local Tabs = {
    Combat = Window:Tab({Title = "Combat", Icon = "lucide:swords"}),
    Visual = Window:Tab({Title = "Visual", Icon = "lucide:eye"}),
    Misc = Window:Tab({Title = "Misc", Icon = "lucide:zap"}),
    Settings = Window:Tab({Title = "Settings", Icon = "lucide:settings"})
}

Tabs.Combat:Section({Title = "Silent Aim"})

Tabs.Combat:Toggle({
    Title = "Silent Aim",
    Desc = "Redirects bullets to target",
    Icon = "lucide:crosshair",
    Value = false,
    Callback = function(v)
        Settings.SilentAim.Enabled = v
    end
})

Tabs.Combat:Toggle({
    Title = "Show FOV Circle",
    Icon = "lucide:circle",
    Value = true,
    Callback = function(v)
        Settings.SilentAim.ShowFOV = v
    end
})

Tabs.Combat:Slider({
    Title = "Silent Aim FOV",
    Icon = "lucide:scan",
    Step = 1,
    Value = {Min = 10, Max = 500, Default = 150},
    Callback = function(v)
        Settings.SilentAim.FOV = v
    end
})

Tabs.Combat:Slider({
    Title = "Hit Chance",
    Icon = "lucide:percent",
    Step = 1,
    Value = {Min = 1, Max = 100, Default = 100},
    Callback = function(v)
        Settings.SilentAim.HitChance = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Target Part",
    Icon = "lucide:target",
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    Value = "Head",
    Callback = function(v)
        Settings.SilentAim.TargetPart = v
    end
})

Tabs.Combat:Toggle({
    Title = "Wall Check",
    Icon = "lucide:brick-wall",
    Value = true,
    Callback = function(v)
        Settings.SilentAim.WallCheck = v
    end
})

Tabs.Combat:Toggle({
    Title = "Ignore Downed",
    Icon = "lucide:heart-off",
    Value = true,
    Callback = function(v)
        Settings.SilentAim.CheckDowned = v
    end
})

Tabs.Combat:Section({Title = "Aimbot (FemboyHub Aimlock)"})

Tabs.Combat:Toggle({
    Title = "Aimlock",
    Desc = "Smooth camera snap with prediction",
    Icon = "lucide:target",
    Value = false,
    Callback = function(v)
        Settings.Aimbot.Enabled = v
    end
})

Tabs.Combat:Toggle({
    Title = "Show Aimlock FOV",
    Icon = "lucide:circle",
    Value = true,
    Callback = function(v)
        Settings.Aimbot.ShowFOV = v
    end
})

Tabs.Combat:Slider({
    Title = "Aimlock FOV",
    Icon = "lucide:scan",
    Step = 1,
    Value = {Min = 10, Max = 500, Default = 200},
    Callback = function(v)
        Settings.Aimbot.FOV = v
    end
})

Tabs.Combat:Toggle({
    Title = "Predict Movement",
    Icon = "lucide:activity",
    Value = true,
    Callback = function(v)
        Settings.Aimbot.PredictMovement = v
    end
})

Tabs.Combat:Slider({
    Title = "Prediction Velocity",
    Icon = "lucide:timer",
    Step = 1,
    Value = {Min = 1, Max = 50, Default = 16},
    Callback = function(v)
        Settings.Aimbot.PredictionVelocity = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Aimlock Target Part",
    Icon = "lucide:target",
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    Value = "Head",
    Callback = function(v)
        Settings.Aimbot.TargetPart = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Aimlock Key",
    Icon = "lucide:keyboard",
    Values = {"MB1", "MB2", "Q", "E", "F", "X", "Z", "C"},
    Value = "MB2",
    Callback = function(v)
        Settings.Aimbot.Key = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Aimlock Mode",
    Icon = "lucide:toggle-left",
    Values = {"Hold", "Toggle"},
    Value = "Hold",
    Callback = function(v)
        Settings.Aimbot.Mode = v
    end
})

Tabs.Combat:Toggle({
    Title = "Aimlock Wall Check",
    Icon = "lucide:brick-wall",
    Value = true,
    Callback = function(v)
        Settings.Aimbot.WallCheck = v
    end
})

Tabs.Combat:Toggle({
    Title = "Notify Target",
    Icon = "lucide:bell",
    Value = true,
    Callback = function(v)
        Settings.Aimbot.NotifyTarget = v
    end
})

Tabs.Combat:Section({Title = "Auto Features"})

Tabs.Combat:Toggle({
    Title = "Auto Shoot",
    Desc = "Shoots when target in aimlock FOV",
    Icon = "lucide:flame",
    Value = false,
    Callback = function(v)
        SetAutoShoot(v)
    end
})

Tabs.Combat:Toggle({
    Title = "Spinbot",
    Desc = "Auto-spin",
    Icon = "lucide:rotate-cw",
    Value = false,
    Callback = function(v)
        SetSpinbot(v)
    end
})

Tabs.Combat:Slider({
    Title = "Spin Speed",
    Icon = "lucide:gauge",
    Step = 1,
    Value = {Min = 1, Max = 100, Default = 30},
    Callback = function(v)
        Settings.Spinbot.Speed = v
    end
})

Tabs.Combat:Section({Title = "Trigger Bot"})

Tabs.Combat:Toggle({
    Title = "Trigger Bot",
    Desc = "Auto-shoot when aiming at target",
    Icon = "lucide:target",
    Value = false,
    Callback = function(v)
        Settings.TriggerBot.Enabled = v
    end
})

Tabs.Combat:Toggle({
    Title = "Trigger Bot Active",
    Desc = "Hold to activate trigger bot",
    Icon = "lucide:mouse-pointer-click",
    Value = false,
    Callback = function(v)
        Settings.TriggerBot.Held = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Trigger Method",
    Icon = "lucide:toggle-left",
    Values = {"Hold", "Click"},
    Value = "Hold",
    Callback = function(v)
        Settings.TriggerBot.Method = v
    end
})

Tabs.Combat:Slider({
    Title = "Click Delay (ms)",
    Icon = "lucide:timer",
    Step = 1,
    Value = {Min = 1, Max = 250, Default = 40},
    Callback = function(v)
        Settings.TriggerBot.ClickMs = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Trigger Parts",
    Icon = "lucide:target",
    Values = {"Head", "HumanoidRootPart", "Left Hand", "Right Hand", "Left Leg", "Right Leg"},
    Value = {"Head", "HumanoidRootPart"},
    Multi = true,
    Callback = function(v)
        Settings.TriggerBot.Part = v
    end
})

Tabs.Combat:Toggle({
    Title = "Team Check",
    Icon = "lucide:users",
    Value = false,
    Callback = function(v)
        Settings.TriggerBot.TeamCheck = v
    end
})

Tabs.Combat:Toggle({
    Title = "Wall Check",
    Icon = "lucide:brick-wall",
    Value = true,
    Callback = function(v)
        Settings.TriggerBot.WallCheck = v
    end
})

Tabs.Combat:Toggle({
    Title = "Ignore Downed",
    Icon = "lucide:heart-off",
    Value = true,
    Callback = function(v)
        Settings.TriggerBot.CheckDown = v
    end
})

Tabs.Combat:Toggle({
    Title = "Ignore ForceField",
    Icon = "lucide:shield",
    Value = true,
    Callback = function(v)
        Settings.TriggerBot.CheckForceField = v
    end
})

Tabs.Combat:Section({Title = "Bullet Tracers"})

Tabs.Combat:Toggle({
    Title = "Bullet Tracers",
    Desc = "Visual bullet beam effects",
    Icon = "lucide:move-right",
    Value = false,
    Callback = function(v)
        Settings.BulletTracer.Enabled = v
        if v then
            SetupBulletTracerConnections()
        else
            ClearBulletTracerConnections()
        end
    end
})

Tabs.Combat:Colorpicker({
    Title = "Tracer Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.BulletTracer.Color = c
    end
})

Tabs.Combat:Slider({
    Title = "Tracer Thickness",
    Icon = "lucide:minus",
    Step = 0.1,
    Value = {Min = 0.1, Max = 2, Default = 0.1},
    Callback = function(v)
        Settings.BulletTracer.Thick = v
    end
})

Tabs.Combat:Slider({
    Title = "Tracer Lifetime",
    Icon = "lucide:clock",
    Step = 0.1,
    Value = {Min = 0.1, Max = 10, Default = 2},
    Callback = function(v)
        Settings.BulletTracer.Life = v
    end
})

Tabs.Combat:Slider({
    Title = "Tracer Transparency",
    Icon = "lucide:opacity",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0.65},
    Callback = function(v)
        Settings.BulletTracer.Trans = v
    end
})

Tabs.Combat:Dropdown({
    Title = "Tracer Design",
    Icon = "lucide:sparkles",
    Values = {"Classic", "Rainbow"},
    Value = "Classic",
    Callback = function(v)
        Settings.BulletTracer.Design = v
    end
})

Tabs.Visual:Section({Title = "ESP"})

Tabs.Visual:Toggle({
    Title = "ESP",
    Desc = "Master ESP switch",
    Icon = "lucide:eye",
    Value = false,
    Callback = function(v)
        Settings.ESP.Enabled = v
    end
})

Tabs.Visual:Toggle({
    Title = "Corner Box",
    Icon = "lucide:square",
    Value = true,
    Callback = function(v)
        Settings.ESP.CornerBox = v
    end
})

Tabs.Visual:Toggle({
    Title = "Box Fill",
    Icon = "lucide:square-dot",
    Value = false,
    Callback = function(v)
        Settings.ESP.BoxFilled = v
    end
})

Tabs.Visual:Slider({
    Title = "Box Thickness",
    Icon = "lucide:minus",
    Step = 0.5,
    Value = {Min = 0.5, Max = 5, Default = 1.5},
    Callback = function(v)
        Settings.ESP.BoxThickness = v
    end
})

Tabs.Visual:Slider({
    Title = "Fill Transparency",
    Icon = "lucide:opacity",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0.3},
    Callback = function(v)
        Settings.ESP.BoxFillTransparency = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Box Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.BoxColor = c
    end
})

Tabs.Visual:Colorpicker({
    Title = "Fill Color",
    Icon = "lucide:paint-bucket",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.BoxFillColor = c
    end
})

Tabs.Visual:Section({Title = "Skeleton"})

Tabs.Visual:Toggle({
    Title = "Skeleton",
    Icon = "lucide:bone",
    Value = true,
    Callback = function(v)
        Settings.ESP.Skeleton = v
    end
})

Tabs.Visual:Slider({
    Title = "Skeleton Thickness",
    Icon = "lucide:minus",
    Step = 0.5,
    Value = {Min = 0.5, Max = 5, Default = 1},
    Callback = function(v)
        Settings.ESP.SkeletonThickness = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Skeleton Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(200, 200, 200),
    Callback = function(c)
        Settings.ESP.SkeletonColor = c
    end
})

Tabs.Visual:Section({Title = "Health Bar"})

Tabs.Visual:Toggle({
    Title = "Health Bar",
    Icon = "lucide:heart",
    Value = true,
    Callback = function(v)
        Settings.ESP.HealthBar = v
    end
})

Tabs.Visual:Dropdown({
    Title = "Health Bar Position",
    Icon = "lucide:move",
    Values = {"Left", "Right"},
    Value = "Left",
    Callback = function(v)
        Settings.ESP.HealthBarPosition = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Health Color (Low)",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.ESP.HealthBarColorLow = c
    end
})

Tabs.Visual:Colorpicker({
    Title = "Health Color (High)",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(c)
        Settings.ESP.HealthBarColorHigh = c
    end
})

Tabs.Visual:Section({Title = "Info"})

Tabs.Visual:Toggle({
    Title = "Name",
    Icon = "lucide:type",
    Value = true,
    Callback = function(v)
        Settings.ESP.Name = v
    end
})

Tabs.Visual:Toggle({
    Title = "Show Health in Name",
    Icon = "lucide:heart-pulse",
    Value = false,
    Callback = function(v)
        Settings.ESP.ShowHealthText = v
    end
})

Tabs.Visual:Toggle({
    Title = "Show Max Health",
    Icon = "lucide:heart-pulse",
    Value = false,
    Callback = function(v)
        Settings.ESP.ShowMaxHealth = v
    end
})

Tabs.Visual:Slider({
    Title = "Name Size",
    Icon = "lucide:text",
    Step = 1,
    Value = {Min = 8, Max = 24, Default = 14},
    Callback = function(v)
        Settings.ESP.NameSize = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Name Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.NameColor = c
    end
})

Tabs.Visual:Toggle({
    Title = "Distance",
    Icon = "lucide:ruler",
    Value = true,
    Callback = function(v)
        Settings.ESP.Distance = v
    end
})

Tabs.Visual:Slider({
    Title = "Distance Size",
    Icon = "lucide:text",
    Step = 1,
    Value = {Min = 8, Max = 24, Default = 13},
    Callback = function(v)
        Settings.ESP.DistanceSize = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Distance Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(c)
        Settings.ESP.DistanceColor = c
    end
})

Tabs.Visual:Toggle({
    Title = "Tool",
    Icon = "lucide:wrench",
    Value = true,
    Callback = function(v)
        Settings.ESP.Tool = v
    end
})

Tabs.Visual:Slider({
    Title = "Tool Size",
    Icon = "lucide:text",
    Step = 1,
    Value = {Min = 8, Max = 24, Default = 13},
    Callback = function(v)
        Settings.ESP.ToolSize = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Tool Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 255, 0),
    Callback = function(c)
        Settings.ESP.ToolColor = c
    end
})

Tabs.Visual:Toggle({
    Title = "Tracer",
    Icon = "lucide:move-right",
    Value = true,
    Callback = function(v)
        Settings.ESP.Tracer = v
    end
})

Tabs.Visual:Dropdown({
    Title = "Tracer Origin",
    Icon = "lucide:move",
    Values = {"Bottom", "Top", "Center", "Mouse"},
    Value = "Bottom",
    Callback = function(v)
        Settings.ESP.TracerOrigin = v
    end
})

Tabs.Visual:Slider({
    Title = "Tracer Thickness",
    Icon = "lucide:minus",
    Step = 0.5,
    Value = {Min = 0.5, Max = 5, Default = 1.5},
    Callback = function(v)
        Settings.ESP.TracerThickness = v
    end
})

Tabs.Visual:Colorpicker({
    Title = "Tracer Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.ESP.TracerColor = c
    end
})

Tabs.Visual:Section({Title = "Chams"})

Tabs.Visual:Toggle({
    Title = "Chams",
    Desc = "Highlight players through walls",
    Icon = "lucide:sparkles",
    Value = false,
    Callback = function(v)
        Settings.Chams.Enabled = v
        if v then
            UpdateAllChams()
        else
            for player, _ in pairs(ChamsObjects) do
                RemoveChams(player)
            end
        end
    end
})

Tabs.Visual:Colorpicker({
    Title = "Fill Color",
    Icon = "lucide:paint-bucket",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.Chams.FillColor = c
        UpdateAllChams()
    end
})

Tabs.Visual:Colorpicker({
    Title = "Outline Color",
    Icon = "lucide:palette",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.Chams.OutlineColor = c
        UpdateAllChams()
    end
})

Tabs.Visual:Slider({
    Title = "Fill Transparency",
    Icon = "lucide:opacity",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0.5},
    Callback = function(v)
        Settings.Chams.FillTransparency = v
        UpdateAllChams()
    end
})

Tabs.Visual:Slider({
    Title = "Outline Transparency",
    Icon = "lucide:opacity",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0},
    Callback = function(v)
        Settings.Chams.OutlineTransparency = v
        UpdateAllChams()
    end
})

Tabs.Visual:Dropdown({
    Title = "Depth Mode",
    Icon = "lucide:layers",
    Values = {"AlwaysOnTop", "Occluded"},
    Value = "AlwaysOnTop",
    Callback = function(v)
        Settings.Chams.DepthMode = v
        UpdateAllChams()
    end
})

Tabs.Visual:Section({Title = "Limits"})

Tabs.Visual:Slider({
    Title = "Max Distance",
    Icon = "lucide:ruler",
    Step = 10,
    Value = {Min = 100, Max = 5000, Default = 2000},
    Callback = function(v)
        Settings.ESP.MaxDistance = v
    end
})

Tabs.Misc:Section({Title = "Movement"})

Tabs.Misc:Toggle({
    Title = "Speedhack",
    Desc = "Velocity method (no kick)",
    Icon = "lucide:zap",
    Value = false,
    Callback = function(v)
        SetSpeedhack(v)
    end
})

Tabs.Misc:Slider({
    Title = "Speed",
    Icon = "lucide:gauge",
    Step = 1,
    Value = {Min = 20, Max = 200, Default = 80},
    Callback = function(v)
        Settings.Speedhack.Speed = v
    end
})

Tabs.Misc:Section({Title = "Stamina"})

Tabs.Misc:Toggle({
    Title = "Infinite Stamina",
    Desc = "Never run out of stamina",
    Icon = "lucide:battery-charging",
    Value = false,
    Callback = function(v)
        Settings.InfStamina.Enabled = v
    end
})

Tabs.Settings:Section({Title = "Config"})

local ConfigManager = Window.ConfigManager

Tabs.Settings:Input({
    Title = "Config Name",
    Icon = "lucide:file-text",
    Placeholder = "default",
    Value = "default",
    Callback = function(v)
        Window.CurrentConfig = ConfigManager:Config(v)
    end
})

Tabs.Settings:Button({
    Title = "Save Config",
    Desc = "Save current settings to file",
    Icon = "lucide:save",
    Callback = function()
        if Window.CurrentConfig and Window.CurrentConfig:Save() then
            WindUI:Notify({
                Title = "Config Saved",
                Content = "Configuration saved successfully!",
                Icon = "lucide:check",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Button({
    Title = "Load Config",
    Desc = "Load settings from file",
    Icon = "lucide:refresh-cw",
    Callback = function()
        if Window.CurrentConfig and Window.CurrentConfig:Load() then
            WindUI:Notify({
                Title = "Config Loaded",
                Content = "Configuration loaded successfully!",
                Icon = "lucide:check",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Section({Title = "Script"})

Tabs.Settings:Button({
    Title = "Unload Script",
    Desc = "Disconnect all connections and destroy UI",
    Icon = "lucide:trash-2",
    Callback = function()
        for _, connection in ipairs(Connections) do
            pcall(function() connection:Disconnect() end)
        end
        for _, connection in pairs(ActiveConnections) do
            pcall(function() connection:Disconnect() end)
        end
        ClearBulletTracerConnections()
        for player, data in pairs(ESPObjects) do
            for key, value in pairs(data) do
                if key == "Corner" or key == "CornerOutline" or key == "Skeleton" then
                    for _, line in pairs(value) do
                        pcall(function() line:Remove() end)
                    end
                else
                    pcall(function() value:Remove() end)
                end
            end
        end
        for player, _ in pairs(ChamsObjects) do
            RemoveChams(player)
        end
        Window:Destroy()
    end
})

Players.PlayerRemoving:Connect(function(player)
    RemoveChams(player)
    RemoveESP(player)
end)

InitESP()
InitSilentAim()
InitAimbot()
InitChams()
InitTriggerBot()
InitBulletTracers()
InitInfiniteStamina()

WindUI:Notify({
    Title = "Criminality Lite",
    Content = "Loaded successfully! Press G to toggle menu.",
    Icon = "lucide:check",
    Duration = 5
})
