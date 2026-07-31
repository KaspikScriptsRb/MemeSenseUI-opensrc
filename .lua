local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")

local library = {
    flags = {},
    elements = {},
    theme = {
        mainBg = Color3.fromRGB(16, 16, 18),
        sidebarBg = Color3.fromRGB(20, 20, 22),
        headerBg = Color3.fromRGB(16, 16, 18),
        accent = Color3.fromRGB(235, 42, 60),
        accentDark = Color3.fromRGB(175, 28, 42),
        textBright = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(180, 180, 190),
        textMuted = Color3.fromRGB(130, 130, 140),
        inputBg = Color3.fromRGB(26, 26, 30),
        inputBorder = Color3.fromRGB(44, 44, 52),
        fontBold = Enum.Font.GothamMedium,
        fontMedium = Enum.Font.Gotham,
    }
}

local folderName = "MemeSense_Configs"

local function ensureFolder()
    if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
        if not isfolder(folderName) then
            pcall(makefolder, folderName)
        end
    end
end

library.activeConfigName = "."

function library.saveConfig(name)
    name = name or library.activeConfigName or "."
    library.activeConfigName = name
    ensureFolder()
    local json = httpService:JSONEncode(library.flags)
    if typeof(writefile) == "function" then
        pcall(writefile, folderName .. "/" .. name .. ".json", json)
    end
    return json
end

function library.loadConfig(nameOrData)
    ensureFolder()
    local data = nameOrData
    local path = folderName .. "/" .. nameOrData .. ".json"
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content then
                data = content
                library.activeConfigName = nameOrData
            end
        elseif isfile("MemeSense_" .. nameOrData .. ".json") then
            local ok, content = pcall(readfile, "MemeSense_" .. nameOrData .. ".json")
            if ok and content then
                data = content
                library.activeConfigName = nameOrData
            end
        end
    end

    local success, decoded = pcall(function()
        return httpService:JSONDecode(data)
    end)

    if success and typeof(decoded) == "table" then
        for flag, val in decoded do
            library.flags[flag] = val
            if library.elements[flag] and typeof(library.elements[flag].set) == "function" then
                library.elements[flag]:set(val)
            end
        end
        return true
    end
    return false
end

function library.deleteConfig(name)
    ensureFolder()
    local path = folderName .. "/" .. name .. ".json"
    if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(path) then
        pcall(delfile, path)
    end
end

function library.getFolderConfigs()
    ensureFolder()
    local found = {}
    if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(folderName) then
        local files = listfiles(folderName)
        for _, filePath in files do
            local fileName = filePath:match("([^/\\]+)%.json$")
            if fileName then
                table.insert(found, {
                    name = fileName,
                    modified = os.date("%Y/%m/%d %H:%M:%S")
                })
            end
        end
    end
    return found
end

local function create(className, props)
    local inst = Instance.new(className)
    for k, v in props do
        inst[k] = v
    end
    return inst
end

local function makeCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 3),
        Parent = parent
    })
end

