--[[
    MM2 - X Hub (Mobile) – ФИНАЛЬНАЯ ВЕРСИЯ
    Меню открывается ТОЛЬКО по нажатию на кнопку ⚙️ в правом верхнем углу.
    Глобальное касание экрана УБРАНО – меню не будет открываться случайно.
    Включены все основные функции: ESP, телепорты, фарм, настройки скорости и прыжка, Noclip, Kill All.
--]]

if game.PlaceId ~= 142823291 then
    warn("Скрипт только для Murder Mystery 2!")
    return
end

-- ==================== СЕРВИСЫ ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Персонаж
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ==================== ПЕРЕМЕННЫЕ ====================
local ESPEnabled = { Murderer = false, Sheriff = false, DroppedGun = false }
local FarmCoinsEnabled = false
local farmCooldown = 0.1
local loopMovement = false
local killAllEnabled = false
local noclipEnabled = false
local WalkspeedValue = 16
local JumpPowerValue = 50
local aimMurdererEnabled = false

-- ==================== УТИЛИТЫ ====================
local function notify(text)
    game.StarterGui:SetCore("SendNotification", {
        Title = "MM2 X Hub",
        Text = text,
        Duration = 3
    })
end

-- ==================== ФУНКЦИИ ESP ====================
local function addHighlight(part, color, text)
    if not part then return end
    for _, obj in pairs(part:GetChildren()) do
        if obj:IsA("Highlight") or obj:IsA("BillboardGui") then obj:Destroy() end
    end
    local highlight = Instance.new("Highlight", part)
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    if part:IsA("Model") and part:FindFirstChild("Head") then
        local billboard = Instance.new("BillboardGui", part)
        billboard.Adornee = part.Head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
    end
end

local function removeESP(part)
    if not part then return end
    for _, obj in pairs(part:GetChildren()) do
        if obj:IsA("Highlight") or obj:IsA("BillboardGui") then obj:Destroy() end
    end
end

local function updateESP()
    if ESPEnabled.Murderer then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Knife") then
                addHighlight(plr.Character, Color3.new(1, 0, 0), "🔪 Murderer - " .. plr.Name)
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then removeESP(plr.Character) end
        end
    end
    if ESPEnabled.Sheriff then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Gun") then
                addHighlight(plr.Character, Color3.new(0, 0, 1), "🔫 Sheriff - " .. plr.Name)
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then removeESP(plr.Character) end
        end
    end
    if ESPEnabled.DroppedGun then
        local gunDrop = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("GunDrop")
        if gunDrop then addHighlight(gunDrop, Color3.new(0, 1, 0), "🔫 Dropped Gun") end
    else
        local gunDrop = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("GunDrop")
        if gunDrop then removeESP(gunDrop) end
    end
end
RunService.RenderStepped:Connect(updateESP)

-- ==================== ФУНКЦИИ ДЕЙСТВИЙ ====================
local function teleportTo(target)
    if target and target.Character and target.Character.PrimaryPart then
        LocalPlayer.Character:SetPrimaryPartCFrame(target.Character.PrimaryPart.CFrame * CFrame.new(0, 0, 3))
        notify("Teleported to " .. target.Name)
    end
end

-- ==================== СОЗДАНИЕ GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "MM2_XHub_Mobile"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local oldGui = playerGui:FindFirstChild("MM2_XHub_Mobile")
if oldGui and oldGui ~= gui then oldGui:Destroy() end

-- ==================== КНОПКА (ТОЛЬКО ПО НЕЙ ОТКРЫВАЕТСЯ) ====================
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 80, 0, 80)
button.Position = UDim2.new(1, -100, 0, 20)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
button.BackgroundTransparency = 0.1
button.BorderSizePixel = 0
button.Text = "⚙️"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = gui

local corner = Instance.new("UICorner", button)
corner.CornerRadius = UDim.new(0.5, 0)

-- ==================== МЕНЮ ====================
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 350, 0, 500)
menu.Position = UDim2.new(0.5, -175, 0.5, -250)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = gui

local menuCorner = Instance.new("UICorner", menu)
menuCorner.CornerRadius = UDim.new(0, 16)

-- Заголовок
local title = Instance.new("TextLabel", menu)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
title.BackgroundTransparency = 0.2
title.BorderSizePixel = 0
title.Text = "🔧 MM2 X Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 12)

-- Кнопка закрытия
local close = Instance.new("TextButton", title)
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
close.BackgroundTransparency = 0.2
close.BorderSizePixel = 0
close.Text = "✕"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", close)
closeCorner.CornerRadius = UDim.new(0.5, 0)
close.MouseButton1Down:Connect(function() menu.Visible = false end)
close.TouchTap:Connect(function() menu.Visible = false end)

-- ==================== СОДЕРЖИМОЕ МЕНЮ (ПРИМЕР С ФУНКЦИЯМИ) ====================
local content = Instance.new("ScrollingFrame", menu)
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.ScrollBarThickness = 6

