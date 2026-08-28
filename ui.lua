local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local function resolveParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)

    if ok and coreGui then
        local test = Instance.new("Folder")
        local worked = pcall(function()
            test.Parent = coreGui
        end)
        test:Destroy()

        if worked then
            return coreGui
        end
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = resolveParent()

if typeof(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        local oldLibrary = env.RatScootLibrary
        if type(oldLibrary) == "table" and type(oldLibrary.Unload) == "function" then
            pcall(function()
                oldLibrary:Unload()
            end)
        end
    end
end

for _, oldName in ipairs({
    "ScootStyle_Refined",
    "ScootStyle_Rebuilt",
    "ScootStyle_Final",
    "ScootStyle_Stable",
    "ScootStyle_Smooth",
}) do
    local oldGui = GuiParent:FindFirstChild(oldName)
    if oldGui then
        pcall(function()
            oldGui:Destroy()
        end)
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScootStyle_Smooth"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = GuiParent

if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
    pcall(syn.protect_gui, ScreenGui)
elseif typeof(protectgui) == "function" then
    pcall(protectgui, ScreenGui)
end

local Theme = {

    Background = Color3.fromRGB(11, 11, 11),
    Border = Color3.fromRGB(4, 4, 4),
    Inline = Color3.fromRGB(18, 18, 18),
    Hovered = Color3.fromRGB(38, 38, 38),
    PageBackground = Color3.fromRGB(24, 24, 24),
    Outline = Color3.fromRGB(48, 48, 48),
    Element = Color3.fromRGB(29, 29, 29),
    Gradient = Color3.fromRGB(210, 210, 210),
    Text = Color3.fromRGB(248, 248, 248),
    MutedText = Color3.fromRGB(194, 194, 194),
    TextStroke = Color3.fromRGB(0, 0, 0),
    Accent = Color3.fromRGB(255, 255, 255),
    Risky = Color3.fromRGB(255, 90, 90),
}

local Library = {
    Version = "UI-v3-inline-5-clean-motion",
    SupportsInlineColorPicker = true,
    Theme = Theme,
    Flags = {},
    Connections = {},
    Windows = {},
    MenuKeybind = Enum.KeyCode.RightControl,
    MenuBindMode = "Toggle",
    OpenFrames = {},
    ScreenGui = ScreenGui,
    PopupOpenedAt = 0,
    ActivePopupInsideCheck = nil,

    ThemeBindings = {
        Background = {},
        Tabs = {},
        InnerTabs = {},
        Main = {},
        Text = {},
        Risky = {},
    },

    Toggles = {},
    Options = {},
}

function Library:CloseOpenFrames()
    local closer = self.ActivePopupCloser
    self.ActivePopupCloser = nil
    self.ActivePopupObject = nil
    self.ActivePopupSource = nil
    self.ActivePopupInsideCheck = nil
    self.PopupOpenedAt = 0

    if type(closer) == "function" then
        pcall(closer)
    end
end

function Library:SetOpenFrameCloser(closer, popupObject, sourceObject, insideCheck)
    if self.ActivePopupCloser == closer then
        self.ActivePopupObject = popupObject or self.ActivePopupObject
        self.ActivePopupSource = sourceObject or self.ActivePopupSource
        self.ActivePopupInsideCheck = insideCheck or self.ActivePopupInsideCheck
        self.PopupOpenedAt = os.clock()
        return
    end

    self:CloseOpenFrames()
    self.ActivePopupCloser = closer
    self.ActivePopupObject = popupObject
    self.ActivePopupSource = sourceObject
    self.ActivePopupInsideCheck = insideCheck
    self.PopupOpenedAt = os.clock()
end

local function keyName(key)
    if key == Enum.UserInputType.MouseButton1 then
        return "LMB"
    elseif key == Enum.UserInputType.MouseButton2 then
        return "RMB"
    elseif key == Enum.UserInputType.MouseButton3 then
        return "MMB"
    end

    local raw = tostring(key or Enum.KeyCode.Unknown)
    raw = string.gsub(raw, "Enum.KeyCode.", "")
    raw = string.gsub(raw, "Enum.UserInputType.", "")
    return string.upper(raw)
end

function Library:UpdateMenuBindLabels()
    for _, window in ipairs(self.Windows) do
        if window.MenuHintLabel and window.MenuHintLabel.Parent then
            window.MenuHintLabel.Text = string.format(
                "%s  •  %s",
                keyName(self.MenuKeybind),
                string.upper(self.MenuBindMode or "Toggle")
            )
        end
    end
end

function Library:SetMenuKeybind(key)
    if typeof(key) ~= "EnumItem" then
        return
    end

    self.MenuKeybind = key
    self:UpdateMenuBindLabels()
end

function Library:SetMenuBindMode(mode)
    if mode ~= "Hold" and mode ~= "Toggle" and mode ~= "Always On" then
        return
    end

    self.MenuBindMode = mode
    self:UpdateMenuBindLabels()

    if mode == "Always On" then
        for _, window in ipairs(self.Windows) do
            if window and window.SetOpen then
                window:SetOpen(true)
            end
        end
    end
end

local function getThemeRoleForColor(color)
    if typeof(color) ~= "Color3" then
        return nil
    end

    if color == Theme.Background then
        return "Background"
    elseif color == Theme.PageBackground then
        return "Tabs"
    elseif color == Theme.Inline or color == Theme.Element then
        return "InnerTabs"
    elseif color == Theme.Accent then
        return "Main"
    elseif color == Theme.Text then
        return "Text"
    elseif color == Theme.Risky then
        return "Risky"
    end

    return nil
end

local function registerThemeProperty(object, propertyName)
    if not object then
        return
    end

    local ok, value = pcall(function()
        return object[propertyName]
    end)

    if not ok then
        return
    end

    local role = getThemeRoleForColor(value)
    if not role then
        return
    end

    local variant = nil
    if role == "InnerTabs" then
        if value == Theme.Element then
            variant = "Element"
        else
            variant = "Inline"
        end
    end

    table.insert(Library.ThemeBindings[role], {
        Object = object,
        Property = propertyName,
        Variant = variant,
    })
end

local function autoBindThemeProperties(object)
    registerThemeProperty(object, "BackgroundColor3")
    registerThemeProperty(object, "BorderColor3")
    registerThemeProperty(object, "TextColor3")
    registerThemeProperty(object, "ImageColor3")

    if object:IsA("UIStroke") then
        registerThemeProperty(object, "Color")
    end
end

local function create(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end

    local wantsCorner = false
    if className == "CanvasGroup" or className == "TextBox" then
        wantsCorner = true
    elseif className == "TextButton" then
        wantsCorner = (object.BackgroundTransparency < 1)
    elseif className == "Frame" then
        wantsCorner = object.BorderSizePixel > 0
    end

    if wantsCorner then
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 6)
        uiCorner.Parent = object
    end

    autoBindThemeProperties(object)

    return object
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Library.Connections, connection)
    return connection
end

local function tween(object, goal, time, style, direction)
    local info = TweenInfo.new(
        time or 0.26,
        style or Enum.EasingStyle.Sine,
        direction or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(object, info, goal)
    tw:Play()
    return tw
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Parent = parent,
        Color = color or Theme.Outline,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        LineJoinMode = Enum.LineJoinMode.Round,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function textStroke(label, transparency)

    label.TextStrokeColor3 = Theme.TextStroke
    label.TextStrokeTransparency = 1
end

local function gradient(parent, rotation)
    return create("UIGradient", {
        Parent = parent,
        Rotation = rotation or -165,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Theme.Gradient),
        }),
    })
end

