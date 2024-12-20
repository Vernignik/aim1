local Config = {
    AutoClickEnabled = false,  -- Включить/выключить автоклик (правая кнопка мыши)
    LeftClickEnabled = false,  -- Включить/выключить одиночный выстрел (левая кнопка мыши)
    LockCameraEnabled = false  -- Включить/выключить блокировку камеры на голове игрока
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

local function isLobbyVisible()
    -- Убедитесь, что объект Lobby существует, прежде чем проверять его видимость
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

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance < shortestDistance then
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
    -- Подключаем автокликер, если правая кнопка зажата
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if isRightMouseDown and Config.AutoClickEnabled then
            if not isLobbyVisible() then
                mouse1click() -- Выполнение автоклика
            end
        end
    end)
end

local function stopAutoClick()
    -- Останавливаем автокликер
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed and Config.LeftClickEnabled then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            -- Одиночный выстрел
            if not isLobbyVisible() then
                mouse1click()
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed and Config.AutoClickEnabled then
        if not isRightMouseDown then
            isRightMouseDown = true
            -- Запуск автокликера, если правая кнопка мыши нажата
            startAutoClick()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        isRightMouseDown = false
        -- Остановить автокликер, если правая кнопка отпущена
        stopAutoClick()
    end
end)

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        targetPlayer = getClosestPlayerToMouse()
        if targetPlayer and Config.LockCameraEnabled then
            lockCameraToHead()
        end
    end
end)

return Config
