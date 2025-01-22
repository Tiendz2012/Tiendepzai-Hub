local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Tiendepzai Hub",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Tiendepzai Hub",
   LoadingSubtitle = "by Tien",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local Tab = Window:CreateTab("Main", 80420354651157) -- Title, Image

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera

-- Variables
local espEnabled = false
local maxESPDistance = 1000 -- Maximum distance for ESP

-- Function to create a box for ESP
local function createBox()
    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0) -- Red color for enemies
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false
    return box
end

-- Function to update ESP for a player
local function updateBoxESP(player, box)
    if player == Players.LocalPlayer or not player.Character then
        box.Visible = false
        return
    end

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")

    if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
        box.Visible = false
        return
    end

    -- Check if the player is within the maxESPDistance
    local distance = (humanoidRootPart.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if distance > maxESPDistance then
        box.Visible = false
        return
    end

    -- Check if the player is on the same team
    if player.TeamColor == Players.LocalPlayer.TeamColor then
        box.Visible = false
        return
    end

    -- Calculate the 2D position on the screen
    local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    if onScreen then
        local size = math.clamp(2000 / distance, 20, 100) -- Adjust box size based on distance
        box.Size = Vector2.new(size, size * 1.5) -- Box size
        box.Position = Vector2.new(vector.X - box.Size.X / 2, vector.Y - box.Size.Y / 2) -- Center box
        box.Visible = true
    else
        box.Visible = false
    end
end

-- Table to store ESP boxes for players
local espBoxes = {}

-- Function to add ESP for a player
local function addESP(player)
    if espBoxes[player] then return end -- Prevent duplicate boxes
    local box = createBox()
    espBoxes[player] = box

    -- Update ESP dynamically
    RunService.RenderStepped:Connect(function()
        if not espBoxes[player] then return end -- Stop if the box is removed
        updateBoxESP(player, espBoxes[player])
    end)
end

-- Function to remove ESP for a player
local function removeESP(player)
    if espBoxes[player] then
        espBoxes[player]:Remove()
        espBoxes[player] = nil
    end
end

-- Function to toggle ESP
local function toggleESP(enabled)
    espEnabled = enabled

    if espEnabled then
        -- Add ESP for all current players
        for _, player in ipairs(Players:GetPlayers()) do
            addESP(player)
        end

        -- Listen for new players
        Players.PlayerAdded:Connect(addESP)
        Players.PlayerRemoving:Connect(removeESP)
    else
        -- Remove all ESP boxes
        for _, box in pairs(espBoxes) do
            box:Remove()
        end
        espBoxes = {}
    end
end

-- Toggle integration (adjust for your UI)
local Toggle = Tab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle", -- Unique identifier
    Callback = function(value)
        toggleESP(value)
    end,
})

-- Variables
local aimbotEnabled = false
local targetPlayer = nil

-- Function to find the closest enemy to aim at
local function getClosestEnemy()
    local localPlayer = game.Players.LocalPlayer
    local closestDistance = math.huge
    local closestTarget = nil

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") and player.TeamColor ~= localPlayer.TeamColor then
            local character = player.Character
            local head = character.Head

            -- Calculate distance from the player's camera
            local distance = (workspace.CurrentCamera.CFrame.Position - head.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestTarget = head
            end
        end
    end

    return closestTarget
end

-- Function to handle the aimbot
local function aimbot()
    if aimbotEnabled then
        -- Continuously lock aim to the closest enemy
        game:GetService("RunService").RenderStepped:Connect(function()
            if aimbotEnabled then
                targetPlayer = getClosestEnemy()
                if targetPlayer then
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetPlayer.Position)
                end
            end
        end)
    end
end

-- Toggle integration (adjust for your UI)
local Toggle = Tab:CreateToggle({
    Name = "Aimbot(mobile)",
    CurrentValue = false,
    Flag = "Aimbot_Toggle", -- Unique identifier
    Callback = function(value)
        aimbotEnabled = value
        if aimbotEnabled then
            aimbot()
        else
            targetPlayer = nil -- Clear target when disabled
        end
    end,
})

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local aimbotEnabled = false
local isRightClickHeld = false
local lockedTarget = nil

-- Function to check if a part is on the screen
local function isOnScreen(targetPart)
    local camera = workspace.CurrentCamera
    local viewportPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
    return onScreen
end

