local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local UI_COLORS = {
    BG = Color3.fromRGB(12, 10, 18),
    TAB_INACTIVE = Color3.fromRGB(22, 18, 32),
    TAB_ACTIVE = Color3.fromRGB(180, 50, 255),
    CHECKBOX_OFF = Color3.fromRGB(30, 24, 45),
    CHECKBOX_ON = Color3.fromRGB(180, 50, 255),
    TEXT = Color3.fromRGB(240, 235, 255),
    BIND_ON = Color3.fromRGB(100, 255, 150),
    BIND_OFF = Color3.fromRGB(200, 190, 220)
}

local Settings = {
    Enabled = {
        AntiKick = false, 
        Aim = false, AutoShoot = false, ShowFOV = true, VisibleCheck = true, FOVRGB = false,
        EnableESP = false, BoxESP = false, ChamsESP = false, HealthBarESP = false, TracerESP = false, ESPRGB = false,
        SkyRGB = false,
        SpeedHack = false,
        AutoJump = false
    },
    SpeedHackActive = false,
    AutoJumpActive = false,
    VisibleCheckActive = true,
    AntiKickActive = false,
    SpeedMultiplier = 1,
    AimFOV = 100,
    ESPDistance = 1000,
    AimSmooth = 0.2,
    AutoShootDelay = 0.1,
    AimPart = "Head",
    FOVColor = Color3.fromRGB(180, 50, 255),
    ESPColor = Color3.fromRGB(180, 50, 255),
    SkyColor = Color3.fromRGB(30, 20, 50)
}

pcall(function()
    if hookmetamethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Settings.Enabled.AntiKick and self == player and (method == "Kick" or method == "kick" or method == "Destroy") then
                return
            end
            return old(self, ...)
        end)
    end
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = Settings.Enabled.ShowFOV
fovCircle.Transparency = 0.7
fovCircle.Thickness = 1.5
fovCircle.Color = Settings.FOVColor
fovCircle.Filled = false

local espDrawings = {}

