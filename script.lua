local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HubName = "TideHub - SolsRNG"

local Window = Rayfield:CreateWindow({
    Name = HubName,
    Theme = "DarkBlue",
    ToggleUIKeybind = "J",
    ShowText = "hub",
    LoadingTitle = "Loading hub...",
    LoadingSubtitle = "by a random dev",
    ScriptID = "sid_lcw2fvqkpili",

    ConfigurationSaving = {
        Enabled = true,
        FolderName = HubName,
        FileName = HubName
    },
})

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local function getCharacter() return plr.Character or plr.CharacterAdded:Wait() end
local input = loadstring(game:HttpGet('https://pastebin.com/raw/dYzQv3d8'))()

local Tab = Window:CreateTab("Main", "box")

Tab:CreateButton({ Name = "Random hub i made no judge", Callback = function()end })
Tab:CreateDivider()

local eggLabel = Tab:CreateButton({ Name = "Eggs collected: 0" })
local guc = Tab:CreateButton({ Name = "\"Give up\" count: 0" })
local tt = Tab:CreateButton({ Name = "Eggs detected: 0" })
local estt = Tab:CreateButton({ Name = "Elapsed Time: 0" })

Tab:CreateDivider()
Rayfield:Notify({
   Title = "Map tweaking",
   Content = " man the stupid fricking pathfinding got stuck very single time so i had to tweak it a little bit",
   Duration = 6.5,
   Image = "rewind",
})

local config = {
    egg = false,
    timeout = 40,
    repath = 2,
    repathIncrement = 0.01
}

Tab:CreateToggle({
    Name = "Auto Collect Egg",
    CurrentValue = false,
    Callback = function(v)
        config.egg = v
    end,
})

Tab:CreateSlider({
    Name = "Timeout",
    Range = {30, 90},
    Increment = 5,
    Suffix = "Seconds",
    CurrentValue = 40,
    Callback = function(v)
        config.timeout = v
    end,
})

Tab:CreateSlider({
    Name = "Repath if not reached in seconds",
    Range = {1, 5},
    Increment = 0.2,
    Suffix = "Seconds",
    CurrentValue = 1.5,
    Callback = function(v)
        config.repath = v
    end,
})

Tab:CreateSlider({
    Name = "Repath timer increment",
    Range = {0.01, 0.25},
    Increment = 0.01,
    CurrentValue = 0.1,
    Suffix = "Seconds",
    Callback = function(v)
        config.repathIncrement = v
    end,
})

local eggs = {}
local function isEgg(v)
    if v:IsA("MeshPart") and string.find(string.lower(v.Name), "egg") then return true end
    if v:IsA("Model") and string.find(string.lower(v.Name), "random_potion") then return true end
    return false