local function makeStroke(parent, color, thickness)
    return create("UIStroke", {
        Color = color or library.theme.inputBorder,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function setupAutoScrollBar(scrollFrame, maxThickness)
    maxThickness = maxThickness or 2
    scrollFrame.ScrollBarThickness = 0
    scrollFrame.ScrollBarImageTransparency = 1
    scrollFrame.ScrollBarImageColor3 = library.theme.inputBorder
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.BackgroundTransparency = 1

    local function update()
        task.defer(function()
            if scrollFrame.AbsoluteCanvasSize.Y > scrollFrame.AbsoluteSize.Y + 20 then
                scrollFrame.ScrollBarThickness = maxThickness
                scrollFrame.ScrollBarImageTransparency = 0
            else
                scrollFrame.ScrollBarThickness = 0
                scrollFrame.ScrollBarImageTransparency = 1
            end
        end)
    end

    scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
    scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
    update()
end

local defaultIcons = {
    Legitbot = "rbxassetid://10723415903",
    ["Aim Assist"] = "rbxassetid://10723416040",
    Players = "rbxassetid://10723424180",
    Chams = "rbxassetid://10723424350",
    Items = "rbxassetid://10723424505",
    Visuals = "rbxassetid://10723424680",
    World = "rbxassetid://10723424838",
    View = "rbxassetid://10723425000",
    Indicators = "rbxassetid://10723425164",
    Miscellaneous = "rbxassetid://10723425316",
    Inventory = "rbxassetid://10723425482",
    Configs = "rbxassetid://10723425624",
}

function library.createWindow(options)
    options = options or {}
    local size = options.size or UDim2.new(0, 690, 0, 510)
    local toggleKey = options.toggleKey or Enum.KeyCode.RightShift

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MemeSenseGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local guiParent = coreGui
    if typeof(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then guiParent = res end
    end
    screenGui.Parent = guiParent

    local window = {
        visible = true,
        tabs = {},
        activeTab = nil,
        fading = false,
    }

    local main = create("CanvasGroup", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = library.theme.mainBg,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Parent = screenGui,
    })
    local mainStroke = makeStroke(main, Color3.fromRGB(32, 32, 36), 1)

    local globalOverlayFrame = create("Frame", {
        Name = "GlobalOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 100000,
        Parent = main,
    })

    local function getPositionInMain(elem)
        local elemAbs = elem.AbsolutePosition
        local mainAbs = main.AbsolutePosition
        return Vector2.new(elemAbs.X - mainAbs.X, elemAbs.Y - mainAbs.Y)
    end

    local topBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = main,
    })

    local gradient = create("UIGradient", {
        Parent = topBar,
    })

    local hue = 0
    runService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * 0.25) % 1
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHSV((hue + 0.00) % 1, 0.85, 0.95)),
            ColorSequenceKeypoint.new(0.20, Color3.fromHSV((hue + 0.20) % 1, 0.85, 0.95)),
            ColorSequenceKeypoint.new(0.40, Color3.fromHSV((hue + 0.40) % 1, 0.85, 0.95)),
            ColorSequenceKeypoint.new(0.60, Color3.fromHSV((hue + 0.60) % 1, 0.85, 0.95)),
            ColorSequenceKeypoint.new(0.80, Color3.fromHSV((hue + 0.80) % 1, 0.85, 0.95)),
            ColorSequenceKeypoint.new(1.00, Color3.fromHSV((hue + 1.00) % 1, 0.85, 0.95)),
        })
    end)

    local sidebar = create("Frame", {
        Size = UDim2.new(0, 165, 1, 0),
        BackgroundColor3 = library.theme.sidebarBg,
        BorderSizePixel = 0,
        Parent = main,
    })

    local logoFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    create("TextLabel", {
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Text = '<font color="rgb(235,42,60)">Meme</font> Sense',
        RichText = true,
        Font = library.theme.fontBold,
        TextSize = 18,
        TextColor3 = library.theme.textBright,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent = logoFrame,
    })

    local tabScroll = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollBarImageColor3 = library.theme.inputBorder,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    })
    setupAutoScrollBar(tabScroll, 2)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = tabScroll,
    })

    local headerBar = create("Frame", {
        Size = UDim2.new(1, -165, 0, 44),
        Position = UDim2.new(0, 165, 0, 0),
        BackgroundColor3 = library.theme.headerBg,
        BorderSizePixel = 0,
        Parent = main,
    })

    local headerLeft = create("Frame", {
        Size = UDim2.new(0.65, -15, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Parent = headerBar,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = headerLeft,
    })

    local headerRight = create("Frame", {
        Size = UDim2.new(0.35, -15, 1, 0),
        Position = UDim2.new(1, -15, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = headerBar,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = headerRight,
    })

    local contentArea = create("Frame", {
        Size = UDim2.new(1, -165, 1, -44),
        Position = UDim2.new(0, 165, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })

    local isDragging = false
    local dragStart, dragOrigin

    local function startDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            dragOrigin = main.Position
        end
    end

    local function stopDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end

    logoFrame.InputBegan:Connect(startDragging)
    logoFrame.InputEnded:Connect(stopDragging)
    headerBar.InputBegan:Connect(startDragging)
    headerBar.InputEnded:Connect(stopDragging)

    local dragConn
    dragConn = userInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            if not main:IsDescendantOf(game) then
                if dragConn then dragConn:Disconnect() end
                return
            end
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                dragOrigin.X.Scale,
                dragOrigin.X.Offset + delta.X,
                dragOrigin.Y.Scale,
                dragOrigin.Y.Offset + delta.Y
            )
        end
    end)

    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    function window.toggle()
        if window.fading then return end
        window.fading = true
        window.visible = not window.visible

        local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if window.visible then
            globalOverlayFrame.Visible = true
            main.Visible = true
            local t = tweenService:Create(main, tweenInfo, { GroupTransparency = 0 })
            tweenService:Create(mainStroke, tweenInfo, { Transparency = 0 }):Play()
            t:Play()
            t.Completed:Connect(function() window.fading = false end)
        else
            globalOverlayFrame.Visible = false
            for _, child in globalOverlayFrame:GetChildren() do
                if child:IsA("Frame") then child.Visible = false end
            end
            local t = tweenService:Create(main, tweenInfo, { GroupTransparency = 1 })
            tweenService:Create(mainStroke, tweenInfo, { Transparency = 1 }):Play()
            t:Play()
            t.Completed:Connect(function()
                main.Visible = false
                window.fading = false
            end)
        end
    end

    local function isInsideView(element)
        if not element or not element:IsDescendantOf(game) then return false end
        local mainAbsPos = main.AbsolutePosition
        local mainAbsSize = main.AbsoluteSize
        local elemAbsPos = element.AbsolutePosition
        local elemAbsSize = element.AbsoluteSize

        if (elemAbsPos.Y + elemAbsSize.Y) < (mainAbsPos.Y + 44) or elemAbsPos.Y > (mainAbsPos.Y + mainAbsSize.Y) then
            return false
        end
        return true
    end

    function window.createHeaderToggle(config)
        local targetTab = window.activeTab or window.tabs[1]
        if targetTab then
            return targetTab:createHeaderToggle(config)
        end
    end

    function window.createHeaderButton(config)
        config = config or {}
        local name = config.name or "Save"
        local icon = config.icon or "rbxassetid://109683101189277"
        local callback = config.callback or function() end

        local btn = create("TextButton", {
            Size = UDim2.new(0, 0, 0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(38, 38, 46),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            LayoutOrder = 2,
            Parent = headerRight,
        })
        makeCorner(btn, 4)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = btn,
        })

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 7),
            Parent = btn,
        })

        if icon ~= "" then
            create("ImageLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ImageTransparency = 0,
                Parent = btn,
            })
        end

        create("TextLabel", {
            Text = name,
            Font = library.theme.fontBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = btn,
        })

        btn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end

    function window.createTab(config)
        config = typeof(config) == "table" and config or { name = tostring(config) }
        local name = config.name or "Tab"
        local icon = config.icon or defaultIcons[name] or "rbxassetid://10723415903"

        local tab = {
            name = name,
            subTabs = {},
        }

        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = tabScroll,
        })

        local activeBar = create("Frame", {
            Size = UDim2.new(0, 4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = library.theme.accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Parent = btn,
        })

        local layoutFrame = create("Frame", {
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Parent = btn,
        })

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
            Parent = layoutFrame,
        })

        local tabIcon = create("ImageLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0,
            Parent = layoutFrame,
        })

        local tabLabel = create("TextLabel", {
            Text = name,
            Font = library.theme.fontBold,
            TextSize = 13,
            TextColor3 = library.theme.textDim,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = layoutFrame,
        })

        local view = create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ClipsDescendants = false,
            Parent = contentArea,
        })

        local fullScroll = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            ScrollBarImageColor3 = library.theme.inputBorder,
            ClipsDescendants = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = view,
        })

        create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
            Parent = fullScroll,
        })

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = fullScroll,
        })

        local columnsFrame = create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Parent = view,
        })

        create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
            Parent = columnsFrame,
        })

        local colLeft = create("ScrollingFrame", {
            Size = UDim2.new(0.5, -12, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            ScrollBarImageColor3 = library.theme.inputBorder,
            ClipsDescendants = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = columnsFrame,
        })

        local colRight = create("ScrollingFrame", {
            Size = UDim2.new(0.5, -12, 1, 0),
            Position = UDim2.new(0.5, 12, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            ScrollBarImageColor3 = library.theme.inputBorder,
            ClipsDescendants = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = columnsFrame,
        })

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = colLeft,
        })

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = colRight,
        })

        local tabHeaderLeft = create("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = headerLeft,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
            Parent = tabHeaderLeft,
        })

        local tabHeaderRight = create("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = headerRight,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
            Parent = tabHeaderRight,
        })

        local function closeGlobalOverlays()
            for _, child in globalOverlayFrame:GetChildren() do
                if child:IsA("GuiObject") then
                    child.Visible = false
                end
            end
        end

        function tab.activate()
            closeGlobalOverlays()
            for _, t in window.tabs do
                t.deactivate()
            end
            window.activeTab = tab
            view.Visible = true
            tabHeaderLeft.Visible = true
            tabHeaderRight.Visible = true
            activeBar.BackgroundTransparency = 0
            tabIcon.ImageColor3 = library.theme.accent
            tabLabel.TextColor3 = library.theme.textBright
            btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            btn.BackgroundTransparency = 0

            if window.masterToggleContainer then
                window.masterToggleContainer.Visible = (tab.name ~= "Configs")
            end
        end

        function tab.deactivate()
            closeGlobalOverlays()
            view.Visible = false
            tabHeaderLeft.Visible = false
            tabHeaderRight.Visible = false
            activeBar.BackgroundTransparency = 1
            tabIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            tabLabel.TextColor3 = library.theme.textDim
            btn.BackgroundTransparency = 1
        end

        function tab.createHeaderToggle(self, config)
            config = config or {}
            local name = config.name or "Master switch"
            local state = config.default or false
            local callback = config.callback or function() end
            local side = config.side == "Left" and tabHeaderLeft or tabHeaderRight

            local container = create("TextButton", {
                Size = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = config.layoutOrder or 1,
                Parent = side,
            })

            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                Parent = container,
            })

            local box = create("Frame", {
                Size = UDim2.new(0, 15, 0, 15),
                BackgroundColor3 = state and library.theme.accent or library.theme.inputBg,
                BorderSizePixel = 0,
                Parent = container,
            })
            makeCorner(box, 3)
            makeStroke(box, state and library.theme.accent or library.theme.inputBorder)

            local checkmark = create("ImageLabel", {
                Size = UDim2.new(0, 11, 0, 11),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://14189590169",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ImageTransparency = state and 0 or 1,
                Parent = box,
            })

            create("TextLabel", {
                Text = name,
                Font = library.theme.fontBold,
                TextSize = 13,
                TextColor3 = library.theme.textBright,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Parent = container,
            })

            container.MouseButton1Click:Connect(function()
                state = not state
                box.BackgroundColor3 = state and library.theme.accent or library.theme.inputBg
                box.UIStroke.Color = state and library.theme.accent or library.theme.inputBorder
                checkmark.ImageTransparency = state and 0 or 1
                pcall(callback, state)
            end)

            return {
                set = function(val)
                    state = val
                    box.BackgroundColor3 = state and library.theme.accent or library.theme.inputBg
                    box.UIStroke.Color = state and library.theme.accent or library.theme.inputBorder
                    checkmark.ImageTransparency = state and 0 or 1
                    pcall(callback, state)
                end,
                get = function() return state end
            }
        end

        function tab.createHeaderDropdown(self, config)
            config = config or {}
            local options = config.options or {}
            local default = config.default or options[1] or ""
            local side = config.side == "Right" and tabHeaderRight or tabHeaderLeft
            local callback = config.callback or function() end

            local dropHeader = create("TextButton", {
                Size = UDim2.new(0, config.width or 135, 0, 24),
                BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                ZIndex = 20,
                Parent = side,
            })
            makeCorner(dropHeader, 3)

            local selected = default
            local selectedLabel = create("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                Text = tostring(selected),
                Font = library.theme.fontBold,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1,
                ZIndex = 21,
                Parent = dropHeader,
            })

            local arrow = create("ImageLabel", {
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new(1, -6, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://10709791523",
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 21,
                Rotation = 180,
                Parent = dropHeader,
            })

            local listContainer = create("Frame", {
                Size = UDim2.new(0, config.width or 110, 0, 0),
                BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Active = true,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 100001,
                Parent = globalOverlayFrame,
            })
            makeCorner(listContainer, 3)

            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0), Parent = listContainer })
            create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), Parent = listContainer })

                local function updateHeaderDropdownPos()
                    if open and dropHeader:IsDescendantOf(game) then
                        local relPos = getPositionInMain(dropHeader)
                        local absWidth = math.round(dropHeader.AbsoluteSize.X)
                        local absHeight = dropHeader.AbsoluteSize.Y
                        listContainer.Position = UDim2.new(0, math.round(relPos.X), 0, math.round(relPos.Y + absHeight - 4))
                        listContainer.Size = UDim2.new(0, absWidth, 0, math.min(#options * 22 + 6, 166))
                    end
                end

                local trackConn
                local function startTracking()
                    if trackConn then trackConn:Disconnect() end
                    trackConn = runService.RenderStepped:Connect(function()
                        if not open or not dropHeader:IsDescendantOf(game) then
                            if trackConn then trackConn:Disconnect() end
                            trackConn = nil
                            listContainer.Visible = false
                            arrow.Rotation = 180
                            return
                        end
                        updateHeaderDropdownPos()
                    end)
                end

                dropHeader.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        for _, child in listContainer:GetChildren() do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        updateHeaderDropdownPos()
                        task.defer(updateHeaderDropdownPos)

                        for _, opt in options do
                            local isSel = (opt == selected)
                            local optBtn = create("TextButton", {
                                Size = UDim2.new(1, -16, 0, 22),
                                Position = UDim2.new(0, 8, 0, 0),
                                BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Text = opt,
                                Font = library.theme.fontBold,
                                TextSize = 12,
                                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 100002,
                                Parent = listContainer,
                            })

                            optBtn.MouseEnter:Connect(function()
                                if not isSel then optBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end
                            end)
                            optBtn.MouseLeave:Connect(function()
                                optBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)
                            end)

                            optBtn.MouseButton1Click:Connect(function()
                                selected = opt
                                selectedLabel.Text = selected
                                open = false
                                if trackConn then trackConn:Disconnect() end
                                trackConn = nil
                                listContainer.Visible = false
                                arrow.Rotation = 180
                                if flag then library.flags[flag] = selected end
                                pcall(callback, selected)
                            end)
                        end
                        listContainer.Visible = true
                        arrow.Rotation = 0
                        startTracking()
                    else
                        if trackConn then trackConn:Disconnect() end
                        trackConn = nil
                        listContainer.Visible = false
                        arrow.Rotation = 180
                    end
                end)

            return {
                set = function(val)
                    selected = val
                    selectedLabel.Text = tostring(selected)
                    if flag then library.flags[flag] = selected end
                    pcall(callback, selected)
                end,
                get = function() return selected end
            }
        end

        function tab.createHeaderButton(self, config)
            config = config or {}
            local name = config.name or "Button"
            local icon = config.icon or ""
            local side = config.side == "Right" and tabHeaderRight or tabHeaderLeft
            local callback = config.callback or function() end

            local btn = create("TextButton", {
                Size = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = side,
            })
            makeCorner(btn, 3)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = btn,
            })

            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 5),
                Parent = btn,
            })

            if icon ~= "" then
                create("ImageLabel", {
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundTransparency = 1,
                    Image = icon,
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = btn,
                })
            end

            create("TextLabel", {
                Text = name,
                Font = library.theme.fontBold,
                TextSize = 12,
                TextColor3 = library.theme.textBright,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Parent = btn,
            })

            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return btn
        end

        function tab.createHeaderPopover(self, config)
            config = config or {}
            local name = config.name or "Menu"
            local icon = config.icon or ""
            local width = config.width or 220

            local btn = tab:createHeaderButton({
                name = name,
                icon = icon,
                side = config.side,
            })

            local popoverFrame = create("Frame", {
                Size = UDim2.new(0, width, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(20, 20, 24),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 100000,
                ClipsDescendants = false,
                Parent = globalOverlayFrame,
            })
            makeCorner(popoverFrame, 4)

            create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = popoverFrame,
            })

            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Parent = popoverFrame,
            })

            local function updatePopoverPos()
                if popoverFrame.Visible and btn:IsDescendantOf(game) then
                    local relPos = getPositionInMain(btn)
                    local btnAbsSize = btn.AbsoluteSize
                    if config.side == "Left" then
                        popoverFrame.Position = UDim2.new(0, relPos.X, 0, relPos.Y + btnAbsSize.Y + 4)
                    else
                        popoverFrame.Position = UDim2.new(0, relPos.X + btnAbsSize.X - width, 0, relPos.Y + btnAbsSize.Y + 4)
                    end
                end
            end

            local popTrackConn
            local function startPopoverTracking()
                if popTrackConn then popTrackConn:Disconnect() end
                popTrackConn = runService.RenderStepped:Connect(function()
                    if not popoverFrame.Visible or not btn:IsDescendantOf(game) then
                        if popTrackConn then popTrackConn:Disconnect() end
                        popTrackConn = nil
                        popoverFrame.Visible = false
                        return
                    end
                    updatePopoverPos()
                end)
            end

            btn.MouseButton1Click:Connect(function()
                local wasVisible = popoverFrame.Visible
                closeGlobalOverlays()
                popoverFrame.Visible = not wasVisible
                if popoverFrame.Visible then
                    updatePopoverPos()
                    task.defer(updatePopoverPos)
                    startPopoverTracking()
                else
                    if popTrackConn then popTrackConn:Disconnect() end
                    popTrackConn = nil
                end
            end)

            local popObj = {
                frame = popoverFrame,
                button = btn,
                open = function() popoverFrame.Visible = true end,
                close = function() popoverFrame.Visible = false end,
                toggle = function() popoverFrame.Visible = not popoverFrame.Visible end,
            }

            function popObj.addInput(self, iConfig)
                iConfig = iConfig or {}
                local placeholder = iConfig.placeholder or ""
                local text = iConfig.default or ""
                local underline = iConfig.underline or false
                local callback = iConfig.callback or function() end

                local boxFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    BorderSizePixel = 0,
                    ZIndex = 301,
                    Parent = popoverFrame,
                })
                makeCorner(boxFrame, 3)

                local box = create("TextBox", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = library.theme.textMuted,
                    Font = library.theme.fontBold,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 302,
                    Parent = boxFrame,
                })

                if underline then
                    create("Frame", {
                        Size = UDim2.new(1, 0, 0, 2),
                        Position = UDim2.new(0, 0, 1, -2),
                        BackgroundColor3 = Color3.fromRGB(200, 30, 40),
                        BorderSizePixel = 0,
                        ZIndex = 303,
                        Parent = boxFrame,
                    })
                end

                box.FocusLost:Connect(function()
                    pcall(callback, box.Text)
                end)

                return {
                    getText = function() return box.Text end,
                    setText = function(t) box.Text = t end,
                    box = box
                }
            end

            function popObj.addToggle(self, tConfig)
                tConfig = tConfig or {}
                local name = tConfig.name or "Toggle"
                local state = tConfig.default or false
                local flag = tConfig.flag
                local callback = tConfig.callback or function() end

                if flag then library.flags[flag] = state end

                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 301,
                    Parent = popoverFrame,
                })

                local box = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = state and library.theme.accent or Color3.fromRGB(28, 28, 34),
                    BorderSizePixel = 0,
                    ZIndex = 302,
                    Parent = row,
                })
                makeCorner(box, 3)

                local checkIcon = create("ImageLabel", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://14189590169",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    Visible = state,
                    ZIndex = 303,
                    Parent = box,
                })

                local nameLabel = create("TextLabel", {
                    Position = UDim2.new(0, 22, 0, 0),
                    Size = UDim2.new(1, -22, 1, 0),
                    Text = name,
                    Font = library.theme.fontMedium,
                    TextSize = 12,
                    TextColor3 = state and library.theme.textBright or library.theme.textDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ZIndex = 302,
                    Parent = row,
                })

                row.MouseButton1Click:Connect(function()
                    state = not state
                    if flag then library.flags[flag] = state end
                    box.BackgroundColor3 = state and library.theme.accent or Color3.fromRGB(28, 28, 34)
                    checkIcon.Visible = state
                    nameLabel.TextColor3 = state and library.theme.textBright or library.theme.textDim
                    pcall(callback, state)
                end)
            end

            function popObj.addSlider(self, sConfig)
                sConfig = sConfig or {}
                local name = sConfig.name or "Slider"
                local min = sConfig.min or 0
                local max = sConfig.max or 10
                local value = sConfig.default or min
                local decimals = sConfig.decimals or 4
                local flag = sConfig.flag
                local callback = sConfig.callback or function() end

                local row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    ZIndex = 301,
                    Parent = popoverFrame,
                })

                local titleLabel = create("TextLabel", {
                    Size = UDim2.new(0.6, 0, 0, 14),
                    Text = name,
                    Font = library.theme.fontMedium,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ZIndex = 302,
                    Parent = row,
                })

                local valLabel = create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 0, 14),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Text = string.format("%." .. decimals .. "f", value),
                    Font = library.theme.fontMedium,
                    TextSize = 12,
                    TextColor3 = library.theme.textDim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    ZIndex = 302,
                    Parent = row,
                })

                local track = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 3),
                    Position = UDim2.new(0, 0, 1, -3),
                    BackgroundColor3 = Color3.fromRGB(36, 36, 44),
                    BorderSizePixel = 0,
                    ZIndex = 302,
                    Parent = row,
                })

                local fill = create("Frame", {
                    Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0),
                    BackgroundColor3 = library.theme.accent,
                    BorderSizePixel = 0,
                    ZIndex = 303,
                    Parent = track,
                })

                local dragging = false
                local function updateSlider(input)
                    local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = min + (max - min) * percent
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    valLabel.Text = string.format("%." .. decimals .. "f", value)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateSlider(input)
                    end
                end)
                userInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
            end

            function popObj.addDropdown(self, dConfig)
                dConfig = dConfig or {}
                local name = dConfig.name or "Dropdown"
                local options = dConfig.options or {}
                local selected = dConfig.default or options[1] or ""
                local flag = dConfig.flag
                local callback = dConfig.callback or function() end

                local row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    ZIndex = 301,
                    Parent = popoverFrame,
                })

                create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Text = name,
                    Font = library.theme.fontBold,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ZIndex = 302,
                    Parent = row,
                })

                local dropHeader = create("TextButton", {
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 302,
                    Parent = row,
                })
                makeCorner(dropHeader, 3)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Text = tostring(selected),
                    Font = library.theme.fontBold,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ZIndex = 303,
                    Parent = dropHeader,
                })

                create("ImageLabel", {
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://10709791523",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    Rotation = 180,
                    ZIndex = 303,
                    Parent = dropHeader,
                })

                dropHeader.MouseButton1Click:Connect(function()
                    local nextIdx = 1
                    for idx, opt in options do
                        if opt == selected then nextIdx = (idx % #options) + 1 break end
                    end
                    selected = options[nextIdx] or options[1]
                    label.Text = tostring(selected)
                    if flag then library.flags[flag] = selected end
                    pcall(callback, selected)
                end)
            end

            function popObj.addButton(self, bConfig)
                bConfig = bConfig or {}
                local name = bConfig.name or "Button"
                local callback = bConfig.callback or function() end

                local btnItem = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Color3.fromRGB(36, 36, 44),
                    Text = name,
                    Font = library.theme.fontBold,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    BorderSizePixel = 0,
                    ZIndex = 301,
                    Parent = popoverFrame,
                })
                makeCorner(btnItem, 3)

                btnItem.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
            end

            function popObj.addKeybindButton(self, kConfig)
                kConfig = kConfig or {}
                local keyName = kConfig.defaultName or "INS"
                local callback = kConfig.callback or function() end

                local keyBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = keyName,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    BorderSizePixel = 0,
                    ZIndex = 301,
                    Parent = popoverFrame,
                })
                makeCorner(keyBtn, 3)

                local binding = false
                keyBtn.MouseButton1Click:Connect(function()
                    binding = true
                    keyBtn.Text = "..."
                end)

                userInputService.InputBegan:Connect(function(input)
                    if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        keyName = input.KeyCode.Name
                        keyBtn.Text = keyName
                        window.toggleKey = input.KeyCode
                        pcall(callback, input.KeyCode)
                    end
                end)
            end

            return popObj
        end

        function tab.createHeaderIcon(self, config)
            config = config or {}
            local icon = config.icon or "rbxassetid://10723346959"
            local side = config.side == "Right" and tabHeaderRight or tabHeaderLeft
            local callback = config.callback or function() end

            local iconLabel = create("ImageButton", {
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                Parent = side,
            })

            iconLabel.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return iconLabel
        end

        btn.MouseButton1Click:Connect(function()
            tab.activate()
        end)

        local function createSection(parentCol, title)
            local card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = false,
                Parent = parentCol,
            })

            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = card,
            })

            if title and title ~= "" then
                create("TextLabel", {
                    Text = title,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 18),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BackgroundTransparency = 1,
                    Parent = card,
                })
            end

            local section = {}

            function section.createSubTabs(self, config)
                config = typeof(config) == "table" and config or { options = config }
                local opts = config.options or {}
                local callback = config.callback or function() end
                local active = config.default or opts[1] or ""

                local bar = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Parent = card,
                })

                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 18),
                    Parent = bar,
                })

                local btns = {}
                for _, opt in opts do
                    local b = create("TextButton", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = opt,
                        Font = library.theme.fontBold,
                        TextSize = 13,
                        TextColor3 = (opt == active) and library.theme.textBright or library.theme.textMuted,
                        Parent = bar,
                    })

                    b.MouseButton1Click:Connect(function()
                        active = opt
                        for name, btnObj in btns do
                            btnObj.TextColor3 = (name == active) and library.theme.textBright or library.theme.textMuted
                        end
                        pcall(callback, active)
                    end)

                    btns[opt] = b
                end

                return {
                    set = function(val)
                        active = val
                        for name, btnObj in btns do
                            btnObj.TextColor3 = (name == active) and library.theme.textBright or library.theme.textMuted
                        end
                        pcall(callback, active)
                    end
                }
            end

            function section.createToggle(self, config)
                config = config or {}
                local name = config.name or "Toggle"
                local state = config.default or false
                local flag = config.flag
                local callback = config.callback or function() end

                if flag then library.flags[flag] = state end

                local row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    Parent = card,
                })

                local toggleBtn = create("TextButton", {
                    Size = UDim2.new(1, -30, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = row,
                })

                local box = create("Frame", {
                    Size = UDim2.new(0, 15, 0, 15),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = state and library.theme.accent or library.theme.inputBg,
                    BorderSizePixel = 0,
                    Parent = toggleBtn,
                })
                makeCorner(box, 3)
                makeStroke(box, state and library.theme.accent or library.theme.inputBorder)

                local checkmark = create("ImageLabel", {
                    Size = UDim2.new(0, 11, 0, 11),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://14189590169",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ImageTransparency = state and 0 or 1,
                    Parent = box,
                })

                local label = create("TextLabel", {
                    Position = UDim2.new(0, 23, 0, 0),
                    Size = UDim2.new(1, -23, 1, 0),
                    Text = name,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = toggleBtn,
                })

                local rightControls = create("Frame", {
                    Size = UDim2.new(0, 60, 1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    Parent = row,
                })

                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 4),
                    Parent = rightControls,
                })

                local function updateVisuals()
                    box.BackgroundColor3 = state and library.theme.accent or library.theme.inputBg
                    box.UIStroke.Color = state and library.theme.accent or library.theme.inputBorder
                    checkmark.ImageTransparency = state and 0 or 1
                end

                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    if flag then library.flags[flag] = state end
                    updateVisuals()
                    pcall(callback, state)
                end)

                local toggleObj = {
                    set = function(val)
                        state = val
                        if flag then library.flags[flag] = state end
                        updateVisuals()
                        pcall(callback, state)
                    end,
                    get = function() return state end,
                }
                if flag then library.elements[flag] = toggleObj end

                function toggleObj.addKeybind(self, kConfig)
                    kConfig = kConfig or {}
                    local currentKey = kConfig.default or Enum.KeyCode.Unknown
                    local keyMode = kConfig.mode or "On key down"
                    local keyCallback = kConfig.callback or function() end
                    local binding = false

                    local iconBtn = create("ImageButton", {
                        Size = UDim2.new(0, 18, 0, 16),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://121332782788896",
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ImageTransparency = 0,
                        BorderSizePixel = 0,
                        Parent = rightControls,
                    })

                    local popup = create("Frame", {
                        Size = UDim2.new(0, 150, 0, 75),
                        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        Active = true,
                        Visible = false,
                        ZIndex = 100005,
                        Parent = globalOverlayFrame,
                    })
                    makeCorner(popup, 4)
                    create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = popup })

                    local bindTrackConn
                    local function startBindTracking()
                        if bindTrackConn then bindTrackConn:Disconnect() end
                        bindTrackConn = runService.RenderStepped:Connect(function()
                            if not popup.Visible or not iconBtn:IsDescendantOf(game) or not isInsideView(iconBtn) then
                                if bindTrackConn then bindTrackConn:Disconnect() end
                                bindTrackConn = nil
                                popup.Visible = false
                                return
                            end
                            local relPos = getPositionInMain(iconBtn)
                            local iconAbsSize = iconBtn.AbsoluteSize
                            popup.Position = UDim2.new(0, relPos.X + iconAbsSize.X + 4, 0, relPos.Y + iconAbsSize.Y + 4)
                        end)
                    end

                    iconBtn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            popup.Visible = not popup.Visible
                            if popup.Visible then
                                local relPos = getPositionInMain(iconBtn)
                                local iconAbsSize = iconBtn.AbsoluteSize
                                popup.Position = UDim2.new(0, relPos.X + iconAbsSize.X + 4, 0, relPos.Y + iconAbsSize.Y + 4)
                                startBindTracking()
                            else
                                if bindTrackConn then bindTrackConn:Disconnect() end
                                bindTrackConn = nil
                            end
                        end
                    end)

                    create("TextLabel", {
                        Size = UDim2.new(0.4, 0, 0, 16),
                        Text = "Type",
                        Font = library.theme.fontBold,
                        TextSize = 12,
                        TextColor3 = library.theme.textBright,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        ZIndex = 100006,
                        Parent = popup,
                    })

                    local modeDropBtn = create("TextButton", {
                        Size = UDim2.new(0.55, 0, 0, 18),
                        Position = UDim2.new(1, 0, 0, 0),
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                        BorderSizePixel = 0,
                        Active = true,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 100006,
                        Parent = popup,
                    })
                    makeCorner(modeDropBtn, 3)

                    local modeLabel = create("TextLabel", {
                        Size = UDim2.new(1, -14, 1, 0),
                        Position = UDim2.new(0, 5, 0, 0),
                        Text = keyMode,
                        Font = library.theme.fontBold,
                        TextSize = 11,
                        TextColor3 = library.theme.textBright,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        ZIndex = 100006,
                        Parent = modeDropBtn,
                    })

                    local modeArrow = create("ImageLabel", {
                        Size = UDim2.new(0, 8, 0, 8),
                        Position = UDim2.new(1, -4, 0.5, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://10709791523",
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 100006,
                        Rotation = 180,
                        Parent = modeDropBtn,
                    })

                    local modeDropContainer = create("Frame", {
                        Size = UDim2.new(0, 85, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        Active = true,
                        Visible = false,
                        ZIndex = 100007,
                        Parent = globalOverlayFrame,
                    })
                    makeCorner(modeDropContainer, 3)

                    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0), Parent = modeDropContainer })
                    create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = modeDropContainer })

                    local modeDropOpen = false
                    modeDropBtn.MouseButton1Click:Connect(function()
                        modeDropOpen = not modeDropOpen
                        if modeDropOpen then
                            local relBPos = getPositionInMain(modeDropBtn)
                            local bWidth = math.round(modeDropBtn.AbsoluteSize.X)
                            local bHeight = modeDropBtn.AbsoluteSize.Y
                            modeDropContainer.Position = UDim2.new(0, math.round(relBPos.X), 0, math.round(relBPos.Y + bHeight - 4))
                            modeDropContainer.Size = UDim2.new(0, bWidth, 0, 4 * 20 + 6)
                            modeDropContainer.Visible = true
                            modeArrow.Rotation = 0
                        else
                            modeDropContainer.Visible = false
                            modeArrow.Rotation = 180
                        end
                    end)

                    local modeOptions = {"Always on", "On key down", "Toggle", "Disabled"}
                    for _, mOpt in modeOptions do
                        local isSel = (mOpt == keyMode)
                        local mBtn = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 20),
                            BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Text = mOpt,
                            Font = library.theme.fontBold,
                            TextSize = 11,
                            TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 100008,
                            Parent = modeDropContainer,
                        })
                        create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = mBtn })

                        mBtn.MouseEnter:Connect(function()
                            if not isSel then mBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end
                        end)
                        mBtn.MouseLeave:Connect(function()
                            mBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)
                        end)

                        mBtn.MouseButton1Click:Connect(function()
                            keyMode = mOpt
                            modeLabel.Text = keyMode
                            modeDropOpen = false
                            modeDropContainer.Visible = false
                            modeArrow.Rotation = 180
                            if keyMode == "Always on" then
                                toggleObj.set(true)
                            elseif keyMode == "Disabled" or keyMode == "On key down" then
                                toggleObj.set(false)
                            end
                            pcall(keyCallback, currentKey, keyMode)
                        end)
                    end

                    local keyBox = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 22),
                        Position = UDim2.new(0, 0, 0, 28),
                        BackgroundColor3 = Color3.fromRGB(20, 22, 26),
                        BorderSizePixel = 0,
                        Text = "[" .. (currentKey == Enum.KeyCode.Unknown and "none" or currentKey.Name:lower()) .. "]",
                        Font = library.theme.fontBold,
                        TextSize = 12,
                        TextColor3 = library.theme.textBright,
                        ZIndex = 100006,
                        Parent = popup,
                    })
                    makeCorner(keyBox, 3)

                    keyBox.MouseButton1Click:Connect(function()
                        binding = true
                        keyBox.Text = "[...]"
                    end)

                    userInputService.InputBegan:Connect(function(input, gpe)
                        if binding then
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                currentKey = input.KeyCode
                                binding = false
                                keyBox.Text = "[" .. (currentKey == Enum.KeyCode.Unknown and "none" or currentKey.Name:lower()) .. "]"
                                iconBtn.ImageColor3 = (currentKey ~= Enum.KeyCode.Unknown) and library.theme.accent or Color3.fromRGB(255, 255, 255)
                                pcall(keyCallback, currentKey, keyMode)
                            end
                        elseif not gpe and input.KeyCode == currentKey and currentKey ~= Enum.KeyCode.Unknown then
                            if keyMode == "Toggle" then
                                toggleObj.set(not state)
                            elseif keyMode == "On key down" then
                                toggleObj.set(true)
                            elseif keyMode == "Always on" then
                                toggleObj.set(true)
                            end
                        end
                    end)

                    userInputService.InputEnded:Connect(function(input, gpe)
                        if not gpe and input.KeyCode == currentKey and currentKey ~= Enum.KeyCode.Unknown then
                            if keyMode == "On key down" then
                                toggleObj.set(false)
                            end
                        end
                    end)

                    return toggleObj
                end

                return toggleObj
            end

            -- Highly Flexible Slider (Integers, Decimals, minText "Disabled", maxText "∞", custom format)
            function section.createSlider(self, config)
                config = config or {}
                local name = config.name or "Slider"
                local min = config.min or 0
                local max = config.max or 100
                local default = config.default or min
                local decimals = config.decimals or 0
                local suffix = config.suffix or ""
                local minText = config.minText
                local maxText = config.maxText
                local customFormat = config.format
                local flag = config.flag
                local callback = config.callback or function() end

                local value = math.clamp(default, min, max)
                if flag then library.flags[flag] = value end

                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    Parent = card,
                })

                create("TextLabel", {
                    Size = UDim2.new(0.6, 0, 0, 14),
                    Text = name,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local function getFormattedValue(val)
                    if customFormat then
                        return customFormat(val)
                    end
                    if minText and val == min then
                        return minText
                    end
                    if maxText and val == max then
                        return maxText
                    end
                    return string.format("%." .. decimals .. "f", val) .. suffix
                end

                local valButton = create("TextButton", {
                    Size = UDim2.new(0.35, 0, 0, 14),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    Text = getFormattedValue(value),
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = container,
                })

                local manualInputFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(20, 22, 28),
                    BorderSizePixel = 0,
                    ClipsDescendants = false,
                    Visible = false,
                    ZIndex = 500,
                    Parent = container,
                })
                makeCorner(manualInputFrame, 4)

                create("Frame", {
                    Size = UDim2.new(1, -4, 0, 2),
                    Position = UDim2.new(0, 2, 1, -2),
                    BackgroundColor3 = library.theme.accent,
                    BorderSizePixel = 0,
                    ZIndex = 501,
                    Parent = manualInputFrame,
                })

                local manualTextBox = create("TextBox", {
                    Size = UDim2.new(1, -10, 1, -2),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = string.format("%." .. decimals .. "f", value),
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    ZIndex = 502,
                    Parent = manualInputFrame,
                })

                local track = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 4),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = container,
                })
                makeCorner(track, 3)

                local fill = create("Frame", {
                    Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(200, 205, 215),
                    BorderSizePixel = 0,
                    Parent = track,
                })
                makeCorner(fill, 3)

                local function applyValue(val)
                    value = math.clamp(val, min, max)
                    local percent = (value - min) / (max - min)
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    valButton.Text = getFormattedValue(value)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                local dragging = false
                local function updateSlider(input)
                    local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local rawVal = min + (max - min) * percent
                    local rounded = math.floor(rawVal * (10 ^ decimals) + 0.5) / (10 ^ decimals)
                    applyValue(rounded)
                end

                valButton.MouseButton1Click:Connect(function()
                    manualInputFrame.Visible = true
                    manualTextBox.Text = string.format("%." .. decimals .. "f", value)
                    manualTextBox:CaptureFocus()
                end)

                manualTextBox.FocusLost:Connect(function()
                    manualInputFrame.Visible = false
                    local num = tonumber(manualTextBox.Text)
                    if num then
                        applyValue(num)
                    end
                end)

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateSlider(input)
                    end
                end)

                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                userInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)

                local sliderObj = {
                    set = applyValue,
                    get = function() return value end,
                }
                if flag then library.elements[flag] = sliderObj end
                return sliderObj
            end

            function section.createDropdown(self, config)
                config = config or {}
                local name = config.name or "Dropdown"
                local options = config.options or {}
                local isMulti = config.multi or false
                local showIcon = config.icon
                if showIcon == nil then showIcon = true end

                local selected = isMulti and (config.default or {}) or (config.default or options[1] or "")
                local flag = config.flag
                local callback = config.callback or function() end
                local open = false

                if flag then library.flags[flag] = selected end

                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    Parent = card,
                })

                create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = name,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local rightGroup = create("Frame", {
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    Parent = container,
                })

                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = rightGroup,
                })

                if showIcon then
                    create("ImageLabel", {
                        Size = UDim2.new(0, 18, 0, 16),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://120242544565484",
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ImageTransparency = 0,
                        Parent = rightGroup,
                    })
                end

                local dropHeader = create("TextButton", {
                    Size = UDim2.new(0, config.width or 135, 0, 24),
                    BackgroundColor3 = library.theme.inputBg,
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Parent = rightGroup,
                })
                makeCorner(dropHeader, 3)

                local function getDisplayText()
                    if isMulti then
                        local activeList = {}
                        for opt, val in selected do
                            if val then table.insert(activeList, opt) end
                        end
                        if #activeList == 0 then return "None" end
                        return table.concat(activeList, ", ")
                    else
                        return tostring(selected)
                    end
                end

                local selectedLabel = create("TextLabel", {
                    Size = UDim2.new(1, -22, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Text = getDisplayText(),
                    Font = library.theme.fontBold,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = dropHeader,
                })

                local arrow = create("ImageLabel", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://10709791523",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ImageTransparency = 0,
                    Rotation = 180,
                    Parent = dropHeader,
                })

                local listContainer = create("Frame", {
                    Size = UDim2.new(0, 115, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Active = true,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 100001,
                    Parent = globalOverlayFrame,
                })
                makeCorner(listContainer, 3)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 0),
                    Parent = listContainer,
                })
                create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), Parent = listContainer })

                local function updateDropdownPosition()
                    if open and dropHeader:IsDescendantOf(game) then
                        local relPos = getPositionInMain(dropHeader)
                        local absWidth = math.round(dropHeader.AbsoluteSize.X)
                        local absHeight = dropHeader.AbsoluteSize.Y
                        listContainer.Position = UDim2.new(0, math.round(relPos.X), 0, math.round(relPos.Y + absHeight - 4))
                        listContainer.Size = UDim2.new(0, absWidth, 0, math.min(#options * 22 + 6, 166))
                    end
                end

                local trackConn
                local function startTracking()
                    if trackConn then trackConn:Disconnect() end
                    trackConn = runService.RenderStepped:Connect(function()
                        if not open or not dropHeader:IsDescendantOf(game) or not isInsideView(dropHeader) then
                            if trackConn then trackConn:Disconnect() end
                            trackConn = nil
                            listContainer.Visible = false
                            arrow.Rotation = 180
                            return
                        end
                        updateDropdownPosition()
                    end)
                end

                local function populateOptions()
                    for _, child in listContainer:GetChildren() do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in options do
                        local isSel = (isMulti and selected[opt] == true) or (not isMulti and opt == selected)
                        local optTextColor = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)

                        local optBtn = create("TextButton", {
                            Size = UDim2.new(1, -12, 0, 22),
                            Position = UDim2.new(0, 6, 0, 0),
                            BackgroundColor3 = Color3.fromRGB(24, 25, 30),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Text = opt,
                            Font = library.theme.fontBold,
                            TextSize = 12,
                            TextColor3 = optTextColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 100002,
                            Parent = listContainer,
                        })

                        optBtn.MouseEnter:Connect(function()
                            if not isSel then
                                optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                        end)
                        optBtn.MouseLeave:Connect(function()
                            optBtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 135, 145)
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                selected[opt] = not selected[opt]
                                optBtn.TextColor3 = selected[opt] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 165)
                            else
                                selected = opt
                                open = false
                                if trackConn then trackConn:Disconnect() end
                                trackConn = nil
                                listContainer.Visible = false
                                arrow.Rotation = 180
                            end
                            selectedLabel.Text = getDisplayText()
                            if flag then library.flags[flag] = selected end
                            pcall(callback, selected)
                        end)
                    end
                end

                dropHeader.MouseButton1Click:Connect(function()
                    local wasOpen = open
                    closeGlobalOverlays()
                    open = not wasOpen
                    if open then
                        populateOptions()
                        updateDropdownPosition()
                        task.defer(updateDropdownPosition)
                        listContainer.Visible = true
                        arrow.Rotation = 0
                        startTracking()
                    else
                        if trackConn then trackConn:Disconnect() end
                        trackConn = nil
                        listContainer.Visible = false
                        arrow.Rotation = 180
                    end
                end)

                local dropObj = {
                    set = function(val)
                        selected = val
                        selectedLabel.Text = getDisplayText()
                        if flag then library.flags[flag] = selected end
                        pcall(callback, selected)
                    end,
                    get = function() return selected end,
                }
                if flag then library.elements[flag] = dropObj end
                return dropObj
            end

            function section.createConfigSystem(self, config)
                config = config or {}
                local folderFiles = library.getFolderConfigs()
                local configsList = config.list or folderFiles

                local hasDot = false
                for _, cfg in configsList do
                    if cfg.name == "." then
                        hasDot = true
                        cfg.icon = "knife"
                        break
                    end
                end
                if not hasDot then
                    table.insert(configsList, 1, {
                        name = ".",
                        icon = "knife",
                        modified = os.date("%Y/%m/%d %H:%M:%S")
                    })
                end

                local activeConfigName = config.active or (configsList[1] and configsList[1].name) or "."
                library.activeConfigName = activeConfigName
                local onSave = config.onSave or function() end
                local onLoad = config.onLoad or function() end
                local onDelete = config.onDelete or function() end
                local onCreate = config.onCreate or function() end
                local onRename = config.onRename or function() end

                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Parent = card,
                })

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = container,
                })

                local listFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = listFrame,
                })

                local function renderList()
                    for _, child in listFrame:GetChildren() do
                        if child:IsA("Frame") then child:Destroy() end
                    end

                    for idx, item in configsList do
                        if not item.modified or item.modified == "" then
                            item.modified = os.date("%Y/%m/%d %H:%M:%S")
                        end
                        local isActive = (item.name == activeConfigName)
                        local cardItem = create("Frame", {
                            Size = UDim2.new(1, 0, 0, 48),
                            BackgroundColor3 = Color3.fromRGB(22, 22, 26),
                            BorderSizePixel = 0,
                            Parent = listFrame,
                        })
                        makeCorner(cardItem, 4)

                        local iconAsset = (item.name == "." or item.icon == "brush") and "rbxassetid://15330618083" or "rbxassetid://10723425624"
                        create("ImageLabel", {
                            Size = UDim2.new(0, 16, 0, 16),
                            Position = UDim2.new(0, 12, 0, 10),
                            BackgroundTransparency = 1,
                            Image = iconAsset,
                            ImageColor3 = Color3.fromRGB(255, 255, 255),
                            Parent = cardItem,
                        })

                        local nameLabel = create("TextLabel", {
                            Size = UDim2.new(1, -175, 0, 18),
                            Position = UDim2.new(0, 36, 0, 8),
                            Text = item.name,
                            Font = library.theme.fontBold,
                            TextSize = 13,
                            TextColor3 = library.theme.textBright,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 1,
                            Parent = cardItem,
                        })

                        local nameEditBox = create("TextBox", {
                            Size = UDim2.new(1, -175, 0, 20),
                            Position = UDim2.new(0, 36, 0, 7),
                            BackgroundColor3 = Color3.fromRGB(16, 16, 18),
                            Text = item.name,
                            Font = library.theme.fontBold,
                            TextSize = 13,
                            TextColor3 = library.theme.textBright,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Visible = false,
                            BorderSizePixel = 0,
                            Parent = cardItem,
                        })
                        makeCorner(nameEditBox, 3)
                        create("UIPadding", { PaddingLeft = UDim.new(0, 4), Parent = nameEditBox })

                        local subFrame = create("Frame", {
                            Size = UDim2.new(1, -175, 0, 14),
                            Position = UDim2.new(0, 36, 0, 26),
                            BackgroundTransparency = 1,
                            Parent = cardItem,
                        })
                        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = subFrame })

                        create("TextLabel", {
                            AutomaticSize = Enum.AutomaticSize.X,
                            Size = UDim2.new(0, 0, 1, 0),
                            Text = "Modified:",
                            Font = library.theme.fontBold,
                            TextSize = 11,
                            TextColor3 = library.theme.textDim,
                            BackgroundTransparency = 1,
                            Parent = subFrame,
                        })

                        create("TextLabel", {
                            AutomaticSize = Enum.AutomaticSize.X,
                            Size = UDim2.new(0, 0, 1, 0),
                            Text = item.modified or "2026/01/01 00:00:00",
                            Font = library.theme.fontBold,
                            TextSize = 11,
                            TextColor3 = Color3.fromRGB(220, 40, 40),
                            BackgroundTransparency = 1,
                            Parent = subFrame,
                        })

                        local rightActions = create("Frame", {
                            Size = UDim2.new(0, 140, 1, 0),
                            Position = UDim2.new(1, -12, 0, 0),
                            AnchorPoint = Vector2.new(1, 0),
                            BackgroundTransparency = 1,
                            Parent = cardItem,
                        })

                        create("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Right,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 8),
                            Parent = rightActions,
                        })

                        local editIcon = create("ImageButton", {
                            Size = UDim2.new(0, 15, 0, 15),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://88134306391339",
                            ImageColor3 = Color3.fromRGB(220, 220, 220),
                            Parent = rightActions,
                        })

                        editIcon.MouseButton1Click:Connect(function()
                            nameLabel.Visible = false
                            nameEditBox.Visible = true
                            nameEditBox:CaptureFocus()
                        end)

                        nameEditBox.FocusLost:Connect(function(enterPressed)
                            nameLabel.Visible = true
                            nameEditBox.Visible = false
                            if nameEditBox.Text ~= "" and nameEditBox.Text ~= item.name then
                                local oldName = item.name
                                item.name = nameEditBox.Text
                                if activeConfigName == oldName then
                                    activeConfigName = item.name
                                end
                                nameLabel.Text = item.name
                                pcall(onRename, oldName, item.name)
                            else
                                nameEditBox.Text = item.name
                            end
                        end)

                        local deleteIcon = create("ImageButton", {
                            Size = UDim2.new(0, 15, 0, 15),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://14002617467",
                            ImageColor3 = Color3.fromRGB(220, 220, 220),
                            Parent = rightActions,
                        })

                        deleteIcon.MouseButton1Click:Connect(function()
                            local deletedName = item.name
                            library.deleteConfig(deletedName)
                            table.remove(configsList, idx)
                            if activeConfigName == deletedName then
                                activeConfigName = configsList[1] and configsList[1].name or ""
                            end
                            pcall(onDelete, deletedName)
                            renderList()
                        end)

                        local actionBtn = create("TextButton", {
                            Size = UDim2.new(0, 68, 0, 28),
                            BackgroundColor3 = Color3.fromRGB(38, 38, 46),
                            Text = "",
                            AutoButtonColor = false,
                            BorderSizePixel = 0,
                            Parent = rightActions,
                        })
                        makeCorner(actionBtn, 4)

                        create("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0, 5),
                            Parent = actionBtn,
                        })

                        create("ImageLabel", {
                            Size = UDim2.new(0, 14, 0, 14),
                            BackgroundTransparency = 1,
                            Image = isActive and "rbxassetid://109683101189277" or "rbxassetid://10709791437",
                            ImageColor3 = Color3.fromRGB(255, 255, 255),
                            Parent = actionBtn,
                        })

                        create("TextLabel", {
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = isActive and "Save" or "Load",
                            Font = library.theme.fontBold,
                            TextSize = 12,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            BackgroundTransparency = 1,
                            Parent = actionBtn,
                        })

                        actionBtn.MouseButton1Click:Connect(function()
                            if isActive then
                                local dateStr = os.date("%Y/%m/%d %H:%M:%S")
                                item.modified = dateStr
                                if config.autoSave ~= false then
                                    library.saveConfig(item.name)
                                end
                                pcall(onSave, item.name)
                                renderList()
                            else
                                activeConfigName = item.name
                                if config.autoLoad ~= false then
                                    library.loadConfig(item.name)
                                end
                                pcall(onLoad, item.name)
                                renderList()
                            end
                        end)
                    end
                end

                local function refreshFolderFiles()
                    local diskFiles = library.getFolderConfigs()
                    if #diskFiles > 0 then
                        local existingMap = {}
                        for _, c in configsList do
                            existingMap[c.name] = true
                        end
                        for _, diskItem in diskFiles do
                            if not existingMap[diskItem.name] then
                                table.insert(configsList, 1, diskItem)
                            end
                        end
                    end
                    renderList()
                end

                refreshFolderFiles()

                return {
                    refresh = refreshFolderFiles,
                    getConfigs = function() return configsList end,
                    getActive = function() return activeConfigName end,
                    setActive = function(name)
                        activeConfigName = name
                        renderList()
                    end,
                    createConfig = function(name)
                        if name and name ~= "" then
                            local dateStr = os.date("%Y/%m/%d %H:%M:%S")
                            table.insert(configsList, 1, { name = name, modified = dateStr })
                            activeConfigName = name
                            if config.autoSave ~= false then
                                library.saveConfig(name)
                            end
                            pcall(onCreate, name)
                            renderList()
                        end
                    end
                }
            end

            return section
        end

        function tab.createColumn(self, side)
            local targetCol = (side == "Right" or side == 2) and colRight or colLeft
            return {
                createSection = function(_, title)
                    return createSection(targetCol, title)
                end
            }
        end

        function tab.createSection(self, title)
            columnsFrame.Visible = false
            return createSection(fullScroll, title)
        end

        table.insert(window.tabs, tab)

        if #window.tabs == 1 then
            tab.activate()
        end

        return tab
    end

    return window
end

return library
