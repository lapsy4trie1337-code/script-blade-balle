--[[
    Flow Hub - Interface Améliorée
    Script Hub Universel | 20+ Jeux
    Recréation avec UI moderne
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Nettoyage si déjà chargé
local _guiId = "FH_" .. math.random(1000, 9999)
if game.CoreGui:FindFirstChild(_guiId) then
    game.CoreGui:FindFirstChild(_guiId):Destroy()
end

-- ═══════════════════════════════════════════
-- CONFIG & ÉTAT
-- ═══════════════════════════════════════════

local Config = {
    ESP = false,
    ESPColor = Color3.fromRGB(0, 200, 255),
    ESPTeamCheck = false,
    Speed = false,
    SpeedValue = 16,
    Fly = false,
    FlySpeed = 50,
    InfiniteJump = false,
    Noclip = false,
    Fullbright = false,
    Aimbot = false,
    AimbotFOV = 200,
    AimbotSmooth = 5,
    KillAura = false,
    KillAuraRange = 15,
    AutoFarm = false,
    Teleport = false,
    GodMode = false,
    AntiAFK = true,
    -- Blade Ball
    AutoParry = false,
    AutoParryMode = "Distance", -- "Distance" ou "Timing"
    AutoParryDistance = 35,
    AutoParryDelay = 0.08,
    ParryVisualize = true,
}

local Connections = {}
local ESPObjects = {}
local FlyBody = nil
local FlyGyro = nil
local CurrentGame = "Universal"

-- ═══════════════════════════════════════════
-- JEUX SUPPORTÉS
-- ═══════════════════════════════════════════

local GameDatabase = {
    {name = "Blox Fruits", id = 2753915549, icon = "🍎", features = {"AutoFarm", "ESP", "Teleport", "AutoQuest", "ServerHop"}},
    {name = "RIVALS", id = 17625359962, icon = "🎯", features = {"Aimbot", "ESP", "Speed", "Fly", "Noclip"}},
    {name = "Blade Ball", id = 13772394625, icon = "⚔️", features = {"AutoParry", "ESP", "Speed", "KillAura"}},
    {name = "Brookhaven", id = 4924922222, icon = "🏠", features = {"ESP", "Speed", "Fly", "Noclip", "Teleport"}},
    {name = "Jujutsu Shenanigans", id = 15069882803, icon = "👊", features = {"AutoFarm", "ESP", "KillAura", "Speed"}},
    {name = "Murder Mystery 2", id = 142823291, icon = "🔪", features = {"ESP", "Speed", "Teleport", "GodMode"}},
    {name = "Sailor Piece", id = 0, icon = "⛵", features = {"AutoFarm", "ESP", "Teleport", "Speed"}},
    {name = "Fish it!", id = 0, icon = "🐟", features = {"AutoFarm", "ESP", "AutoCatch", "Teleport"}},
    {name = "Flickshot", id = 0, icon = "🔫", features = {"Aimbot", "ESP", "Speed", "Fly"}},
    {name = "Escape Tsunami", id = 0, icon = "🌊", features = {"Speed", "Fly", "Noclip", "InfiniteJump"}},
    {name = "99 Nights In The Forest", id = 0, icon = "🌲", features = {"ESP", "Speed", "Fly", "Fullbright", "GodMode"}},
    {name = "Scary Shawarma", id = 0, icon = "🌯", features = {"ESP", "Speed", "Fullbright", "Noclip"}},
    {name = "Garden Horizon", id = 0, icon = "🌻", features = {"AutoFarm", "ESP", "Teleport", "Speed"}},
    {name = "Da Hood", id = 2788229376, icon = "🔫", features = {"Aimbot", "ESP", "Speed", "KillAura", "GodMode"}},
    {name = "Pet Simulator X", id = 6284583030, icon = "🐾", features = {"AutoFarm", "ESP", "Teleport", "AutoHatch"}},
    {name = "King Legacy", id = 4520749081, icon = "👑", features = {"AutoFarm", "ESP", "Teleport", "AutoQuest"}},
    {name = "Anime Fighters", id = 8304191830, icon = "⭐", features = {"AutoFarm", "ESP", "Teleport"}},
    {name = "Shindo Life", id = 4616652839, icon = "🥷", features = {"AutoFarm", "ESP", "Speed", "KillAura"}},
    {name = "Arsenal", id = 286090429, icon = "💣", features = {"Aimbot", "ESP", "Speed", "Fly"}},
    {name = "Tower of Hell", id = 1962086868, icon = "🗼", features = {"Speed", "Fly", "InfiniteJump", "Noclip"}},
}

-- ═══════════════════════════════════════════
-- COULEURS & THÈME
-- ═══════════════════════════════════════════

local Theme = {
    Background = Color3.fromRGB(15, 15, 25),
    Surface = Color3.fromRGB(22, 22, 35),
    SurfaceLight = Color3.fromRGB(30, 30, 48),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentLight = Color3.fromRGB(110, 125, 255),
    AccentDark = Color3.fromRGB(60, 70, 180),
    Success = Color3.fromRGB(45, 212, 120),
    Danger = Color3.fromRGB(237, 66, 69),
    Warning = Color3.fromRGB(254, 180, 44),
    Text = Color3.fromRGB(230, 230, 245),
    TextDim = Color3.fromRGB(140, 140, 165),
    Border = Color3.fromRGB(45, 45, 65),
    Glow = Color3.fromRGB(88, 101, 242),
}

-- ═══════════════════════════════════════════
-- UTILITAIRES UI
-- ═══════════════════════════════════════════

local function Tween(obj, props, duration, style, direction)
    local tween = TweenService:Create(obj, TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), props)
    tween:Play()
    return tween
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function CreatePadding(parent, top, right, bottom, left)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 8)
    padding.PaddingRight = UDim.new(0, right or 8)
    padding.PaddingBottom = UDim.new(0, bottom or 8)
    padding.PaddingLeft = UDim.new(0, left or 8)
    padding.Parent = parent
    return padding
end

local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

-- ═══════════════════════════════════════════
-- CRÉATION DE L'INTERFACE
-- ═══════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = _guiId
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Conteneur principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 580, 0, 420)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 12)
CreateStroke(MainFrame, Theme.Border, 1)

-- Animation d'ouverture
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundTransparency = 1
Tween(MainFrame, {
    Size = UDim2.new(0, 580, 0, 420),
    Position = UDim2.new(0.5, -290, 0.5, -210),
    BackgroundTransparency = 0
}, 0.5, Enum.EasingStyle.Back)

