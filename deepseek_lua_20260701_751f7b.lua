--[[
    MM2 - X Hub (Mobile) – ПОЛНАЯ ВЕРСИЯ
    Компактное меню с вкладками: ESP, Movement, Utility, Settings.
    Все функции из оригинального скрипта сохранены.
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
local GravityValue = 196.2
local aimMurdererEnabled = false

-- ==================== УТИЛИТЫ ====================
local function notify(text)
    game.StarterGui:SetCore("SendNotification", {
        Title = "MM2 X Hub",
        Text = text,
        Duration = 3
    })
end

-- ==================== ФУНКЦИИ ESP (БЕЗ ИЗМЕНЕНИЙ) ====================
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
    -- Убийца
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
    -- Шериф
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
    -- Оружие
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

-- ==================== КНОПКА ОТКРЫТИЯ ====================
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 70, 0, 70)
button.Position = UDim2.new(1, -85, 0, 15)
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

-- ==================== ОСНОВНОЕ МЕНЮ (КОМПАКТНОЕ) ====================
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 320, 0, 400)
menu.Position = UDim2.new(0.5, -160, 0.5, -200)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = gui

local menuCorner = Instance.new("UICorner", menu)
menuCorner.CornerRadius = UDim.new(0, 16)

-- Заголовок с вкладками
local titleBar = Instance.new("Frame", menu)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔧 MM2 X Hub"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0.5, 0)
closeBtn.MouseButton1Down:Connect(function() menu.Visible = false end)
closeBtn.TouchTap:Connect(function() menu.Visible = false end)

-- Контейнер для вкладок (кнопки переключения)
local tabsContainer = Instance.new("Frame", menu)
tabsContainer.Size = UDim2.new(1, 0, 0, 35)
tabsContainer.Position = UDim2.new(0, 0, 0, 40)
tabsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tabsContainer.BackgroundTransparency = 0.2
tabsContainer.BorderSizePixel = 0

local tabNames = {"ESP", "Move", "Util", "Set"}
local tabButtons = {}
local currentTab = 1

local function createTabButton(name, index)
    local btn = Instance.new("TextButton", tabsContainer)
    btn.Size = UDim2.new(0.25, -2, 1, -4)
    btn.Position = UDim2.new((index-1)*0.25, 1, 0, 2)
    btn.BackgroundColor3 = index == 1 and Color3.fromRGB(70, 70, 90) or Color3.fromRGB(40, 40, 55)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Down:Connect(function()
        switchTab(index)
    end)
    btn.TouchTap:Connect(function()
        switchTab(index)
    end)
    return btn
end

-- Контейнер для содержимого вкладок (скроллинг)
local contentContainer = Instance.new("Frame", menu)
contentContainer.Size = UDim2.new(1, 0, 1, -80)
contentContainer.Position = UDim2.new(0, 0, 0, 75)
contentContainer.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", contentContainer)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4

-- Создаём вкладки (каждая – отдельный Frame внутри scroll)
local tabContents = {}
for i = 1, 4 do
    local frame = Instance.new("Frame", scroll)
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    tabContents[i] = frame
end

