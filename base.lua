-- base.lua
-- Menu flutuante independente (sem Rayfield/Orion externo)
-- Interface compatível com scripts que esperam a API estilo "Painel:CreateWindow / Window:CreateTab / Tab:CreateToggle etc."

local Library = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- util: tentativa segura de salvar arquivo (exploit functions)
local function safe_writefile(path, content)
    if type(writefile) == "function" then
        pcall(writefile, path, content)
        return true
    end
    if type(syn_write_file) == "function" then
        pcall(syn_write_file, path, content)
        return true
    end
    return false
end

local function safe_readfile(path)
    if type(readfile) == "function" then
        local ok, c = pcall(readfile, path)
        if ok then return c end
    end
    if type(syn_read_file) == "function" then
        local ok, c = pcall(syn_read_file, path)
        if ok then return c end
    end
    return nil
end

-- Cria ScreenGui (único)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeuPainel"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Estilos básicos reutilizáveis
local function make_rounded(instance, radius)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, radius or 6)
    u.Parent = instance
    return u
end

-- Notification simple
local function create_notify(title, content, duration)
    duration = duration or 4
    local notifyFrame = Instance.new("Frame")
    notifyFrame.Size = UDim2.new(0, 300, 0, 70)
    notifyFrame.Position = UDim2.new(1, -310, 0, 10)
    notifyFrame.AnchorPoint = Vector2.new(0, 0)
    notifyFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    notifyFrame.BorderSizePixel = 0
    notifyFrame.Parent = ScreenGui
    make_rounded(notifyFrame, 6)

    local titleLbl = Instance.new("TextLabel", notifyFrame)
    titleLbl.Size = UDim2.new(1, -20, 0, 28)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or "Notificação"
    titleLbl.TextColor3 = Color3.new(1,1,1)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local contentLbl = Instance.new("TextLabel", notifyFrame)
    contentLbl.Size = UDim2.new(1, -20, 0, 30)
    contentLbl.Position = UDim2.new(0, 10, 0, 30)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content or ""
    contentLbl.TextColor3 = Color3.new(1,1,1)
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 14
    contentLbl.TextWrapped = true
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextYAlignment = Enum.TextYAlignment.Top

    notifyFrame.AnchorPoint = Vector2.new(0,0)
    notifyFrame.Position = UDim2.new(1, -310, 0, 10)

    notifyFrame.Visible = true
    notifyFrame.BackgroundTransparency = 1
    TweenService:Create(notifyFrame, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    spawn(function()
        wait(duration)
        local ok = pcall(function() TweenService:Create(notifyFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end)
        wait(0.3)
        pcall(function() notifyFrame:Destroy() end)
    end)
end

-- Função principal: CreateWindow
function Library:CreateWindow(settings)
    settings = settings or {}
    local Window = {}

    -- Attempt config load path
    local configFolder = (settings.ConfigurationSaving and settings.ConfigurationSaving.FolderName) and settings.ConfigurationSaving.FolderName or "MeuPainelConfig"
    local configFile = (settings.ConfigurationSaving and settings.ConfigurationSaving.FileName) and settings.ConfigurationSaving.FileName .. ".json" or "config.json"
    local configPath = configFolder .. "/" .. configFile

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 540, 0, 360)
    Frame.Position = UDim2.new(0.5, -270, 0.5, -180)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    Frame.Active = true
    Frame.SelectionImageObject = nil
    Frame.ZIndex = 2
    make_rounded(Frame, 8)
    Frame.Draggable = true

    -- Title Bar
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TitleBar.BorderSizePixel = 0
    make_rounded(TitleBar, 8)

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = settings.Name or "Painel"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Loading subtitle (optional)
    local Subtitle = Instance.new("TextLabel", TitleBar)
    Subtitle.Size = UDim2.new(0, 100, 1, 0)
    Subtitle.Position = UDim2.new(1, -110, 0, 0)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = settings.LoadingSubtitle or ""
    Subtitle.TextColor3 = Color3.fromRGB(200,200,200)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 12
    Subtitle.TextXAlignment = Enum.TextXAlignment.Right

    -- Container for tabs and content
    local TabContainer = Instance.new("Frame", Frame)
    TabContainer.Size = UDim2.new(0, 140, 1, -40)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabContainer.BorderSizePixel = 0
    make_rounded(TabContainer, 6)

    local ContentContainer = Instance.new("Frame", Frame)
    ContentContainer.Size = UDim2.new(1, -150, 1, -50)
    ContentContainer.Position = UDim2.new(0, 150, 0, 40)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ContentContainer.BorderSizePixel = 0
    make_rounded(ContentContainer, 6)

    -- inside content frame: UIListLayout for automatic stacking
    local Tabs = {}
    local TabButtons = {}

    local TabButtonLayout = Instance.new("UIListLayout", TabContainer)
    TabButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabButtonLayout.Padding = UDim.new(0, 6)

    -- config store
    local config = {}
    local function load_config()
        if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
            local ok, content = pcall(safe_readfile, configPath)
            if ok and content then
                local suc, tbl = pcall(function() return HttpService:JSONDecode(content) end)
                if suc and type(tbl) == "table" then
                    config = tbl
                end
            end
        end
    end

    local function save_config()
        if settings.ConfigurationSaving and settings.ConfigurationSaving.Enabled then
            local ok, encoded = pcall(function() return HttpService:JSONEncode(config) end)
            if ok and encoded then
                pcall(function()
                    -- ensure folder exists (some environments)
                    if type(makefolder) == "function" then
                        pcall(makefolder, configFolder)
                    end
                    safe_writefile(configPath, encoded)
                end)
            end
        end
    end

    -- load on open
    load_config()

    -- Notify method
    function Window:Notify(opts)
        opts = opts or {}
        create_notify(opts.Title or "Notification", opts.Content or "", opts.Duration)
    end

    -- CreateTab: returns tab object with CreateToggle, CreateSlider, CreateColorPicker, CreateButton
    function Window:CreateTab(name, icon)
        local Tab = {}

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -12, 0, 36)
        Button.Position = UDim2.new(0, 6, 0, (#TabButtons) * 44 + 6)
        Button.BackgroundColor3 = Color3.fromRGB(45,45,45)
        Button.TextColor3 = Color3.new(1,1,1)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.Text = name or "Tab"
        Button.Parent = TabContainer
        Button.ZIndex = 3
        make_rounded(Button, 6)
        table.insert(TabButtons, Button)

        local TabFrame = Instance.new("ScrollingFrame")
        TabFrame.Size = UDim2.new(1, -20, 1, -20)
        TabFrame.Position = UDim2.new(0, 10, 0, 10)
        TabFrame.BackgroundTransparency = 1
        TabFrame.ScrollBarThickness = 6
        TabFrame.CanvasSize = UDim2.new(0,0,0,0)
        TabFrame.Parent = ContentContainer
        TabFrame.Visible = false
        TabFrame.ZIndex = 2

        local layout = Instance.new("UIListLayout", TabFrame)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)

        -- update canvas size automatically
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)

        -- button click toggles tab
        Button.MouseButton1Click:Connect(function()
            for _, tb in pairs(TabContainer:GetChildren()) do
                if tb:IsA("TextButton") then
                    tb.BackgroundColor3 = Color3.fromRGB(45,45,45)
                end
            end
            for _, fr in pairs(ContentContainer:GetChildren()) do
                if fr:IsA("ScrollingFrame") then
                    fr.Visible = false
                end
            end
            Button.BackgroundColor3 = Color3.fromRGB(60,60,60)
            TabFrame.Visible = true
        end)

        -- helper to create labeled container
        local function create_item_frame()
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -20, 0, 36)
            item.BackgroundTransparency = 1
            item.Parent = TabFrame
            return item
        end

        -- Toggle: expects opts table { Name, CurrentValue, Callback }
        function Tab:CreateToggle(opts)
            opts = type(opts) == "table" and opts or { Name = tostring(opts) }
            local name = opts.Name or "Toggle"
            local state = opts.CurrentValue and true or false
            local callback = opts.Callback

            local item = create_item_frame()

            local label = Instance.new("TextLabel", item)
            label.Size = UDim2.new(0.65, 0, 1, 0)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Color3.new(1,1,1)
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left

            local btn = Instance.new("TextButton", item)
            btn.Size = UDim2.new(0, 100, 0, 28)
            btn.Position = UDim2.new(1, -110, 0, 4)
            btn.BackgroundColor3 = (state and Color3.fromRGB(36, 152, 126) or Color3.fromRGB(80,80,80))
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.Text = (state and "[ ON ] " or "[ OFF ] ") .. name
            btn.Parent = item
            make_rounded(btn, 6)

            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.BackgroundColor3 = (state and Color3.fromRGB(36, 152, 126) or Color3.fromRGB(80,80,80))
                btn.Text = (state and "[ ON ] " or "[ OFF ] ") .. name
                if callback then
                    pcall(callback, state)
                end
                -- store config
                config[name] = state
                save_config()
            end)

            -- apply initial state
            if callback then
                pcall(callback, state)
            end

            return {
                Set = function(val)
                    state = val and true or false
                    btn.BackgroundColor3 = (state and Color3.fromRGB(36, 152, 126) or Color3.fromRGB(80,80,80))
                    btn.Text = (state and "[ ON ] " or "[ OFF ] ") .. name
                    if callback then pcall(callback, state) end
                end,
                Get = function() return state end
            }
        end

        -- Button: expects opts table { Name, Callback }
        function Tab:CreateButton(opts)
            opts = type(opts) == "table" and opts or { Name = tostring(opts) }
            local name = opts.Name or "Button"
            local callback = opts.Callback

            local item = create_item_frame()
            local btn = Instance.new("TextButton", item)
            btn.Size = UDim2.new(0, 200, 0, 30)
            btn.Position = UDim2.new(0, 6, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.Text = name
            make_rounded(btn, 6)

            btn.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
            end)

            return {
                Click = function() pcall(callback) end
            }
        end

        -- Slider: expects opts table { Name, Range = {min,max}, Increment, CurrentValue, Callback }
        function Tab:CreateSlider(opts)
            opts = type(opts) == "table" and opts or {}
            local name = opts.Name or "Slider"
            local min = (opts.Range and opts.Range[1]) or 0
            local max = (opts.Range and opts.Range[2]) or 100
            local inc = opts.Increment or 1
            local value = opts.CurrentValue or min
            local callback = opts.Callback

            local item = create_item_frame()

            local label = Instance.new("TextLabel", item)
            label.Size = UDim2.new(0.6, 0, 0, 18)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = string.format("%s: %d", name, value)
            label.TextColor3 = Color3.new(1,1,1)
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left

            local sliderBg = Instance.new("Frame", item)
            sliderBg.Size = UDim2.new(0.85, 0, 0, 10)
            sliderBg.Position = UDim2.new(0, 6, 0, 20)
            sliderBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
            sliderBg.BorderSizePixel = 0
            make_rounded(sliderBg, 6)

            local sliderFill = Instance.new("Frame", sliderBg)
            sliderFill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(36,152,126)
            sliderFill.BorderSizePixel = 0
            make_rounded(sliderFill, 6)

            local function set_value_from_x(px)
                local rel = math.clamp((px - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                local raw = min + (max - min) * rel
                -- round to increment
                local rounded = math.floor((raw / inc) + 0.5) * inc
                if rounded < min then rounded = min end
                if rounded > max then rounded = max end
                value = rounded
                sliderFill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
                label.Text = string.format("%s: %d", name, value)
                if callback then pcall(callback, value) end
                config[name] = value
                save_config()
            end

            -- input handling
            local dragging
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    set_value_from_x(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    set_value_from_x(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            -- initial callback
            if callback then pcall(callback, value) end

            return {
                Set = function(v)
                    value = math.clamp(v, min, max)
                    sliderFill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
                    label.Text = string.format("%s: %d", name, value)
                    if callback then pcall(callback, value) end
                    config[name] = value
                    save_config()
                end,
                Get = function() return value end
            }
        end

        -- ColorPicker: expects opts table { Name, Color = Color3, Callback }
        function Tab:CreateColorPicker(opts)
            opts = type(opts) == "table" and opts or {}
            local name = opts.Name or "Color"
            local color = opts.Color or Color3.new(1,1,1)
            local callback = opts.Callback

            local item = create_item_frame()

            local label = Instance.new("TextLabel", item)
            label.Size = UDim2.new(0.65, 0, 1, 0)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Color3.new(1,1,1)
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left

            local colorBtn = Instance.new("TextButton", item)
            colorBtn.Size = UDim2.new(0, 80, 0, 28)
            colorBtn.Position = UDim2.new(1, -90, 0, 4)
            colorBtn.BackgroundColor3 = color
            colorBtn.Text = ""
            colorBtn.BorderSizePixel = 0
            make_rounded(colorBtn, 6)

            -- pop-up with three sliders (R G B)
            local picker = Instance.new("Frame")
            picker.Size = UDim2.new(0, 240, 0, 150)
            picker.Position = UDim2.new(0.5, -120, 0.5, -75)
            picker.BackgroundColor3 = Color3.fromRGB(30,30,30)
            picker.BorderSizePixel = 0
            picker.Parent = ScreenGui
            make_rounded(picker, 8)
            picker.Visible = false
            picker.ZIndex = 50

            local pickTitle = Instance.new("TextLabel", picker)
            pickTitle.Size = UDim2.new(1, -16, 0, 24)
            pickTitle.Position = UDim2.new(0, 8, 0, 8)
            pickTitle.BackgroundTransparency = 1
            pickTitle.Text = "Escolher cor - " .. name
            pickTitle.TextColor3 = Color3.new(1,1,1)
            pickTitle.Font = Enum.Font.GothamBold
            pickTitle.TextSize = 14
            pickTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- sliders for R G B
            local function make_color_slider(y, labelTxt, initial)
                local lbl = Instance.new("TextLabel", picker)
                lbl.Size = UDim2.new(0.5, -12, 0, 18)
                lbl.Position = UDim2.new(0, 8, 0, y)
                lbl.BackgroundTransparency = 1
                lbl.Text = labelTxt .. ": " .. math.floor(initial * 255)
                lbl.TextColor3 = Color3.new(1,1,1)
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 13
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local bg = Instance.new("Frame", picker)
                bg.Size = UDim2.new(0.95, 0, 0, 10)
                bg.Position = UDim2.new(0, 8, 0, y + 20)
                bg.BackgroundColor3 = Color3.fromRGB(60,60,60)
                bg.BorderSizePixel = 0
                make_rounded(bg, 6)

                local fill = Instance.new("Frame", bg)
                fill.Size = UDim2.new(initial, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(200,200,200)
                fill.BorderSizePixel = 0
                make_rounded(fill, 6)

                return {
                    Label = lbl,
                    Bg = bg,
                    Fill = fill
                }
            end

            local r, g, b = color.R, color.G, color.B
            local rS = make_color_slider(36, "R", r)
            local gS = make_color_slider(76, "G", g)
            local bS = make_color_slider(116, "B", b)

            local function update_picker_visuals()
                rS.Fill.Size = UDim2.new(r, 0, 1, 0)
                rS.Label.Text = "R: " .. math.floor(r * 255)
                gS.Fill.Size = UDim2.new(g, 0, 1, 0)
                gS.Label.Text = "G: " .. math.floor(g * 255)
                bS.Fill.Size = UDim2.new(b, 0, 1, 0)
                bS.Label.Text = "B: " .. math.floor(b * 255)
                colorBtn.BackgroundColor3 = Color3.new(r,g,b)
            end

            -- input handling
            local function slider_input(slider, setter)
                local dragging
                slider.Bg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local rel = math.clamp((input.Position.X - slider.Bg.AbsolutePosition.X) / slider.Bg.AbsoluteSize.X, 0, 1)
                        setter(rel)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((input.Position.X - slider.Bg.AbsolutePosition.X) / slider.Bg.AbsoluteSize.X, 0, 1)
                        setter(rel)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
            end

            slider_input(rS, function(v) r = v; update_picker_visuals(); if callback then pcall(callback, Color3.new(r,g,b)) end end)
            slider_input(gS, function(v) g = v; update_picker_visuals(); if callback then pcall(callback, Color3.new(r,g,b)) end end)
            slider_input(bS, function(v) b = v; update_picker_visuals(); if callback then pcall(callback, Color3.new(r,g,b)) end end)

            -- close button
            local closeBtn = Instance.new("TextButton", picker)
            closeBtn.Size = UDim2.new(0, 60, 0, 26)
            closeBtn.Position = UDim2.new(1, -70, 1, -36)
            closeBtn.Text = "Fechar"
            closeBtn.Font = Enum.Font.Gotham
            closeBtn.TextSize = 13
            closeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
            closeBtn.TextColor3 = Color3.new(1,1,1)
            make_rounded(closeBtn, 6)
            closeBtn.MouseButton1Click:Connect(function()
                picker.Visible = false
            end)

            colorBtn.MouseButton1Click:Connect(function()
                picker.Visible = not picker.Visible
            end)

            -- initial visuals & initial callback
            update_picker_visuals()
            if callback then pcall(callback, Color3.new(r,g,b)) end
            config[name] = {r = r, g = g, b = b}
            save_config()

            return {
                Set = function(c3)
                    if typeof(c3) == "Color3" then
                        r,g,b = c3.R, c3.G, c3.B
                        update_picker_visuals()
                        if callback then pcall(callback, Color3.new(r,g,b)) end
                        config[name] = {r = r, g = g, b = b}
                        save_config()
                    end
                end,
                Get = function()
                    return Color3.new(r,g,b)
                end
            }
        end

        -- return Tab object
        Tabs[name] = TabFrame
        return Tab
    end

    -- expose some methods on Window
    function Window:SaveConfig()
        save_config()
    end

    function Window:LoadConfig()
        load_config()
    end

    function Window:Destroy()
        pcall(function() Frame:Destroy() end)
    end

    -- return Window
    return Window
end

return Library