-- Glow Effect derrière
local GlowFrame = Instance.new("Frame")
GlowFrame.Name = "Glow"
GlowFrame.Size = UDim2.new(1, 4, 1, 4)
GlowFrame.Position = UDim2.new(0, -2, 0, -2)
GlowFrame.BackgroundColor3 = Theme.Glow
GlowFrame.BackgroundTransparency = 0.85
GlowFrame.ZIndex = 0
GlowFrame.Parent = MainFrame
CreateCorner(GlowFrame, 14)

-- ═══════════════════════════════════════════
-- BARRE DE TITRE
-- ═══════════════════════════════════════════

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Theme.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
CreateCorner(TitleBar, 12)

-- Fix coins bas de la barre de titre
local TitleBarFix = Instance.new("Frame")
TitleBarFix.Name = "Fix"
TitleBarFix.Size = UDim2.new(1, 0, 0, 15)
TitleBarFix.Position = UDim2.new(0, 0, 1, -15)
TitleBarFix.BackgroundColor3 = Theme.Surface
TitleBarFix.BorderSizePixel = 0
TitleBarFix.Parent = TitleBar

-- Ligne accent sous la barre
local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, 0)
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TitleBar

-- Gradient sur la ligne accent
local lineGradient = Instance.new("UIGradient")
lineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentDark),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentDark),
})
lineGradient.Parent = AccentLine

-- Logo / Titre
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FLOW HUB"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Indicateur accent dans le titre
local TitleDot = Instance.new("TextLabel")
TitleDot.Name = "Dot"
TitleDot.Size = UDim2.new(0, 20, 1, 0)
TitleDot.Position = UDim2.new(0, 100, 0, 0)
TitleDot.BackgroundTransparency = 1
TitleDot.Text = "v2.0"
TitleDot.TextColor3 = Theme.Accent
TitleDot.TextSize = 11
TitleDot.Font = Enum.Font.GothamMedium
TitleDot.TextXAlignment = Enum.TextXAlignment.Left
TitleDot.Parent = TitleBar

-- Info joueur
local PlayerInfo = Instance.new("TextLabel")
PlayerInfo.Name = "PlayerInfo"
PlayerInfo.Size = UDim2.new(0, 200, 1, 0)
PlayerInfo.Position = UDim2.new(1, -260, 0, 0)
PlayerInfo.BackgroundTransparency = 1
PlayerInfo.Text = LocalPlayer.Name .. " | " .. game.PlaceId
PlayerInfo.TextColor3 = Theme.TextDim
PlayerInfo.TextSize = 11
PlayerInfo.Font = Enum.Font.Gotham
PlayerInfo.TextXAlignment = Enum.TextXAlignment.Right
PlayerInfo.Parent = TitleBar

-- Bouton Minimiser
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "Minimize"
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -68, 0, 6)
MinBtn.BackgroundColor3 = Theme.SurfaceLight
MinBtn.BorderSizePixel = 0
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextDim
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
CreateCorner(MinBtn, 6)

-- Bouton Fermer
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 6)
CloseBtn.BackgroundColor3 = Theme.Danger
CloseBtn.BackgroundTransparency = 0.7
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
CreateCorner(CloseBtn, 6)

-- ═══════════════════════════════════════════
-- DRAGGING
-- ═══════════════════════════════════════════

local dragging, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ═══════════════════════════════════════════
-- SIDEBAR (NAVIGATION)
-- ═══════════════════════════════════════════

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 55, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = Theme.Surface
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

-- Fix coin haut de sidebar
local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(1, 0, 0, 10)
SidebarFix.BackgroundColor3 = Theme.Surface
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

-- Bordure droite sidebar
local SidebarBorder = Instance.new("Frame")
SidebarBorder.Size = UDim2.new(0, 1, 1, 0)
SidebarBorder.Position = UDim2.new(1, 0, 0, 0)
SidebarBorder.BackgroundColor3 = Theme.Border
SidebarBorder.BorderSizePixel = 0
SidebarBorder.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 12)
SidebarPadding.Parent = Sidebar

local TabPages = {}
local TabButtons = {}
local ActiveTab = nil

local Tabs = {
    {name = "Home", icon = "🏠", order = 1},
    {name = "Games", icon = "🎮", order = 2},
    {name = "Universal", icon = "🌐", order = 3},
    {name = "Player", icon = "🏃", order = 4},
    {name = "Visuals", icon = "👁", order = 5},
    {name = "BladeBall", icon = "⚔️", order = 6},
    {name = "Settings", icon = "⚙", order = 7},
}

-- ═══════════════════════════════════════════
-- ZONE DE CONTENU
-- ═══════════════════════════════════════════

local ContentArea = Instance.new("Frame")
ContentArea.Name = "Content"
ContentArea.Size = UDim2.new(1, -56, 1, -44)
ContentArea.Position = UDim2.new(0, 56, 0, 44)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

-- ═══════════════════════════════════════════
-- SYSTÈME DE NOTIFICATIONS
-- ═══════════════════════════════════════════

local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Notifications"
NotifContainer.Size = UDim2.new(0, 280, 1, 0)
NotifContainer.Position = UDim2.new(1, -290, 0, 50)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Parent = NotifContainer

local function Notify(title, message, duration, notifType)
    local color = Theme.Accent
    if notifType == "success" then color = Theme.Success
    elseif notifType == "error" then color = Theme.Danger
    elseif notifType == "warning" then color = Theme.Warning end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Theme.Surface
    notif.BorderSizePixel = 0
    notif.BackgroundTransparency = 1
    notif.Parent = NotifContainer
    CreateCorner(notif, 8)
    CreateStroke(notif, color, 1)

    local notifAccent = Instance.new("Frame")
    notifAccent.Size = UDim2.new(0, 3, 1, -8)
    notifAccent.Position = UDim2.new(0, 4, 0, 4)
    notifAccent.BackgroundColor3 = color
    notifAccent.BorderSizePixel = 0
    notifAccent.Parent = notif
    CreateCorner(notifAccent, 2)

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Size = UDim2.new(1, -20, 0, 20)
    notifTitle.Position = UDim2.new(0, 14, 0, 6)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Theme.Text
    notifTitle.TextSize = 13
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextXAlignment = Enum.TextXAlignment.Left
    notifTitle.Parent = notif

    local notifMsg = Instance.new("TextLabel")
    notifMsg.Size = UDim2.new(1, -20, 0, 28)
    notifMsg.Position = UDim2.new(0, 14, 0, 26)
    notifMsg.BackgroundTransparency = 1
    notifMsg.Text = message
    notifMsg.TextColor3 = Theme.TextDim
    notifMsg.TextSize = 11
    notifMsg.Font = Enum.Font.Gotham
    notifMsg.TextXAlignment = Enum.TextXAlignment.Left
    notifMsg.TextWrapped = true
    notifMsg.Parent = notif

    Tween(notif, {BackgroundTransparency = 0}, 0.3)

    task.delay(duration or 3, function()
        Tween(notif, {BackgroundTransparency = 1}, 0.3)
        task.delay(0.35, function()
            notif:Destroy()
        end)
    end)