local function removeEspForPlayer(plr)
    if espDrawings[plr] then
        if espDrawings[plr].Box then espDrawings[plr].Box:Remove() end
        if espDrawings[plr].HealthBarBg then espDrawings[plr].HealthBarBg:Remove() end
        if espDrawings[plr].HealthBar then espDrawings[plr].HealthBar:Remove() end
        if espDrawings[plr].Tracer then espDrawings[plr].Tracer:Remove() end
        espDrawings[plr] = nil
    end
    if plr.Character then
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local highlight = part:FindFirstChild("ChamsHighlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end

local function isVisible(targetPart)
    if not player.Character or not player.Character:FindFirstChild("Head") then return false end
    local origin = player.Character.Head.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if not raycastResult then
        return true
    end
    
    local hitPart = raycastResult.Instance
    if hitPart:IsDescendantOf(targetPart.Parent) then
        return true
    end
    
    local character = hitPart.Parent
    if character:FindFirstChild("Humanoid") then
        return true
    end
    
    return false
end

local function getBestTarget()
    local bestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = camera.ViewportSize / 2

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild(Settings.AimPart) then
            local humanoid = v.Character.Humanoid
            local aimPart = v.Character[Settings.AimPart]
            if humanoid.Health > 0 then
                if not Settings.Enabled.VisibleCheck or not Settings.VisibleCheckActive or isVisible(aimPart) then
                    local screenPos, onScreen = camera:WorldToViewportPoint(aimPart.Position)

                    if onScreen then
                        local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                        local centerDistance = (screenVector - screenCenter).Magnitude
                        local worldDistance = (aimPart.Position - camera.CFrame.Position).Magnitude

                        if centerDistance <= Settings.AimFOV then
                            local score = centerDistance + (worldDistance * 0.1)
                            if score < shortestDistance then
                                shortestDistance = score
                                bestTarget = aimPart
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Безопасная авто-стрельба для мобильных устройств
task.spawn(function()
    while true do
        task.wait(Settings.AutoShootDelay)
        if Settings.Enabled.AutoShoot then
            local target = getBestTarget()
            if target then
                local canShoot = true
                if Settings.Enabled.VisibleCheck and Settings.VisibleCheckActive then
                    canShoot = isVisible(target)
                end
                
                if canShoot then
                    pcall(function()
                        if mouse1press then
                            mouse1press()
                            task.wait(0.02)
                            mouse1release()
                        end
                    end)
                end
            end
        end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Inverium"
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local welcomeFrame = Instance.new("Frame", screenGui)
welcomeFrame.Size = UDim2.new(0, 320, 0, 90)
welcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
welcomeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
welcomeFrame.BackgroundColor3 = UI_COLORS.BG
welcomeFrame.BorderSizePixel = 0
welcomeFrame.BackgroundTransparency = 1
welcomeFrame.ZIndex = 10

Instance.new("UICorner", welcomeFrame).CornerRadius = UDim.new(0, 12)

local welcomeStroke = Instance.new("UIStroke", welcomeFrame)
welcomeStroke.Color = UI_COLORS.TAB_ACTIVE
welcomeStroke.Transparency = 1
welcomeStroke.Thickness = 1.5

local welcomeText = Instance.new("TextLabel", welcomeFrame)
welcomeText.Size = UDim2.new(1, 0, 1, 0)
welcomeText.Text = "Welcome to Inverium"
welcomeText.TextColor3 = UI_COLORS.TEXT
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextSize = 18
welcomeText.BackgroundTransparency = 1
welcomeText.TextTransparency = 1
welcomeText.ZIndex = 11

local bindListContainer = Instance.new("Frame", screenGui)
bindListContainer.Size = UDim2.new(0, 180, 0, 150)
bindListContainer.Position = UDim2.new(0, 10, 0, 60)
bindListContainer.BackgroundTransparency = 1
Instance.new("UIListLayout", bindListContainer)

local function updateBindList()
    bindListContainer:ClearAllChildren()
    Instance.new("UIListLayout", bindListContainer)

    local binds = {
        {Name = "SpeedHack", Active = Settings.SpeedHackActive},
        {Name = "VisibleCheck", Active = Settings.VisibleCheckActive},
        {Name = "AutoJump", Active = Settings.AutoJumpActive}
    }

    for _, b in ipairs(binds) do
        local label = Instance.new("TextLabel", bindListContainer)
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Text = b.Name .. " [" .. (b.Active and "ON" or "OFF") .. "]"
        label.TextColor3 = b.Active and UI_COLORS.BIND_ON or UI_COLORS.BIND_OFF
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
    end
end

local toggleMenuBtn = Instance.new("TextButton", screenGui)
toggleMenuBtn.Size = UDim2.new(0, 100, 0, 36)
toggleMenuBtn.Position = UDim2.new(0, 10, 0, 10)
toggleMenuBtn.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
toggleMenuBtn.TextColor3 = UI_COLORS.TEXT
toggleMenuBtn.Text = "Menu"
toggleMenuBtn.Font = Enum.Font.GothamBold
toggleMenuBtn.TextSize = 14
Instance.new("UICorner", toggleMenuBtn).CornerRadius = UDim.new(0, 8)

local draggingBtn = false
local dragInputBtn, dragStartBtn, startPosBtn

toggleMenuBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBtn = true
        dragStartBtn = input.Position
        startPosBtn = toggleMenuBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingBtn = false
            end
        end)
    end
end)

toggleMenuBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputBtn = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputBtn and draggingBtn then
        local delta = input.Position - dragStartBtn
        toggleMenuBtn.Position = UDim2.new(
            startPosBtn.X.Scale, 
            startPosBtn.X.Offset + delta.X, 
            startPosBtn.Y.Scale, 
            startPosBtn.Y.Offset + delta.Y
        )
    end
