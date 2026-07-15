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
        TeamCheck = false,
        ShowFOV = true,
        CheckDowned = true,
        CheckForceField = true,
    },
    ESP = {
        Enabled = false,
        Chams = true,
        ChamsColor = Color3.fromRGB(255, 0, 0),
        ChamsOutlineColor = Color3.fromRGB(0, 0, 0),
        ChamsFillTransparency = 0.5,
        ChamsOutlineTransparency = 0,
        Name = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 14,
        ShowHealthText = false,
        ShowMaxHealth = false,
        Distance = true,
        Tool = true,
        TeamCheck = false,
        MaxDistance = 2000,
        DistanceColor = Color3.fromRGB(0, 255, 255),
        ToolColor = Color3.fromRGB(255, 255, 0),
        DistanceSize = 13,
        ToolSize = 13,
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
    }
}

local ESPObjects = {}
local Connections = {}
local SilentAimTarget = nil
local AimbotTarget = nil

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

local function HideAllESP(data)
    if data.Name then data.Name.Visible = false end
    if data.Distance then data.Distance.Visible = false end
    if data.Tool then data.Tool.Visible = false end
    if data.Chams then
        pcall(function()
            data.Chams.Enabled = false
            data.Chams.Adornee = nil
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
                local highlight = Instance.new("Highlight")
                highlight.Name = "ChamsESP"
                highlight.FillColor = Settings.ESP.ChamsColor
                highlight.OutlineColor = Settings.ESP.ChamsOutlineColor
                highlight.FillTransparency = Settings.ESP.ChamsFillTransparency
                highlight.OutlineTransparency = Settings.ESP.ChamsOutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = false
                highlight.Parent = char

                ESPObjects[plr] = {
                    Chams = highlight,
                    Name = NewDrawing("Text", {Size = Settings.ESP.NameSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.NameColor, Visible = false}),
                    Distance = NewDrawing("Text", {Size = Settings.ESP.DistanceSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.DistanceColor, Visible = false}),
                    Tool = NewDrawing("Text", {Size = Settings.ESP.ToolSize, Center = true, Outline = true, Font = 2, Color = Settings.ESP.ToolColor, Visible = false}),
                }
            end

            local data = ESPObjects[plr]
            local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

            if not onScreen or not headPos then
                HideAllESP(data)
                continue
            end

            if Settings.ESP.Chams then
                pcall(function()
                    data.Chams.Adornee = char
                    data.Chams.FillColor = Settings.ESP.ChamsColor
                    data.Chams.OutlineColor = Settings.ESP.ChamsOutlineColor
                    data.Chams.FillTransparency = Settings.ESP.ChamsFillTransparency
                    data.Chams.OutlineTransparency = Settings.ESP.ChamsOutlineTransparency
                    data.Chams.Enabled = true
                end)
            else
                pcall(function() data.Chams.Enabled = false end)
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
                data.Name.Position = Vector2.new(sp.X, headPos.Y - 20)
                data.Name.Color = Settings.ESP.NameColor
                data.Name.Size = Settings.ESP.NameSize
                data.Name.Visible = true
            else
                data.Name.Visible = false
            end

            if Settings.ESP.Distance then
                data.Distance.Text = string.format("[%dm]", math.floor(dist))
                data.Distance.Position = Vector2.new(sp.X, sp.Y + 20)
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
                    data.Tool.Position = Vector2.new(sp.X, sp.Y + 34)
                    data.Tool.Color = Settings.ESP.ToolColor
                    data.Tool.Size = Settings.ESP.ToolSize
                    data.Tool.Visible = true
                else
                    data.Tool.Visible = false
                end
            else
                data.Tool.Visible = false
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if ESPObjects[plr] then
            local d = ESPObjects[plr]
            pcall(function() d.Chams:Destroy() end)
            pcall(function() d.Name:Remove() end)
            pcall(function() d.Distance:Remove() end)
            pcall(function() d.Tool:Remove() end)
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

local function InitAimbot()
    local fovCircle = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Transparency = 0.5, Visible = false, Color = Color3.fromRGB(255, 255, 255), NumSides = 64})
    Settings.Aimbot.FOVCircle = fovCircle

    local inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local key = Settings.Aimbot.Key
        local match = false
        if key == "MB1" and input.UserInputType == Enum.UserInputType.MouseButton1 then match = true
        elseif key == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2 then match = true
        elseif input.KeyCode == Enum.KeyCode[key] then match = true end

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
            if key == "MB1" and input.UserInputType == Enum.UserInputType.MouseButton1 then match = true
            elseif key == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2 then match = true
            elseif input.KeyCode == Enum.KeyCode[key] then match = true end

            if match then
                Settings.Aimbot.Active = false
                AimbotTarget = nil
            end
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
    Title = "Vasia2 Lab",
    Icon = "crosshair",
    Folder = "Vasia2Lab",
    OpenButton = {
        Title = "Open Vasia2 Lab",
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
    Flag = "ESPChams",
    Title = "Chams",
    Default = true,
    Callback = function(v)
        Settings.ESP.Chams = v
    end
})

VisualTab:Colorpicker({
    Flag = "ESPChamsColor",
    Title = "Chams Fill Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c)
        Settings.ESP.ChamsColor = c
    end
})

VisualTab:Colorpicker({
    Flag = "ESPChamsOutlineColor",
    Title = "Chams Outline Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(c)
        Settings.ESP.ChamsOutlineColor = c
    end
})

VisualTab:Slider({
    Flag = "ESPChamsFillTrans",
    Title = "Fill Transparency",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        Settings.ESP.ChamsFillTransparency = v
    end
})

VisualTab:Slider({
    Flag = "ESPChamsOutlineTrans",
    Title = "Outline Transparency",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0 },
    Callback = function(v)
        Settings.ESP.ChamsOutlineTransparency = v
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
        for plr, data in pairs(ESPObjects) do
            pcall(function() data.Chams:Destroy() end)
            pcall(function() data.Name:Remove() end)
            pcall(function() data.Distance:Remove() end)
            pcall(function() data.Tool:Remove() end)
        end
        Window:Destroy()
    end
})

InitESP()
InitSilentAim()
InitAimbot()

WindUI:Notify({
    Title = "Vasia2 Lab",
    Content = "Loaded successfully!",
    Icon = "check",
    Duration = 5,
})