end

-- ═══════════════════════════════════════════
-- COMPOSANTS UI RÉUTILISABLES
-- ═══════════════════════════════════════════

local function CreateToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 36)
    container.BackgroundColor3 = Theme.SurfaceLight
    container.BorderSizePixel = 0
    container.Parent = parent
    CreateCorner(container, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 22)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBg.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(50, 50, 70)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    CreateCorner(toggleBg, 11)

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBg
    CreateCorner(toggleCircle, 8)

    local enabled = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = container

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        Tween(toggleBg, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(50, 50, 70)}, 0.2)
        Tween(toggleCircle, {Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2)
        if callback then callback(enabled) end
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        Tween(container, {BackgroundColor3 = Color3.fromRGB(38, 38, 58)}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(container, {BackgroundColor3 = Theme.SurfaceLight}, 0.15)
    end)

    return container, function() return enabled end, function(val)
        enabled = val
        Tween(toggleBg, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(50, 50, 70)}, 0.2)
        Tween(toggleCircle, {Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2)
    end
end

local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 52)
    container.BackgroundColor3 = Theme.SurfaceLight
    container.BorderSizePixel = 0
    container.Parent = parent
    CreateCorner(container, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -58, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 6)
    sliderBg.Position = UDim2.new(0, 12, 0, 32)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    CreateCorner(sliderBg, 3)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    CreateCorner(sliderFill, 3)

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 0, 20)
    sliderBtn.Position = UDim2.new(0, 0, 0, 24)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = container

    local sliding = false

    sliderBtn.MouseButton1Down:Connect(function()
        sliding = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end
    end)

    return container
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 34)
    btn.BackgroundColor3 = Theme.Accent
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    CreateCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.AccentLight}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        Tween(btn, {Size = UDim2.new(1, -20, 0, 32)}, 0.1)
        task.delay(0.1, function()
            Tween(btn, {Size = UDim2.new(1, -16, 0, 34)}, 0.1)
        end)
        if callback then callback() end
    end)

    return btn
end

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 24)
    section.BackgroundTransparency = 1
    section.Parent = parent

    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Size = UDim2.new(1, -8, 1, 0)
    sectionLabel.Position = UDim2.new(0, 4, 0, 0)
    sectionLabel.BackgroundTransparency = 1
    sectionLabel.Text = string.upper(title)
    sectionLabel.TextColor3 = Theme.TextDim
    sectionLabel.TextSize = 10
    sectionLabel.Font = Enum.Font.GothamBold
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel.Parent = section

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -8, 0, 1)
    line.Position = UDim2.new(0, 4, 1, -1)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    line.Parent = section

    return section
end

-- ═══════════════════════════════════════════
-- CRÉER LES BOUTONS DE SIDEBAR
-- ═══════════════════════════════════════════

for i, tabData in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Name = tabData.name
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.BackgroundColor3 = Theme.SurfaceLight
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = tabData.icon
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = tabData.order
    btn.Parent = Sidebar
    CreateCorner(btn, 10)

    TabButtons[tabData.name] = btn
end

-- ═══════════════════════════════════════════
-- CRÉER LES PAGES
-- ═══════════════════════════════════════════

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    CreatePadding(page, 10, 8, 10, 8)

    TabPages[name] = page
    return page
end

-- ═══════════════════════════════════════════
-- PAGE HOME
-- ═══════════════════════════════════════════

local homePage = CreatePage("Home")

-- Bannière
local banner = Instance.new("Frame")
banner.Size = UDim2.new(1, -16, 0, 100)
banner.BackgroundColor3 = Theme.Accent
banner.BorderSizePixel = 0
banner.Parent = homePage
CreateCorner(banner, 10)

local bannerGradient = Instance.new("UIGradient")
bannerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 60, 220)),
})
bannerGradient.Rotation = 25
bannerGradient.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Size = UDim2.new(1, -20, 0, 30)
bannerTitle.Position = UDim2.new(0, 15, 0, 15)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Text = "FLOW HUB v2.0"
bannerTitle.TextColor3 = Color3.new(1, 1, 1)
bannerTitle.TextSize = 22
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
bannerTitle.Parent = banner

local bannerSub = Instance.new("TextLabel")
bannerSub.Size = UDim2.new(1, -20, 0, 20)
bannerSub.Position = UDim2.new(0, 15, 0, 45)
bannerSub.BackgroundTransparency = 1
bannerSub.Text = "Script Hub Universel | 20+ Jeux | Interface Premium"
bannerSub.TextColor3 = Color3.fromRGB(210, 210, 240)
bannerSub.TextSize = 12
bannerSub.Font = Enum.Font.GothamMedium
bannerSub.TextXAlignment = Enum.TextXAlignment.Left
bannerSub.Parent = banner

local bannerStats = Instance.new("TextLabel")
bannerStats.Size = UDim2.new(1, -20, 0, 20)
bannerStats.Position = UDim2.new(0, 15, 0, 68)
bannerStats.BackgroundTransparency = 1
bannerStats.Text = "Joueur: " .. LocalPlayer.Name .. "  |  Jeu: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
bannerStats.TextColor3 = Color3.fromRGB(190, 190, 220)
bannerStats.TextSize = 11
bannerStats.Font = Enum.Font.Gotham
bannerStats.TextXAlignment = Enum.TextXAlignment.Left
bannerStats.Parent = banner

pcall(function()
    bannerStats.Text = "Joueur: " .. LocalPlayer.Name .. "  |  Jeu: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

-- Statut cards
local statsRow = Instance.new("Frame")
statsRow.Size = UDim2.new(1, -16, 0, 60)
statsRow.BackgroundTransparency = 1
statsRow.Parent = homePage

local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.Padding = UDim.new(0, 8)
statsLayout.Parent = statsRow

local function CreateStatCard(parent, title, value, color)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.32, -4, 1, 0)
    card.BackgroundColor3 = Theme.SurfaceLight
    card.BorderSizePixel = 0
    card.Parent = parent
    CreateCorner(card, 8)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0.6, 0)
    accent.Position = UDim2.new(0, 5, 0.2, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = card
    CreateCorner(accent, 2)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(1, -20, 0, 22)
    valLabel.Position = UDim2.new(0, 14, 0, 8)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = value
    valLabel.TextColor3 = Theme.Text
    valLabel.TextSize = 16
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Left
    valLabel.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 16)
    titleLabel.Position = UDim2.new(0, 14, 0, 32)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextDim
    titleLabel.TextSize = 10
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    return card
end

