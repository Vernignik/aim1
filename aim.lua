local Aim = {
    AutoClickEnabled = false,
    LeftClickEnabled = false,
    LockCameraEnabled = false,
    FOVRadius = 100,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 1,
    FOVVisible = true,
    FOVThickness = 2,
    FOVSides = 64
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false

-- Сохраняем предыдущие значения для отслеживания изменений
local oldValues = {}

-- Функция для обновления FOVCircle
local function updateFOVCircle(property, value)
    if property == "FOVRadius" then
        FOVCircle.Radius = value
    elseif property == "FOVColor" then
        FOVCircle.Color = value
    elseif property == "FOVTransparency" then
        FOVCircle.Transparency = value
    elseif property == "FOVVisible" then
        FOVCircle.Visible = value
    elseif property == "FOVThickness" then
        FOVCircle.Thickness = value
    elseif property == "FOVSides" then
        FOVCircle.NumSides = value
    end
end

-- Инициализация FOVCircle с начальными значениями
for key, value in pairs(Aim) do
    oldValues[key] = value
    updateFOVCircle(key, value)
end

-- Цикл для проверки изменений
game:GetService("RunService").RenderStepped:Connect(function()
    for key, value in pairs(Aim) do
        if oldValues[key] ~= value then
            oldValues[key] = value
            updateFOVCircle(key, value)
        end
    end
end)

-- Дополнительные функции (например, работа камеры, автоклик, и т. д.)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil

local function getClosestPlayerToFOV()
    local closestPlayer = nil
    local shortestDistance = Aim.FOVRadius
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance <= Aim.FOVRadius and distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

RunService.Heartbeat:Connect(function()
    -- Обновление положения круга
    FOVCircle.Position = UserInputService:GetMouseLocation()

    -- Получение ближайшего игрока в пределах FOV
    targetPlayer = getClosestPlayerToFOV()
end)

return Aim
