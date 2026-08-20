if not hookfunction then return end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if not LocalPlayer then return end

local target = nil
local dddEnabled = false
local aimFOV = 200
local jumpTrailEnabled = false
local autofireEnabled = false
local lastFire = 0
local fireDelay = 0.03
local bhopEnabled = false
local spaceHeld = false
local humanoid = nil
local trailEnabled = false
local trailColor = Color3.fromRGB(200, 0, 255)
local trailDuration = 0.5
local chamsEnabled = false

local Settings = {
    ESP = false,
    HP = false,
    Night = false,
    Darkness = 0.7,
    Ddd = false,
    JumpTrail = false,
    Autofire = false,
    Bhop = false,
    Trail = false,
    Chams = false
}

local original = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local highlights = {}
local chamsObjects = {}

-- ============================
-- TRAIL (ТОНКИЙ ФИОЛЕТОВЫЙ)
-- ============================
local function createRayTrail(origin, targetPos, color)
    if not trailEnabled then return end

    local direction = (targetPos - origin)
    local distance = direction.Magnitude

    if distance < 1 then return end

    local part = Instance.new("Part")
    part.Name = "RayTrail"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = color or trailColor
    part.Transparency = 0
    part.Size = Vector3.new(0.05, 0.05, distance)
    part.CFrame = CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -distance / 2)
    part.Parent = Workspace

    local glow = Instance.new("PointLight")
    glow.Color = part.Color
    glow.Range = 4
    glow.Brightness = 1.5
    glow.Parent = part

    task.spawn(function()
        local startTime = tick()
        local duration = trailDuration

        while part.Parent and tick() - startTime < duration do
            local alpha = 1 - (tick() - startTime) / duration
            part.Transparency = 1 - alpha
            if glow then
                glow.Brightness = 1.5 * alpha
                glow.Range = 4 * alpha
            end
            task.wait()
        end

        part:Destroy()
    end)
end

-- ============================
-- ОТСЛЕЖИВАНИЕ ВЫСТРЕЛОВ
-- ============================
local function getAimTarget()
    if dddEnabled and target then
        return target.Position
    else
        local cam = Workspace.CurrentCamera
        if not cam then return nil end

        local origin = cam.CFrame.Position
        local direction = cam.CFrame.LookVector * 500

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.IgnoreWater = true

        local result = Workspace:Raycast(origin, direction, params)
        return result and result.Position or (origin + direction)
    end
end

local function onShoot()
    if not trailEnabled then return end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local origin = cam.CFrame.Position
    local targetPos = getAimTarget()

    if targetPos then
        createRayTrail(origin, targetPos, trailColor)
    end
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.spawn(onShoot)
    end
end)

local oldActivate
pcall(function()
    oldActivate = hookfunction(Instance.new("Tool").Activate, function(self)
        if trailEnabled then
            task.spawn(onShoot)
        end
        return oldActivate(self)
    end)
end)

-- ============================
-- CHAMS
-- ============================
local function removeChams(player)
    local obj = chamsObjects[player]
    if obj then
        pcall(function() obj:Destroy() end)
        chamsObjects[player] = nil
    end
end

local function addChams(player)
    if player == LocalPlayer then return end
    if not chamsEnabled then return end

    local character = player.Character
    if not character then return end

    removeChams(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "SWILL_Chams"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0.5
    highlight.FillColor = Color3.fromRGB(200, 0, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = character

    chamsObjects[player] = highlight
end

local function updateChams()
    if chamsEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                addChams(player)
            end
        end
    else
        for player, _ in pairs(chamsObjects) do
            removeChams(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if chamsEnabled then addChams(player) end
    end)
end)

Players.PlayerRemoving:Connect(removeChams)

-- ============================
-- JUMP TRAIL
-- ============================
local RING_SIZE = 10
local DURATION = 0.8
local COLOR = Color3.fromRGB(255, 255, 255)

local function createJumpRing(position)
    if not jumpTrailEnabled then return end

    local part = Instance.new("Part")
    part.Name = "JumpRing"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Size = Vector3.new(1, 0.05, 1)
    part.Position = Vector3.new(position.X, position.Y - 3, position.Z)
    part.Parent = Workspace

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Top
    surface.AlwaysOnTop = true
    surface.LightInfluence = 0
    surface.Parent = part

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.Image = "rbxassetid://266543268"
    image.ImageColor3 = COLOR
    image.ImageTransparency = 0.1
    image.Parent = surface

    local grow = TweenService:Create(part, TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(RING_SIZE, 0.05, RING_SIZE)
    })

    local fade = TweenService:Create(image, TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = 1
    })

    grow:Play()
    fade:Play()

    task.delay(DURATION + 0.1, function()
        if part then part:Destroy() end
    end)