CreateStatCard(statsRow, "JEUX", tostring(#GameDatabase) .. "+", Theme.Accent)
CreateStatCard(statsRow, "JOUEURS", tostring(#Players:GetPlayers()), Theme.Success)
CreateStatCard(statsRow, "PING", tostring(math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())) .. "ms", Theme.Warning)

-- Quick Actions
CreateSection(homePage, "Actions Rapides")

CreateButton(homePage, "Rejoindre le Discord", function()
    Notify("Discord", "Lien copie dans le presse-papier", 3, "success")
    if setclipboard then setclipboard("discord.gg/flowhub") end
end)

CreateButton(homePage, "Copier le Script", function()
    Notify("Script", "Loadstring copie!", 3, "success")
    if setclipboard then setclipboard('loadstring(game:HttpGet("https://example.com"))()') end
end)

-- ═══════════════════════════════════════════
-- PAGE GAMES
-- ═══════════════════════════════════════════

local gamesPage = CreatePage("Games")
CreateSection(gamesPage, "Jeux avec Support Dedie (" .. #GameDatabase .. " jeux)")

-- Détection du jeu actuel
local currentPlaceId = game.PlaceId
local detectedGame = nil

for _, gameInfo in ipairs(GameDatabase) do
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -16, 0, 50)
    card.BackgroundColor3 = Theme.SurfaceLight
    card.BorderSizePixel = 0
    card.Parent = gamesPage
    CreateCorner(card, 8)

    local isCurrentGame = gameInfo.id == currentPlaceId
    if isCurrentGame then
        detectedGame = gameInfo
        CreateStroke(card, Theme.Success, 1)
    end

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 36, 0, 36)
    icon.Position = UDim2.new(0, 8, 0.5, -18)
    icon.BackgroundColor3 = Theme.Background
    icon.Text = gameInfo.icon
    icon.TextSize = 18
    icon.Parent = card
    CreateCorner(icon, 8)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -130, 0, 20)
    name.Position = UDim2.new(0, 52, 0, 5)
    name.BackgroundTransparency = 1
    name.Text = gameInfo.name
    name.TextColor3 = Theme.Text
    name.TextSize = 13
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = card

    local features = Instance.new("TextLabel")
    features.Size = UDim2.new(1, -60, 0, 16)
    features.Position = UDim2.new(0, 52, 0, 27)
    features.BackgroundTransparency = 1
    features.Text = table.concat(gameInfo.features, " | ")
    features.TextColor3 = Theme.TextDim
    features.TextSize = 10
    features.Font = Enum.Font.Gotham
    features.TextXAlignment = Enum.TextXAlignment.Left
    features.Parent = card

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 70, 0, 22)
    status.Position = UDim2.new(1, -78, 0.5, -11)
    status.BackgroundColor3 = isCurrentGame and Theme.Success or Theme.AccentDark
    status.BackgroundTransparency = isCurrentGame and 0.8 or 0.85
    status.Text = isCurrentGame and "ACTIF" or "PRET"
    status.TextColor3 = isCurrentGame and Theme.Success or Theme.Accent
    status.TextSize = 10
    status.Font = Enum.Font.GothamBold
    status.Parent = card
    CreateCorner(status, 6)
end

-- ═══════════════════════════════════════════
-- PAGE UNIVERSAL
-- ═══════════════════════════════════════════

local universalPage = CreatePage("Universal")
CreateSection(universalPage, "ESP & Visuels")

CreateToggle(universalPage, "Player ESP (Boites)", Config.ESP, function(val)
    Config.ESP = val
    if val then
        Notify("ESP", "ESP Active - Tous les joueurs sont visibles", 3, "success")
    else
        Notify("ESP", "ESP Desactive", 2)
        for _, obj in pairs(ESPObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        ESPObjects = {}
    end
end)

CreateToggle(universalPage, "Team Check ESP", Config.ESPTeamCheck, function(val)
    Config.ESPTeamCheck = val
end)

CreateToggle(universalPage, "Fullbright", Config.Fullbright, function(val)
    Config.Fullbright = val
    if val then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Notify("Fullbright", "Luminosite maximale activee", 2, "success")
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Notify("Fullbright", "Luminosite restauree", 2)
    end
end)

CreateSection(universalPage, "Combat")

CreateToggle(universalPage, "Aimbot", Config.Aimbot, function(val)
    Config.Aimbot = val
    Notify("Aimbot", val and "Aimbot Active" or "Aimbot Desactive", 2, val and "success" or nil)
end)

CreateSlider(universalPage, "FOV Aimbot", 50, 500, Config.AimbotFOV, function(val)
    Config.AimbotFOV = val
end)

CreateSlider(universalPage, "Smoothness", 1, 20, Config.AimbotSmooth, function(val)
    Config.AimbotSmooth = val
end)

CreateToggle(universalPage, "Kill Aura", Config.KillAura, function(val)
    Config.KillAura = val
    Notify("Kill Aura", val and "Kill Aura Active" or "Kill Aura Desactive", 2, val and "warning" or nil)
end)

CreateSlider(universalPage, "Range Kill Aura", 5, 50, Config.KillAuraRange, function(val)
    Config.KillAuraRange = val
end)

-- ═══════════════════════════════════════════
-- PAGE PLAYER
-- ═══════════════════════════════════════════

local playerPage = CreatePage("Player")
CreateSection(playerPage, "Mouvement")

CreateToggle(playerPage, "Speed Hack", Config.Speed, function(val)
    Config.Speed = val
    if not val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
    Notify("Speed", val and "Speed activee" or "Speed desactivee", 2, val and "success" or nil)
end)

CreateSlider(playerPage, "Vitesse", 16, 200, Config.SpeedValue, function(val)
    Config.SpeedValue = val
end)

CreateToggle(playerPage, "Fly", Config.Fly, function(val)
    Config.Fly = val
    if val then
        Notify("Fly", "Vol active - E pour monter, Q pour descendre", 3, "success")
    else
        Notify("Fly", "Vol desactive", 2)
        if FlyBody then FlyBody:Destroy() FlyBody = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    end
end)

CreateSlider(playerPage, "Vitesse de Vol", 10, 200, Config.FlySpeed, function(val)
    Config.FlySpeed = val
end)

CreateToggle(playerPage, "Infinite Jump", Config.InfiniteJump, function(val)
    Config.InfiniteJump = val
    Notify("Jump", val and "Infinite Jump active" or "Infinite Jump desactive", 2, val and "success" or nil)
end)

CreateToggle(playerPage, "Noclip", Config.Noclip, function(val)
    Config.Noclip = val
    Notify("Noclip", val and "Noclip active" or "Noclip desactive", 2, val and "success" or nil)
end)

CreateSection(playerPage, "Teleportation")

CreateButton(playerPage, "Teleport au Curseur (Clic Droit)", function()
    Config.Teleport = not Config.Teleport
    Notify("Teleport", Config.Teleport and "Cliquez droit pour teleporter" or "Teleport desactive", 2, Config.Teleport and "success" or nil)
end)

CreateToggle(playerPage, "God Mode (Tentative)", Config.GodMode, function(val)
    Config.GodMode = val
    if val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function()
            LocalPlayer.Character.Humanoid.MaxHealth = math.huge
            LocalPlayer.Character.Humanoid.Health = math.huge
        end)
        Notify("God Mode", "God Mode active (peut ne pas marcher sur tous les jeux)", 3, "warning")
    end
end)