end
local function addEgg(v) if isEgg(v) then eggs[v] = true end end
local function removeEgg(v) if isEgg(v) then eggs[v] = nil end end
local ws = game:GetService("Workspace")
for _, v in ipairs(ws:GetChildren()) do addEgg(v) end
for _, v in ipairs(ws.Map.Miscs.WaterBlocks:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false v.CanQuery = false v.CanTouch = false end end
for _, v in ipairs(workspace.Map.leafygrass:GetChildren()) do
    if v:IsA("BasePart") then
        local indent = 25
        if not v:GetAttribute("ogpos") then v:SetAttribute("ogpos", v.Position.Y) else v.Position = Vector3.new(v.Position.X, v:GetAttribute("ogpos"),v.Position.Z) end
        v.Size = Vector3.new(v.Size.X, indent, v.Size.Z)
        v.Position = Vector3.new(v.Position.X, v.Position.Y - (indent / 2),v.Position.Z)
    end
end
ws.ChildAdded:Connect(addEgg)
ws.ChildRemoved:Connect(removeEgg)

---=-=-=-=-==-=--=-=-=-=-=-=-=-`-=~_+=_~+_~+_~+-`=-`=_~+-`=~_+~_+~_+~

local pf = game:GetService("PathfindingService")

local function moveToTarget(hum, target)
    local root = hum.RootPart
    local path = pf:CreatePath({
        AgentRadius = root.Size.Z,
        AgentHeight = 25, -- prevent stucking at places has low ceiling
        AgentCanJump = true,
        AgentJumpHeight = hum.JumpHeight,
        AgentMaxSlope = 45
    })

    path:ComputeAsync(root.Position, target)
    if path.Status ~= Enum.PathStatus.Success then return end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if (root.Position - target).Magnitude < 3 then break end
        hum:MoveTo(waypoint.Position)

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            local state = hum:GetState()
            if state ~= Enum.HumanoidStateType.Freefall then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end

        local done = false
        local conn = hum.MoveToFinished:Connect(function() done = true end)

        local timer = 0
        while not done and timer < config.repath do task.wait(config.repathIncrement) timer += config.repathIncrement end

        conn:Disconnect()

        if not done then
            print("recovering from mistake")
            moveToTarget(hum, target)
            return
        end
    end
end

---=-=-=-=-==-=--=-=-=-=-=-=-=-`-=~_+=_~+_~+_~+-`=-`=_~+-`=~_+~_+~_+~

local moving = false
local stop = false
local hb

local eggcount = getgenv().thec or 0
local giveupCount = getgenv().thguc or 0
if not getgenv().est then getgenv().est = 0 end
if not getgenv().idk then
    idk = Instance.new("BindableEvent")
    idk.Event:Once(function()
        if hb then hb:Disconnect() end
    end)
end

local elapsedTime = getgenv().est

function updec()
    eggcount+=1
    getgenv().thec = eggcount
    eggLabel:Set("Eggs collected: " .. tostring(eggcount))
    tt:Set("Eggs detected: " .. tostring(eggcount + giveupCount))
end

function updguc()
    giveupCount+=1
    getgenv().thguc = giveupCount
    guc:Set("\"Give up\" count: " .. tostring(giveupCount))
    tt:Set("Eggs detected: " .. tostring(eggcount + giveupCount))
end

local start
local eggPos

function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

hb = game:GetService("RunService").Heartbeat:Connect(function(dt)
    elapsedTime += dt
    getgenv().est = elapsedTime 
    estt:Set("Elapsed Time: " .. formatTime(elapsedTime))
end)

coroutine.wrap(function()
while task.wait(0.1) do
    if not config.egg then continue end
    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = humanoid.RootPart

    local closestEgg, closestDist = nil, math.huge

    for egg in pairs(eggs) do
        if egg and egg.Parent then
            local eggPos = egg:IsA("Model") and egg:GetPivot().Position or egg.Position
            local dist = (root.Position - eggPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestEgg = egg
            end
        end
    end

    if moving then continue end

    if closestEgg then
        print("found egg")

        eggPos = closestEgg:IsA("Model") and closestEgg:GetPivot().Position or closestEgg.Position
        moving = true
        
        start = tick()
        stop = false

        moveToTarget(humanoid, eggPos)

        repeat
            if tick() - start > config.timeout then stop = true end
            task.wait(0.1)
            if (root.Position - eggPos).Magnitude < 30 then
                input.press(Enum.KeyCode.E)
            end
        until not closestEgg.Parent or stop or (closestEgg:IsA("BasePart") and closestEgg.Transparency > 0 or nil)

        eggs[closestEgg] = nil

        if stop then
            print("i give up 🥀")
            updguc()
        else
            updec()
            print("egg collected. total:", eggcount)
        end

        moving = false
    end
end
end)()

Tab:CreateDivider()

local derender3d

function derender(v, enb)
    local pb = v:IsA("BasePart") or v:IsA("Decal")
    local vfx = v:IsA("Light") or v:IsA("ParticleEmitter") or v:IsA("RopeConstraint") or v:IsA("BillboardGui")
    
    if enb then
        if pb then
            v:SetAttribute("OgTrans", v.Transparency)
            v.Transparency = 1
        elseif vfx then
            v:SetAttribute("OgEnb", v.Enabled)
            v.Enabled = false
        end
    else
        if pb then
            v.Transparency = v:GetAttribute("OgTrans")
        elseif vfx then
            v.Enabled = v:GetAttribute("OgEnb")
        end
    end
end

Tab:CreateToggle({
    Name = "Derender (3D)",
    Callback = function(enb)
        for _, v in ipairs(ws:GetDescendants()) do
            derender(v, enb)
        end

        if enb then
            derender3d = ws.DescendantAdded:Connect(function(v) derender(v, enb) end)
            game:GetService("Lighting"):SetAttribute("WeatherEnabled", false)
            game:GetService("Lighting"):SetAttribute("AtmosphereEnabled", false)
            game:GetService("Lighting"):SetAttribute("RBX_LightningTechnologyUnifiedMigration", false)
            ws.Camera.CFrame = CFrame.new(213.156082, 97.8955994, -361.385651, 0.311008245, -0.935968399, 0.165037051, 0, 0.173648775, 0.98480773, -0.950407267, -0.306283325, 0.0540062003)
        else
            derender3d:Disconnect()
            game:GetService("Lighting"):SetAttribute("WeatherEnabled", true)
            game:GetService("Lighting"):SetAttribute("AtmosphereEnabled", true)
            game:GetService("Lighting"):SetAttribute("RBX_LightningTechnologyUnifiedMigration", true)
        end

        
    end
})

Tab:CreateToggle({
    Name = "Derender (GUI)",
    Callback = function(enb)
        for _, v in ipairs(plr.PlayerGui:GetChildren()) do
            if v:IsA("ScreenGui") then
                if enb then
                    v:SetAttribute("OgEnb", v.Enabled)
                    v.Enabled = false
                else
                    v.Enabled = v:GetAttribute("OgEnb")
                end
            end
        end
    end
})

Tab:CreateButton({
    Name = "Enable derender (legacy)",
    Callback = function()
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    end
})

Tab:CreateButton({
    Name = "Disable derender (legacy)",
    Callback = function()
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end
})

Tab:CreateSlider({
    Name = "Walkspeed",
    Range = {16,20},
    Increment = 0.2,
    CurrentValue = 16,
    Suffix = "stud/s",
    Callback = function(v)
        getCharacter():FindFirstChildWhichIsA("Humanoid").WalkSpeed = v
    end,
})