local function clamp(v, mn, mx)
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function round(value, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(value * m + 0.5) / m
end

local function getPointerPosition(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(input.Position.X, input.Position.Y)
    end

    local mouse = UserInputService:GetMouseLocation()
    return Vector2.new(mouse.X, mouse.Y)
end

local function pointInsideGui(gui, point)
    if not gui or not gui.Parent then
        return false
    end

    local pos = gui.AbsolutePosition
    local size = gui.AbsoluteSize

    return point.X >= pos.X
        and point.Y >= pos.Y
        and point.X <= pos.X + size.X
        and point.Y <= pos.Y + size.Y
end

connect(UserInputService.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local popup = Library.ActivePopupObject
    local closer = Library.ActivePopupCloser

    if not popup or type(closer) ~= "function" then
        return
    end

    if os.clock() - (Library.PopupOpenedAt or 0) < 0.10 then
        return
    end

    local point = getPointerPosition(input)
    local rawPoint = Vector2.new(input.Position.X, input.Position.Y)

    local insideCheck = Library.ActivePopupInsideCheck
    if type(insideCheck) == "function" then
        local okA, insideA = pcall(insideCheck, point)
        local okB, insideB = pcall(insideCheck, rawPoint)

        if (okA and insideA) or (okB and insideB) then
            return
        end
    end

    if pointInsideGui(popup, point) or pointInsideGui(popup, rawPoint) then
        return
    end

    local source = Library.ActivePopupSource
    if pointInsideGui(source, point) or pointInsideGui(source, rawPoint) then
        return
    end

    Library:CloseOpenFrames()
end)

local function normalizeToOffsets(target)
    if target.AnchorPoint ~= Vector2.new(0, 0) then
        local abs = target.AbsolutePosition
        target.AnchorPoint = Vector2.new(0, 0)
        target.Position = UDim2.fromOffset(abs.X, abs.Y)
    end
end

local WINDOW_MARGIN = 8
local MAX_WINDOW_WIDTH = 1100
local MAX_WINDOW_HEIGHT = 760

local function getViewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local function getWindowLimits(minWidth, minHeight)
    local viewport = getViewportSize()
    local usableWidth = math.max(320, viewport.X - WINDOW_MARGIN * 2)
    local usableHeight = math.max(260, viewport.Y - WINDOW_MARGIN * 2)

    local maxWidth = math.min(MAX_WINDOW_WIDTH, usableWidth)
    local maxHeight = math.min(MAX_WINDOW_HEIGHT, usableHeight)
    local safeMinWidth = math.min(minWidth or 650, maxWidth)
    local safeMinHeight = math.min(minHeight or 440, maxHeight)

    return viewport, safeMinWidth, safeMinHeight, maxWidth, maxHeight
end

local function constrainWindow(target, minWidth, minHeight)
    normalizeToOffsets(target)

    local viewport, safeMinWidth, safeMinHeight, maxWidth, maxHeight = getWindowLimits(minWidth, minHeight)
    local width = clamp(target.AbsoluteSize.X, safeMinWidth, maxWidth)
    local height = clamp(target.AbsoluteSize.Y, safeMinHeight, maxHeight)

    local maxX = math.max(WINDOW_MARGIN, viewport.X - width - WINDOW_MARGIN)
    local maxY = math.max(WINDOW_MARGIN, viewport.Y - height - WINDOW_MARGIN)
    local x = clamp(target.AbsolutePosition.X, WINDOW_MARGIN, maxX)
    local y = clamp(target.AbsolutePosition.Y, WINDOW_MARGIN, maxY)

    target.Position = UDim2.fromOffset(x, y)
    target.Size = UDim2.fromOffset(width, height)
end

local function makePreviewDraggable(handles, target, accentColor, onMoved)
    if typeof(handles) ~= "table" then
        handles = {handles}
    end

    local dragging = false
    local dragStart
    local startPosition
    local preview
    local renderConnection
    local targetPreviewPosition
    local smoothPreviewPosition

    local function stopRender()
        if renderConnection then
            pcall(function()
                renderConnection:Disconnect()
            end)
            renderConnection = nil
        end
    end

    local function destroyPreview()
        stopRender()

        if preview and preview.Parent then
            preview:Destroy()
        end

        preview = nil
        targetPreviewPosition = nil
        smoothPreviewPosition = nil
    end

    local function beginDrag(input)
        if dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        Library:CloseOpenFrames()

        dragging = true
        dragStart = getPointerPosition(input)

        startPosition = Vector2.new(
            target.Position.X.Offset,
            target.Position.Y.Offset
        )

        targetPreviewPosition = startPosition
        smoothPreviewPosition = startPosition

        preview = Instance.new("Frame")
        preview.Name = "DragPreview"
        preview.Parent = target.Parent
        preview.AnchorPoint = target.AnchorPoint
        preview.Position = target.Position
        preview.Size = target.Size
        preview.BackgroundTransparency = 1
        preview.BorderSizePixel = 0
        preview.ZIndex = 999999

        local targetCorner = target:FindFirstChildOfClass("UICorner")
        local previewCorner = Instance.new("UICorner")
        previewCorner.CornerRadius = targetCorner and targetCorner.CornerRadius or UDim.new(0, 8)
        previewCorner.Parent = preview

        local previewStroke = Instance.new("UIStroke")
        previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        previewStroke.Color = accentColor or Theme.Accent
        previewStroke.Thickness = 1
        previewStroke.Transparency = 0.02
        previewStroke.LineJoinMode = Enum.LineJoinMode.Round
        previewStroke.Parent = preview

        preview.Position = target.Position

        renderConnection = connect(RunService.RenderStepped, function(dt)
            if not dragging or not preview or not preview.Parent or not targetPreviewPosition then
                return
            end

            local alpha = 1 - math.exp(-34 * math.min(dt, 1 / 20))
            smoothPreviewPosition = smoothPreviewPosition:Lerp(targetPreviewPosition, alpha)

            preview.Position = UDim2.fromOffset(
                math.floor(smoothPreviewPosition.X + 0.5),
                math.floor(smoothPreviewPosition.Y + 0.5)
            )
        end)
    end

    for _, handle in ipairs(handles) do
        connect(handle.InputBegan, beginDrag)
    end

    connect(UserInputService.InputChanged, function(input)
        if not dragging or not preview then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local pointer = getPointerPosition(input)
        local delta = pointer - dragStart
        local viewport = getViewportSize()
        local size = target.AbsoluteSize

        local maxX = math.max(WINDOW_MARGIN, viewport.X - size.X - WINDOW_MARGIN)
        local maxY = math.max(WINDOW_MARGIN, viewport.Y - size.Y - WINDOW_MARGIN)

        targetPreviewPosition = Vector2.new(
            clamp(startPosition.X + delta.X, WINDOW_MARGIN, maxX),
            clamp(startPosition.Y + delta.Y, WINDOW_MARGIN, maxY)
        )
    end)

    connect(UserInputService.InputEnded, function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = false
        stopRender()

        if not targetPreviewPosition then
            destroyPreview()
            return
        end

        local destination = Vector2.new(
            math.floor(targetPreviewPosition.X + 0.5),
            math.floor(targetPreviewPosition.Y + 0.5)
        )

        if type(onMoved) == "function" then
            onMoved(destination)
        end

        if preview and preview.Parent then
            preview:Destroy()
        end

        preview = nil
        targetPreviewPosition = nil
        smoothPreviewPosition = nil

        tween(
            target,
            {Position = UDim2.fromOffset(destination.X, destination.Y)},
            0.34,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )
    end)
end

local function makeCornerResizable(target, handle, minWidth, minHeight, linkedSurface, onSizeChanged)
    minWidth = minWidth or 650
    minHeight = minHeight or 440

    local resizing = false
    local startPointer
    local startSize
    local startPosition
    local targetSize
    local smoothSize
    local renderConnection

    local function stopRender()
        if renderConnection then
            pcall(function()
                renderConnection:Disconnect()
            end)
            renderConnection = nil
        end
    end

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        Library:CloseOpenFrames()

        resizing = true
        startPointer = getPointerPosition(input)

        startPosition = Vector2.new(
            target.Position.X.Offset,
            target.Position.Y.Offset
        )

        startSize = Vector2.new(
            target.AbsoluteSize.X,
            target.AbsoluteSize.Y
        )

        targetSize = startSize
        smoothSize = startSize

        stopRender()

        renderConnection = connect(RunService.RenderStepped, function(dt)
            if not resizing or not targetSize then
                return
            end

            local alpha = 1 - math.exp(-32 * math.min(dt, 1 / 20))
            smoothSize = smoothSize:Lerp(targetSize, alpha)

            local w = math.floor(smoothSize.X + 0.5)
            local h = math.floor(smoothSize.Y + 0.5)

            target.Size = UDim2.fromOffset(w, h)

            if linkedSurface and linkedSurface.Parent then
                linkedSurface.Size = UDim2.fromOffset(w, h)
            end

            if type(onSizeChanged) == "function" then
                onSizeChanged(Vector2.new(w, h))
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local pointer = getPointerPosition(input)
        local delta = pointer - startPointer

        local viewport, safeMinWidth, safeMinHeight, maxWidth, maxHeight =
            getWindowLimits(minWidth, minHeight)

        local availableWidth = math.max(
            safeMinWidth,
            viewport.X - startPosition.X - WINDOW_MARGIN
        )

        local availableHeight = math.max(
            safeMinHeight,
            viewport.Y - startPosition.Y - WINDOW_MARGIN
        )

        local allowedWidth = math.min(maxWidth, availableWidth)
        local allowedHeight = math.min(maxHeight, availableHeight)

        targetSize = Vector2.new(
            clamp(
                startSize.X + delta.X,
                safeMinWidth,
                allowedWidth
            ),
            clamp(
                startSize.Y + delta.Y,
                safeMinHeight,
                allowedHeight
            )
        )
    end)

    connect(UserInputService.InputEnded, function(input)
        if not resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        resizing = false
        stopRender()

        if targetSize then

            local w = math.floor(targetSize.X + 0.5)
            local h = math.floor(targetSize.Y + 0.5)

            target.Size = UDim2.fromOffset(w, h)

            if linkedSurface and linkedSurface.Parent then
                linkedSurface.Size = UDim2.fromOffset(w, h)
            end

            if type(onSizeChanged) == "function" then
                onSizeChanged(Vector2.new(w, h))
            end
        end

        startPointer = nil
        startSize = nil
        startPosition = nil
        targetSize = nil
        smoothSize = nil
    end)
end

local function hover(button, enter, leave)
    connect(button.MouseEnter, enter)
    connect(button.MouseLeave, leave)
end

local function attachSmoothMarquee(viewport, textLabel, centerWhenShort)
    local generation = 0
    local activeTween

    local function stopTween()
        if activeTween then
            pcall(function()
                activeTween:Cancel()
            end)
            activeTween = nil
        end
    end

    local function refresh(newText)
        generation += 1
        local myGeneration = generation

        stopTween()

        textLabel.Text = tostring(newText or "")
        textLabel.Position = UDim2.fromOffset(0, 0)

        task.defer(function()
            if myGeneration ~= generation or not textLabel.Parent or not viewport.Parent then
                return
            end

            local available = math.floor(viewport.AbsoluteSize.X + 0.5)
            if available <= 4 then
                return
            end

            local measured = TextService:GetTextSize(
                textLabel.Text,
                textLabel.TextSize,
                textLabel.Font,
                Vector2.new(10000, math.max(20, viewport.AbsoluteSize.Y))
            ).X

            if measured <= available - 6 then
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.Position = UDim2.fromOffset(0, 0)
                textLabel.TextXAlignment = centerWhenShort
                    and Enum.TextXAlignment.Center
                    or Enum.TextXAlignment.Left
                return
            end

            local startPadding = 2
            local endPadding = 7
            local textWidth = math.ceil(measured) + 2

            local endX = -(textWidth - available + endPadding)
            local travel = math.abs(endX - startPadding)

            local pixelsPerSecond = 48
            local duration = math.max(0.85, travel / pixelsPerSecond)

            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Size = UDim2.fromOffset(
                textWidth,
                math.max(20, math.floor(viewport.AbsoluteSize.Y + 0.5))
            )
            textLabel.Position = UDim2.fromOffset(startPadding, 0)

            task.spawn(function()
                while myGeneration == generation
                and textLabel.Parent
                and viewport.Parent do
                    activeTween = TweenService:Create(
                        textLabel,
                        TweenInfo.new(
                            duration,
                            Enum.EasingStyle.Sine,
                            Enum.EasingDirection.InOut
                        ),
                        {Position = UDim2.fromOffset(endX, 0)}
                    )
                    activeTween:Play()
                    activeTween.Completed:Wait()

                    if myGeneration ~= generation or not textLabel.Parent then
                        break
                    end

                    activeTween = TweenService:Create(
                        textLabel,
                        TweenInfo.new(
                            duration,
                            Enum.EasingStyle.Sine,
                            Enum.EasingDirection.InOut
                        ),
                        {Position = UDim2.fromOffset(startPadding, 0)}
                    )
                    activeTween:Play()
                    activeTween.Completed:Wait()
                end
            end)
        end)
    end

    connect(viewport:GetPropertyChangedSignal("AbsoluteSize"), function()
        refresh(textLabel.Text)
    end)

    return refresh
end

local function applyThemeRole(role, color)
    local bindings = Library.ThemeBindings[role]
    if not bindings then
        return
    end

    for i = #bindings, 1, -1 do
        local binding = bindings[i]
        local object = binding.Object

        if not object or not object.Parent then
            table.remove(bindings, i)
        else
            pcall(function()
                object[binding.Property] = color
            end)
        end
    end
end

function Library:SetThemeColor(role, color)
    if typeof(color) ~= "Color3" then
        return
    end

    if role == "Background" then
        Theme.Background = color
        applyThemeRole("Background", color)

    elseif role == "Tabs" then
        Theme.PageBackground = color
        applyThemeRole("Tabs", color)

    elseif role == "InnerTabs" then

        Theme.Inline = color

        local h, s, v = color:ToHSV()
        Theme.Element = Color3.fromHSV(h, s, math.clamp(v + 0.045, 0, 1))

        local bindings = Library.ThemeBindings.InnerTabs
        for i = #bindings, 1, -1 do
            local binding = bindings[i]
            local object = binding.Object

            if not object or not object.Parent then
                table.remove(bindings, i)
            else
                local targetColor = binding.Variant == "Element"
                    and Theme.Element
                    or Theme.Inline

                pcall(function()
                    object[binding.Property] = targetColor
                end)
            end
        end

    elseif role == "Main" then
        Theme.Accent = color
        applyThemeRole("Main", color)

    elseif role == "Text" then
        Theme.Text = color
        applyThemeRole("Text", color)

    elseif role == "Risky" then
        Theme.Risky = color
        applyThemeRole("Risky", color)
    end
end

function Library:SetAccent(color)
    self:SetThemeColor("Main", color)
end

function Library:Unload()
    self:CloseOpenFrames()

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(self.Connections)

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local PageMethods = {}
PageMethods.__index = PageMethods

local SectionMethods = {}
SectionMethods.__index = SectionMethods

function Library:Window(data)
    data = data or {}

    local window = setmetatable({
        Name = data.Name or data.Title or "",
        Logo = data.Logo or "",
        FadeTime = data.FadeTime or 0.25,
        Size = data.Size or UDim2.fromOffset(752, 540),
        Pages = {},
        IsOpen = true,
        AccentObjects = {},
        CurrentPage = nil,
    }, WindowMethods)

    local initialViewport = getViewportSize()
    local initialWidth = math.floor(initialViewport.X * window.Size.X.Scale + window.Size.X.Offset + 0.5)
    local initialHeight = math.floor(initialViewport.Y * window.Size.Y.Scale + window.Size.Y.Offset + 0.5)
    local initialX = math.floor((initialViewport.X - initialWidth) * 0.5 + 0.5)
    local initialY = math.floor((initialViewport.Y - initialHeight) * 0.5 + 0.5)

    local windowRoot = create("Frame", {
        Parent = ScreenGui,
        Name = "WindowClip",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(initialX, initialY),
        Size = window.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })

    local main = create("Frame", {
        Parent = windowRoot,
        Name = "Window",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(0, 0),
        Size = window.Size,
        BackgroundColor3 = Theme.Background,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        ClipsDescendants = true,
    })

    window.Main = windowRoot
    window.Surface = main
    window.OpenPixelSize = Vector2.new(initialWidth, initialHeight)
    window.RestPosition = Vector2.new(initialX, initialY)
    window.AnimationToken = 0

    local wipeEdge = create("Frame", {
        Parent = windowRoot,
        Name = "WipeEdge",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 9000,
    })
    table.insert(window.AccentObjects, wipeEdge)
    window.WipeEdge = wipeEdge

    local outerStroke = stroke(main, Theme.Outline, 0, 1)
    outerStroke.LineJoinMode = Enum.LineJoinMode.Round

    local side = create("Frame", {
        Parent = main,
        Name = "Side",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(0, 200, 1, -24),
        BackgroundColor3 = Theme.Inline,
        BorderColor3 = Theme.Outline,
        BorderSizePixel = 2,
        ClipsDescendants = true,
    })
    stroke(side, Theme.Border, 0, 1)

    local accentTop = create("Frame", {
        Parent = side,
        Name = "AccentTop",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    table.insert(window.AccentObjects, accentTop)

    local menuHintLabel = create("TextLabel", {
        Parent = side,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 7),
        Size = UDim2.new(1, -16, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = string.format(
            "%s  •  %s",
            keyName(Library.MenuKeybind),
            string.upper(Library.MenuBindMode)
        ),
        TextColor3 = Theme.Text,
        TextSize = 12,
    })
    textStroke(menuHintLabel, 1)
    window.MenuHintLabel = menuHintLabel

    local pagesHolder = create("Frame", {
        Parent = side,
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 1, -39),
    })

    create("UIPadding", {
        Parent = pagesHolder,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })

    create("UIListLayout", {
        Parent = pagesHolder,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local content = create("Frame", {
        Parent = main,
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(226, 12),
        Size = UDim2.new(1, -238, 1, -24),
        ClipsDescendants = true,
    })

    window.Side = side
    window.PagesHolder = pagesHolder
    window.Content = content

    main.AnchorPoint = Vector2.new(0, 0)
    main.Position = UDim2.fromOffset(0, 0)
    constrainWindow(windowRoot, 650, 440)

    main.Size = UDim2.fromOffset(
        windowRoot.AbsoluteSize.X,
        windowRoot.AbsoluteSize.Y
    )
    window.OpenPixelSize = Vector2.new(
        windowRoot.AbsoluteSize.X,
        windowRoot.AbsoluteSize.Y
    )
    window.RestPosition = Vector2.new(
        windowRoot.Position.X.Offset,
        windowRoot.Position.Y.Offset
    )

    local function dragHandle(name, position, size)
        return create("TextButton", {
            Parent = main,
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = position,
            Size = size,
            ZIndex = 1100,
        })
    end

    local dragThickness = 9
    local resizeCornerSize = 20

    local dragTop = dragHandle(
        "DragTop",
        UDim2.fromOffset(0, 0),
        UDim2.new(1, 0, 0, dragThickness)
    )

    local dragLeft = dragHandle(
        "DragLeft",
        UDim2.fromOffset(0, dragThickness),
        UDim2.new(0, dragThickness, 1, -(dragThickness * 2))
    )

    local dragRight = dragHandle(
        "DragRight",
        UDim2.new(1, -dragThickness, 0, dragThickness),
        UDim2.new(0, dragThickness, 1, -(dragThickness + resizeCornerSize))
    )

    local dragBottom = dragHandle(
        "DragBottom",
        UDim2.new(0, 0, 1, -dragThickness),
        UDim2.new(1, -resizeCornerSize, 0, dragThickness)
    )

    makePreviewDraggable({
        dragTop,
        dragLeft,
        dragRight,
        dragBottom,
    }, windowRoot, Theme.Accent, function(position)
        window.RestPosition = position
    end)

    local resizeHandle = create("TextButton", {
        Parent = main,
        Name = "ResizeCorner",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(resizeCornerSize, resizeCornerSize),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 1300,
    })

    for i = 0, 2 do
        create("Frame", {
            Parent = resizeHandle,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -(3 + i * 4), 1, -3),
            Size = UDim2.fromOffset(8, 1),
            Rotation = -45,
            BackgroundColor3 = i == 0 and Theme.Accent or Theme.Outline,
            BorderSizePixel = 0,
            ZIndex = 1301,
        })
    end

    makeCornerResizable(
        windowRoot,
        resizeHandle,
        650,
        440,
        main,
        function(size)
            window.OpenPixelSize = size
        end
    )

    connect(UserInputService.InputBegan, function(input, processed)
        if processed then
            return
        end

        if input.KeyCode ~= Library.MenuKeybind then
            return
        end

        local mode = Library.MenuBindMode or "Toggle"

        if mode == "Hold" then
            window:SetOpen(true)
        elseif mode == "Toggle" then
            window:SetOpen(not window.IsOpen)
        elseif mode == "Always On" then
            window:SetOpen(true)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.KeyCode == Library.MenuKeybind
        and (Library.MenuBindMode or "Toggle") == "Hold" then
            window:SetOpen(false)
        end
    end)

    table.insert(Library.Windows, window)

    windowRoot.Visible = true
    main.Visible = true

    function window:PlayStartupAnimation()
        if self.StartupPlayed then
            return
        end

        self.StartupPlayed = true
        self.StartupAnimating = true

        self.AnimationToken =
            (self.AnimationToken or 0) + 1

        local token =
            self.AnimationToken

        local root =
            self.Main

        local surface =
            self.Surface

        local edge =
            self.WipeEdge

        if not root
            or not root.Parent
            or not surface then

            self.StartupAnimating = false
            return
        end

        local fullSize =
            self.OpenPixelSize
            or Vector2.new(
                root.AbsoluteSize.X,
                root.AbsoluteSize.Y
            )

        local rest =
            self.RestPosition
            or Vector2.new(
                root.Position.X.Offset,
                root.Position.Y.Offset
            )

        local centerX =
            rest.X + fullSize.X * 0.5

        local centerY =
            rest.Y + fullSize.Y * 0.5

        root.Visible = false

        local cursor =
            Instance.new("Frame")

        cursor.Name =
            "StartupCursor"

        cursor.Parent =
            ScreenGui

        cursor.AnchorPoint =
            Vector2.new(0.5, 0.5)

        cursor.Position =
            UDim2.fromOffset(
                centerX,
                centerY
            )

        cursor.Size =
            UDim2.fromOffset(
                3,
                3
            )

        cursor.BackgroundColor3 =
            Theme.Accent

        cursor.BackgroundTransparency =
            0.02

        cursor.BorderSizePixel = 0
        cursor.ZIndex = 9999999

        self.StartupEffect =
            cursor

        local cursorCorner =
            Instance.new("UICorner")

        cursorCorner.CornerRadius =
            UDim.new(1, 0)

        cursorCorner.Parent =
            cursor

        local cursorGlow =
            Instance.new("UIStroke")

        cursorGlow.ApplyStrokeMode =
            Enum.ApplyStrokeMode.Border

        cursorGlow.Color =
            Theme.Accent

        cursorGlow.Thickness = 1
        cursorGlow.Transparency = 0.30
        cursorGlow.LineJoinMode =
            Enum.LineJoinMode.Round

        cursorGlow.Parent =
            cursor

        local function stillValid()
            return self.AnimationToken == token
                and root
                and root.Parent
                and cursor
                and cursor.Parent
        end

        local function playStep(
            position,
            size,
            duration
        )
            if not stillValid() then
                return false
            end

            local tw =
                tween(
                    cursor,
                    {
                        Position = position,
                        Size = size
                    },
                    duration,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out
                )

            tw.Completed:Wait()

            return stillValid()
        end

        task.spawn(function()
            -- UP
            if not playStep(
                UDim2.fromOffset(
                    centerX,
                    centerY - 34
                ),
                UDim2.fromOffset(
                    2,
                    20
                ),
                0.11
            ) then
                return
            end

            -- DOWN
            if not playStep(
                UDim2.fromOffset(
                    centerX,
                    centerY + 34
                ),
                UDim2.fromOffset(
                    2,
                    20
                ),
                0.13
            ) then
                return
            end

            -- RIGHT
            if not playStep(
                UDim2.fromOffset(
                    centerX + 58,
                    centerY
                ),
                UDim2.fromOffset(
                    24,
                    1
                ),
                0.12
            ) then
                return
            end

            -- LEFT
            if not playStep(
                UDim2.fromOffset(
                    centerX - 58,
                    centerY
                ),
                UDim2.fromOffset(
                    24,
                    1
                ),
                0.13
            ) then
                return
            end

            -- Return to center as a thin horizontal scanner.
            if not playStep(
                UDim2.fromOffset(
                    centerX,
                    centerY
                ),
                UDim2.fromOffset(
                    36,
                    1
                ),
                0.10
            ) then
                return
            end

            -- Stretch into one clean 1px line.
            local stretchTween =
                tween(
                    cursor,
                    {
                        Size =
                            UDim2.fromOffset(
                                fullSize.X,
                                1
                            )
                    },
                    0.20,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out
                )

            stretchTween.Completed:Wait()

            if not stillValid() then
                return
            end

            -- Prepare bottom-to-top reveal.
            root.Visible = true
            root.Position =
                UDim2.fromOffset(
                    rest.X,
                    rest.Y + fullSize.Y - 1
                )

            root.Size =
                UDim2.fromOffset(
                    fullSize.X,
                    1
                )

            surface.Size =
                UDim2.fromOffset(
                    fullSize.X,
                    fullSize.Y
                )

            surface.Position =
                UDim2.fromOffset(
                    0,
                    -(fullSize.Y - 1)
                )

            if edge then
                edge.Visible = true
                edge.Position =
                    UDim2.fromOffset(
                        0,
                        0
                    )

                edge.Size =
                    UDim2.new(
                        1,
                        0,
                        0,
                        1
                    )

                edge.BackgroundTransparency =
                    0.05
            end

            -- Fade the startup scanner into the GUI edge.
            tween(
                cursor,
                {
                    BackgroundTransparency = 1
                },
                0.08,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )

            task.delay(0.08, function()
                if cursor
                    and cursor.Parent then

                    cursor:Destroy()
                end

                if self.StartupEffect
                    == cursor then

                    self.StartupEffect = nil
                end
            end)

            local revealTween =
                tween(
                    root,
                    {
                        Position =
                            UDim2.fromOffset(
                                rest.X,
                                rest.Y
                            ),

                        Size =
                            UDim2.fromOffset(
                                fullSize.X,
                                fullSize.Y
                            )
                    },
                    0.42,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out
                )

            tween(
                surface,
                {
                    Position =
                        UDim2.fromOffset(
                            0,
                            0
                        )
                },
                0.42,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )

            revealTween.Completed:Wait()

            if self.AnimationToken ~= token
                or not root
                or not root.Parent then

                self.StartupAnimating = false
                return
            end

            root.Position =
                UDim2.fromOffset(
                    rest.X,
                    rest.Y
                )

            root.Size =
                UDim2.fromOffset(
                    fullSize.X,
                    fullSize.Y
                )

            surface.Position =
                UDim2.fromOffset(
                    0,
                    0
                )

            surface.Size =
                UDim2.fromOffset(
                    fullSize.X,
                    fullSize.Y
                )

            if edge
                and edge.Parent then

                edge.Visible = false
                edge.BackgroundTransparency =
                    0.18
            end

            self.StartupAnimating = false
        end)
    end

    -- Defer one scheduler step so pages/sections can be built first.
    task.defer(function()
        if window
            and window.Main
            and window.Main.Parent then

            window:PlayStartupAnimation()
        end
    end)

    return window
end

function WindowMethods:SetOpen(state)
    state = state == true

    if self.StartupAnimating then
        self.AnimationToken =
            (self.AnimationToken or 0) + 1

        self.StartupAnimating = false

        if self.StartupEffect
            and self.StartupEffect.Parent then

            self.StartupEffect:Destroy()
        end

        self.StartupEffect = nil

        local startupRoot =
            self.Main

        local startupSurface =
            self.Surface

        local startupSize =
            self.OpenPixelSize

        local startupRest =
            self.RestPosition

        if startupRoot
            and startupRoot.Parent
            and startupSize
            and startupRest then

            startupRoot.Visible = true

            startupRoot.Position =
                UDim2.fromOffset(
                    startupRest.X,
                    startupRest.Y
                )

            startupRoot.Size =
                UDim2.fromOffset(
                    startupSize.X,
                    startupSize.Y
                )

            if startupSurface then
                startupSurface.Position =
                    UDim2.fromOffset(
                        0,
                        0
                    )

                startupSurface.Size =
                    UDim2.fromOffset(
                        startupSize.X,
                        startupSize.Y
                    )
            end
        end
    end

    if self.IsOpen == state then
        return
    end

    self.IsOpen = state

    self.AnimationToken =
        (self.AnimationToken or 0) + 1

    local token =
        self.AnimationToken

    if not state then
        Library:CloseOpenFrames()
    end

    local root =
        self.Main

    local surface =
        self.Surface

    local edge =
        self.WipeEdge

    if not root
        or not root.Parent
        or not surface then
        return
    end

    local fullSize =
        self.OpenPixelSize
        or Vector2.new(
            surface.AbsoluteSize.X,
            surface.AbsoluteSize.Y
        )

    local rest =
        self.RestPosition
        or Vector2.new(
            root.Position.X.Offset,
            root.Position.Y.Offset
        )

    local openX =
        rest.X

    local openY =
        rest.Y

    surface.Size =
        UDim2.fromOffset(
            fullSize.X,
            fullSize.Y
        )

    if state then
        -- Open from a clean 1px TOP line.
        root.Visible = true

        root.Position =
            UDim2.fromOffset(
                openX,
                openY
            )

        root.Size =
            UDim2.fromOffset(
                fullSize.X,
                1
            )

        surface.Position =
            UDim2.fromOffset(
                0,
                0
            )

        if edge then
            edge.Visible = true
            edge.Position =
                UDim2.fromOffset(
                    0,
                    0
                )

            edge.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    1
                )

            edge.BackgroundTransparency =
                0.04
        end

        local openTween =
            tween(
                root,
                {
                    Size =
                        UDim2.fromOffset(
                            fullSize.X,
                            fullSize.Y
                        )
                },
                0.34,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )

        openTween.Completed:Wait()

        if self.AnimationToken ~= token
            or not self.IsOpen then
            return
        end

        root.Position =
            UDim2.fromOffset(
                openX,
                openY
            )

        root.Size =
            UDim2.fromOffset(
                fullSize.X,
                fullSize.Y
            )

        surface.Position =
            UDim2.fromOffset(
                0,
                0
            )

        if edge
            and edge.Parent then

            edge.Visible = false
            edge.BackgroundTransparency =
                0.18
        end

    else
        -- Collapse upward into the same 1px TOP line.
        root.Visible = true

        root.Position =
            UDim2.fromOffset(
                openX,
                openY
            )

        root.Size =
            UDim2.fromOffset(
                fullSize.X,
                fullSize.Y
            )

        surface.Position =
            UDim2.fromOffset(
                0,
                0
            )

        if edge then
            edge.Visible = true
            edge.Position =
                UDim2.fromOffset(
                    0,
                    0
                )

            edge.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    1
                )

            edge.BackgroundTransparency =
                0.04
        end

        local closeTween =
            tween(
                root,
                {
                    Size =
                        UDim2.fromOffset(
                            fullSize.X,
                            1
                        )
                },
                0.28,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.InOut
            )

        closeTween.Completed:Wait()

        if self.AnimationToken ~= token
            or self.IsOpen then
            return
        end

        -- Briefly leave only the 1px top line visible.
        task.wait(0.035)

        if self.AnimationToken ~= token
            or self.IsOpen then
            return
        end

        root.Visible = false

        root.Position =
            UDim2.fromOffset(
                openX,
                openY
            )

        root.Size =
            UDim2.fromOffset(
                fullSize.X,
                fullSize.Y
            )

        surface.Position =
            UDim2.fromOffset(
                0,
                0
            )

        surface.Size =
            UDim2.fromOffset(
                fullSize.X,
                fullSize.Y
            )

        if edge
            and edge.Parent then

            edge.Visible = false
            edge.BackgroundTransparency =
                0.18
        end
    end
end


function WindowMethods:Page(data)
    data = data or {}

    local page = setmetatable({
        Window = self,
        Name = data.Name or "Page",
        Columns = data.Columns or 2,
        Active = false,
        Sections = {},
        ColumnsData = {},
    }, PageMethods)

    local button = create("TextButton", {
        Parent = self.PagesHolder,
        Name = "PageButton",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = Theme.PageBackground,
        BackgroundTransparency = 0.6,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
    })
    page.Button = button

    local pageCorner = button:FindFirstChildOfClass("UICorner")
    if pageCorner then
        pageCorner.CornerRadius = UDim.new(0, 6)
    end

    local buttonStroke = stroke(button, Theme.Outline, 0.6, 1)

    local liner = create("Frame", {
        Parent = button,
        Position = UDim2.fromOffset(3, 5),
        Size = UDim2.new(0, 2, 1, -10),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    create("UICorner", {
        Parent = liner,
        CornerRadius = UDim.new(1, 0),
    })
    table.insert(self.AccentObjects, liner)

    local glow = create("Frame", {
        Parent = button,
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(0, 26, 1, -6),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    })
    create("UICorner", {
        Parent = glow,
        CornerRadius = UDim.new(0, 6),
    })
    table.insert(self.AccentObjects, glow)

    create("UIGradient", {
        Parent = glow,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.25, 0.8),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })

    local text = create("TextLabel", {
        Parent = button,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = page.Name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(text, 0.45)

    local frame = create("Frame", {
        Parent = self.Content,
        Name = "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
    })
    page.Frame = frame

    local columnGap = 14
    for i = 1, page.Columns do
        local column = create("ScrollingFrame", {
            Parent = frame,
            Name = "Column" .. i,
            Position = UDim2.new((i - 1) / page.Columns, ((i - 1) * columnGap) / page.Columns, 0, 0),
            Size = UDim2.new(1 / page.Columns, -((page.Columns - 1) * columnGap) / page.Columns, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })

        local layout = create("UIListLayout", {
            Parent = column,
            Padding = UDim.new(0, 14),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        page.ColumnsData[i] = {
            Frame = column,
            Layout = layout,
        }
    end

    function page:Turn(state)

        if self.Active == state and state then
            return
        end

        self.Active = state
        self.TransitionToken = (self.TransitionToken or 0) + 1

        if state then

            for _, other in ipairs(self.Window.Pages) do
                if other ~= self and other.Frame and other.Frame.Parent then
                    other.TransitionToken = (other.TransitionToken or 0) + 1
                    other.Frame.Visible = false
                    other.Frame.Position = UDim2.fromOffset(0, 0)
                end
            end

            self.Frame.Visible = true
            self.Frame.Position = UDim2.fromOffset(5, 0)

            tween(self.Button, {
                BackgroundTransparency = 0,
                BackgroundColor3 = Theme.PageBackground
            }, 0.18)

            tween(buttonStroke, {
                Transparency = 0.22,
                Color = Theme.Outline,
                Thickness = 1,
            }, 0.18)

            tween(liner, {BackgroundTransparency = 0}, 0.18)
            tween(glow, {BackgroundTransparency = 0.72}, 0.18)
            tween(text, {Position = UDim2.new(0, 13, 0.5, 0)}, 0.18)

            tween(
                self.Frame,
                {Position = UDim2.fromOffset(0, 0)},
                0.18,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )

            self.Window.CurrentPage = self
        else

            self.Frame.Visible = false
            self.Frame.Position = UDim2.fromOffset(0, 0)

            tween(self.Button, {
                BackgroundTransparency = 0.6,
                BackgroundColor3 = Theme.PageBackground
            }, 0.18)

            tween(buttonStroke, {
                Transparency = 0.6,
                Color = Theme.Outline,
                Thickness = 1,
            }, 0.18)

            tween(liner, {BackgroundTransparency = 1}, 0.18)
            tween(glow, {BackgroundTransparency = 1}, 0.18)
            tween(text, {Position = UDim2.new(0, 8, 0.5, 0)}, 0.18)
        end
    end

    connect(button.MouseButton1Down, function()
        if page.Active then
            return
        end

        Library:CloseOpenFrames()

        for _, other in ipairs(self.Pages) do
            if other ~= page then
                other:Turn(false)
            end
        end

        page:Turn(true)
    end)

    hover(button,
        function()
            if not page.Active then
                tween(button, {BackgroundColor3 = Theme.Hovered}, 0.15)
            end
        end,
        function()
            if not page.Active then
                tween(button, {BackgroundColor3 = Theme.PageBackground}, 0.15)
            end
        end
    )

    table.insert(self.Pages, page)

    if #self.Pages == 1 then
        page:Turn(true)
    end

    return page
end

function PageMethods:Section(data)
    data = data or {}

    local side = clamp(data.Side or 1, 1, #self.ColumnsData)

    local section = setmetatable({
        Window = self.Window,
        Page = self,
        Name = data.Name or "Section",
        Side = side,
        Items = {},
    }, SectionMethods)

    local frame = create("Frame", {
        Parent = self.ColumnsData[side].Frame,
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Inline,
        BorderColor3 = Theme.Outline,
        BorderSizePixel = 2,
        AutomaticSize = Enum.AutomaticSize.None,
    })
    stroke(frame, Theme.Border, 0, 1)

    local liner = create("Frame", {
        Parent = frame,
        Name = "Liner",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    table.insert(self.Window.AccentObjects, liner)

    local glow = create("Frame", {
        Parent = frame,
        Name = "Glow",
        Position = UDim2.fromOffset(0, 1),
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
    })
    table.insert(self.Window.AccentObjects, glow)

    create("UIGradient", {
        Parent = glow,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })

    local title = create("TextLabel", {
        Parent = frame,
        Position = UDim2.fromOffset(6, 5),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = section.Name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(title, 0.45)

    local content = create("Frame", {
        Parent = frame,
        Position = UDim2.fromOffset(10, 26),
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    local layout = create("UIListLayout", {
        Parent = content,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    section.Frame = frame
    section.Content = content
    section.Layout = layout

    local function updateSize()
        frame.Size = UDim2.new(1, 0, 0, math.max(35, 34 + layout.AbsoluteContentSize.Y))
    end

    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateSize)
    task.defer(updateSize)

    table.insert(self.Sections, section)

    return section
end

local function registerFlag(flag, value)
    Library.Flags[flag] = value
end

function SectionMethods:Toggle(data)
    data = data or {}

    local flag = data.Flag or data.Name or ("Toggle_" .. tostring(#self.Items + 1))
    local value = data.Default == true
    local callback = data.Callback or function() end

    local row = create("TextButton", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })

    local box = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        AutoButtonColor = false,
        Text = "",
    })
    local boxStroke = stroke(box, Theme.Outline, 0, 1)
    gradient(box)

    local fill = create("Frame", {
        Parent = box,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = value and 0 or 1,
        BorderSizePixel = 0,
    })
    table.insert(self.Window.AccentObjects, fill)
    create("UICorner", {
        Parent = fill,
        CornerRadius = UDim.new(0, 4),
    })

    local label = create("TextLabel", {
        Parent = row,
        Position = UDim2.fromOffset(20, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(label, 0.45)

    local toggle = {
        Value = value,
        Flag = flag,
        Row = row,
        Label = label,
        Box = box,
        Section = self
    }

    function toggle:Set(newValue, silent)
        value = newValue == true
        self.Value = value
        registerFlag(flag, value)

        tween(fill, {BackgroundTransparency = value and 0 or 1}, 0.14)

        if not silent then
            task.spawn(callback, value)
        end
    end

    function toggle:Get()
        return value
    end

    connect(box.MouseButton1Down, function()
        toggle:Set(not value)
    end)

    hover(box,
        function()
            tween(box, {BackgroundColor3 = Theme.Hovered}, 0.12)
        end,
        function()
            tween(box, {BackgroundColor3 = Theme.Element}, 0.12)
        end
    )

    toggle:Set(value, true)
    table.insert(self.Items, toggle)
    return toggle
end

function SectionMethods:Slider(data)
    data = data or {}

    local minimum = data.Min or 0
    local maximum = data.Max or 100
    local decimals = data.Decimals or 0
    local suffix = data.Suffix or ""
    local flag = data.Flag or data.Name or ("Slider_" .. tostring(#self.Items + 1))
    local value = clamp(data.Default or minimum, minimum, maximum)
    local callback = data.Callback or function() end

    local row = create("Frame", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
    })

    local label = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -52, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(label, 0.45)

    local valueLabel = create("TextLabel", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(52, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    textStroke(valueLabel, 0.45)

    local bar = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        AutoButtonColor = false,
        Text = "",
    })
    stroke(bar, Theme.Outline, 0, 1)
    gradient(bar)
    bar.ClipsDescendants = true

    local fill = create("Frame", {
        Parent = bar,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    })
    table.insert(self.Window.AccentObjects, fill)
    create("UICorner", {
        Parent = fill,
        CornerRadius = UDim.new(0, 5),
    })

    local fillGradient = create("UIGradient", {
        Parent = fill,
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.35),
        }),
    })

    local sliding = false
    local slider = {Value = value, Flag = flag}

    local function setFromX(x)
        local alpha = clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        slider:Set(minimum + (maximum - minimum) * alpha)
    end

    function slider:Set(newValue, silent)
        newValue = clamp(round(tonumber(newValue) or minimum, decimals), minimum, maximum)
        value = newValue
        self.Value = newValue
        registerFlag(flag, newValue)

        local alpha = maximum == minimum and 0 or ((newValue - minimum) / (maximum - minimum))
        tween(fill, {Size = UDim2.new(alpha, 0, 1, 0)}, 0.08)
        valueLabel.Text = tostring(newValue) .. suffix

        if not silent then
            task.spawn(callback, newValue)
        end
    end

    function slider:Get()
        return value
    end

    connect(bar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(input.Position.X)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not sliding then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    slider:Set(value, true)
    table.insert(self.Items, slider)
    return slider
end

function SectionMethods:Button(data)
    if typeof(data) == "string" then
        data = {Name = data}
    end
    data = data or {}

    local callback = data.Callback or function() end
    local baseTextColor = data.Risky and Theme.Risky or Theme.Text

    local button = create("TextButton", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        Text = data.Name or "Button",
        TextColor3 = baseTextColor,
        TextSize = 13,
    })
    textStroke(button, 0.45)
    stroke(button, Theme.Outline, 0, 1)
    gradient(button)

    hover(button,
        function()
            tween(button, {BackgroundColor3 = Theme.Hovered}, 0.12)
        end,
        function()
            tween(button, {BackgroundColor3 = Theme.Element}, 0.12)
        end
    )

    connect(button.MouseButton1Down, function()
        tween(button, {
            TextColor3 = data.Risky and Theme.Risky or Theme.Accent
        }, 0.08)

        task.delay(0.12, function()
            if button.Parent then
                tween(button, {
                    TextColor3 = data.Risky and Theme.Risky or Theme.Text
                }, 0.12)
            end
        end)
        task.spawn(callback)
    end)

    local object = {}
    function object:Press()
        task.spawn(callback)
    end

    table.insert(self.Items, object)
    return object
end

local function closePopup(popup)
    if popup and popup.Parent then
        popup:Destroy()
    end
end

function SectionMethods:Dropdown(data)
    data = data or {}

    local items = data.Items or {}
    local flag = data.Flag or data.Name or ("Dropdown_" .. tostring(#self.Items + 1))
    local value = data.Default
    local callback = data.Callback or function() end
    local open = false
    local popup

    if value == nil and #items > 0 then
        value = items[1]
    end

    local row = create("Frame", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    })

    local label = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(label, 0.45)

    local selector = create("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
    })
    stroke(selector, Theme.Outline, 0, 1)
    gradient(selector)

    local selectedText = create("TextLabel", {
        Parent = selector,
        Position = UDim2.fromOffset(5, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = tostring(value or "None"),
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Active = false,
    })
    textStroke(selectedText, 0.5)

    local arrow = create("TextLabel", {
        Parent = selector,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "v",
        TextColor3 = Theme.MutedText,
        TextSize = 12,
        Active = false,
    })

    local dropdown = {Value = value, Flag = flag}

    function dropdown:Set(newValue, silent)
        value = newValue
        self.Value = newValue
        registerFlag(flag, newValue)
        selectedText.Text = tostring(newValue or "None")

        if not silent then
            task.spawn(callback, newValue)
        end
    end

    function dropdown:Refresh(newItems)
        items = newItems or {}
        if value ~= nil and not table.find(items, value) then
            self:Set(items[1], true)
        end
    end

    local function close()
        open = false
        arrow.Text = "v"
        closePopup(popup)
        popup = nil

        if Library.ActivePopupCloser == close then
            Library.ActivePopupCloser = nil
            Library.ActivePopupObject = nil
            Library.ActivePopupSource = nil
        end
    end

    local function openPopup()
        if open then
            close()
            return
        end

        Library:CloseOpenFrames()
        open = true
        arrow.Text = "^"

        popup = create("Frame", {
            Parent = ScreenGui,
            Name = "DropdownPopup",
            Position = UDim2.fromOffset(selector.AbsolutePosition.X, selector.AbsolutePosition.Y + selector.AbsoluteSize.Y + 3),
            Size = UDim2.fromOffset(selector.AbsoluteSize.X, math.min(#items * 20 + 4, 145)),
            BackgroundColor3 = Theme.Inline,
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            ZIndex = 5000,
            ClipsDescendants = true,
        })
        stroke(popup, Theme.Outline, 0, 1)
        Library:SetOpenFrameCloser(close, popup, selector)

        local scroller = create("ScrollingFrame", {
            Parent = popup,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ZIndex = 5001,
        })

        local list = create("UIListLayout", {
            Parent = scroller,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        for _, option in ipairs(items) do
            local optionButton = create("TextButton", {
                Parent = scroller,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Code,
                Text = "  " .. tostring(option),
                TextColor3 = option == value and Theme.Accent or Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5002,
            })
            textStroke(optionButton, 0.5)

            hover(optionButton,
                function()
                    tween(optionButton, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Hovered}, 0.1)
                end,
                function()
                    tween(optionButton, {BackgroundTransparency = 1}, 0.1)
                end
            )

            connect(optionButton.MouseButton1Down, function()
                dropdown:Set(option)
                close()
            end)
        end
    end

    connect(selector.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            openPopup()
        end
    end)
    dropdown:Set(value, true)
    table.insert(self.Items, dropdown)
    return dropdown
end

function SectionMethods:Textbox(data)
    data = data or {}

    local flag = data.Flag or data.Name or ("Textbox_" .. tostring(#self.Items + 1))
    local callback = data.Callback or function() end
    local value = tostring(data.Default or "")

    local row = create("Frame", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    })

    local label = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Textbox",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(label, 0.45)

    local box = create("TextBox", {
        Parent = row,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        ClearTextOnFocus = false,
        Font = Enum.Font.Code,
        PlaceholderText = data.Placeholder or "...",
        PlaceholderColor3 = Theme.MutedText,
        Text = value,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    stroke(box, Theme.Outline, 0, 1)

    create("UIPadding", {
        Parent = box,
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })

    local object = {Value = value, Flag = flag}

    function object:Set(newValue, silent)
        value = tostring(newValue or "")
        self.Value = value
        box.Text = value
        registerFlag(flag, value)

        if not silent then
            task.spawn(callback, value)
        end
    end

    connect(box.FocusLost, function(enterPressed)
        object:Set(box.Text)
    end)

    object:Set(value, true)
    table.insert(self.Items, object)
    return object
end

function SectionMethods:Label(name)
    local label = create("TextLabel", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = tostring(name or "Label"),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })
    textStroke(label, 0.45)

    local object = {}

    function object:Set(text)
        label.Text = tostring(text or "")
    end

    table.insert(self.Items, object)
    return object
end

function SectionMethods:MarqueeLabel(name)
    local viewport = create("Frame", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })

    local label = create("TextLabel", {
        Parent = viewport,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = tostring(name or "Label"),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    textStroke(label, 1)

    local refresh = attachSmoothMarquee(viewport, label, false)
    refresh(name or "Label")

    local object = {}

    function object:Set(newText)
        refresh(tostring(newText or ""))
    end

    table.insert(self.Items, object)
    return object
end

function SectionMethods:Separator(name)
    local row = create("Frame", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, name and 18 or 5),
        BackgroundTransparency = 1,
    })

    local line = create("Frame", {
        Parent = row,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
    })

    if name then
        local text = create("TextLabel", {
            Parent = row,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundColor3 = Theme.Inline,
            BorderSizePixel = 0,
            Font = Enum.Font.Code,
            Text = "  " .. tostring(name) .. "  ",
            TextColor3 = Theme.MutedText,
            TextSize = 13,
        })
        textStroke(text, 0.5)
    end

    local object = {}
    table.insert(self.Items, object)
    return object
end

function SectionMethods:Keybind(data)
    data = data or {}

    local flag = data.Flag or data.Name or ("Keybind_" .. tostring(#self.Items + 1))
    local callback = data.Callback or function() end
    local changedCallback = data.OnChanged or data.Changed or function() end

    local key = data.Default or Enum.KeyCode.RightShift
    local mode = data.Mode or "Toggle"
    local waiting = false
    local waitingStartedAt = 0
    local active = mode == "Always On"
    local modePopup

    if mode ~= "Hold" and mode ~= "Toggle" and mode ~= "Always On" then
        mode = "Toggle"
    end

    local row = create("TextButton", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = false,
    })

    local labelViewport = create("Frame", {
        Parent = row,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })

    local label = create("TextLabel", {
        Parent = labelViewport,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Keybind",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    textStroke(label, 1)

    local keyBox = create("Frame", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(112, 20),
        BackgroundColor3 = Theme.Element,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
        ClipsDescendants = true,
    })
    stroke(keyBox, Theme.Outline, 0, 1)

    local keyViewport = create("Frame", {
        Parent = keyBox,
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -27, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    })

    local keyText = create("TextLabel", {
        Parent = keyViewport,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = keyName(key),
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 3,
    })
    textStroke(keyText, 1)

    local modeSeparator = create("Frame", {
        Parent = keyBox,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -21, 0, 3),
        Size = UDim2.new(0, 1, 1, -6),
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        ZIndex = 4,
    })

    local modeTag = create("TextLabel", {
        Parent = keyBox,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = string.sub(string.upper(mode), 1, 1),
        TextColor3 = Theme.MutedText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5,
    })
    textStroke(modeTag, 1)

    local refreshLabelMarquee = attachSmoothMarquee(labelViewport, label, false)
    local refreshKeyMarquee = attachSmoothMarquee(keyViewport, keyText, true)

    local object = {
        Value = key,
        Flag = flag,
        Mode = mode,
        Active = active,
    }

    local function updateFlagState()
        registerFlag(flag, key)
        registerFlag(flag .. "_Mode", mode)
        registerFlag(flag .. "_State", active)
    end

    local function fireState(newState)
        if active == newState then
            return
        end

        active = newState
        object.Active = active
        registerFlag(flag .. "_State", active)
        task.spawn(callback, active, key, mode)
    end

    local function inputMatchesKey(input, bind)
        if typeof(bind) ~= "EnumItem" then
            return false
        end

        if bind.EnumType == Enum.KeyCode then
            return bind ~= Enum.KeyCode.Unknown
                and input.KeyCode == bind
        end

        if bind.EnumType == Enum.UserInputType then
            return bind ~= Enum.UserInputType.None
                and input.UserInputType == bind
        end

        return false
    end

    local function getBindableInput(input)
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            return input.KeyCode
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
            return input.UserInputType
        end

        return nil
    end

    local function closeModePopup()
        if modePopup and modePopup.Parent then
            modePopup:Destroy()
        end

        modePopup = nil

        if Library.ActivePopupCloser == closeModePopup then
            Library.ActivePopupCloser = nil
            Library.ActivePopupObject = nil
            Library.ActivePopupSource = nil
        end
    end

    function object:Set(newKey, silent)
        if typeof(newKey) ~= "EnumItem" then
            return
        end

        key = newKey
        self.Value = newKey
        refreshKeyMarquee(keyName(newKey))
        updateFlagState()

        if data.MenuBind then
            Library:SetMenuKeybind(newKey)
        end

        if not silent then
            task.spawn(changedCallback, newKey, mode)
        end
    end

    function object:SetMode(newMode, silent)
        if newMode ~= "Hold" and newMode ~= "Toggle" and newMode ~= "Always On" then
            return
        end

        local previousMode = mode
        mode = newMode
        self.Mode = newMode
        modeTag.Text = string.sub(string.upper(newMode), 1, 1)

        if newMode == "Always On" then
            active = true
        elseif previousMode == "Always On" or newMode == "Hold" then
            active = false
        end

        self.Active = active
        updateFlagState()

        if data.MenuBind then
            Library:SetMenuBindMode(newMode)
        elseif newMode == "Always On" then
            task.spawn(callback, true, key, mode)
        else
            task.spawn(callback, false, key, mode)
        end

        if not silent then
            task.spawn(changedCallback, key, newMode)
        end
    end

    function object:Get()
        return key
    end

    function object:GetMode()
        return mode
    end

    local function openModePopup()
        if modePopup then
            closeModePopup()
            return
        end

        Library:CloseOpenFrames()

        local width = 108
        local height = 66
        local viewport = getViewportSize()

        local x = clamp(
            keyBox.AbsolutePosition.X + keyBox.AbsoluteSize.X - width,
            WINDOW_MARGIN,
            math.max(WINDOW_MARGIN, viewport.X - width - WINDOW_MARGIN)
        )
        local y = clamp(
            keyBox.AbsolutePosition.Y + keyBox.AbsoluteSize.Y + 4,
            WINDOW_MARGIN,
            math.max(WINDOW_MARGIN, viewport.Y - height - WINDOW_MARGIN)
        )

        modePopup = create("Frame", {
            Parent = ScreenGui,
            Name = "KeybindModePopup",
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, height),
            BackgroundColor3 = Theme.Inline,
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            ZIndex = 7000,
        })
        stroke(modePopup, Theme.Outline, 0, 1)

        create("UIPadding", {
            Parent = modePopup,
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
        })

        create("UIListLayout", {
            Parent = modePopup,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        for _, option in ipairs({"Hold", "Toggle", "Always On"}) do
            local optionButton = create("TextButton", {
                Parent = modePopup,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = option == mode and Theme.Hovered or Theme.Element,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Code,
                Text = option,
                TextColor3 = option == mode and Theme.Accent or Theme.Text,
                TextSize = 11,
                ZIndex = 7001,
            })
            textStroke(optionButton, 1)

            hover(
                optionButton,
                function()
                    tween(optionButton, {BackgroundColor3 = Theme.Hovered}, 0.1)
                end,
                function()
                    if option ~= mode then
                        tween(optionButton, {BackgroundColor3 = Theme.Element}, 0.1)
                    end
                end
            )

            connect(optionButton.MouseButton1Down, function()
                object:SetMode(option)
                closeModePopup()
            end)
        end

        Library:SetOpenFrameCloser(closeModePopup, modePopup, row)
    end

    connect(row.InputBegan, function(input)
        if waiting then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeModePopup()
            waiting = true
            waitingStartedAt = os.clock()
            refreshKeyMarquee("PRESS KEY")
            tween(keyText, {TextColor3 = Theme.Accent}, 0.1)

        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            waiting = false
            refreshKeyMarquee(keyName(key))
            tween(keyText, {TextColor3 = Theme.Text}, 0.1)
            openModePopup()
        end
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if waiting then
            -- Ignore only the exact LMB press that opened capture mode.
            -- A later LMB press is a valid bind.
            if input.UserInputType == Enum.UserInputType.MouseButton1
            and os.clock() - waitingStartedAt < 0.08 then
                return
            end

            if input.KeyCode == Enum.KeyCode.Escape then
                waiting = false
                refreshKeyMarquee(keyName(key))
                tween(keyText, {TextColor3 = Theme.Text}, 0.1)
                return
            end

            local newKey = getBindableInput(input)

            if newKey then
                waiting = false
                object:Set(newKey)
                refreshKeyMarquee(keyName(key))
                tween(keyText, {TextColor3 = Theme.Text}, 0.1)
            end

            return
        end

        if processed or data.MenuBind then
            return
        end

        if not inputMatchesKey(input, key) then
            return
        end

        if mode == "Hold" then
            fireState(true)
        elseif mode == "Toggle" then
            fireState(not active)
        elseif mode == "Always On" then
            fireState(true)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if data.MenuBind then
            return
        end

        if inputMatchesKey(input, key)
        and mode == "Hold" then
            fireState(false)
        end
    end)

    refreshLabelMarquee(data.Name or "Keybind")
    object:Set(key, true)
    object:SetMode(mode, true)

    table.insert(self.Items, object)
    return object
end

function SectionMethods:Colorpicker(data)
    data = data or {}

    local flag = data.Flag or data.Name or ("Color_" .. tostring(#self.Items + 1))
    local callback = data.Callback or function() end
    local value = data.Default or Theme.Accent
    local popup
    local popupConnections = {}

    local function popupConnect(signal, callbackFn)
        local c = signal:Connect(callbackFn)
        table.insert(popupConnections, c)
        return c
    end

    local function clearPopupConnections()
        for _, c in ipairs(popupConnections) do
            pcall(function()
                c:Disconnect()
            end)
        end
        table.clear(popupConnections)
    end

    local row = create("TextButton", {
        Parent = self.Content,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
    })

    local label = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = data.Name or "Color",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    textStroke(label, 0.45)

    local preview = create("Frame", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(30, 13),
        BackgroundColor3 = value,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 2,
    })
    stroke(preview, Theme.Outline, 0, 1)

    local object = {
        Value = value,
        Flag = flag,
        Row = row,
        Preview = preview,
        Label = label,
        Section = self
    }

    function object:Set(color, silent)
        if typeof(color) ~= "Color3" then
            return
        end

        value = color
        self.Value = color
        preview.BackgroundColor3 = color
        registerFlag(flag, color)

        if not silent then
            task.spawn(callback, color)
        end
    end

    local function destroyPopup()
        clearPopupConnections()

        if popup and popup.Parent then
            popup:Destroy()
        end

        popup = nil

        if Library.ActivePopupCloser == destroyPopup then
            Library.ActivePopupCloser = nil
            Library.ActivePopupObject = nil
            Library.ActivePopupSource = nil
            Library.ActivePopupInsideCheck = nil
            Library.PopupOpenedAt = 0
        end
    end

    connect(row.MouseButton1Down, function()
        if popup then
            destroyPopup()
            return
        end

        Library:CloseOpenFrames()

        local popupWidth = 186
        local popupHeight = 174
        local viewport = getViewportSize()
        local wantedX = preview.AbsolutePosition.X + preview.AbsoluteSize.X - popupWidth
        local wantedY = preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 4
        local popupX = clamp(wantedX, WINDOW_MARGIN, math.max(WINDOW_MARGIN, viewport.X - popupWidth - WINDOW_MARGIN))
        local popupY = clamp(wantedY, WINDOW_MARGIN, math.max(WINDOW_MARGIN, viewport.Y - popupHeight - WINDOW_MARGIN))

        popup = create("Frame", {
            Parent = ScreenGui,
            Name = "ColorPickerPopup",
            Position = UDim2.fromOffset(popupX, popupY),
            Size = UDim2.fromOffset(popupWidth, popupHeight),
            BackgroundColor3 = Theme.Inline,
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            ZIndex = 6000,
            ClipsDescendants = false,
            Active = true,
        })
        stroke(popup, Theme.Outline, 0, 1)

        local pickerMouseInside = false

        popupConnect(popup.MouseEnter, function()
            pickerMouseInside = true
        end)

        popupConnect(popup.MouseLeave, function()
            pickerMouseInside = false
        end)

        Library:SetOpenFrameCloser(
            destroyPopup,
            popup,
            row,
            function(point)

                return pickerMouseInside or pointInsideGui(popup, point)
            end
        )

        local pickerDrag = create("TextButton", {
            Parent = popup,
            Name = "PickerDrag",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundColor3 = Theme.PageBackground,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.Code,
            Text = "  " .. tostring(data.Name or "Color Picker"),
            TextColor3 = Theme.MutedText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6010,
        })
        textStroke(pickerDrag, 1)

        local pickerDragging = false
        local pickerDragStart
        local pickerStartPosition

        popupConnect(pickerDrag.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            pickerDragging = true

            pickerDragStart = getPointerPosition(input)
            pickerStartPosition = Vector2.new(
                popup.Position.X.Offset,
                popup.Position.Y.Offset
            )
        end)

        local sat = create("TextButton", {
            Parent = popup,
            Position = UDim2.fromOffset(8, 24),
            Size = UDim2.fromOffset(144, 112),
            BackgroundColor3 = Color3.fromHSV(0, 1, 1),
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 6001,
            ClipsDescendants = false,
        })
        stroke(sat, Theme.Outline, 0, 1)

        local satWhite = create("Frame", {
            Parent = sat,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 6002,
            Active = false,
        })
        create("UIGradient", {
            Parent = satWhite,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
        })

        local satBlack = create("Frame", {
            Parent = sat,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 6003,
            Active = false,
        })
        create("UIGradient", {
            Parent = satBlack,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
        })

        local satMarker = create("Frame", {
            Parent = sat,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromOffset(9, 9),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            ZIndex = 6006,
            Active = false,
        })
        create("UICorner", {
            Parent = satMarker,
            CornerRadius = UDim.new(1, 0),
        })
        local markerStroke = stroke(satMarker, Color3.fromRGB(12, 12, 12), 0.05, 2)
        markerStroke.LineJoinMode = Enum.LineJoinMode.Round

        local hue = create("TextButton", {
            Parent = popup,
            Position = UDim2.fromOffset(160, 24),
            Size = UDim2.fromOffset(18, 112),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 6001,
        })
        stroke(hue, Theme.Outline, 0, 1)
        create("UIGradient", {
            Parent = hue,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
            })
        })

        local hueMarker = create("Frame", {
            Parent = hue,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 6, 0, 2),
            BackgroundColor3 = Color3.fromRGB(245, 245, 245),
            BorderSizePixel = 0,
            ZIndex = 6006,
            Active = false,
        })
        stroke(hueMarker, Color3.fromRGB(10, 10, 10), 0.15, 1)

        local hex = create("TextBox", {
            Parent = popup,
            Position = UDim2.fromOffset(8, 146),
            Size = UDim2.fromOffset(170, 20),
            BackgroundColor3 = Theme.Element,
            BorderColor3 = Theme.Border,
            BorderSizePixel = 2,
            ClearTextOnFocus = false,
            Font = Enum.Font.Code,
            Text = "#FFFFFF",
            TextColor3 = Theme.Text,
            TextSize = 13,
            ZIndex = 6001,
        })
        stroke(hex, Theme.Outline, 0, 1)

        local h, s, v = value:ToHSV()
        local satDrag = false
        local hueDrag = false

        local function update()
            if not popup or not popup.Parent then
                return
            end

            local color = Color3.fromHSV(h, s, v)
            sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

            satMarker.Position = UDim2.fromScale(s, 1 - v)
            hueMarker.Position = UDim2.fromScale(0.5, h)

            hex.Text = string.format(
                "#%02X%02X%02X",
                math.floor(color.R * 255 + 0.5),
                math.floor(color.G * 255 + 0.5),
                math.floor(color.B * 255 + 0.5)
            )

            object:Set(color)
        end

        local function satInput(pos)
            s = clamp((pos.X - sat.AbsolutePosition.X) / math.max(sat.AbsoluteSize.X, 1), 0, 1)
            v = 1 - clamp((pos.Y - sat.AbsolutePosition.Y) / math.max(sat.AbsoluteSize.Y, 1), 0, 1)
            update()
        end

        local function hueInput(pos)
            h = clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
            update()
        end

        popupConnect(sat.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                satDrag = true
                satInput(input.Position)
            end
        end)

        popupConnect(hue.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                hueDrag = true
                hueInput(input.Position)
            end
        end)

        popupConnect(UserInputService.InputChanged, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if pickerDragging and pickerDragStart and pickerStartPosition then
                local pointer = getPointerPosition(input)
                local delta = pointer - pickerDragStart
                local viewport = getViewportSize()

                local maxX = math.max(WINDOW_MARGIN, viewport.X - popup.AbsoluteSize.X - WINDOW_MARGIN)
                local maxY = math.max(WINDOW_MARGIN, viewport.Y - popup.AbsoluteSize.Y - WINDOW_MARGIN)

                popup.Position = UDim2.fromOffset(
                    math.floor(clamp(pickerStartPosition.X + delta.X, WINDOW_MARGIN, maxX) + 0.5),
                    math.floor(clamp(pickerStartPosition.Y + delta.Y, WINDOW_MARGIN, maxY) + 0.5)
                )
                return
            end

            if satDrag then
                satInput(input.Position)
            elseif hueDrag then
                hueInput(input.Position)
            end
        end)

        popupConnect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                pickerDragging = false
                pickerDragStart = nil
                pickerStartPosition = nil
                satDrag = false
                hueDrag = false
            end
        end)

        popupConnect(hex.FocusLost, function()
            local raw = string.gsub(hex.Text, "#", "")

            if #raw == 6 then
                local r = tonumber(string.sub(raw, 1, 2), 16)
                local g = tonumber(string.sub(raw, 3, 4), 16)
                local b = tonumber(string.sub(raw, 5, 6), 16)

                if r and g and b then
                    local newColor = Color3.fromRGB(r, g, b)
                    h, s, v = newColor:ToHSV()
                    update()
                end
            end
        end)

        update()
    end)

    object:Set(value, true)
    table.insert(self.Items, object)
    return object
end

function Library:Notify(data)
    data = data or {}

    local holder = ScreenGui:FindFirstChild("Notifications")
    if not holder then
        holder = create("Frame", {
            Parent = ScreenGui,
            Name = "Notifications",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -14, 0, 14),
            Size = UDim2.fromOffset(560, 520),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 8000,
        })

        create("UIListLayout", {
            Parent = holder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    end

    local duration = math.max(0.35, tonumber(data.Duration) or 3)
    local logName = tostring(data.Name or data.Title or "Log")
    local logText = tostring(data.Log or data.Text or "log")
    local formattedLog = string.format('[%s] %q', logName, logText)

    local CARD_H = 32
    local MIN_CARD_W = 170

    local measuredText = TextService:GetTextSize(
        formattedLog,
        13,
        Enum.Font.Code,
        Vector2.new(10000, CARD_H)
    ).X

    local viewport = getViewportSize()
    local MAX_CARD_W = math.max(
        MIN_CARD_W,
        math.min(520, viewport.X - 36)
    )

    local CARD_W = clamp(
        math.ceil(measuredText) + 28,
        MIN_CARD_W,
        MAX_CARD_W
    )

    local slot = create("Frame", {
        Parent = holder,
        Size = UDim2.fromOffset(CARD_W, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 8001,
    })

    local card = create("Frame", {
        Parent = slot,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.fromOffset(CARD_W, CARD_H),
        BackgroundColor3 = Theme.Inline,
        BackgroundTransparency = 1,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        ZIndex = 8002,
        ClipsDescendants = true,
    })

    local cardCorner = card:FindFirstChildOfClass("UICorner")
    if cardCorner then
        cardCorner.CornerRadius = UDim.new(0, 10)
    end

    local cardStroke = stroke(card, Theme.Outline, 1, 1)
    cardStroke.LineJoinMode = Enum.LineJoinMode.Round

    local logLabel = create("TextLabel", {
        Parent = card,
        Position = UDim2.fromOffset(9, 2),
        Size = UDim2.new(1, -18, 1, -9),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = formattedLog,
        TextColor3 = Theme.Text,
        TextTransparency = 1,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8004,
    })
    textStroke(logLabel, 1)

    local timerTrack = create("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 8, 1, -3),
        Size = UDim2.new(1, -16, 0, 2),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8004,
        ClipsDescendants = true,
    })

    create("UICorner", {
        Parent = timerTrack,
        CornerRadius = UDim.new(1, 0),
    })

    local timerFill = create("Frame", {
        Parent = timerTrack,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8005,
    })

    create("UICorner", {
        Parent = timerFill,
        CornerRadius = UDim.new(1, 0),
    })

    task.spawn(function()
        tween(
            slot,
            {Size = UDim2.fromOffset(CARD_W, CARD_H)},
            0.24,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )

        local cardIn = tween(
            card,
            {
                Position = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 0.16,
            },
            0.30,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )

        tween(logLabel, {TextTransparency = 0}, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        tween(cardStroke, {Transparency = 0.08}, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        tween(timerTrack, {BackgroundTransparency = 0.16}, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        tween(timerFill, {BackgroundTransparency = 0}, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

        cardIn.Completed:Wait()

        if not card.Parent then
            return
        end

        local timerTween = tween(
            timerFill,
            {Size = UDim2.new(0, 0, 1, 0)},
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        )

        timerTween.Completed:Wait()

        if not card.Parent then
            return
        end

        local cardOut = tween(
            card,
            {
                Position = UDim2.fromOffset(42, 0),
                BackgroundTransparency = 1,
            },
            0.28,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.In
        )

        tween(logLabel, {TextTransparency = 1}, 0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        tween(cardStroke, {Transparency = 1}, 0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        tween(timerTrack, {BackgroundTransparency = 1}, 0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        tween(timerFill, {BackgroundTransparency = 1}, 0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

        cardOut.Completed:Wait()

        if not slot.Parent then
            return
        end

        local collapse = tween(
            slot,
            {Size = UDim2.fromOffset(CARD_W, 0)},
            0.24,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.InOut
        )

        collapse.Completed:Wait()

        if slot and slot.Parent then
            slot:Destroy()
        end
    end)
end

function Library:Log(name, log, duration)
    return self:Notify({
        Name = name,
        Log = log,
        Duration = duration,
    })
end

local function normalizeControlName(id, data)
    data = data or {}
    return data.Text or data.Name or tostring(id or "")
end

local function registerLinoriaControl(store, id, object)
    if id ~= nil and tostring(id) ~= "" then
        store[tostring(id)] = object
    end
    return object
end

local function decorateLinoriaObject(object)
    if not object then
        return object
    end

    if object.Set and not object.SetValue then
        object.SetValue = function(self, value)
            return self:Set(value)
        end
    end

    if object.Get and not object.GetValue then
        object.GetValue = function(self)
            return self:Get()
        end
    end

    return object
end

function Library:CreateWindow(data)
    data = data or {}

    local window = self:Window({
        Name = data.Title or data.Name or "",
        Size = data.Size or UDim2.fromOffset(
            tonumber(data.Width) or 752,
            tonumber(data.Height) or 540
        ),
        FadeTime = data.FadeTime or 0.34,
    })

    if data.Position and typeof(data.Position) == "UDim2" then
        local root = window.Main
        root.Position = data.Position
        window.RestPosition = Vector2.new(
            root.Position.X.Offset,
            root.Position.Y.Offset
        )
    end

    if data.AutoShow == false then
        window.IsOpen = false
        window.Main.Visible = false
    end

    return window
end

function WindowMethods:AddTab(data)
    if type(data) == "string" then
        data = {Name = data}
    else
        data = data or {}
    end

    return self:Page({
        Name = data.Name or data.Title or data.Text or "",
        Columns = data.Columns or 2,
    })
end

function PageMethods:AddGroupbox(name, side)
    local data

    if type(name) == "table" then
        data = name
    else
        data = {
            Name = name,
            Side = side,
        }
    end

    return self:Section({
        Name = data.Name or data.Title or data.Text or "",
        Side = data.Side or 1,
    })
end

function PageMethods:AddLeftGroupbox(name)
    return self:AddGroupbox(name, 1)
end

function PageMethods:AddRightGroupbox(name)
    return self:AddGroupbox(name, 2)
end

function SectionMethods:AddToggle(id, data)
    data = data or {}

    local changed = {}
    local userCallback = data.Callback

    local object = self:Toggle({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Default = data.Default == true,
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end

            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    object.AddColorPicker = function(selfObject, colorId, colorData)
        colorData = colorData or {}

        local picker = selfObject.Section:Colorpicker({
            Name = "",
            Flag = tostring(colorId),
            Default = colorData.Default or Color3.fromRGB(255, 255, 255),
            Callback = colorData.Callback or function() end,
        })

        decorateLinoriaObject(picker)
        registerLinoriaControl(Library.Options, colorId, picker)

        local pickerRow = picker.Row
        local preview = picker.Preview
        local pickerLabel = picker.Label

        if pickerRow and selfObject.Row then
            pickerRow.Parent = selfObject.Row
            pickerRow.AnchorPoint = Vector2.new(1, 0.5)
            pickerRow.Position = UDim2.new(1, -1, 0.5, 0)
            pickerRow.Size = UDim2.fromOffset(24, 14)
            pickerRow.BackgroundTransparency = 1
            pickerRow.ZIndex = 50

            if pickerLabel then
                pickerLabel.Visible = false
                pickerLabel.Text = ""
            end

            if preview then
                preview.AnchorPoint = Vector2.new(0.5, 0.5)
                preview.Position = UDim2.fromScale(0.5, 0.5)
                preview.Size = UDim2.fromOffset(22, 12)
                preview.ZIndex = 51
            end

            if selfObject.Label then
                selfObject.Label.Size = UDim2.new(1, -52, 1, 0)
            end
        end

        return picker
    end

    return registerLinoriaControl(Library.Toggles, id, object)
end

function SectionMethods:AddSlider(id, data)
    data = data or {}

    local changed = {}
    local userCallback = data.Callback

    local object = self:Slider({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Min = data.Min or 0,
        Max = data.Max or 100,
        Default = data.Default or data.Min or 0,
        Decimals = data.Rounding or data.Decimals or 0,
        Suffix = data.Suffix or "",
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end

            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    return registerLinoriaControl(Library.Options, id, object)
end

function SectionMethods:AddDropdown(id, data)
    data = data or {}

    local values = data.Values or data.Items or {}
    local default = data.Default

    if type(default) == "number" and values[default] ~= nil then
        default = values[default]
    end

    if default == nil then
        default = values[1]
    end

    local changed = {}
    local userCallback = data.Callback

    local object = self:Dropdown({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Items = values,
        Default = default,
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end

            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    object.SetValues = function(selfObject, newValues)
        if selfObject.Refresh then
            selfObject:Refresh(newValues)
        end
        return selfObject
    end

    return registerLinoriaControl(Library.Options, id, object)
end

function SectionMethods:AddInput(id, data)
    data = data or {}

    local changed = {}
    local userCallback = data.Callback

    local object = self:Textbox({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Default = data.Default or "",
        Placeholder = data.Placeholder or data.PlaceholderText or "",
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end

            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    return registerLinoriaControl(Library.Options, id, object)
end

function SectionMethods:AddButton(data, callback)
    if type(data) == "string" then
        data = {
            Text = data,
            Func = callback,
        }
    else
        data = data or {}
    end

    return self:Button({
        Name = data.Text or data.Name or "Button",
        Risky = data.Risky == true,
        Callback = data.Func or data.Callback or function() end,
    })
end

function SectionMethods:AddLabel(text)
    return self:Label(tostring(text or ""))
end

function SectionMethods:AddDivider(text)
    return self:Separator(text)
end

function SectionMethods:AddColorPicker(id, data)
    data = data or {}

    local changed = {}
    local userCallback = data.Callback

    local object = self:Colorpicker({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Default = data.Default or Color3.fromRGB(255, 255, 255),
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end

            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    return registerLinoriaControl(Library.Options, id, object)
end

local KeyAliases = {
    MB1 = Enum.UserInputType.MouseButton1,
    MB2 = Enum.UserInputType.MouseButton2,
    MB3 = Enum.UserInputType.MouseButton3,

    LMB = Enum.UserInputType.MouseButton1,
    RMB = Enum.UserInputType.MouseButton2,
    MMB = Enum.UserInputType.MouseButton3,

    MOUSE1 = Enum.UserInputType.MouseButton1,
    MOUSE2 = Enum.UserInputType.MouseButton2,
    MOUSE3 = Enum.UserInputType.MouseButton3,

    MOUSEBUTTON1 = Enum.UserInputType.MouseButton1,
    MOUSEBUTTON2 = Enum.UserInputType.MouseButton2,
    MOUSEBUTTON3 = Enum.UserInputType.MouseButton3,
}

local function resolveLinoriaKey(value)
    if typeof(value) == "EnumItem" then
        return value
    end

    if type(value) ~= "string" then
        return Enum.KeyCode.Unknown
    end

    local upper = string.upper(value)

    if KeyAliases[upper] then
        return KeyAliases[upper]
    end

    local ok, key = pcall(function()
        return Enum.KeyCode[upper]
    end)

    if ok and key then
        return key
    end

    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        if string.upper(item.Name) == upper then
            return item
        end
    end

    return Enum.KeyCode.Unknown
end

function SectionMethods:AddKeyPicker(id, data)
    data = data or {}

    local changed = {}
    local userCallback = data.Callback

    local object = self:Keybind({
        Name = normalizeControlName(id, data),
        Flag = tostring(id),
        Default = resolveLinoriaKey(data.Default or Enum.KeyCode.Unknown),
        Mode = data.Mode or "Toggle",
        MenuBind = data.MenuBind == true,
        Callback = function(value)
            if userCallback then
                task.spawn(userCallback, value)
            end
        end,
        OnChanged = function(value)
            for _, callback in ipairs(changed) do
                task.spawn(callback, value)
            end
        end,
    })

    decorateLinoriaObject(object)

    object.OnChanged = function(selfObject, callback)
        if type(callback) == "function" then
            table.insert(changed, callback)
        end
        return selfObject
    end

    return registerLinoriaControl(Library.Options, id, object)
end

SectionMethods.AddTextbox = SectionMethods.AddInput
SectionMethods.AddKeybind = SectionMethods.AddKeyPicker
SectionMethods.AddColorpicker = SectionMethods.AddColorPicker

if typeof(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        env.Toggles = Library.Toggles
        env.Options = Library.Options
    end
end

if typeof(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        env.RatScootLibrary = Library
    end
end

return Library
