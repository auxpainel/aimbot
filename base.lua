-- floating_menu.lua
-- Módulo que cria um menu flutuante, arrastável e minimizável
-- Retorna uma factory: CreateFloatingMenu(options)

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local function CreateFloatingMenu(opts)
	opts = opts or {}
	local titleText = opts.Title or "Menu"
	local startingPos = opts.Position or UDim2.new(0.7, 0, 0.3, 0)
	local width = opts.Width or 260
	local height = opts.Height or 360
	local parent = opts.Parent or game.CoreGui
	local persistKey = opts.PersistKey -- string opcional para salvar posição com HttpService/Settings se quiser

	-- root gui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = titleText .. "_FloatingMenu"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parent

	-- main frame
	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = UDim2.new(0, width, 0, height)
	frame.Position = startingPos
	frame.AnchorPoint = Vector2.new(0,0)
	frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	frame.Active = true

	local uiCorner = Instance.new("UICorner", frame)
	uiCorner.CornerRadius = UDim.new(0, 8)

	-- titlebar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 34)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = titleText
	titleLabel.Size = UDim2.new(1, -70, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(240,240,240)
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- minimize button
	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Text = "—"
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 18
	minBtn.TextColor3 = Color3.fromRGB(220,220,220)
	minBtn.Size = UDim2.new(0, 28, 0, 24)
	minBtn.Position = UDim2.new(1, -36, 0, 5)
	minBtn.BackgroundTransparency = 0.7
	minBtn.Parent = titleBar
	local minCorner = Instance.new("UICorner", minBtn); minCorner.CornerRadius = UDim.new(0,4)

	-- close button (opcional)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(220,220,220)
	closeBtn.Size = UDim2.new(0, 28, 0, 24)
	closeBtn.Position = UDim2.new(1, -6, 0, 5)
	closeBtn.BackgroundTransparency = 0.7
	closeBtn.Parent = titleBar
	local closeCorner = Instance.new("UICorner", closeBtn); closeCorner.CornerRadius = UDim.new(0,4)

	-- content container
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0, 0, 0, 34)
	content.Size = UDim2.new(1, 0, 1, -34)
	content.BackgroundTransparency = 1
	content.Parent = frame

	local contentPadding = Instance.new("UIListLayout", content)
	contentPadding.Name = "Layout"
	contentPadding.Padding = UDim.new(0, 8)
	contentPadding.SortOrder = Enum.SortOrder.LayoutOrder

	local uiPadding = Instance.new("UIPadding", content)
	uiPadding.PaddingTop = UDim.new(0, 10)
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)

	-- state
	local minimized = false
	local expandedSize = frame.Size
	local collapsedSize = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 34)

	-- dragging
	local dragging = false
	local dragInput, dragStart, startPos

	local function updatePosition(input)
		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y
		-- clamp to screen roughly
		local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1024, 768)
		newX = math.clamp(newX, 0, screenSize.X - frame.AbsoluteSize.X)
		newY = math.clamp(newY, 0, screenSize.Y - 40)
		frame.Position = UDim2.new(0, newX, 0, newY)
	end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					-- opcional: persistir posição se desejar
					if persistKey then
						local ok, _ = pcall(function()
							local data = {x = frame.Position.X.Offset, y = frame.Position.Y.Offset}
							writefile and writefile(persistKey..".json", HttpService:JSONEncode(data))
						end)
					end
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
		if dragging and input == dragInput then
			updatePosition(input)
		end
	end)

	-- minimize / restore
	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			-- esconder conteúdo + reduzir frame
			for _, v in ipairs(content:GetChildren()) do
				if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
					v.Visible = false
				end
			end
			TweenService:Create(frame, tweenInfo, {Size = collapsedSize}):Play()
			minBtn.Text = "+"
		else
			TweenService:Create(frame, tweenInfo, {Size = expandedSize}):Play()
			-- aguarda o tween terminar rapidamente antes de mostrar
			task.delay(0.18, function()
				for _, v in ipairs(content:GetChildren()) do
					if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
						v.Visible = true
					end
				end
			end)
			minBtn.Text = "—"
		end
	end)

	-- close
	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- helper factory para criar controles
	local api = {}
	local layoutOrderCounter = 1

	local function setLayout(child)
		child.LayoutOrder = layoutOrderCounter
		layoutOrderCounter = layoutOrderCounter + 1
	end

	function api:AddLabel(text)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.Text = text or ""
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = content
		setLayout(lbl)
		return lbl
	end

	function api:AddButton(text, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
		btn.TextColor3 = Color3.fromRGB(235,235,235)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Text = text or "Button"
		btn.AutoButtonColor = true
		btn.Parent = content
		local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0,6)
		setLayout(btn)
		btn.MouseButton1Click:Connect(function() 
			pcall(function() if callback then callback() end end)
		end)
		return btn
	end

	function api:AddToggle(text, default, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,0,0,28)
		container.BackgroundTransparency = 1
		container.Parent = content
		setLayout(container)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.75, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text or "Toggle"
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Parent = container

		local toggle = Instance.new("TextButton")
		toggle.Size = UDim2.new(0.2, 0, 0.7, 0)
		toggle.Position = UDim2.new(0.78, 0, 0.15, 0)
		toggle.BackgroundColor3 = default and Color3.fromRGB(60,160,80) or Color3.fromRGB(80,80,80)
		toggle.Text = default and "ON" or "OFF"
		toggle.Font = Enum.Font.GothamBold
		toggle.TextSize = 12
		toggle.TextColor3 = Color3.fromRGB(240,240,240)
		toggle.AutoButtonColor = false
		toggle.Parent = container
		local corner = Instance.new("UICorner", toggle); corner.CornerRadius = UDim.new(0,6)

		local state = default and true or false
		toggle.MouseButton1Click:Connect(function()
			state = not state
			if state then
				toggle.BackgroundColor3 = Color3.fromRGB(60,160,80)
				toggle.Text = "ON"
			else
				toggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
				toggle.Text = "OFF"
			end
			pcall(function() if callback then callback(state) end end)
		end)

		return {Label = lbl, Toggle = toggle, Get = function() return state end, Set = function(val)
			state = not not val
			if state then toggle.BackgroundColor3 = Color3.fromRGB(60,160,80); toggle.Text = "ON" 
			else toggle.BackgroundColor3 = Color3.fromRGB(80,80,80); toggle.Text = "OFF" end
		end}
	end

	function api:AddSlider(text, min, max, default, callback)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,0,0,36)
		container.BackgroundTransparency = 1
		container.Parent = content
		setLayout(container)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.6,0,0,18)
		lbl.Position = UDim2.new(0,0,0,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text or "Slider"
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Parent = container

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.4,0,0,18)
		valueLabel.Position = UDim2.new(0.6,0,0,0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(default or min)
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 13
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.TextColor3 = Color3.new(1,1,1)
		valueLabel.Parent = container

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, 0, 0, 10)
		barBg.Position = UDim2.new(0,0,0,20)
		barBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
		barBg.Parent = container
		local bgCorner = Instance.new("UICorner", barBg); bgCorner.CornerRadius = UDim.new(0,4)

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(((default or min)-min)/(max-min), 0, 1, 0)
		barFill.BackgroundColor3 = Color3.fromRGB(120,120,120)
		barFill.Parent = barBg
		local fillCorner = Instance.new("UICorner", barFill); fillCorner.CornerRadius = UDim.new(0,4)

		local draggingBar = false
		local function updateBar(input)
			local relative = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
			barFill.Size = UDim2.new(relative, 0, 1, 0)
			local real = min + (max-min) * relative
			local val = math.floor(real)
			valueLabel.Text = tostring(val)
			pcall(function() if callback then callback(val) end end)
		end

		barBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingBar = true
				updateBar(input)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then draggingBar = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if draggingBar and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateBar(input)
			end
		end)

		return {Label = lbl, ValueLabel = valueLabel, Set = function(v)
			local normalized = math.clamp((v - min)/(max-min), 0, 1)
			barFill.Size = UDim2.new(normalized, 0, 1, 0)
			valueLabel.Text = tostring(math.floor(v))
		end, Get = function()
			return tonumber(valueLabel.Text)
		end}
	end

	-- função utilitária para expor o gui inteiro
	function api:GetGui() return screenGui end
	function api:Destroy() screenGui:Destroy() end

	-- tentar carregar posição persistida (se presente)
	if persistKey and readfile and isfile and isfile(persistKey..".json") then
		pcall(function()
			local raw = readfile(persistKey..".json")
			local decoded = HttpService:JSONDecode(raw)
			if decoded.x and decoded.y then
				frame.Position = UDim2.new(0, decoded.x, 0, decoded.y)
			end
		end)
	end

	return api
end

return CreateFloatingMenu