-- Функция переключения вкладок
local function switchTab(index)
    currentTab = index
    for i, frame in pairs(tabContents) do
        frame.Visible = (i == index)
    end
    for i, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (i == index) and Color3.fromRGB(70, 70, 90) or Color3.fromRGB(40, 40, 55)
    end
    -- Обновляем CanvasSize
    local totalHeight = 0
    for _, child in pairs(tabContents[index]:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 5
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

tabButtons[1] = createTabButton("ESP", 1)
tabButtons[2] = createTabButton("Движ", 2)
tabButtons[3] = createTabButton("Утил", 3)
tabButtons[4] = createTabButton("Настр", 4)

-- ==================== ФУНКЦИИ ДОБАВЛЕНИЯ ЭЛЕМЕНТОВ В ВКЛАДКИ ====================
local function addToggle(tabIndex, text, default, callback)
    local frame = Instance.new("Frame", tabContents[tabIndex])
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.Position = UDim2.new(0, 5, 0, #tabContents[tabIndex]:GetChildren() * 35)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0, 50, 0, 22)
    toggleBtn.Position = UDim2.new(1, -55, 0.5, -11)
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

    -- Обновляем CanvasSize
    local totalHeight = 0
    for _, child in pairs(tabContents[tabIndex]:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 5
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

local function addSlider(tabIndex, text, min, max, default, callback)
    local frame = Instance.new("Frame", tabContents[tabIndex])
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.Position = UDim2.new(0, 5, 0, #tabContents[tabIndex]:GetChildren() * 55)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 0.4, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame", frame)
    slider.Size = UDim2.new(0.7, 0, 0, 6)
    slider.Position = UDim2.new(0.1, 0, 0.65, 0)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    slider.BorderSizePixel = 0
    local cornerSlider = Instance.new("UICorner", slider)
    cornerSlider.CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    local cornerFill = Instance.new("UICorner", fill)
    cornerFill.CornerRadius = UDim.new(0, 3)

    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
    valueLabel.Position = UDim2.new(0.8, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.SourceSansBold

    local dragging = false
    local function updateSlider(input)
        local pos = input.Position.X - slider.AbsolutePosition.X
        local width = slider.AbsoluteSize.X
        local percent = math.clamp(pos / width, 0, 1)
        local value = math.round(min + percent * (max - min))
        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value)
        label.Text = text .. ": " .. tostring(value)
        if callback then callback(value) end
    end

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    slider.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateSlider(input)
        end
    end)

    -- Обновляем CanvasSize
    local totalHeight = 0
    for _, child in pairs(tabContents[tabIndex]:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 5
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

local function addButton(tabIndex, text, callback)
    local frame = Instance.new("Frame", tabContents[tabIndex])
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.Position = UDim2.new(0, 5, 0, #tabContents[tabIndex]:GetChildren() * 40)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 1, -6)
    btn.Position = UDim2.new(0, 5, 0, 3)
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

    -- Обновляем CanvasSize
    local totalHeight = 0
    for _, child in pairs(tabContents[tabIndex]:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 5
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

-- ==================== ЗАПОЛНЕНИЕ ВКЛАДОК ====================
-- Вкладка ESP
addToggle(1, "👁️ ESP Убийца", false, function(v) ESPEnabled.Murderer = v end)
addToggle(1, "👁️ ESP Шериф", false, function(v) ESPEnabled.Sheriff = v end)
addToggle(1, "👁️ ESP Оружие", false, function(v) ESPEnabled.DroppedGun = v end)

-- Вкладка Движение
addSlider(2, "Скорость", 16, 200, 16, function(v)
    WalkspeedValue = v
    humanoid.WalkSpeed = v
end)
addSlider(2, "Прыжок", 50, 890, 50, function(v)
    JumpPowerValue = v
    humanoid.JumpPower = v
end)
addSlider(2, "Гравитация", 0, 500, 196, function(v)
    GravityValue = v
    Workspace.Gravity = v
end)
addToggle(2, "Циклическое сохранение", false, function(v)
    loopMovement = v
end)
addToggle(2, "Noclip", false, function(v) noclipEnabled = v end)

-- Вкладка Утилиты
addButton(3, "📞 Телепорт к убийце", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Knife") then
            teleportTo(plr)
            break
        end
    end
end)
addButton(3, "📞 Телепорт к шерифу", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Backpack:FindFirstChild("Gun") then
            teleportTo(plr)
            break
        end
    end
end)
addButton(3, "📞 Телепорт к оружию", function()
    local gunDrop = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("GunDrop")
    if gunDrop then
        LocalPlayer.Character:SetPrimaryPartCFrame(gunDrop.CFrame * CFrame.new(0, 0, 3))
        notify("Телепорт к оружию")
    else
        notify("Оружие не найдено")
    end
end)
addToggle(3, "🪙 Фарм монет", false, function(v) FarmCoinsEnabled = v end)
addToggle(3, "💀 Kill All", false, function(v) killAllEnabled = v end)
addToggle(3, "🎯 Прицел на убийцу", false, function(v) aimMurdererEnabled = v end)

-- Вкладка Настройки
addButton(4, "🚀 Загрузить Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    notify("Infinite Yield загружен!")
end)
addButton(4, "🔄 Перезагрузить скрипт", function()
    menu.Visible = false
    task.wait(0.5)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ferfregre/DBAEGBFAEFD/main/deepseek_lua_20260701_4159bc.lua"))()
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

-- ==================== ОТКРЫТИЕ/ЗАКРЫТИЕ МЕНЮ ====================
local function toggleMenu()
    menu.Visible = not menu.Visible
    if menu.Visible then
        -- Обновляем содержимое вкладки при открытии
        switchTab(currentTab)
    end
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
        menu.Size = UDim2.new(0, screenSize.X - 30, 0, screenSize.Y - 80)
        menu.Position = UDim2.new(0.5, -(screenSize.X - 30)/2, 0.5, -(screenSize.Y - 80)/2)
        button.Size = UDim2.new(0, 65, 0, 65)
        button.Position = UDim2.new(1, -80, 0, 15)
    end
end
resizeElements()
game:GetService("GuiService").ScreenResolutionChanged:Connect(resizeElements)

print("✅ MM2 X Hub (полная версия) успешно загружен!")
notify("Нажми на ⚙️ в правом верхнем углу")