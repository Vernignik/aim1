local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local targetPlayer = nil
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil

-- Настройки круга FOV
_G.CircleSides = 64 -- Количество сторон круга FOV.
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- Цвет круга FOV.
_G.CircleTransparency = 1 -- Прозрачность круга.
_G.CircleRadius = 100 -- Радиус круга / FOV.
_G.CircleFilled = false -- Определяет, будет ли круг заполнен.
_G.CircleVisible = false -- Определяет, будет ли круг видим.
_G.CircleThickness = 2 -- Толщина круга.

_G.AutoClickEnabled = true  -- Включить/выключить автоклик (правая кнопка мыши)
_G.LeftClickEnabled = true  -- Включить/выключить одиночный выстрел (левая кнопка мыши)
_G.LockCameraEnabled = false  -- Включить/выключить блокировку камеры на голове игрока

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

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

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)

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
        local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
        
        -- Проверка, что игрок находится в пределах радиуса FOV
        local mousePosition = UserInputService:GetMouseLocation()
        local distanceToMouse = (Vector2.new(headPosition.X, headPosition.Y) - mousePosition).Magnitude
        
        if distanceToMouse <= _G.CircleRadius then
            if headPosition.Z > 0 then
                local cameraPosition = Camera.CFrame.Position
                Camera.CFrame = CFrame.new(cameraPosition, head.Position)
            end
        end
    end
end

local function startAutoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if isRightMouseDown and _G.AutoClickEnabled then
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

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed and _G.LeftClickEnabled then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if not isLobbyVisible() then
                mouse1click()
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed and _G.AutoClickEnabled then
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
        targetPlayer = getClosestPlayerToMouse()
        if targetPlayer and _G.LockCameraEnabled then
            lockCameraToHead()
        end
    end

    -- Обновление круга FOV
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness
end)
