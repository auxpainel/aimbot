local Painel = {}

-- Serviços
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variáveis principais
local gui = nil
local themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 30),
        LightBackground = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        Button = Color3.fromRGB(60, 60, 60),
        ButtonHover = Color3.fromRGB(70, 70, 70),
        Accent = Color3.fromRGB(0, 120, 215),
        Stroke = Color3.fromRGB(60, 60, 60)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        LightBackground = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(0, 0, 0),
        Button = Color3.fromRGB(200, 200, 200),
        ButtonHover = Color3.fromRGB(190, 190, 190),
        Accent = Color3.fromRGB(0, 90, 180),
        Stroke = Color3.fromRGB(180, 180, 180)
    }
}
local currentTheme = "Dark"
local windows = {}
local notifications = {}

-- Funções utilitárias
function Painel:CreateElement(className, properties)
    local element = Instance.new(className)
    for property, value in pairs(properties) do
        element[property] = value
    end
    return element
end

function Painel:ApplyTheme(element, themeType)
    local theme = themes[currentTheme]
    
    if themeType == "Background" then
        element.BackgroundColor3 = theme.Background
    elseif themeType == "LightBackground" then
        element.BackgroundColor3 = theme.LightBackground
    elseif themeType == "Button" then
        element.BackgroundColor3 = theme.Button
        element.TextColor3 = theme.Text
    elseif themeType == "Text" then
        element.TextColor3 = theme.Text
    elseif themeType == "Stroke" then
        if element:IsA("UIStroke") then
            element.Color = theme.Stroke
        end
    end
end