-- ═══════════════════════════════════════════
-- PAGE VISUALS
-- ═══════════════════════════════════════════

local visualsPage = CreatePage("Visuals")
CreateSection(visualsPage, "Effets Visuels")

CreateToggle(visualsPage, "Anti-Fog", false, function(val)
    if val then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
    end
end)

CreateButton(visualsPage, "Capture d'Ecran (Sans UI)", function()
    MainFrame.Visible = false
    task.wait(0.1)
    Notify("Screenshot", "UI cache pendant 3 secondes", 1, "success")
    task.wait(3)
    MainFrame.Visible = true
end)

CreateSection(visualsPage, "Ambiance")

CreateButton(visualsPage, "Nuit", function()
    Lighting.ClockTime = 0
    Notify("Ambiance", "Mode nuit active", 2)
end)

CreateButton(visualsPage, "Jour", function()
    Lighting.ClockTime = 14
    Notify("Ambiance", "Mode jour active", 2)
end)

CreateButton(visualsPage, "Coucher de Soleil", function()
    Lighting.ClockTime = 18
    Notify("Ambiance", "Coucher de soleil active", 2)
end)

-- ═══════════════════════════════════════════
-- PAGE BLADE BALL (Auto Parry dédié)
-- ═══════════════════════════════════════════

local bladeBallPage = CreatePage("BladeBall")

CreateSection(bladeBallPage, "Auto Parry")

CreateToggle(bladeBallPage, "Auto Parry", Config.AutoParry, function(val)
    Config.AutoParry = val
    if val then
        Notify("Auto Parry", "Active! Parry automatique en cours", 3, "success")
    else
        Notify("Auto Parry", "Desactive", 2)
    end
end)

CreateSlider(bladeBallPage, "Distance de Parry", 10, 80, Config.AutoParryDistance, function(val)
    Config.AutoParryDistance = val
end)

CreateSlider(bladeBallPage, "Delai (ms)", 0, 200, math.floor(Config.AutoParryDelay * 1000), function(val)
    Config.AutoParryDelay = val / 1000
end)

CreateToggle(bladeBallPage, "Visualiser la Zone", Config.ParryVisualize, function(val)
    Config.ParryVisualize = val
end)

CreateSection(bladeBallPage, "Mode")

CreateButton(bladeBallPage, "Mode: Distance (Standard)", function()
    Config.AutoParryMode = "Distance"
    Notify("Mode", "Mode Distance - Parry base sur la distance", 2, "success")
end)

CreateButton(bladeBallPage, "Mode: Timing (Velocity)", function()
    Config.AutoParryMode = "Timing"
    Notify("Mode", "Mode Timing - Parry base sur le temps d'impact", 2, "success")
end)

CreateSection(bladeBallPage, "Info")

local parryInfoLabel = Instance.new("TextLabel")
parryInfoLabel.Size = UDim2.new(1, -16, 0, 90)
parryInfoLabel.BackgroundColor3 = Theme.SurfaceLight
parryInfoLabel.BorderSizePixel = 0
parryInfoLabel.Text = "Mode Distance: Parry quand la balle entre dans le rayon\nMode Timing: Predit le temps d'impact (+ reactif)\n\nParry d'urgence auto si balle < 8 studs\n3 methodes de parry (remote + clic + input)\nDelai 0 = parry instantane"
parryInfoLabel.TextColor3 = Theme.TextDim
parryInfoLabel.TextSize = 11
parryInfoLabel.Font = Enum.Font.Gotham
parryInfoLabel.TextWrapped = true
parryInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
parryInfoLabel.Parent = bladeBallPage
CreateCorner(parryInfoLabel, 8)
CreatePadding(parryInfoLabel, 10, 10, 10, 10)

-- ═══════════════════════════════════════════
-- PAGE SETTINGS
-- ═══════════════════════════════════════════

local settingsPage = CreatePage("Settings")
CreateSection(settingsPage, "General")

CreateToggle(settingsPage, "Anti-AFK", Config.AntiAFK, function(val)
    Config.AntiAFK = val
    Notify("Anti-AFK", val and "Anti-AFK active" or "Anti-AFK desactive", 2, val and "success" or nil)
end)

CreateSection(settingsPage, "Interface")

CreateButton(settingsPage, "Reinitialiser Position", function()
    Tween(MainFrame, {
        Position = UDim2.new(0.5, -290, 0.5, -210)
    }, 0.3)
    Notify("UI", "Position reinitialisee", 2, "success")
end)

CreateButton(settingsPage, "Detruire le Hub", function()
    for _, conn in pairs(Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    for _, obj in pairs(ESPObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    if FlyBody then FlyBody:Destroy() end
    if FlyGyro then FlyGyro:Destroy() end
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.5, function()
        ScreenGui:Destroy()
    end)
end)

CreateSection(settingsPage, "Raccourcis Clavier")

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -16, 0, 80)
infoLabel.BackgroundColor3 = Theme.SurfaceLight
infoLabel.BorderSizePixel = 0
infoLabel.Text = "Insert = Afficher/Cacher le Hub\nClic Droit = Teleport (si active)\nE = Monter (Fly)\nQ = Descendre (Fly)"
infoLabel.TextColor3 = Theme.TextDim
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = settingsPage
CreateCorner(infoLabel, 8)
CreatePadding(infoLabel, 10, 10, 10, 10)

-- ═══════════════════════════════════════════
-- SYSTÈME DE NAVIGATION
-- ═══════════════════════════════════════════

