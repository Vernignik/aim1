local Config = {
    teamCheck = false,
    fov = 150,
    smoothing = 1,
    FOVColor = Color3.fromRGB(255, 128, 128),
    FOVTransparency = 1,
    FOVThickness = 1.5
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = Config.FOVThickness
FOVring.Radius = Config.fov
FOVring.Transparency = Config.FOVTransparency
FOVring.Color = Config.FOVColor
FOVring.Position = workspace.CurrentCamera.ViewportSize/2

local function getClosest(cframe)
   local ray = Ray.new(cframe.Position, cframe.LookVector).Unit
   
   local target = nil
   local mag = math.huge
   
   for i,v in pairs(game.Players:GetPlayers()) do
       if v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= game.Players.LocalPlayer and (v.Team ~= game.Players.LocalPlayer.Team or not Config.teamCheck) then
           local magBuf = (v.Character.Head.Position - ray:ClosestPoint(v.Character.Head.Position)).Magnitude
           
           if magBuf < mag then
               mag = magBuf
               target = v
           end
       end
   end
   
   return target
end

local loop = RunService.RenderStepped:Connect(function()
   local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
   local localPlay = game.Players.LocalPlayer.Character
   local cam = workspace.CurrentCamera
   local zz = workspace.CurrentCamera.ViewportSize/2
   
   if pressed then
       local Line = Drawing.new("Line")
       local curTar = getClosest(cam.CFrame)
       local ssHeadPoint = cam:WorldToScreenPoint(curTar.Character.Head.Position)
       ssHeadPoint = Vector2.new(ssHeadPoint.X, ssHeadPoint.Y)
       if (ssHeadPoint - zz).Magnitude < Config.fov then
           workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(cam.CFrame.Position, curTar.Character.Head.Position), Config.smoothing)
       end
   end
   
   if UserInputService:IsKeyDown(Enum.KeyCode.Delete) then
       loop:Disconnect()
       FOVring:Remove()
   end
end)

return Config
