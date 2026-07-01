-- Самый простой тест GUI для MM2
if game.PlaceId ~= 142823291 then
    warn("Скрипт только для MM2!")
    return
end

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TestGUI"
gui.Parent = player:WaitForChild("PlayerGui")

-- Удаляем старый, если есть
local old = player.PlayerGui:FindFirstChild("TestGUI")
if old and old ~= gui then old:Destroy() end

-- Большая кнопка в центре
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 100)
button.Position = UDim2.new(0.5, -100, 0.5, -50)
button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
button.Text = "ОТКРЫТЬ МЕНЮ"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = gui

local corner = Instance.new("UICorner", button)
corner.CornerRadius = UDim.new(0, 12)

-- Меню (просто рамка)
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 300, 0, 200)
menu.Position = UDim2.new(0.5, -150, 0.5, -100)
menu.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
menu.Visible = false
menu.Parent = gui

local menuCorner = Instance.new("UICorner", menu)
menuCorner.CornerRadius = UDim.new(0, 12)

local label = Instance.new("TextLabel", menu)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "МЕНЮ ОТКРЫТО!"
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Font = Enum.Font.GothamBold

-- Кнопка закрытия
local close = Instance.new("TextButton", menu)
close.Size = UDim2.new(0, 40, 0, 40)
close.Position = UDim2.new(1, -45, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", close)
closeCorner.CornerRadius = UDim.new(0.5, 0)

close.MouseButton1Down:Connect(function()
    menu.Visible = false
end)

-- Открытие по кнопке
button.MouseButton1Down:Connect(function()
    menu.Visible = not menu.Visible
    print("Меню открыто:", menu.Visible)
end)

-- Дополнительно: любое касание экрана (для отладки)
game:GetService("UserInputService").TouchEnded:Connect(function()
    menu.Visible = not menu.Visible
    print("Меню открыто (touch):", menu.Visible)
end)

print("✅ Тестовый GUI загружен. Нажми на красную кнопку.")