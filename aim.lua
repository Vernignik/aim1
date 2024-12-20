local config = {
    AutoClickEnabled = false, -- Включить/выключить автоклик (правая кнопка мыши)
    LeftClickEnabled = false, -- Включить/выключить одиночный выстрел (левая кнопка мыши)
    LockCameraEnabled = false, -- Включить/выключить блокировку камеры на голове игрока
    FOVRadius = 100, -- Радиус FOV круга
    FOVColor = Color3.fromRGB(255, 255, 255), -- Цвет круга
    FOVTransparency = 1, -- Прозрачность круга
    FOVVisible = true, -- Видимость круга
    FOVThickness = 2, -- Толщина круга
    FOVSides = 64 -- Количество сторон у круга
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

-- Создаем круг FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = config.FOVColor
FOVCircle.Radius = config.FOVRadius
FOVCircle.Thickness = config.FOVThickness
FOVCircle.NumSides = config.FOVSides
FOVCircle.Filled = false
FOVCircle.Transparency = config.FOVTransparency
FOVCircle.Visible = config.FOVVisible

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

local function getClosestPlayerToFOV()
    local closestPlayer = nil
    local shortestDistance = config.FOVRadius
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance <= config.FOVRadius and distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

local function lockCameraToHead()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local head = targetPlayer.Character.Head
        local headPosition = camera:WorldToViewportPoint(head.Position)
        if headPosition.Z > 0 then
            local cameraPosition = camera.CFrame.Position
            camera.CFrame = CFrame.new(cameraPosition, head.Position)
        end
    end
end

local function startAutoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if isRightMouseDown and config.AutoClickEnabled then
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

-- Функция для проверки изменений конфигурации
local function updateConfig()
    FOVCircle.Radius = config.FOVRadius
    FOVCircle.Color = config.FOVColor
    FOVCircle.Transparency = config.FOVTransparency
    FOVCircle.Visible = config.FOVVisible
    FOVCircle.Thickness = config.FOVThickness
    FOVCircle.NumSides = config.FOVSides
end

-- Функция для отслеживания изменений в конфигурации
local function watchConfigChanges()
    local previousConfig = table.clone(config) -- создаем копию конфигурации
    while true do
        -- Если конфигурация изменилась
        if previousConfig.AutoClickEnabled ~= config.AutoClickEnabled or 
           previousConfig.LeftClickEnabled ~= config.LeftClickEnabled or 
           previousConfig.LockCameraEnabled ~= config.LockCameraEnabled or 
           previousConfig.FOVRadius ~= config.FOVRadius or
           previousConfig.FOVColor ~= config.FOVColor or
           previousConfig.FOVTransparency ~= config.FOVTransparency or
           previousConfig.FOVVisible ~= config.FOVVisible or
           previousConfig.FOVThickness ~= config.FOVThickness or
           previousConfig.FOVSides ~= config.FOVSides then

            -- Обновляем конфигурацию
            previousConfig = table.clone(config)
            updateConfig()
        end
        wait(0.1)
    end
end

-- Запуск отслеживания изменений конфигурации
spawn(watchConfigChanges)

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed and config.LeftClickEnabled then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if not isLobbyVisible() then
                mouse1click()
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed and config.AutoClickEnabled then
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

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        -- Обновление положения круга
        FOVCircle.Position = UserInputService:GetMouseLocation()

        -- Получение ближайшего игрока в пределах FOV
        targetPlayer = getClosestPlayerToFOV()

        -- Блокировка камеры
        if targetPlayer and config.LockCameraEnabled then
            lockCameraToHead()
        end
    end
end)

return config