local function SwitchTab(tabName)
    if ActiveTab == tabName then return end

    for name, page in pairs(TabPages) do
        if page.Visible and name ~= tabName then
            page.Visible = false
        end
    end

    for name, btn in pairs(TabButtons) do
        if name == tabName then
            Tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent}, 0.2)
        else
            Tween(btn, {BackgroundTransparency = 1}, 0.2)
        end
    end

    if TabPages[tabName] then
        TabPages[tabName].Visible = true
        TabPages[tabName].CanvasPosition = Vector2.new(0, 0)
    end

    ActiveTab = tabName
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= name then
            Tween(btn, {BackgroundTransparency = 0.6, BackgroundColor3 = Theme.SurfaceLight}, 0.15)
        end
    end)

    btn.MouseLeave:Connect(function()
        if ActiveTab ~= name then
            Tween(btn, {BackgroundTransparency = 1}, 0.15)
        end
    end)
end

SwitchTab("Home")

-- ═══════════════════════════════════════════
-- BOUTONS TITRE BAR
-- ═══════════════════════════════════════════

local isMinimized = false

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 44)}, 0.3)
        ContentArea.Visible = false
        Sidebar.Visible = false
    else
        Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 420)}, 0.3)
        task.delay(0.15, function()
            ContentArea.Visible = true
            Sidebar.Visible = true
        end)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.5, function()
        MainFrame.Visible = false
    end)
end)

-- Toggle visibility avec Insert
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            MainFrame.BackgroundTransparency = 1
            Tween(MainFrame, {
                Size = UDim2.new(0, 580, 0, 420),
                Position = UDim2.new(0.5, -290, 0.5, -210),
                BackgroundTransparency = 0
            }, 0.4, Enum.EasingStyle.Back)
        end
    end
end)

-- ═══════════════════════════════════════════
-- FONCTIONNALITÉS PRINCIPALES
-- ═══════════════════════════════════════════

-- ═══════════════════════════════════════════
-- AUTO PARRY (Blade Ball) - v4 Custom Anti-BAC
-- Techniques du script de ref v28 reecrites :
--   zoomies, buffer 24 frames, simulation courbes,
--   omega, compensation ping, teleport/rebond,
--   attribut target, Highlight rouge, clash spam
-- ═══════════════════════════════════════════

local StatsService = game:GetService("Stats")

local HIT_R = 2.5
local SPAM_RANGE = 18
local MAX_BALLES = 40

local pingSec = 0.1
local lastClic = 0
local lastParryTime = 0
local compteurParry = 0
local serieParry = 0
local bestSerie = 0
local persoRouge = false

local ballesTracked = {}
local ballesCount = 0

-- Ping en boucle
local function LirePing()
    local ok, v = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(v) == "number" and v > 0 then return v / 1000 end
    local ok2, v2 = pcall(function() return LocalPlayer:GetNetworkPing() end)
    if ok2 and type(v2) == "number" and v2 > 0 then return v2 * 2 end
    return 0.1
end

task.spawn(function()
    while true do
        pingSec = LirePing()
        task.wait(1)
    end
end)

-- Highlight rouge (le jeu met un Highlight sur le joueur cible)
local function VerifierRouge()
    local c = LocalPlayer.Character
    if not c then persoRouge = false return end
    local ok, h = pcall(c.FindFirstChildWhichIsA, c, "Highlight")
    persoRouge = ok and h ~= nil
end