end)

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0.65, 0, 0.55, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = UI_COLORS.BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.BackgroundTransparency = 1
mainFrame.ClipsDescendants = true

local sizeConstraint = Instance.new("UISizeConstraint", mainFrame)
sizeConstraint.MaxSize = Vector2.new(650, 450)
sizeConstraint.MinSize = Vector2.new(320, 240)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = UI_COLORS.TAB_ACTIVE
mainStroke.Transparency = 1
mainStroke.Thickness = 1.5

local bgContainer = Instance.new("Frame", mainFrame)
bgContainer.Size = UDim2.new(1, 0, 1, 0)
bgContainer.BackgroundTransparency = 1
bgContainer.ZIndex = 0

local function spawnParticle()
    if not mainFrame.Parent then return end
    local p = Instance.new("Frame", bgContainer)
    local size = math.random(4, 7)
    p.Size = UDim2.new(0, size, 0, size)
    local startX = math.random()
    p.Position = UDim2.new(startX, 0, 1.1, 0)
    p.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
    p.BackgroundTransparency = math.random(2, 6) / 10
    p.BorderSizePixel = 0
    p.ZIndex = 1
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    
    local duration = math.random(3, 5)
    local endX = startX + (math.random() - 0.5) * 0.2
    
    local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(endX, 0, -0.1, 0),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        p:Destroy()
        spawnParticle()
    end)
end

local function startParticles()
    for i = 1, 12 do
        task.delay(math.random() * 2, spawnParticle)
    end
end

toggleMenuBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

local header = Instance.new("TextLabel", mainFrame)
header.Text = "inverium"
header.Size = UDim2.new(0.3, 0, 0, 35)
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextColor3 = UI_COLORS.TAB_ACTIVE
header.BackgroundTransparency = 1
header.ZIndex = 2

local tabs = {"Combat", "Player Visuals", "Misc"}
local tabContents = {}
local currentTab = "Combat"

local function switchTab(tabName)
    currentTab = tabName
    for name, content in pairs(tabContents) do
        content.Visible = (name == tabName)
    end
    local container = mainFrame:FindFirstChild("TabContainer")
    if container then
        for _, btn in pairs(container:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = (btn.Text == tabName) and UI_COLORS.TAB_ACTIVE or UI_COLORS.TAB_INACTIVE
            end
        end
    end
end

local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(0.7, -10, 0, 30)
tabContainer.Position = UDim2.new(0.3, 0, 0, 4)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 2

local totalTabs = #tabs
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(1 / totalTabs, -4, 1, 0)
    btn.Position = UDim2.new((i - 1) / totalTabs, 0, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextColor3 = UI_COLORS.TEXT
    btn.BackgroundColor3 = (name == currentTab) and UI_COLORS.TAB_ACTIVE or UI_COLORS.TAB_INACTIVE
    btn.BorderSizePixel = 0
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -16, 1, -45)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.Visible = (name == currentTab)
    scroll.ScrollBarThickness = 4
    scroll.ZIndex = 2
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 4)
    Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 6)
    tabContents[name] = scroll
end

local function createCheckbox(name, parent, settingKey)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -12, 0, 28)
    container.BackgroundTransparency = 1
    container.ZIndex = 2

    local box = Instance.new("TextButton", container)
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 0, 0, 5)
    box.BackgroundColor3 = Settings.Enabled[settingKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.CHECKBOX_OFF
    box.Text = ""
    box.ZIndex = 2
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -26, 1, 0)
    label.Position = UDim2.new(0, 26, 0, 0)
    label.Text = "Enable " .. name
    label.TextColor3 = UI_COLORS.TEXT
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.ZIndex = 2

    box.MouseButton1Click:Connect(function()
        Settings.Enabled[settingKey] = not Settings.Enabled[settingKey]
        box.BackgroundColor3 = Settings.Enabled[settingKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.CHECKBOX_OFF
        updateBindList()
    end)
end

local function createDropdown(name, parent, options, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -12, 0, 30)
    container.BackgroundTransparency = 1
    container.ZIndex = 2

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Text = name
    label.TextColor3 = UI_COLORS.TEXT
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.ZIndex = 2

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.5, 0, 1, -4)
    btn.Position = UDim2.new(0.5, 0, 0, 2)
    btn.Text = Settings.AimPart
    btn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
    btn.TextColor3 = UI_COLORS.TAB_ACTIVE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == Settings.AimPart then currentIndex = i end
    end

    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        local selected = options[currentIndex]
        btn.Text = selected
        callback(selected)
    end)
