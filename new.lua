print("collecting eggs agent starting up")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.OnTeleport:Once(function()
    queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/Ocean102/solsrng/refs/heads/main/new.lua'))()")
end)

if not player.PlayerGui.MainInterface.Enabled then repeat wait() until player.PlayerGui.MainInterface.Enabled end

hookfunction(player.Kick, function()end)
local rj = game:GetService("ReplicatedFirst").ClientHandlers.Utils:FindFirstChild("RejoinPlayer")
if rj then rj:Destroy() end
for i,v in pairs(getconnections(player.Idled)) do v:Disable() end

print("capping fps and disable 3d to save performance")
setfpscap(30)
game:GetService("RunService"):Set3dRenderingEnabled(false)
print("player loaded...")

local vim = game:GetService("VirtualInputManager")

function press(enumKeyCode)
    vim:SendKeyEvent(true, enumKeyCode, false, game)
    task.wait(0.01)
    vim:SendKeyEvent(false, enumKeyCode, false, game)
end

local function getCharacter() return player.Character or player.CharacterAdded:Wait() end

local hrp = getCharacter():FindFirstChildWhichIsA("Humanoid").RootPart
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
for _, v in ipairs(ws.Map.leafygrass:GetChildren()) do
    if v:IsA("BasePart") then
        local indent = 25
        if not v:GetAttribute("ogpos") then v:SetAttribute("ogpos", v.Position.Y) else v.Position = Vector3.new(v.Position.X, v:GetAttribute("ogpos"),v.Position.Z) end
        v.Size = Vector3.new(v.Size.X, indent, v.Size.Z)
        v.Position = Vector3.new(v.Position.X, v.Position.Y - (indent / 2),v.Position.Z)
    end
end

for _,v in ipairs(player.PlayerGui.MainInterface:GetChildren()) do
    if v.Name == v.ClassName and not v:IsA("ImageButton") then v:Remove() end
end

for _, v in ipairs(player.PlayerGui:GetChildren()) do
    if v.Name ~= "MainInterface" and not string.find(v.Name, "Proximity") and not v:IsA("Model") then
        v:Destroy()
    end
end

game:GetService("ReplicatedStorage").Modules.UI.Icon:Destroy()

local function hasValidEggAncestor(obj)
    local current = obj.Parent

    while current do
        if isEgg(current) then
            return true
        end

        current = current.Parent
    end

    return false
end

coroutine.wrap(function()
    for _, v in ipairs(ws:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            if not hasValidEggAncestor(v) then
                v:Destroy()
            end
        end
    end
end)()

ws.ChildAdded:Connect(addEgg)
ws.ChildRemoved:Connect(removeEgg)

local PathfindingService = game:GetService("PathfindingService")

local function moveToTarget(hum, target)
    coroutine.wrap(function()
        local root = hum.RootPart
        local path = PathfindingService:CreatePath({
            AgentRadius = root.Size.Z,
            AgentHeight = 30,
            AgentCanJump = true,
            AgentJumpHeight = hum.JumpHeight,
            AgentMaxSlope = 45
        })

        path:ComputeAsync(root.Position, target)
        if path.Status ~= Enum.PathStatus.Success then return "cantgo" end

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
            while not done and timer < 2 do task.wait(0.01) timer += 0.01 end

            conn:Disconnect()

            if not done then
                print("recovering from mistake")
                moveToTarget(hum, target)
                return
            end
        end
    end)()
end

local moving = false
local eggcount = 0
local timeout = 40

local start
local eggPos
local stop = false

local guis = game:GetService("GuiService")

function checkRareAura(v)
    local accept, deny

    if v.Parent.Name == "Background" or v.Name == "Background" then
        for _, v in ipairs(player.PlayerGui.MainInterface:GetChildren()) do
            if v:IsA("ImageButton") and v:FindFirstChild("TextLabel") then
                if v.TextLabel.Text:lower() == "equip" then
                    accept = v
                else
                    deny = v
                end
            end

            if deny and accept then break end
        end

        guis.GuiNavigationEnabled = true
        guis.SelectedObject = deny
        press(Enum.KeyCode.Return)
        guis.GuiNavigationEnabled = false
        guis.SelectedObject = nil
    end
end

player.PlayerGui.MainInterface.Background.ChildAdded:Connect(checkRareAura)
task.delay(2, function()
    for _,v in ipairs(player.PlayerGui.MainInterface:GetChildren()) do
        checkRareAura(v)
    end
    
    local btg = player.PlayerGui.MainInterface.BottomFrame
    local ar, qr = btg.AutoRoll, btg.QuickRoll

    function changed(v)
        local status = string.find(v.Context.Text:lower(), "on")

        if not status then
            task.wait(0.1)
            guis.GuiNavigationEnabled = true
            guis.SelectedObject = v

            repeat
                press(Enum.KeyCode.Return)
                status = string.find(v.Context.Text:lower(), "on")
                task.wait(0.05)
            until status

            guis.SelectedObject = nil
        end
    end

    changed(ar) changed(qr)

    ar.Context:GetPropertyChangedSignal("Text"):Connect(function()
        changed(ar)
    end)

    qr.Context:GetPropertyChangedSignal("Text"):Connect(function()
        changed(qr)
    end)
end)

coroutine.wrap(function()

while task.wait(0.1) do
    local character = getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

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

        local run =  moveToTarget(humanoid, eggPos)

        repeat
            if tick() - start > timeout then stop = true end
            if run == "cantgo" then stop = true end
            task.wait(0.1)
            press(Enum.KeyCode.E)
        until not closestEgg.Parent or stop or (closestEgg:IsA("BasePart") and closestEgg.Transparency > 0 or nil)

        eggs[closestEgg] = nil

        if tick() - start > timeout then
            eggcount += 1
            print("egg collected #", eggcount)
        end

        moving = false
    end
end

end)()