end

local function setupJumpDetection()
    local char = LocalPlayer.Character
    if not char then return end
    humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            createJumpRing(root.Position)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    setupJumpDetection()
end)

setupJumpDetection()

-- ============================
-- BHOP
-- ============================
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = false
    end
end)

task.spawn(function()
    while true do
        task.wait()
        if Settings.Bhop and spaceHeld and humanoid and humanoid.Health > 0 then
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- ============================
-- AUTOFIRE
-- ============================
local function doAutofire()
    if not target or not autofireEnabled then return end
    local now = tick()
    if now - lastFire < fireDelay then return end
    lastFire = now

    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
        task.spawn(onShoot)
    end

    if VIM then
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.spawn(onShoot)
    end
end

-- ============================
-- DDD (SILENT AIM)
-- ============================
local function isVisible(targetPart)
    if not targetPart or not targetPart:IsA("BasePart") then return false end
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local origin = cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    params.IgnoreWater = true
    local direction = (targetPart.Position - origin).Unit * 500
    local result = Workspace:Raycast(origin, direction, params)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then
            return true
        end
        return false
    else
        return true
    end
end

local function isEnemy(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local upperTorso = char:FindFirstChild("UpperTorso")
    if not upperTorso then return false end
    local status = player:FindFirstChild("Status")
    if not status then return false end
    local team = status:FindFirstChild("Team")
    if not team or team.Value == "Spectator" then return false end
    local localStatus = LocalPlayer:FindFirstChild("Status")
    if not localStatus then return false end
    local localTeam = localStatus:FindFirstChild("Team")
    if not localTeam then return false end
    if team.Value == localTeam.Value then return false end
    local alive = status:FindFirstChild("Alive")
    if not alive or not alive.Value then return false end
    return true
end

local function getClosestPlayer()
    local closestDistance = math.huge
    local closest = nil
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp:IsA("BasePart") then continue end
        local head = char:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - camera.ViewportSize / 2).Magnitude
            if distance < closestDistance and distance < aimFOV then
                if not isVisible(head) then continue end
                closestDistance = distance
                closest = head
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if dddEnabled then
        target = getClosestPlayer()
    else
        target = nil
    end
    doAutofire()
end)

local oldRay
pcall(function()
    oldRay = hookfunction(Ray.new, function(origin, direction)
        if target and target:IsA("BasePart") then
            direction = (target.Position - origin).Unit * 500
        end
        return oldRay(origin, direction)
    end)
end)

-- ============================
-- NIGHT
-- ============================
local function updateNight()
    if not Settings.Night then
        Lighting.ClockTime = original.ClockTime
        Lighting.Brightness = original.Brightness
        Lighting.Ambient = original.Ambient
        Lighting.OutdoorAmbient = original.OutdoorAmbient
        return
    end
    local s = math.clamp(Settings.Darkness, 0, 1)
    Lighting.ClockTime = 0
    Lighting.Brightness = math.max(0.05, original.Brightness * (1 - 0.9 * s))
    Lighting.Ambient = original.Ambient:Lerp(Color3.fromRGB(8, 8, 18), s)
    Lighting.OutdoorAmbient = original.OutdoorAmbient:Lerp(Color3.fromRGB(5, 5, 12), s)