end

local function createSlider(name, parent, min, max, settingKey)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -12, 0, 42)
    container.BackgroundTransparency = 1
    container.ZIndex = 2

    local label = Instance.new("TextLabel", container)
    label.Text = name .. ": " .. string.format("%.2f", Settings[settingKey])
    label.TextColor3 = UI_COLORS.TEXT
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.ZIndex = 2

    local bg = Instance.new("Frame", container)
    bg.Size = UDim2.new(1, 0, 0, 10)
    bg.Position = UDim2.new(0, 0, 0, 22)
    bg.BackgroundColor3 = UI_COLORS.CHECKBOX_OFF
    bg.ZIndex = 2
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

    local bar = Instance.new("Frame", bg)
    bar.Size = UDim2.new(math.clamp((Settings[settingKey]-min)/(max-min), 0, 1), 0, 1, 0)
    bar.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
    bar.ZIndex = 2
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

    local dragging = false
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation()
            local relativeX = math.clamp(mousePos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X)
            local percent = relativeX / bg.AbsoluteSize.X
            local rawVal = min + (max - min) * percent
            Settings[settingKey] = math.floor(rawVal * 100) / 100
            bar.Size = UDim2.new(percent, 0, 1, 0)
            label.Text = name .. ": " .. string.format("%.2f", Settings[settingKey])
        end
    end)
end

local function createActionButton(parent, labelText, onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -12, 0, 30)
    btn.Text = labelText
    btn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
    btn.TextColor3 = UI_COLORS.TEXT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(onClick)
end

local combatContent = tabContents["Combat"]
createCheckbox("Aim", combatContent, "Aim")
createSlider("Aim Smooth", combatContent, 0, 1, "AimSmooth")
createCheckbox("Auto Shoot", combatContent, "AutoShoot")
createSlider("Auto Shoot Delay", combatContent, 0, 1, "AutoShootDelay")
createCheckbox("Show FOV", combatContent, "ShowFOV")
createCheckbox("FOV RGB", combatContent, "FOVRGB")
createSlider("Aim FOV", combatContent, 10, 500, "AimFOV")
createDropdown("Aim Part", combatContent, {"Head", "UpperTorso", "HumanoidRootPart"}, function(val)
    Settings.AimPart = val
end)
createCheckbox("Visible Check", combatContent, "VisibleCheck")
createActionButton(combatContent, "Toggle Visible Check", function()
    Settings.VisibleCheckActive = not Settings.VisibleCheckActive
    updateBindList()
end)

local playerVisualsContent = tabContents["Player Visuals"]
createCheckbox("ESP", playerVisualsContent, "EnableESP")
createCheckbox("Box ESP", playerVisualsContent, "BoxESP")
createCheckbox("Chams ESP", playerVisualsContent, "ChamsESP")
createCheckbox("Health Bar ESP", playerVisualsContent, "HealthBarESP")
createCheckbox("Tracer ESP", playerVisualsContent, "TracerESP")
createCheckbox("ESP RGB", playerVisualsContent, "ESPRGB")
createSlider("ESP Distance", playerVisualsContent, 100, 5000, "ESPDistance")

local miscContent = tabContents["Misc"]
createCheckbox("SpeedHack", miscContent, "SpeedHack")
createSlider("Speed Multiplier", miscContent, 1, 10, "SpeedMultiplier")
createActionButton(miscContent, "Toggle SpeedHack", function()
    Settings.SpeedHackActive = not Settings.SpeedHackActive
    updateBindList()
end)