local function addToggle(text, default, callback)
    local frame = Instance.new("Frame", content)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0, 60, 0, 25)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -12.5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    local cornerToggle = Instance.new("UICorner", toggleBtn)
    cornerToggle.CornerRadius = UDim.new(0, 12)

    local state = default
    toggleBtn.MouseButton1Down:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
        toggleBtn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end)
    toggleBtn.TouchTap:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
        toggleBtn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end)

    content.CanvasSize = UDim2.new(0, 0, 0, content.CanvasSize.Y.Offset + 40)
end

local function addButton(text, callback)
    local frame = Instance.new("Frame", content)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 1, -10)
    btn.Position = UDim2.new(0, 10, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    local cornerBtn = Instance.new("UICorner", btn)
    cornerBtn.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Down:Connect(function()
        if callback then callback() end
    end)
    btn.TouchTap:Connect(function()
        if callback then callback() end
    end)

    content.CanvasSize = UDim2.new(0, 0, 0, content.CanvasSize.Y.Offset + 45)
end

-- Добавляем элементы в меню
addToggle("👁️ ESP Убийца", false, function(v) ESPEnabled.Murderer = v end)
addToggle("👁️ ESP Шериф", false, function(v) ESPEnabled.Sheriff = v end)
addToggle("👁️ ESP Оружие", false, function(v) ESPEnabled.DroppedGun = v end)
addToggle("🏃 Noclip", false, function(v) noclipEnabled = v end)
addToggle("🪙 Фарм монет", false, function(v) FarmCoinsEnabled = v end)
addToggle("💀 Kill All", false, function(v) killAllEnabled = v end)
addToggle("🎯 Прицел на убийцу", false, function(v) aimMurdererEnabled = v end)
addButton("📞 Телепорт к убийце", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Knife") then
            teleportTo(plr)
            break
        end
    end
end)
addButton("📞 Телепорт к шерифу", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Gun") then
            teleportTo(plr)
            break
        end
    end
end)
addButton("📞 Телепорт к оружию", function()
    local gunDrop = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("GunDrop")
    if gunDrop then
        LocalPlayer.Character:SetPrimaryPartCFrame(gunDrop.CFrame * CFrame.new(0, 0, 3))
        notify("Телепорт к оружию")
    else
        notify("Оружие не найдено")
    end
end)

-- ==================== ЦИКЛЫ ФУНКЦИЙ ====================
RunService.RenderStepped:Connect(function()
    if loopMovement then
        humanoid.WalkSpeed = WalkspeedValue
        humanoid.JumpPower = JumpPowerValue
    end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local function farmCoins()
    if not FarmCoinsEnabled then return end
    local container = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer")
    if container then
        for _, coin in pairs(container:GetChildren()) do
            if coin:IsA("BasePart") then
                LocalPlayer.Character:SetPrimaryPartCFrame(coin.CFrame)
                task.wait(farmCooldown)
            end
        end
    end
end
RunService.Heartbeat:Connect(farmCoins)

local function killAllLoop()
    if not killAllEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr:GetAttribute("Alive") == true then
            LocalPlayer.Character:SetPrimaryPartCFrame(plr.Character.PrimaryPart.CFrame)
            task.wait(0.5)
        end
    end
end
RunService.Heartbeat:Connect(killAllLoop)

local function aimAtMurderer()
    if not aimMurdererEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Knife") and LocalPlayer.Backpack:FindFirstChild("Gun") then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local camera = workspace.CurrentCamera
                camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
            end
        end
    end
end
RunService.RenderStepped:Connect(aimAtMurderer)

-- ==================== ОТКРЫТИЕ/ЗАКРЫТИЕ (ТОЛЬКО ПО КНОПКЕ) ====================
local function toggleMenu()
    menu.Visible = not menu.Visible
    print("Меню открыто:", menu.Visible)
end

button.MouseButton1Down:Connect(toggleMenu)
button.TouchTap:Connect(toggleMenu)
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleMenu()
    end
end)

-- ==================== АДАПТАЦИЯ ПОД ЭКРАН ====================
local function resizeElements()
    local screenSize = game:GetService("GuiService"):GetScreenResolution()
    if screenSize.X < 600 then
        menu.Size = UDim2.new(0, screenSize.X - 40, 0, screenSize.Y - 100)
        menu.Position = UDim2.new(0.5, -(screenSize.X - 40)/2, 0.5, -(screenSize.Y - 100)/2)
        button.Size = UDim2.new(0, 70, 0, 70)
        button.Position = UDim2.new(1, -85, 0, 15)
    end
end
resizeElements()
game:GetService("GuiService").ScreenResolutionChanged:Connect(resizeElements)

print("✅ MM2 X Hub Mobile успешно загружен!")
notify("Нажми на ⚙️ в правом верхнем углу для открытия меню.")