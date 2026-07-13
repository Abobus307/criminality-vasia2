local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

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
        Smoothness = 0.15,
        Prediction = 0.165,
        FOV = 200,
        TargetPart = "Head",
        WallCheck = true,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
        Key = "MB2",
        Mode = "Hold",
        Active = false,
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
}

local ESPObjects = {}
local ChamsObjects = {}
local Connections = {}
local ActiveConnections = {}
local SilentAimTarget = nil
local AimbotTarget = nil

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
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end
        if config.CheckDowned and IsDowned(player) then continue end
        if config.CheckForceField and HasForceField(player) then continue end

        local character = GetCharacter(player)
        if not character then continue end
        local part = character:FindFirstChild(config.TargetPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local distance2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distance2D > shortest then continue end
        if config.WallCheck and not IsVisible(part) then continue end

        closest = player
        shortest = distance2D
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
        HealthBar = NewDrawing("Line", {Thickness = 2, Visible = false}),
        HealthBarOutline = NewDrawing("Line", {Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false}),
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
            barX = position.X - 8
            barY = position.Y
        elseif Settings.ESP.HealthBarPosition == "Right" then
            barX = position.X + width + 8
            barY = position.Y
        else
            barX = position.X - 8
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
        local map = isR15 and {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        } or {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Left Arm", "Left Leg"},
            {"Torso", "Right Arm"}, {"Right Arm", "Right Leg"},
            {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
        }
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
            index += 1
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
            if player == LocalPlayer then continue end
            CreateESPObject(player)
            UpdateESP(player)
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

    local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
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
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
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

Window:SetToggleKey(Enum.KeyCode.G)

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

CombatTab:Dropdown({
    Flag = "AimbotKey",
    Title = "Aimbot Key",
    Values = { "MB1", "MB2", "Q", "E", "F", "X", "Z", "C" },
    Value = "MB2",
    Callback = function(v)
        Settings.Aimbot.Key = v
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

CombatTab:Space()

CombatTab:Toggle({
    Flag = "AutoShootToggle",
    Title = "Auto Shoot",
    Desc = "Shoots when target in aimbot FOV",
    Default = false,
    Callback = function(v)
        SetAutoShoot(v)
    end
})

CombatTab:Space()

CombatTab:Toggle({
    Flag = "SpinbotToggle",
    Title = "Spinbot",
    Desc = "Auto-spin",
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
    Flag = "ESPCornerBox",
    Title = "Corner Box",
    Default = true,
    Callback = function(v)
        Settings.ESP.CornerBox = v
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
    Flag = "ChamsToggle",
    Title = "Chams",
    Desc = "Highlight players through walls",
    Default = false,
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

VisualTab:Colorpicker({
    Flag = "ChamsFillColor",
    Title = "Fill Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.Chams.FillColor = c
        UpdateAllChams()
    end
})

VisualTab:Colorpicker({
    Flag = "ChamsOutlineColor",
    Title = "Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Settings.Chams.OutlineColor = c
        UpdateAllChams()
    end
})

VisualTab:Slider({
    Flag = "ChamsFillTransparency",
    Title = "Fill Transparency",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        Settings.Chams.FillTransparency = v
        UpdateAllChams()
    end
})

VisualTab:Slider({
    Flag = "ChamsOutlineTransparency",
    Title = "Outline Transparency",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0 },
    Callback = function(v)
        Settings.Chams.OutlineTransparency = v
        UpdateAllChams()
    end
})

VisualTab:Dropdown({
    Flag = "ChamsDepthMode",
    Title = "Depth Mode",
    Values = { "AlwaysOnTop", "Occluded" },
    Value = "AlwaysOnTop",
    Callback = function(v)
        Settings.Chams.DepthMode = v
        UpdateAllChams()
    end
})

VisualTab:Space()

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
        for _, connection in ipairs(Connections) do
            pcall(function() connection:Disconnect() end)
        end
        for _, connection in pairs(ActiveConnections) do
            pcall(function() connection:Disconnect() end)
        end
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

WindUI:Notify({
    Title = "Criminality Lite",
    Content = "Loaded successfully! Use the open button to toggle UI.",
    Icon = "check",
    Duration = 5,
})