-- Velocite : zoomies > AssemblyLinearVelocity > delta position
local function LireVelocite(part, st, now, pos)
    local buf = st.buf
    local dernier = buf[#buf]

    if not dernier then
        buf[1] = {t = now, p = pos}
    elseif now - dernier.t > 0.0005 then
        local saut = pos - dernier.p
        local sautMag = saut.Magnitude
        local velMag = st.vel.Magnitude

        if sautMag > 50 and sautMag > velMag * (now - dernier.t) * 4 then
            st.buf = {}
            buf = st.buf
            st.vel = Vector3.zero
        elseif st.stable >= 2 and velMag > 20
            and sautMag > velMag * (now - dernier.t) * 0.3
            and saut:Dot(st.vel) < -0.5 * sautMag * velMag then
            buf = {dernier}
            st.buf = buf
        end

        buf[#buf + 1] = {t = now, p = pos}
        if #buf > 24 then table.remove(buf, 1) end
    end

    st.stable = 0
    local n = #buf
    if n >= 2 then
        local ancien = buf[1]
        for i = n - 1, 1, -1 do
            ancien = buf[i]
            if now - ancien.t >= 0.08 then break end
        end
        local duree = now - ancien.t
        if duree >= 0.03 then
            st.vel = (pos - ancien.p) / duree
            st.stable = n >= 3 and 2 or 1
        end
    end

    local vel, src = nil, "aucune"
    local z = part:FindFirstChild("zoomies")
    if z then
        local ok, v = pcall(function() return z.VectorVelocity end)
        if ok and typeof(v) == "Vector3" and v.Magnitude > 1 then
            vel, src = v, "zoomies"
        end
    end

    if not vel then
        local ok, v = pcall(function() return part.AssemblyLinearVelocity end)
        if ok and typeof(v) == "Vector3" and v.Magnitude > 1 then
            vel, src = v, "physique"
        end
    end

    if not vel and st.stable >= 2 then
        vel, src = st.vel, "delta"
    end

    if not vel then return Vector3.zero, 0, src end
    local speed = vel.Magnitude
    if speed < 0.01 then return Vector3.zero, 0, src end

    if src ~= "delta" and st.stable >= 2 and st.vel.Magnitude > 2 then
        local du = st.vel.Unit
        if (vel / speed):Dot(du) < 0.5 then
            vel = du * speed
        end
    end

    return vel, speed, src
end

-- Vitesse de virage (omega rad/s)
local function MajVirage(st, vel, speed, now)
    if speed < 2 then return end
    local u = vel / speed
    if st.dir then
        local dt = now - st.dirT
        if dt > 0.001 then
            local w = math.acos(math.clamp(u:Dot(st.dir), -1, 1)) / dt
            if w < 25 then
                st.omega = st.omega + (w - st.omega) * 0.35
            end
        end
    end
    st.dir = u
    st.dirT = now
end

-- Prediction trajectoire avec courbes (simulation 1/120s)
local function PredireImpact(pos, vel, speed, posJoueur, omega, horizon)
    if speed < 2 then return 999 end
    local p = pos
    local d = vel / speed
    local h = 1 / 120
    local pasLong = speed * h
    local virageMax = omega * h
    local t = 0

    while t < horizon do
        local versJoueur = posJoueur - p
        local dist = versJoueur.Magnitude
        if dist <= HIT_R then return t end

        if virageMax > 0 and dist > 0.1 then
            local cible = versJoueur / dist
            local angle = math.acos(math.clamp(d:Dot(cible), -1, 1))
            if angle <= virageMax then
                d = cible
            else
                local k = virageMax / angle
                d = (d * (1 - k) + cible * k).Unit
            end
        end

        local along = math.clamp(versJoueur:Dot(d), 0, pasLong)
        if (versJoueur - d * along).Magnitude <= HIT_R then
            return t + along / speed
        end

        p = p + d * pasLong
        t = t + h
    end
    return 999
end

-- Tracking des balles
local function NomContientBall(inst)
    if not inst or inst == Workspace or inst:IsA("BasePart") then return false end
    return string.find(string.lower(inst.Name), "ball", 1, true) ~= nil
end

local function DansPerso(p)
    local a = p.Parent
    while a and a ~= Workspace do
        if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
        a = a.Parent
    end
    return false
end

local function MarqueFort(p)
    local par = p.Parent
    return NomContientBall(par)
        or (par ~= Workspace and NomContientBall(par.Parent))
        or p:GetAttribute("realBall") ~= nil
        or p:GetAttribute("target") ~= nil
        or p:FindFirstChild("zoomies") ~= nil
end

local function Suivre(p)
    if ballesTracked[p] or ballesCount >= MAX_BALLES then return end
    if not p.Parent or not p:IsA("BasePart") then return end
    if p.Size.Magnitude > 25 then return end
    if not p:IsDescendantOf(Workspace) or DansPerso(p) then return end
    if not MarqueFort(p) then return end

    local st = {
        buf = {{t = tick(), p = p.Position}},
        vel = Vector3.zero,
        stable = 0,
        parried = false,
        parriedAt = 0,
        lastParryAt = 0,
        clashJusqua = 0,
        omega = 0,
        dir = nil,
        dirT = 0,
    }

    pcall(function()
        st.conn = p:GetAttributeChangedSignal("target"):Connect(function()
            st.parried = false
        end)
    end)

    ballesTracked[p] = st
    ballesCount = ballesCount + 1
end

local function Dessuivre(p)
    local st = ballesTracked[p]
    if not st then return end
    if st.conn then pcall(function() st.conn:Disconnect() end) end
    ballesTracked[p] = nil
    ballesCount = ballesCount - 1
end

Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("BasePart") then
        pcall(Suivre, d)
    elseif d.Name == "zoomies" then
        local par = d.Parent
        if par and par:IsA("BasePart") then pcall(Suivre, par) end
    end
end)

Workspace.DescendantRemoving:Connect(function(d)
    if ballesTracked[d] then Dessuivre(d) end
end)

task.spawn(function()
    while true do
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and not ballesTracked[d] then
                pcall(Suivre, d)
            end
        end
        task.wait(5)
    end
end)

-- Systeme de clic (methodes anti-detection)
local remoteParry = nil

local function TrouverRemote()
    if remoteParry then return remoteParry end
    local mots = {"parry", "deflect", "block", "click", "hit"}
    local endroits = {game:GetService("ReplicatedStorage")}
    for _, nom in ipairs({"Remotes", "Events", "GameEvents", "Shared", "Network"}) do
        local d = game:GetService("ReplicatedStorage"):FindFirstChild(nom)
        if d then table.insert(endroits, d) end
    end
    for _, mot in ipairs(mots) do
        for _, endroit in ipairs(endroits) do
            for _, obj in ipairs(endroit:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
                    and obj.Name:lower():find(mot) then
                    remoteParry = obj
                    return obj
                end
            end
        end
    end
    return nil
end

local VIM_Parry = nil

local function ClicBrut()
    -- Methode 1 : mouse1click (Solara, Fluxus, Delta, etc.)
    if type(mouse1click) == "function" then
        local ok = pcall(mouse1click)
        if ok then return true end
    end

    -- Methode 2 : VirtualInputManager (compatible la plupart des executors)
    local ok2 = pcall(function()
        if not VIM_Parry then
            VIM_Parry = game:GetService("VirtualInputManager")
        end
        VIM_Parry:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.defer(function()
            pcall(function()
                VIM_Parry:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end)
    end)
    if ok2 then return true end

    -- Methode 3 : remote du jeu directement
    local remote = TrouverRemote()
    if remote then
        local ok3 = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
            else
                remote:InvokeServer()
            end
        end)
        if ok3 then return true end
    end

    -- Methode 4 : firesignal si disponible (Synapse, etc.)
    if type(firesignal) == "function" then
        local ok4 = pcall(function()
            local mouse = LocalPlayer:GetMouse()
            firesignal(mouse.Button1Down)
        end)
        if ok4 then return true end
    end

    -- Methode 5 : keypress F comme fallback
    if type(keypress) == "function" then
        pcall(function()
            keypress(0x46)
            task.defer(function()
                pcall(keyrelease, 0x46)
            end)
        end)
        return true
    end

    return false
end

local function Cliquer(estSpam)
    local now = tick()
    if now - lastClic < 0.04 then return false end
    if not ClicBrut() then return false end
    lastClic = now
    if not estSpam then
        compteurParry = compteurParry + 1
        serieParry = serieParry + 1
        if serieParry > bestSerie then bestSerie = serieParry end
    end
    return true
end

-- Pas de Part dans Workspace (anti-detection BAC)

-- Evaluation d'une balle
local function EvaluerBalle(part, st, now, posJoueur, seuil)
    local pos = part.Position
    local versNous = posJoueur - pos
    local dist = versNous.Magnitude

    local vel, speed, src = LireVelocite(part, st, now, pos)
    MajVirage(st, vel, speed, now)

    local approche = 0
    if dist > 0.01 and speed > 0 then
        approche = vel:Dot(versNous) / dist
    end

    local nousVise, raison
    local target = part:GetAttribute("target")
    if type(target) == "string" and target ~= "" then
        nousVise = (target == LocalPlayer.Name)
        raison = "attr"
    else
        nousVise = persoRouge
        raison = "rouge"
    end

    if st.parried then
        if now - st.parriedAt > 1.0 then
            st.parried = false
        elseif raison ~= "attr" and approche < -5 then
            st.parried = false
        end
    end

    local omega = st.omega
    if nousVise then
        omega = math.max(omega, 2)
    end
    local eta = PredireImpact(pos, vel, speed, posJoueur, omega, seuil + 0.15)

    local doitParry = false
    if not st.parried and speed > 2 then
        if raison == "attr" then
            doitParry = nousVise and eta <= seuil
        else
            if nousVise then
                doitParry = eta <= seuil
            else
                doitParry = approche > 0 and dist <= 6 and eta <= seuil
            end
        end
    end

    local spam = nousVise and now < st.clashJusqua and dist <= SPAM_RANGE

    return dist, speed, eta, nousVise, doitParry, spam
end

-- Boucle principale RenderStepped
local frameNum = 0

Connections.autoParry = RunService.RenderStepped:Connect(function()
    if not Config.AutoParry then return end

    frameNum = frameNum + 1
    local now = tick()

    if frameNum % 3 == 0 then VerifierRouge() end

    local racine = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not racine then return end
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then serieParry = 0 return end

    local posJoueur = racine.Position

    local seuil = Config.AutoParryDistance / 100 + 0.2
    seuil = seuil + math.min(pingSec, 0.35)

    for p in pairs(ballesTracked) do
        if p.Parent == nil or not p:IsDescendantOf(Workspace) then
            Dessuivre(p)
        end
    end

    local aParry = {}
    local aSpam = {}
    local meilleureDist = math.huge
    local meilleureEta = 999

    for part, st in pairs(ballesTracked) do
        local realBall = part:GetAttribute("realBall")
        if realBall ~= false then
            local dist, speed, eta, nousVise, doitParry, spam = EvaluerBalle(part, st, now, posJoueur, seuil)

            if doitParry then aParry[#aParry + 1] = st end
            if spam then aSpam[#aSpam + 1] = st end

            if nousVise and eta < meilleureEta then
                meilleureEta = eta
                meilleureDist = dist
            end
        end
    end

    -- Visualisation retiree (anti-BAC)

    if #aParry > 0 and now - lastParryTime >= 0.15 then
        if Cliquer(false) then
            for _, st in ipairs(aParry) do
                st.parried = true
                st.parriedAt = now
                if now - st.lastParryAt < 0.7 then
                    st.clashJusqua = now + 0.6
                end
                st.lastParryAt = now
            end
            lastParryTime = now
        end
    elseif #aSpam > 0 then
        if Cliquer(true) then
            for _, st in ipairs(aSpam) do
                st.clashJusqua = now + 0.5
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    serieParry = 0
    persoRouge = false
end)

-- ESP
local function CreateESP(player)
    if player == LocalPlayer then return end

    local function onCharacter(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "HL_" .. math.random(1000, 9999)
        highlight.FillColor = Config.ESPColor
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Config.ESPColor
        highlight.OutlineTransparency = 0.3
        highlight.Adornee = character
        highlight.Parent = character
        table.insert(ESPObjects, highlight)

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "BB_" .. math.random(1000, 9999)
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = rootPart
        billboard.Parent = character
        table.insert(ESPObjects, billboard)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Config.ESPColor
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.new(1, 1, 1)
        distLabel.TextSize = 11
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextStrokeTransparency = 0.5
        distLabel.Parent = billboard

        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0.8, 0, 0, 3)
        healthBar.Position = UDim2.new(0.1, 0, 1, -3)
        healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = billboard
        CreateCorner(healthBar, 2)

        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Theme.Success
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBar
        CreateCorner(healthFill, 2)

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not Config.ESP or not character.Parent or not rootPart.Parent then
                highlight.Enabled = false
                billboard.Enabled = false
                if not Config.ESP then return end
                conn:Disconnect()
                return
            end

            highlight.Enabled = true
            billboard.Enabled = true

            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local dist = math.floor((myRoot.Position - rootPart.Position).Magnitude)
                distLabel.Text = "[" .. dist .. "m] HP: " .. math.floor(humanoid.Health)
            end

            local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthFill.Size = UDim2.new(healthPct, 0, 1, 0)
            healthFill.BackgroundColor3 = Color3.fromRGB(
                255 * (1 - healthPct),
                255 * healthPct,
                0
            )
        end)
        table.insert(Connections, conn)
    end

    if player.Character then onCharacter(player.Character) end
    player.CharacterAdded:Connect(onCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

-- Speed
Connections.speed = RunService.RenderStepped:Connect(function()
    if Config.Speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.SpeedValue
    end
end)

-- Fly
Connections.fly = RunService.RenderStepped:Connect(function()
    if Config.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        if not FlyBody then
            FlyBody = Instance.new("BodyVelocity")
            FlyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            FlyBody.Velocity = Vector3.new(0, 0, 0)
            FlyBody.Parent = root
        end
        if not FlyGyro then
            FlyGyro = Instance.new("BodyGyro")
            FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            FlyGyro.P = 9000
            FlyGyro.Parent = root
        end

        local direction = Vector3.new(0, 0, 0)
        local cf = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then direction = direction + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction = direction - Vector3.new(0, 1, 0) end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        FlyBody.Velocity = direction * Config.FlySpeed
        FlyGyro.CFrame = cf
    elseif not Config.Fly then
        if FlyBody then FlyBody:Destroy() FlyBody = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip
Connections.noclip = RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Aimbot
Connections.aimbot = RunService.RenderStepped:Connect(function()
    if Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local closestPlayer = nil
        local closestDist = Config.AimbotFOV

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
            local targetPos = closestPlayer.Character.Head.Position
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            Camera.CFrame = currentCF:Lerp(targetCF, 1 / Config.AimbotSmooth)
        end
    end
end)

-- Teleport au curseur
Mouse.Button2Down:Connect(function()
    if Config.Teleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local target = Mouse.Hit
        if target then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target + Vector3.new(0, 3, 0)
            Notify("Teleport", "Teleporte!", 1, "success")
        end
    end
end)

-- Anti-AFK (methode safe)
if Config.AntiAFK then
    Players.LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            pcall(function()
                local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = r.CFrame * CFrame.new(0, 0.1, 0) end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════
-- NOTIFICATION DE BIENVENUE
-- ═══════════════════════════════════════════

task.delay(0.8, function()
    Notify("Flow Hub v2.0", "Charge avec succes! Appuyez sur Insert pour afficher/cacher.", 5, "success")
    if detectedGame then
        task.delay(1, function()
            Notify("Jeu Detecte", detectedGame.name .. " - Support dedie disponible!", 4, "success")
        end)
    end
end)

-- Pulse animation sur la ligne accent
task.spawn(function()
    while MainFrame and MainFrame.Parent do
        Tween(AccentLine, {BackgroundTransparency = 0.3}, 1.5, Enum.EasingStyle.Sine)
        task.wait(1.5)
        Tween(AccentLine, {BackgroundTransparency = 0}, 1.5, Enum.EasingStyle.Sine)
        task.wait(1.5)
    end
end)