-- Function to check if the target is visible (not behind walls) and on the screen
local function isVisibleAndOnScreen(targetPart)
    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position -- Camera's position
    local direction = (targetPart.Position - origin).Unit * 1000 -- Direction vector to the target
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character} -- Ignore the local player

    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    if rayResult and rayResult.Instance then
        -- Check if the ray hit the target and the target is on the screen
        return rayResult.Instance:IsDescendantOf(targetPart.Parent) and isOnScreen(targetPart)
    end
    return false
end

-- Function to find the closest visible enemy on the screen
local function getClosestVisibleEnemy()
    local localPlayer = game.Players.LocalPlayer
    local closestDistance = math.huge
    local closestTarget = nil

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") and player.TeamColor ~= localPlayer.TeamColor then
            local character = player.Character
            local head = character.Head

            -- Check visibility and on-screen status
            if isVisibleAndOnScreen(head) then
                -- Calculate distance from the player's camera
                local distance = (workspace.CurrentCamera.CFrame.Position - head.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestTarget = head
                end
            end
        end
    end

    return closestTarget
end

-- Function to handle aimbot logic
local function aimbot()
    RunService.RenderStepped:Connect(function()
        if aimbotEnabled and isRightClickHeld then
            -- If lockedTarget is invalid or not visible, find a new target
            if not lockedTarget or not lockedTarget.Parent or not lockedTarget:IsDescendantOf(workspace) or not isVisibleAndOnScreen(lockedTarget) then
                lockedTarget = getClosestVisibleEnemy()
            end

            -- Aim at the locked target if valid
            if lockedTarget then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, lockedTarget.Position)
            end
        else
            -- Reset locked target when right-click is released or aimbot is disabled
            lockedTarget = nil
        end
    end)
end

-- Detect right-click hold/release
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click
        isRightClickHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click release
        isRightClickHeld = false
    end
end)

-- Toggle integration (adjust for your UI)
local Toggle = Tab:CreateToggle({
    Name = "Aimbot (Lock-on Target)",
    CurrentValue = false,
    Flag = "Aimbot_Toggle", -- Unique identifier
    Callback = function(value)
        aimbotEnabled = value
        if aimbotEnabled then
            aimbot()
        else
            lockedTarget = nil -- Clear target when disabled
        end
    end,
})

local Tab = Window:CreateTab("Setting", 80420354651157) -- Title, Image

-- Services
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Function to server hop
local function serverHop()
    local gameId = game.PlaceId
    local serversListUrl = "https://games.roblox.com/v1/games/" .. gameId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(serversListUrl))
    end)

    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                -- Teleport to the new server
                TeleportService:TeleportToPlaceInstance(gameId, server.id)
                return
            end
        end
    end

    -- If no suitable server is found
    warn("No available servers found to hop to.")
end

-- Button to initiate server hop
local Button = Tab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        serverHop()
    end,
})

local Button = Tab:CreateButton({
    Name = "No Recoil",
    Callback = function()
        -- Recursively search for all RecoilControl values in the game
        local function RemoveRecoil(folder)
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("NumberValue") and obj.Name == "RecoilControl" then
                    obj.Value = 0

                    -- Prevent recoil from being restored
                    obj:GetPropertyChangedSignal("Value"):Connect(function()
                        obj.Value = 0
                    end)
                end
            end
        end

        -- Apply no recoil to the most likely areas where weapons might be stored
        RemoveRecoil(workspace) -- Check the workspace
        RemoveRecoil(game.Players.LocalPlayer) -- Check the player's character or local player
        RemoveRecoil(game.ReplicatedStorage) -- Check shared storage
        RemoveRecoil(game.Lighting) -- Some games store assets in Lighting

        print("No Recoil activated for all guns!")
    end,
})

local Button = Tab:CreateButton({
   Name = "NoClip",
   Callback = function()
      local noclipEnabled = true -- Set NoClip enabled
      
      -- Print confirmation
      print("NoClip Enabled")
      
      -- Start NoClip functionality
      game:GetService("RunService").Stepped:Connect(function()
         if noclipEnabled then
            for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
               if part:IsA("BasePart") and part.CanCollide then
                  part.CanCollide = false
               end
            end
         end
      end)
   end,
})

local Button = Tab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
      local TeleportService = game:GetService("TeleportService")
      local player = game.Players.LocalPlayer

      -- Rejoin the current server
      TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
   end,
})