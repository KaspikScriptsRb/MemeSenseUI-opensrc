local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")

local library = {
    flags = {},
    theme = {
        mainBg = Color3.fromRGB(16, 16, 18),
        sidebarBg = Color3.fromRGB(20, 20, 22),
        headerBg = Color3.fromRGB(16, 16, 18),
        columnBg = Color3.fromRGB(16, 16, 18),
        
        accent = Color3.fromRGB(235, 42, 60),
        accentDark = Color3.fromRGB(175, 28, 42),
        
        textBright = Color3.fromRGB(245, 245, 250),
        textDim = Color3.fromRGB(175, 175, 182),
        textMuted = Color3.fromRGB(115, 115, 122),
        
        inputBg = Color3.fromRGB(26, 26, 30),
        inputBorder = Color3.fromRGB(40, 40, 46),
        
        fontBold = Enum.Font.Roboto,
        fontMedium = Enum.Font.Roboto,
        fontRegular = Enum.Font.Roboto,
    }
}

if typeof(getgenv) == "function" and getgenv().memeSenseUI then
    pcall(function()
        getgenv().memeSenseUI:Destroy()
    end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MemeSenseGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local guiParent = coreGui
if typeof(gethui) == "function" then
    guiParent = gethui()
elseif typeof(syn) == "table" and syn.protect_gui then
    syn.protect_gui(screenGui)
end
screenGui.Parent = guiParent

if typeof(getgenv) == "function" then
    getgenv().memeSenseUI = screenGui
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

    local window = {
        visible = true,
        tabs = {},
        activeTab = nil,
        dragging = false,
        dragStart = nil,
        startPos = nil,
        fading = false,
    }

    local main = create("CanvasGroup", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = library.theme.mainBg,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    makeStroke(main, Color3.fromRGB(30, 30, 34), 1)

    local topBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = main,
    })

    local gradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(235, 50, 50)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(235, 150, 50)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(235, 235, 50)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(50, 235, 100)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(50, 150, 235)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(180, 50, 235)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(235, 50, 50)),
        }),
        Offset = Vector2.new(-1, 0),
        Parent = topBar,
    })

    local gradientOffset = -1
    runService.RenderStepped:Connect(function(dt)
        gradientOffset += dt * 0.35
        if gradientOffset >= 1 then
            gradientOffset = -1
        end
        gradient.Offset = Vector2.new(gradientOffset, 0)
    end)

    local sidebar = create("Frame", {
        Size = UDim2.new(0, 150, 1, -2),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = library.theme.sidebarBg,
        BorderSizePixel = 0,
        Parent = main,
    })

    local logoFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    local memeLabel = create("TextLabel", {
        Position = UDim2.new(0, 16, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Text = "Meme",
        Font = library.theme.fontBold,
        TextSize = 19,
        TextColor3 = library.theme.accent,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = logoFrame,
    })

    local senseLabel = create("TextLabel", {
        Position = UDim2.new(0, 16 + memeLabel.AbsoluteSize.X, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Text = "Sense",
        Font = library.theme.fontBold,
        TextSize = 19,
        TextColor3 = library.theme.textBright,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = logoFrame,
    })

    memeLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        senseLabel.Position = UDim2.new(0, 16 + memeLabel.AbsoluteSize.X, 0.5, 0)
    end)

    local tabScroll = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    })

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
        Parent = tabScroll,
    })

    local headerBar = create("Frame", {
        Size = UDim2.new(1, -150, 0, 42),
        Position = UDim2.new(0, 150, 0, 2),
        BackgroundColor3 = library.theme.headerBg,
        BorderSizePixel = 0,
        Parent = main,
    })

    local headerLeft = create("Frame", {
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Parent = headerBar,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = headerLeft,
    })

    local headerRight = create("Frame", {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(1, -16, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = headerBar,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = headerRight,
    })

    local contentArea = create("Frame", {
        Size = UDim2.new(1, -150, 1, -44),
        Position = UDim2.new(0, 150, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })

    logoFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = true
            window.dragStart = input.Position
            window.startPos = main.Position
        end
    end)

    logoFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end)

    userInputService.InputChanged:Connect(function(input)
        if window.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - window.dragStart
            main.Position = UDim2.new(
                window.startPos.X.Scale,
                window.startPos.X.Offset + delta.X,
                window.startPos.Y.Scale,
                window.startPos.Y.Offset + delta.Y
            )
        end
    end)

    function window.toggle()
        if window.fading then return end
        window.fading = true
        window.visible = not window.visible

        if window.visible then
            main.Visible = true
            local t = tweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
            t:Play()
            t.Completed:Connect(function() window.fading = false end)
        else
            local t = tweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
            t:Play()
            t.Completed:Connect(function() main.Visible = false window.fading = false end)
        end
    end

    userInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            window.toggle()
        end
    end)

    function window.createHeaderToggle(config)
        config = config or {}
        local name = config.name or "Master switch"
        local state = config.default or false
        local callback = config.callback or function() end

        local container = create("TextButton", {
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = "",
            Parent = headerLeft,
        })

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = container,
        })

        local box = create("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = state and library.theme.accent or library.theme.inputBg,
            BorderSizePixel = 0,
            Parent = container,
        })
        makeStroke(box, state and library.theme.accent or library.theme.inputBorder)

        local checkmark = create("ImageLabel", {
            Size = UDim2.new(0, 10, 0, 10),
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
            Font = library.theme.fontMedium,
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

    function window.createHeaderButton(config)
        config = config or {}
        local name = config.name or "Save"
        local icon = config.icon or "rbxassetid://109683101189277"
        local callback = config.callback or function() end

        local btn = create("TextButton", {
            Size = UDim2.new(0, 0, 0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(34, 34, 40),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = headerRight,
        })
        makeCorner(btn, 4)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = btn,
        })

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = btn,
        })

        if icon ~= "" then
            create("ImageLabel", {
                Size = UDim2.new(0, 13, 0, 13),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Color3.fromRGB(230, 230, 235),
                Parent = btn,
            })
        end

        create("TextLabel", {
            Text = name,
            Font = library.theme.fontBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(230, 230, 235),
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
            Size = UDim2.new(1, 0, 0, 30),
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
            Padding = UDim.new(0, 8),
            Parent = layoutFrame,
        })

        local tabIcon = create("ImageLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = library.theme.textDim,
            Parent = layoutFrame,
        })

        local tabLabel = create("TextLabel", {
            Text = name,
            Font = library.theme.fontMedium,
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
            Parent = contentArea,
        })

        local subtabHeaderBar = create("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, 4),
            BackgroundTransparency = 1,
            Parent = view,
        })

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 24),
            Parent = subtabHeaderBar,
        })

        local columnsFrame = create("Frame", {
            Size = UDim2.new(1, 0, 1, -28),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundTransparency = 1,
            Parent = view,
        })

        create("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            Parent = columnsFrame,
        })

        local colLeft = create("ScrollingFrame", {
            Size = UDim2.new(0.5, -10, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = columnsFrame,
        })

        local colRight = create("ScrollingFrame", {
            Size = UDim2.new(0.5, -10, 1, 0),
            Position = UDim2.new(0.5, 10, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
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

        function tab.activate()
            for _, t in window.tabs do
                t.deactivate()
            end
            window.activeTab = tab
            view.Visible = true
            activeBar.BackgroundTransparency = 0
            tabIcon.ImageColor3 = library.theme.accent
            tabLabel.TextColor3 = library.theme.textBright
            btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            btn.BackgroundTransparency = 0
        end

        function tab.deactivate()
            view.Visible = false
            activeBar.BackgroundTransparency = 1
            tabIcon.ImageColor3 = library.theme.textDim
            tabLabel.TextColor3 = library.theme.textDim
            btn.BackgroundTransparency = 1
        end

        btn.MouseButton1Click:Connect(function()
            tab.activate()
        end)

        -- Section SubTabs Switcher Creator (Aim, Accuracy, RCS, Misc)
        function tab.createSubTabSwitcher(self, options, callback)
            options = options or {}
            callback = callback or function() end
            local buttons = {}
            local active = options[1] or ""

            for i, opt in options do
                local subBtn = create("TextButton", {
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = library.theme.fontBold,
                    TextSize = 13,
                    TextColor3 = (opt == active) and library.theme.textBright or library.theme.textMuted,
                    Parent = subtabHeaderBar,
                })

                subBtn.MouseButton1Click:Connect(function()
                    active = opt
                    for name, b in buttons do
                        b.TextColor3 = (name == active) and library.theme.textBright or library.theme.textMuted
                    end
                    pcall(callback, active)
                end)

                buttons[opt] = subBtn
            end

            return {
                set = function(val)
                    active = val
                    for name, b in buttons do
                        b.TextColor3 = (name == active) and library.theme.textBright or library.theme.textMuted
                    end
                    pcall(callback, active)
                end
            }
        end

        local function createSection(parentCol, title)
            local card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
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
                    TextColor3 = library.theme.textDim,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 18),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BackgroundTransparency = 1,
                    Parent = card,
                })
            end

            local section = {}

            -- Internal Section SubTabs Switcher
            function section.createSubTabs(self, config)
                config = config or {}
                local opts = config.options or {}
                local callback = config.callback or function() end
                local active = config.default or opts[1] or ""

                local bar = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = card,
                })

                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 16),
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
                    Parent = card,
                })

                local toggleBtn = create("TextButton", {
                    Size = UDim2.new(1, -30, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = row,
                })

                local box = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = state and library.theme.accent or library.theme.inputBg,
                    BorderSizePixel = 0,
                    Parent = toggleBtn,
                })
                makeStroke(box, state and library.theme.accent or library.theme.inputBorder)

                local checkmark = create("ImageLabel", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://14189590169",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ImageTransparency = state and 0 or 1,
                    Parent = box,
                })

                local label = create("TextLabel", {
                    Position = UDim2.new(0, 20, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Text = name,
                    Font = library.theme.fontMedium,
                    TextSize = 13,
                    TextColor3 = state and library.theme.textBright or library.theme.textMuted,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = toggleBtn,
                })

                local rightControls = create("Frame", {
                    Size = UDim2.new(0, 60, 1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
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
                    label.TextColor3 = state and library.theme.textBright or library.theme.textMuted
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

                function toggleObj.addKeybind(self, kConfig)
                    kConfig = kConfig or {}
                    local currentKey = kConfig.default or Enum.KeyCode.Unknown
                    local keyMode = kConfig.mode or "On key down"
                    local keyCallback = kConfig.callback or function() end
                    local binding = false

                    local iconBtn = create("ImageButton", {
                        Size = UDim2.new(0, 16, 0, 14),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://121332782788896",
                        ImageColor3 = (currentKey ~= Enum.KeyCode.Unknown) and library.theme.accent or library.theme.textDim,
                        BorderSizePixel = 0,
                        Parent = rightControls,
                    })

                    local popup = create("Frame", {
                        Size = UDim2.new(0, 140, 0, 75),
                        Position = UDim2.new(1, 5, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(30, 32, 38),
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 25,
                        Parent = iconBtn,
                    })
                    makeStroke(popup, library.theme.inputBorder)
                    create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = popup })

                    create("TextLabel", {
                        Size = UDim2.new(0.4, 0, 0, 16),
                        Text = "Type",
                        Font = library.theme.fontMedium,
                        TextSize = 12,
                        TextColor3 = library.theme.textBright,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        ZIndex = 26,
                        Parent = popup,
                    })

                    local modeDropBtn = create("TextButton", {
                        Size = UDim2.new(0.55, 0, 0, 18),
                        Position = UDim2.new(1, 0, 0, 0),
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = Color3.fromRGB(42, 46, 56),
                        Text = keyMode,
                        Font = library.theme.fontMedium,
                        TextSize = 11,
                        TextColor3 = library.theme.textBright,
                        ZIndex = 26,
                        Parent = popup,
                    })
                    makeStroke(modeDropBtn, library.theme.inputBorder)

                    local keyBox = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 22),
                        Position = UDim2.new(0, 0, 0, 28),
                        BackgroundColor3 = Color3.fromRGB(20, 22, 26),
                        Text = "[" .. (currentKey == Enum.KeyCode.Unknown and "none" or currentKey.Name:lower()) .. "]",
                        Font = library.theme.fontMedium,
                        TextSize = 12,
                        TextColor3 = library.theme.textBright,
                        ZIndex = 26,
                        Parent = popup,
                    })
                    makeStroke(keyBox, library.theme.inputBorder)

                    iconBtn.MouseButton1Click:Connect(function()
                        popup.Visible = not popup.Visible
                    end)

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
                                iconBtn.ImageColor3 = (currentKey ~= Enum.KeyCode.Unknown) and library.theme.accent or library.theme.textDim
                                pcall(keyCallback, currentKey)
                            end
                        elseif not gpe and input.KeyCode == currentKey and currentKey ~= Enum.KeyCode.Unknown then
                            toggleObj.set(not state)
                        end
                    end)

                    return toggleObj
                end

                return toggleObj
            end

            function section.createSlider(self, config)
                config = config or {}
                local name = config.name or "Slider"
                local min = config.min or 0
                local max = config.max or 100
                local default = config.default or min
                local decimals = config.decimals or 0
                local suffix = config.suffix or ""
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
                    Font = library.theme.fontMedium,
                    TextSize = 13,
                    TextColor3 = library.theme.textMuted,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local valLabel = create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 0, 14),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Text = string.format("%." .. decimals .. "f", value) .. suffix,
                    Font = library.theme.fontMedium,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local track = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 3),
                    Position = UDim2.new(0, 0, 0, 17),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 34),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = container,
                })

                local fill = create("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = library.theme.accent,
                    BorderSizePixel = 0,
                    Parent = track,
                })

                local dragging = false
                local function updateSlider(input)
                    local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local rawVal = min + (max - min) * percent
                    value = math.floor(rawVal * (10 ^ decimals) + 0.5) / (10 ^ decimals)
                    if flag then library.flags[flag] = value end
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    valLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
                    pcall(callback, value)
                end

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

                return {
                    set = function(val)
                        value = math.clamp(val, min, max)
                        local percent = (value - min) / (max - min)
                        fill.Size = UDim2.new(percent, 0, 1, 0)
                        valLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
                        if flag then library.flags[flag] = value end
                        pcall(callback, value)
                    end,
                    get = function() return value end,
                }
            end

            function section.createDropdown(self, config)
                config = config or {}
                local name = config.name or "Dropdown"
                local options = config.options or {}
                local selected = config.default or options[1] or ""
                local flag = config.flag
                local callback = config.callback or function() end
                local open = false

                if flag then library.flags[flag] = selected end

                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent = card,
                })

                local label = create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = name,
                    Font = library.theme.fontMedium,
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
                    Parent = container,
                })

                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = rightGroup,
                })

                create("ImageLabel", {
                    Size = UDim2.new(0, 14, 0, 12),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://120242544565484",
                    ImageColor3 = library.theme.textDim,
                    Parent = rightGroup,
                })

                local dropHeader = create("TextButton", {
                    Size = UDim2.new(0, 115, 0, 20),
                    BackgroundColor3 = library.theme.inputBg,
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Parent = rightGroup,
                })
                makeStroke(dropHeader, library.theme.inputBorder)

                local selectedLabel = create("TextLabel", {
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Text = tostring(selected),
                    Font = library.theme.fontMedium,
                    TextSize = 12,
                    TextColor3 = library.theme.textBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = dropHeader,
                })

                local arrow = create("ImageLabel", {
                    Size = UDim2.new(0, 9, 0, 9),
                    Position = UDim2.new(1, -5, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://10709791523",
                    ImageColor3 = library.theme.textDim,
                    Parent = dropHeader,
                })

                local listContainer = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3 = library.theme.inputBg,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 15,
                    Parent = dropHeader,
                })
                makeStroke(listContainer, library.theme.inputBorder)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1),
                    Parent = listContainer,
                })

                create("UIPadding", {
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    Parent = listContainer,
                })

                local function populateOptions()
                    for _, child in listContainer:GetChildren() do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in options do
                        local isSelected = opt == selected
                        local optBtn = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 18),
                            BackgroundColor3 = isSelected and Color3.fromRGB(34, 34, 40) or library.theme.inputBg,
                            BackgroundTransparency = isSelected and 0 or 1,
                            Text = opt,
                            Font = library.theme.fontMedium,
                            TextSize = 12,
                            TextColor3 = isSelected and library.theme.accent or library.theme.textBright,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 16,
                            Parent = listContainer,
                        })
                        create("UIPadding", {
                            PaddingLeft = UDim.new(0, 5),
                            PaddingRight = UDim.new(0, 5),
                            Parent = optBtn,
                        })

                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            selectedLabel.Text = opt
                            if flag then library.flags[flag] = selected end
                            open = false
                            listContainer.Visible = false
                            arrow.Rotation = 0
                            pcall(callback, selected)
                        end)
                    end
                    listContainer.Size = UDim2.new(1, 0, 0, math.min(#options * 19 + 4, 120))
                end

                dropHeader.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        populateOptions()
                        listContainer.Visible = true
                        arrow.Rotation = 180
                    else
                        listContainer.Visible = false
                        arrow.Rotation = 0
                    end
                end)

                return {
                    set = function(val)
                        selected = val
                        selectedLabel.Text = tostring(val)
                        if flag then library.flags[flag] = selected end
                        pcall(callback, selected)
                    end,
                    get = function() return selected end,
                }
            end

            function section.createButton(self, config)
                config = config or {}
                local name = config.name or "Button"
                local callback = config.callback or function() end

                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = library.theme.inputBg,
                    Text = name,
                    Font = library.theme.fontMedium,
                    TextSize = 13,
                    TextColor3 = library.theme.textBright,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Parent = card,
                })
                makeStroke(btn, library.theme.inputBorder)

                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
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
            return createSection(colLeft, title)
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