end

-- ============================
-- ESP
-- ============================
local function removeESP(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
    if player.Character then
        local old = player.Character:FindFirstChild("ESPHighlight")
        if old then old:Destroy() end
        local hp = player.Character:FindFirstChild("ESP_HP")
        if hp then hp:Destroy() end
    end
end

local function addHP(character)
    if not Settings.HP then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local old = character:FindFirstChild("ESP_HP")
    if old then old:Destroy() end
    local hp = Instance.new("Highlight")
    hp.Name = "ESP_HP"
    hp.Adornee = character
    hp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hp.OutlineTransparency = 1
    hp.FillTransparency = 0.35
    hp.Parent = character
    task.spawn(function()
        while hp.Parent and humanoid.Parent do
            local health = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            if health > 0.6 then
                hp.FillColor = Color3.fromRGB(50, 220, 80)
            elseif health > 0.3 then
                hp.FillColor = Color3.fromRGB(255, 190, 50)
            else
                hp.FillColor = Color3.fromRGB(235, 60, 60)
            end
            task.wait(0.1)
        end
    end)
end

local function addESP(player)
    if player == LocalPlayer then return end
    if not Settings.ESP then return end
    if player.Team == LocalPlayer.Team then return end
    local character = player.Character
    if not character then return end
    removeESP(player)
    local h = Instance.new("Highlight")
    h.Name = "ESPHighlight"
    h.Adornee = character
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = Color3.fromRGB(255, 60, 60)
    h.Parent = character
    highlights[player] = h
    addHP(character)
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP then
                addESP(player)
            else
                removeESP(player)
            end
        end
    end
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        addESP(player)
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        addESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- ============================
-- МЕНЮ
-- ============================
local gui = Instance.new("ScreenGui")
gui.Name = "Menu"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(200, 360)
frame.Position = UDim2.new(0.5, -100, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = frame

local function makeButton(text, y, get, set)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text .. " • " .. (get() and "ON" or "OFF")
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    btn.MouseButton1Click:Connect(function()
        set(not get())
        btn.Text = text .. " • " .. (get() and "ON" or "OFF")
        if text == "ESP" then updateESP() end
        if text == "Night" then updateNight() end
        if text == "Chams" then updateChams() end
    end)
    return btn
end

makeButton("ESP", 35, function() return Settings.ESP end, function(v) Settings.ESP = v end)
makeButton("HP", 68, function() return Settings.HP end, function(v) Settings.HP = v end)
makeButton("Ddd", 101, function() return Settings.Ddd end, function(v) Settings.Ddd = v dddEnabled = v end)
makeButton("Autofire", 134, function() return Settings.Autofire end, function(v) Settings.Autofire = v autofireEnabled = v end)
makeButton("JumpTrail", 167, function() return Settings.JumpTrail end, function(v) Settings.JumpTrail = v jumpTrailEnabled = v end)
makeButton("Bhop", 200, function() return Settings.Bhop end, function(v) Settings.Bhop = v end)
makeButton("Trail", 233, function() return Settings.Trail end, function(v) 
    Settings.Trail = v
    trailEnabled = v
end)
makeButton("Chams", 266, function() return Settings.Chams end, function(v) 
    Settings.Chams = v
    chamsEnabled = v
    updateChams()
end)
makeButton("Night", 299, function() return Settings.Night end, function(v) Settings.Night = v end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 60, 0, 25)
closeBtn.Position = UDim2.new(0.5, -30, 1, -30)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 6)
cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromOffset(40, 40)
openBtn.Position = UDim2.new(0, 10, 1, -60)
openBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
openBtn.Text = "⚙"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextSize = 20
openBtn.Font = Enum.Font.GothamBold
openBtn.BorderSizePixel = 0
openBtn.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0, 10)
oc.Parent = openBtn
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        frame.Visible = not frame.Visible
    end
end)

-- ============================
-- INIT
-- ============================
task.wait(0.5)
updateChams()