createCheckbox("Auto Jump", miscContent, "AutoJump")
createActionButton(miscContent, "Toggle Auto Jump", function()
    Settings.AutoJumpActive = not Settings.AutoJumpActive
    updateBindList()
end)

createCheckbox("AntiKick", miscContent, "AntiKick")
createCheckbox("Sky RGB", miscContent, "SkyRGB")

task.spawn(function()
    local introInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    TweenService:Create(welcomeFrame, introInfo, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(welcomeStroke, introInfo, {Transparency = 0.3}):Play()
    TweenService:Create(welcomeText, introInfo, {TextTransparency = 0}):Play()
    
    task.wait(1.8)
    
    local outroInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(welcomeFrame, outroInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(welcomeStroke, outroInfo, {Transparency = 1}):Play()
    TweenService:Create(welcomeText, outroInfo, {TextTransparency = 1}):Play()
    
    task.wait(0.5)
    welcomeFrame:Destroy()
    
    mainFrame.Visible = true
    startParticles()
    
    local mainTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(mainFrame, mainTweenInfo, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(mainStroke, mainTweenInfo, {Transparency = 0.3}):Play()
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if Settings.Enabled.EnableESP then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= player then
                    local char = v.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")

                    if char and hrp and hum and hum.Health > 0 then
                        if not espDrawings[v] then
                            espDrawings[v] = {
                                Box = Drawing.new("Square"),
                                HealthBarBg = Drawing.new("Square"),
                                HealthBar = Drawing.new("Square"),
                                Tracer = Drawing.new("Line")
                            }
                            espDrawings[v].Box.Visible = false
                            espDrawings[v].Box.Thickness = 1.5
                            espDrawings[v].Box.Filled = false

                            espDrawings[v].HealthBarBg.Visible = false
                            espDrawings[v].HealthBarBg.Thickness = 1
                            espDrawings[v].HealthBarBg.Color = Color3.new(0, 0, 0)
                            espDrawings[v].HealthBarBg.Filled = true

                            espDrawings[v].HealthBar.Visible = false
                            espDrawings[v].HealthBar.Thickness = 1
                            espDrawings[v].HealthBar.Color = Color3.new(0, 1, 0)
                            espDrawings[v].HealthBar.Filled = true

                            espDrawings[v].Tracer.Visible = false
                            espDrawings[v].Tracer.Thickness = 1.5
                        end
                    else
                        removeEspForPlayer(v)
                    end
                end
            end
        else
            for v, _ in pairs(espDrawings) do
                removeEspForPlayer(v)
            end
        end
    end
end)

RunService:BindToRenderStep("InveriumRender", Enum.RenderPriority.Camera.Value + 1, function()
    local screenCenter = camera.ViewportSize / 2
    
    local tickVal = tick() * 2
    local rainbowColor = Color3.fromHSV(tickVal % 1, 1, 1)

    fovCircle.Position = screenCenter
    fovCircle.Radius = Settings.AimFOV
    fovCircle.Visible = Settings.Enabled.ShowFOV
    fovCircle.Color = Settings.Enabled.FOVRGB and rainbowColor or Settings.FOVColor

    local sky = Lighting:FindFirstChildOfClass("Sky")
    if Settings.Enabled.SkyRGB then
        if not sky then
            sky = Instance.new("Sky")
            sky.Parent = Lighting
        end
        sky.SkyboxBk = "rbxassetid://6444884337"
        Lighting.OutdoorAmbient = rainbowColor
    else
        if sky then
            sky:Destroy()
        end
        Lighting.OutdoorAmbient = Settings.SkyColor
    end

    if Settings.Enabled.Aim then
        local target = getBestTarget()
        if target then
            local targetCF = CFrame.new(camera.CFrame.Position, target.Position)
            if Settings.AimSmooth > 0 then
                camera.CFrame = camera.CFrame:Lerp(targetCF, math.clamp(1 - Settings.AimSmooth, 0.01, 1))
            else
                camera.CFrame = targetCF
            end
        end
    end

    if Settings.Enabled.EnableESP then
        for v, data in pairs(espDrawings) do
            if v and v.Character then
                local char = v.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")

                if hrp and hum and hum.Health > 0 and head then
                    local dist = (hrp.Position - camera.CFrame.Position).Magnitude
                    local activeColor = Settings.Enabled.ESPRGB and rainbowColor or Settings.ESPColor

                    if dist <= Settings.ESPDistance then
                        local headPos, headOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local rootPos, rootOn = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))

                        if headOn or rootOn then
                            local height = math.abs(headPos.Y - rootPos.Y)
                            local width = height / 2.2
                            local centerX = headPos.X

                            if Settings.Enabled.BoxESP then
                                data.Box.Size = Vector2.new(width, height)
                                data.Box.Position = Vector2.new(centerX - width / 2, headPos.Y)
                                data.Box.Color = activeColor
                                data.Box.Visible = true
                            else
                                data.Box.Visible = false
                            end

                            if Settings.Enabled.HealthBarESP then
                                local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

                                data.HealthBarBg.Size = Vector2.new(4, height)
                                data.HealthBarBg.Position = Vector2.new(centerX - width / 2 - 6, headPos.Y)
                                data.HealthBarBg.Visible = true

                                data.HealthBar.Size = Vector2.new(2, height * healthPercent)
                                data.HealthBar.Position = Vector2.new(centerX - width / 2 - 5, headPos.Y + (height * (1 - healthPercent)))
                                data.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                                data.HealthBar.Visible = true
                            else
                                data.HealthBarBg.Visible = false
                                data.HealthBar.Visible = false
                            end
                        else
                            data.Box.Visible = false
                            data.HealthBarBg.Visible = false
                            data.HealthBar.Visible = false
                        end

                        if Settings.Enabled.TracerESP then
                            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                data.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                                data.Tracer.Color = activeColor
                                data.Tracer.Visible = true
                            else
                                data.Tracer.Visible = false
                            end
                        else
                            data.Tracer.Visible = false
                        end

                        if Settings.Enabled.ChamsESP then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    local highlight = part:FindFirstChild("ChamsHighlight")
                                    if not highlight then
                                        highlight = Instance.new("Highlight")
                                        highlight.Name = "ChamsHighlight"
                                        highlight.Adornee = part
                                        highlight.FillTransparency = 0.5
                                        highlight.OutlineTransparency = 1
                                        highlight.Parent = part
                                    end
                                    highlight.FillColor = activeColor
                                end
                            end
                        else
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    local highlight = part:FindFirstChild("ChamsHighlight")
                                    if highlight then highlight:Destroy() end
                                end
                            end
                        end
                    else
                        data.Box.Visible = false
                        data.HealthBarBg.Visible = false
                        data.HealthBar.Visible = false
                        data.Tracer.Visible = false
                    end
                else
                    data.Box.Visible = false
                    data.HealthBarBg.Visible = false
                    data.HealthBar.Visible = false
                    data.Tracer.Visible = false
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeEspForPlayer(plr)
end)

RunService.Heartbeat:Connect(function(dt)
    if Settings.Enabled.SpeedHack and Settings.SpeedHackActive and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local hum = player.Character.Humanoid
        local move = hum.MoveDirection
        if move.Magnitude > 0 then
            local targetSpeed = Settings.SpeedMultiplier * 16
            local currentPos = hrp.Position
            local nextPos = currentPos + (move * targetSpeed * dt)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {player.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(currentPos + Vector3.new(0, 2, 0), (nextPos - currentPos), raycastParams)
            if not ray then
                hrp.CFrame = CFrame.new(nextPos, nextPos + hrp.CFrame.LookVector)
            end
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        end
    end

    if Settings.Enabled.AutoJump and Settings.AutoJumpActive and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
