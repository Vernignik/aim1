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
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 1
_G.CircleRadius = 100
_G.CircleFilled = false
_G.CircleVisible = false
_G.CircleThickness = 2

_G.AutoClickEnabled = true
_G.LeftClickEnabled = true
_G.LockCameraEnabled = false
_G.CheckWalls = true -- Новая настройка: проверять стены
_G.CheckTeam = true -- Новая настройка: проверять команду
_G.CheckAlive = true -- Новая настройка: проверять жив ли игрок

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

local function isPlayerValid(player)
    -- Проверка что игрок существует и не является локальным игроком
    if not player or player == localPlayer then return false end
    
    -- Проверка что у игрока есть персонаж и голова
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local head = player.Character:FindFirstChild("Head")
    if not humanoid or not head then return false end
    
    -- Проверка что игрок жив (если включено)
    if _G.CheckAlive and (humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
        return false
    end
    
    -- Проверка команды (если включено)
    if _G.CheckTeam and player.Team == localPlayer.Team then
        return false
    end
    
    return true
end

local function isVisible(position)
    if not _G.CheckWalls then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (position - origin).Unit * 100
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
            return true
        end
        return false
    end
    return true
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if isPlayerValid(player) then
            local head = player.Character.Head
            local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen and isVisible(head.Position) then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance < shortestDistance and distance <= _G.CircleRadius then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

local function lockCameraToHead()
    if targetPlayer and isPlayerValid(targetPlayer) then
        local head = targetPlayer.Character.Head
        local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
        
        if onScreen and isVisible(head.Position) then
            local mousePosition = UserInputService:GetMouseLocation()
            local distanceToMouse = (Vector2.new(headPosition.X, headPosition.Y) - mousePosition).Magnitude
            
            if distanceToMouse <= _G.CircleRadius and headPosition.Z > 0 then
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
        if isRightMouseDown and _G.AutoClickEnabled and targetPlayer and isPlayerValid(targetPlayer) then
            if not isLobbyVisible() then
                mouse1click()
                wait(0.1) -- Добавляем задержку между выстрелами
            end
        end
    end)
end

local function stopAutoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
        autoClickConnection = nil
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed and _G.LeftClickEnabled then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if not isLobbyVisible() and targetPlayer and isPlayerValid(targetPlayer) then
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