-- Função para criar a janela principal
function Painel:CreateWindow(options)
    -- Criar GUI principal
    local screenGui = self:CreateElement("ScreenGui", {
        Name = "PainelGui",
        ResetOnSpawn = false,
        Parent = game.CoreGui
    })
    
    gui = screenGui
    
    -- Container principal
    local mainFrame = self:CreateElement("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = themes[currentTheme].Background,
        Parent = screenGui
    })
    
    self:CreateElement("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = mainFrame
    })
    
    self:CreateElement("UIStroke", {
        Color = themes[currentTheme].Stroke,
        Thickness = 1,
        Parent = mainFrame
    })
    
    -- Barra de título
    local titleBar = self:CreateElement("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = themes[currentTheme].Accent,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    self:CreateElement("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = titleBar
    })
    
    local titleText = self:CreateElement("TextLabel", {
        Name = "TitleText",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Painel",
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = titleBar
    })
    
    local closeButton = self:CreateElement("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = titleBar
    })
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Área de abas
    local tabButtonsFrame = self:CreateElement("Frame", {
        Name = "TabButtons",
        Size = UDim2.new(0, 120, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = themes[currentTheme].LightBackground,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    local tabContentFrame = self:CreateElement("Frame", {
        Name = "TabContent",
        Size = UDim2.new(1, -120, 1, -30),
        Position = UDim2.new(0, 120, 0, 30),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })
    
    -- Configurar arrastável
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    -- Tabela da janela
    local window = {
        Gui = screenGui,
        MainFrame = mainFrame,
        TabButtonsFrame = tabButtonsFrame,
        TabContentFrame = tabContentFrame,
        Tabs = {},
        CurrentTab = nil
    }
    
    table.insert(windows, window)
    
    -- Funções da janela
    function window:CreateTab(name, icon)
        local tabButton = self:CreateElement("TextButton", {
            Name = name .. "TabButton",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = themes[currentTheme].Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = self.TabButtonsFrame
        })
        
        local tabContent = self:CreateElement("ScrollingFrame", {
            Name = name .. "TabContent",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = self.TabContentFrame
        })
        
        local tab = {
            Name = name,
            Button = tabButton,
            Content = tabContent,
            Elements = {},
            Layout = self:CreateElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = tabContent
            })
        }
        
        tabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tab)
        end)
        
        table.insert(self.Tabs, tab)
        
        if #self.Tabs == 1 then
            self:SwitchTab(tab)
        end
        
        -- Funções da aba
        function tab:CreateSection(title)
            local sectionFrame = self:CreateElement("Frame", {
                Name = title .. "Section",
                Size = UDim2.new(1, -20, 0, 0),
                BackgroundTransparency = 1,
                LayoutOrder = #self.Elements + 1,
                Parent = self.Content
            })
            
            local sectionTitle = self:CreateElement("TextLabel", {
                Name = "SectionTitle",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = themes[currentTheme].Text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionFrame
            })
            
            local sectionContent = self:CreateElement("Frame", {
                Name = "SectionContent",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = themes[currentTheme].LightBackground,
                Parent = sectionFrame
            })
            
            self:CreateElement("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = sectionContent
            })
            
            self:CreateElement("UIStroke", {
                Color = themes[currentTheme].Stroke,
                Thickness = 1,
                Parent = sectionContent
            })
            
            local sectionLayout = self:CreateElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = sectionContent
            })
            
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectionContent.Size = UDim2.new(1, 0, 0, sectionLayout.AbsoluteContentSize.Y + 10)
                sectionFrame.Size = UDim2.new(1, -20, 0, sectionLayout.AbsoluteContentSize.Y + 30)
            end)
            
            local section = {
                Frame = sectionFrame,
                Title = sectionTitle,
                Content = sectionContent,
                Layout = sectionLayout,
                Elements = {}
            }
            
            table.insert(self.Elements, section)
            
            -- Funções da seção
            function section:CreateToggle(options)
                local toggleFrame = self:CreateElement("Frame", {
                    Name = options.Name .. "Toggle",
                    Size = UDim2.new(1, -10, 0, 30),
                    BackgroundTransparency = 1,
                    LayoutOrder = #self.Elements + 1,
                    Parent = self.Content
                })
                
                local toggleButton = self:CreateElement("TextButton", {
                    Name = "ToggleButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = themes[currentTheme].Button,
                    Text = "",
                    Parent = toggleFrame
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = toggleButton
                })
                
                local toggleText = self:CreateElement("TextLabel", {
                    Name = "ToggleText",
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = options.Name,
                    TextColor3 = themes[currentTheme].Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleButton
                })
                
                local toggleIndicator = self:CreateElement("Frame", {
                    Name = "ToggleIndicator",
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0.5, -10),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = options.CurrentValue and themes[currentTheme].Accent or themes[currentTheme].Stroke,
                    Parent = toggleButton
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggleIndicator
                })
                
                local toggle = {
                    Value = options.CurrentValue or false,
                    Callback = options.Callback
                }
                
                toggleButton.MouseButton1Click:Connect(function()
                    toggle.Value = not toggle.Value
                    toggleIndicator.BackgroundColor3 = toggle.Value and themes[currentTheme].Accent or themes[currentTheme].Stroke
                    
                    if toggle.Callback then
                        toggle.Callback(toggle.Value)
                    end
                end)
                
                -- Efeito hover
                toggleButton.MouseEnter:Connect(function()
                    game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].ButtonHover
                    }):Play()
                end)
                
                toggleButton.MouseLeave:Connect(function()
                    game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].Button
                    }):Play()
                end)
                
                table.insert(self.Elements, toggle)
                return toggle
            end
            
            function section:CreateSlider(options)
                local sliderFrame = self:CreateElement("Frame", {
                    Name = options.Name .. "Slider",
                    Size = UDim2.new(1, -10, 0, 60),
                    BackgroundTransparency = 1,
                    LayoutOrder = #self.Elements + 1,
                    Parent = self.Content
                })
                
                local sliderText = self:CreateElement("TextLabel", {
                    Name = "SliderText",
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = options.Name .. ": " .. tostring(options.CurrentValue),
                    TextColor3 = themes[currentTheme].Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sliderFrame
                })
                
                local sliderTrack = self:CreateElement("Frame", {
                    Name = "SliderTrack",
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundColor3 = themes[currentTheme].Stroke,
                    Parent = sliderFrame
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderTrack
                })
                
                local sliderFill = self:CreateElement("Frame", {
                    Name = "SliderFill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = themes[currentTheme].Accent,
                    Parent = sliderTrack
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderFill
                })
                
                local sliderThumb = self:CreateElement("Frame", {
                    Name = "SliderThumb",
                    Size = UDim2.new(0, 15, 0, 15),
                    Position = UDim2.new(0, 0, 0.5, -7.5),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = sliderTrack
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = sliderThumb
                })
                
                local minValue = options.Range[1]
                local maxValue = options.Range[2]
                local currentValue = options.CurrentValue or minValue
                local increment = options.Increment or 1
                
                -- Calcular posição inicial
                local fillWidth = ((currentValue - minValue) / (maxValue - minValue)) * sliderTrack.AbsoluteSize.X
                sliderFill.Size = UDim2.new(0, fillWidth, 1, 0)
                sliderThumb.Position = UDim2.new(0, fillWidth, 0.5, -7.5)
                
                local slider = {
                    Value = currentValue,
                    Callback = options.Callback
                }
                
                local function updateSlider(value)
                    local normalized = math.clamp(value, minValue, maxValue)
                    normalized = math.floor(normalized / increment) * increment
                    
                    slider.Value = normalized
                    sliderText.Text = options.Name .. ": " .. tostring(normalized)
                    
                    local fillWidth = ((normalized - minValue) / (maxValue - minValue)) * sliderTrack.AbsoluteSize.X
                    sliderFill.Size = UDim2.new(0, fillWidth, 1, 0)
                    sliderThumb.Position = UDim2.new(0, fillWidth, 0.5, -7.5)
                    
                    if slider.Callback then
                        slider.Callback(normalized)
                    end
                end
                
                local dragging = false
                
                sliderTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local position = input.Position.X - sliderTrack.AbsolutePosition.X
                        local value = minValue + (position / sliderTrack.AbsoluteSize.X) * (maxValue - minValue)
                        updateSlider(value)
                    end
                end)
                
                sliderTrack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local position = input.Position.X - sliderTrack.AbsolutePosition.X
                        local value = minValue + (position / sliderTrack.AbsoluteSize.X) * (maxValue - minValue)
                        updateSlider(value)
                    end
                end)
                
                table.insert(self.Elements, slider)
                return slider
            end
            
            function section:CreateButton(options)
                local buttonFrame = self:CreateElement("Frame", {
                    Name = options.Name .. "Button",
                    Size = UDim2.new(1, -10, 0, 30),
                    BackgroundTransparency = 1,
                    LayoutOrder = #self.Elements + 1,
                    Parent = self.Content
                })
                
                local button = self:CreateElement("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = themes[currentTheme].Button,
                    Text = options.Name,
                    TextColor3 = themes[currentTheme].Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    Parent = buttonFrame
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = button
                })
                
                button.MouseButton1Click:Connect(function()
                    if options.Callback then
                        options.Callback()
                    end
                end)
                
                -- Efeito hover
                button.MouseEnter:Connect(function()
                    game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].ButtonHover
                    }):Play()
                end)
                
                button.MouseLeave:Connect(function()
                    game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].Button
                    }):Play()
                end)
                
                table.insert(self.Elements, button)
                return button
            end
            
            function section:CreateColorPicker(options)
                local colorPickerFrame = self:CreateElement("Frame", {
                    Name = options.Name .. "ColorPicker",
                    Size = UDim2.new(1, -10, 0, 30),
                    BackgroundTransparency = 1,
                    LayoutOrder = #self.Elements + 1,
                    Parent = self.Content
                })
                
                local colorPickerButton = self:CreateElement("TextButton", {
                    Name = "ColorPickerButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = themes[currentTheme].Button,
                    Text = options.Name,
                    TextColor3 = themes[currentTheme].Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = colorPickerFrame
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = colorPickerButton
                })
                
                local colorPreview = self:CreateElement("Frame", {
                    Name = "ColorPreview",
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -25, 0.5, -10),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = options.Color or Color3.new(1, 1, 1),
                    Parent = colorPickerButton
                })
                
                self:CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = colorPreview
                })
                
                self:CreateElement("UIStroke", {
                    Color = themes[currentTheme].Stroke,
                    Thickness = 1,
                    Parent = colorPreview
                })
                
                local colorPicker = {
                    Value = options.Color or Color3.new(1, 1, 1),
                    Callback = options.Callback
                }
                
                -- TODO: Implementar seletor de cores completo
                colorPickerButton.MouseButton1Click:Connect(function()
                    -- Abrir seletor de cores (simplificado)
                    local newColor = Color3.fromHSV(math.random(), 1, 1)
                    colorPreview.BackgroundColor3 = newColor
                    colorPicker.Value = newColor
                    
                    if colorPicker.Callback then
                        colorPicker.Callback(newColor)
                    end
                end)
                
                -- Efeito hover
                colorPickerButton.MouseEnter:Connect(function()
                    game:GetService("TweenService"):Create(colorPickerButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].ButtonHover
                    }):Play()
                end)
                
                colorPickerButton.MouseLeave:Connect(function()
                    game:GetService("TweenService"):Create(colorPickerButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = themes[currentTheme].Button
                    }):Play()
                end)
                
                table.insert(self.Elements, colorPicker)
                return colorPicker
            end
            
            return section
        end
        
        return tab
    end
    
    function window:SwitchTab(tab)
        if self.CurrentTab then
            self.CurrentTab.Button.TextColor3 = themes[currentTheme].Text
            self.CurrentTab.Content.Visible = false
        end
        
        self.CurrentTab = tab
        tab.Button.TextColor3 = themes[currentTheme].Accent
        tab.Content.Visible = true
    end
    
    function window:Notify(options)
        -- Criar notificação
        local notification = self:CreateElement("Frame", {
            Name = "Notification",
            Size = UDim2.new(0, 300, 0, 80),
            Position = UDim2.new(1, -320, 1, -100),
            BackgroundColor3 = themes[currentTheme].Background,
            Parent = self.Gui
        })
        
        self:CreateElement("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = notification
        })
        
        self:CreateElement("UIStroke", {
            Color = themes[currentTheme].Stroke,
            Thickness = 1,
            Parent = notification
        })
        
        local title = self:CreateElement("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = options.Title or "Notificação",
            TextColor3 = themes[currentTheme].Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notification
        })
        
        local content = self:CreateElement("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -20, 1, -45),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundTransparency = 1,
            Text = options.Content or "",
            TextColor3 = themes[currentTheme].Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = notification
        })
        
        -- Animação de entrada
        notification.Position = UDim2.new(1, 300, 1, -100)
        game:GetService("TweenService"):Create(notification, TweenInfo.new(0.3), {
            Position = UDim2.new(1, -320, 1, -100)
        }):Play()
        
        -- Fechar automaticamente após o tempo especificado
        local duration = options.Duration or 5
        delay(duration, function()
            if notification and notification.Parent then
                game:GetService("TweenService"):Create(notification, TweenInfo.new(0.3), {
                    Position = UDim2.new(1, 300, 1, -100)
                }):Play()
                wait(0.3)
                notification:Destroy()
            end
        end)
    end
    
    return window
end

return Painel