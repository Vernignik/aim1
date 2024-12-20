local Config = {
    FOVRadius = 100,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 1,
    FOVVisible = true,
    FOVThickness = 2,
    FOVSides = 64,
    AutoClickEnabled = false,
    LeftClickEnabled = false,
    LockCameraEnabled = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil

local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false

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

-- Функция для обновления всех значений в FOVCircle
local function applyAllSettings()
    for key, value in pairs(Config) do
        updateFOVCircle(key, value)
    end
end

-- Инициализация FOVCircle с начальными значениями
applyAllSettings()

-- Цикл для отслеживания изменений в конфиге
RunService.RenderStepped:Connect(function()
    for key, value in pairs(Config) do
        if FOVCircle[key] ~= value then
            updateFOVCircle(key, value)
        end
    end
end)

-- Функция для проверки видимости лобби
local function isLobbyVisible()
    local lobby = localPlayer.PlayerGui:FindFirstChild("MainGui")
    if lobby then
        local mainFrame = lobby:FindFirstChild("MainFrame")
        if mainFrame then
            local currency = mainFrame:FindFirstChild("Lobby") and mainFrame.Lobby:FindFirstChild("Currency")
            return currency and currency.Visible or false
        end
    end
    return false
end

-- Функция для получения ближайшего игрока в пределах FOV
local function getClosestPlayerToFOV()
    local closestPlayer = nil
    local shortestDistance = Config.FOVRadius
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance <= Config.FOVRadius and distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Функции для работы с автокликером
local function startAutoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if isRightMouseDown and Config.AutoClickEnabled then
            if not isLobbyVisible() then
                mouse1click()
            end
        end
    end)
end

local function stopAutoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
end

-- Обработка ввода
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed and Config.LeftClickEnabled then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if not isLobbyVisible() then
                mouse1click()
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed and Config.AutoClickEnabled then
        if not isRightMouseDown then
            isRightMouseDown = true
            startAutoClick()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        isRightMouseDown = false
        stopAutoClick()
    end
end)

-- Обновление FOV круга и камеры
RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        -- Обновление положения круга
        FOVCircle.Position = UserInputService:GetMouseLocation()

        -- Получение ближайшего игрока в пределах FOV
        targetPlayer = getClosestPlayerToFOV()

        -- Блокировка камеры
        if targetPlayer and Config.LockCameraEnabled then
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                local head = targetPlayer.Character.Head
                local headPosition = camera:WorldToViewportPoint(head.Position)
                if headPosition.Z > 0 then
                    local cameraPosition = camera.CFrame.Position
                    camera.CFrame = CFrame.new(cameraPosition, head.Position)
                end
            end
        end
    end
end)

return Config
