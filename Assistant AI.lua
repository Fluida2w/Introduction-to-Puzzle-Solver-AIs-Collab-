

-- Assistant AI

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


-- Enhanced Message Types with Semantic Meaning
local MESSAGE_TYPES = {
	HELP_REQUEST = {id = 1, priority = 3},
	HINT_PROVIDED = {id = 2, priority = 2},
	RESET_NEEDED = {id = 3, priority = 4},
	SYSTEM_UPDATE = {id = 4, priority = 1},
	PROGRESS_UPDATE = {id = 5, priority = 1},
	BUTTON_FEEDBACK = {id = 6, priority = 2},
	ACKNOWLEDGMENT = {id = 7, priority = 1},
	SOCIAL_SIGNAL = {id = 8, priority = 2},
	DEMONSTRATION = {id = 9, priority = 3},
	ENCOURAGEMENT = {id = 10, priority = 2}  -- New for encouragement messages
}

-- AI Setup with Robust Initialization
local bot = script.Parent
local humanoid = bot:WaitForChild("Humanoid")
local torso = bot:WaitForChild("Torso")
local head = bot:WaitForChild("Head")

-- Animation System with Emotional States
local AnimationSystem = {
	states = {
		idle = {
			animId = "rbxassetid://180435571",
			weight = 1.0,
			speed = 1.0,
			priority = Enum.AnimationPriority.Idle
		},
		walk = {
			animId = "rbxassetid://180426354",
			weight = 1.0,
			speed = 1.1,
			priority = Enum.AnimationPriority.Movement
		},
		explain = {
			animId = "rbxassetid://33796059",
			weight = 0.8,
			speed = 0.9,
			priority = Enum.AnimationPriority.Action
		},
		positive = {
			animId = "rbxassetid://5917459365",
			weight = 0.7,
			speed = 1.2,
			priority = Enum.AnimationPriority.Action
		},
		negative = {
			animId = "rbxassetid://5917466689",
			weight = 0.7,
			speed = 1.2,
			priority = Enum.AnimationPriority.Action
		},
		celebrate = {
			animId = "rbxassetid://5917459365",
			weight = 0.9,
			speed = 1.3,
			priority = Enum.AnimationPriority.Action
		},
		wave = {
			animId = "rbxassetid://5915705587",
			weight = 0.8,
			speed = 1.0,
			priority = Enum.AnimationPriority.Action
		},
		nod = {
			animId = "rbxassetid://5915718521",
			weight = 0.6,
			speed = 1.2,
			priority = Enum.AnimationPriority.Action
		},
		demonstrate = {
			animId = "rbxassetid://188632011",
			weight = 0.9,
			speed = 1.0,
			priority = Enum.AnimationPriority.Action
		},
		cheer = {  -- New animation for cheering
			animId = "rbxassetid://5917459365",
			weight = 0.9,
			speed = 1.5,
			priority = Enum.AnimationPriority.Action
		}
	},
	currentState = "idle",
	tracks = {},
	socialCooldown = 0
}

-- Load animations with error handling
for stateName, config in pairs(AnimationSystem.states) do
	local anim = Instance.new("Animation")
	anim.AnimationId = config.animId

	local success, track = pcall(function()
		local t = humanoid:LoadAnimation(anim)
		t.Priority = config.priority
		t:AdjustSpeed(config.speed)
		return t
	end)

	if success then
		AnimationSystem.tracks[stateName] = track
	else
		warn("Failed to load animation for state: "..stateName)
	end
end

local function setAnimationState(newState, fadeTime)
	fadeTime = fadeTime or 0.3
	if AnimationSystem.currentState == newState then return end

	if AnimationSystem.tracks[AnimationSystem.currentState] then
		AnimationSystem.tracks[AnimationSystem.currentState]:Stop(fadeTime)
	end

	if AnimationSystem.tracks[newState] then
		AnimationSystem.tracks[newState]:Play(fadeTime)
	end

	AnimationSystem.currentState = newState
end

-- Professional Chat System with Social Cues
local chatGui = Instance.new("BillboardGui")
chatGui.Name = "ExpertChat"
chatGui.Size = UDim2.new(5, 0, 2.5, 0)
chatGui.StudsOffset = Vector3.new(0, 3.5, 0)
chatGui.Adornee = head
chatGui.Parent = head

local chatFrame = Instance.new("Frame")
chatFrame.Size = UDim2.new(1, 0, 1, 0)
chatFrame.BackgroundTransparency = 0.9
chatFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
chatFrame.Parent = chatGui

local chatLabel = Instance.new("TextLabel")
chatLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
chatLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
chatLabel.BackgroundTransparency = 1
chatLabel.TextColor3 = Color3.new(1, 1, 1)
chatLabel.TextScaled = true
chatLabel.Font = Enum.Font.GothamBold
chatLabel.TextWrapped = true
chatLabel.TextStrokeTransparency = 0.7
chatLabel.TextStrokeColor3 = Color3.new(0, 0, 0.2)
chatLabel.TextXAlignment = Enum.TextXAlignment.Left
chatLabel.Parent = chatFrame

local typingIndicator = Instance.new("Frame")
typingIndicator.Size = UDim2.new(0.1, 0, 0.05, 0)
typingIndicator.Position = UDim2.new(0.05, 0, 0.9, 0)
typingIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
typingIndicator.AnchorPoint = Vector2.new(0, 0.5)
typingIndicator.Visible = false
typingIndicator.Parent = chatFrame

local typingTween = TweenService:Create(typingIndicator, TweenInfo.new(
	0.8,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	true
	), {
		Size = UDim2.new(0.2, 0, 0.05, 0)
	})

-- Message system with queue
local messageQueue = {}
local currentMessage = nil
local isProcessingMessages = false

local function displayMessage(message, duration, emotion)
	emotion = emotion or "neutral"

	if emotion == "positive" then
		setAnimationState("positive")
	elseif emotion == "negative" then
		setAnimationState("negative")
	elseif emotion == "explaining" then
		setAnimationState("explain")
	elseif emotion == "demonstrating" then
		setAnimationState("demonstrate")
	elseif emotion == "cheering" then
		setAnimationState("cheer")
	else
		setAnimationState("idle")
	end

	local bgColor = Color3.fromRGB(10, 20, 40)
	if emotion == "positive" then bgColor = Color3.fromRGB(20, 40, 10) end
	if emotion == "negative" then bgColor = Color3.fromRGB(40, 10, 10) end
	if emotion == "explaining" then bgColor = Color3.fromRGB(20, 20, 60) end
	if emotion == "demonstrating" then bgColor = Color3.fromRGB(40, 10, 40) end
	if emotion == "cheering" then bgColor = Color3.fromRGB(40, 20, 60) end

	TweenService:Create(chatFrame, TweenInfo.new(0.5), {
		BackgroundColor3 = bgColor
	}):Play()

	chatLabel.Text = ""
	typingIndicator.Visible = true
	typingTween:Play()

	local typingSpeed = #message > 50 and 0.02 or 0.03

	for i = 1, #message do
		chatLabel.Text = string.sub(message, 1, i)
		task.wait(typingSpeed)
	end

	typingTween:Cancel()
	typingIndicator.Visible = false

	if duration then
		task.delay(duration, function()
			if chatLabel.Text == message then
				TweenService:Create(chatFrame, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(10, 20, 40)
				}):Play()
				chatLabel.Text = ""
				setAnimationState("idle")
			end
		end)
	end
end

local function processNextMessage()
	if #messageQueue == 0 then
		currentMessage = nil
		isProcessingMessages = false
		return
	end

	isProcessingMessages = true
	currentMessage = table.remove(messageQueue, 1)
	displayMessage(currentMessage.text, currentMessage.duration, currentMessage.emotion)

	if currentMessage.duration then
		task.delay(currentMessage.duration + 0.5, function()
			if currentMessage and chatLabel.Text == currentMessage.text then
				chatLabel.Text = ""
			end
			processNextMessage()
		end)
	else
		processNextMessage()
	end
end

local function queueMessage(text, duration, priority, emotion)
	table.insert(messageQueue, {
		text = text,
		duration = duration,
		priority = priority or 1,
		emotion = emotion or "neutral"
	})

	table.sort(messageQueue, function(a, b)
		return (a.priority or 1) > (b.priority or 1)
	end)

	if not isProcessingMessages then
		processNextMessage()
	end
end

-- Social Interaction System
local function performSocialGesture(gesture)
	if gesture == "wave" then
		setAnimationState("wave", 0.3)
		queueMessage("*waves*", 2, 1, "positive")
	elseif gesture == "nod" then
		setAnimationState("nod", 0.3)
		queueMessage("*nods*", 1.5, 1, "positive")
	elseif gesture == "celebrate" then
		setAnimationState("celebrate", 0.3)
		queueMessage("*celebrates*", 3, 1, "positive")
	elseif gesture == "cheer" then
		setAnimationState("cheer", 0.3)
		queueMessage("*cheers*", 2, 1, "cheering")
	end
end

-- Enhanced Movement System (simplified like PuzzleAI)
local function navigateTo(position, urgency, socialTarget)
	urgency = urgency or 1
	setAnimationState("walk")

	-- Adjust position if moving near another AI
	if socialTarget then
		local socialTorso = socialTarget:FindFirstChild("Torso")
		if socialTorso then
			local toTarget = (position - socialTorso.Position).Unit
			position = socialTorso.Position + (toTarget * 4) -- Maintain 4 stud distance
		end
	end

	-- Calculate direction and distance
	local direction = (position - torso.Position).Unit
	local distance = (position - torso.Position).Magnitude

	-- Set movement parameters
	humanoid.WalkSpeed = 12 + (urgency * 4)
	humanoid:MoveTo(position)

	-- Wait until reached or timeout
	local startTime = os.clock()
	local timeout = math.min(5, distance / (humanoid.WalkSpeed * 0.7))

	while (torso.Position - position).Magnitude > 2.5 do
		if os.clock() - startTime > timeout then
			queueMessage("Movement delayed", 1, 2, "negative")
			break
		end
		task.wait(0.1)
	end

	setAnimationState("idle")
	return true
end

-- Enhanced Collaboration Beam System
local function createConnectionBeam(target)
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = head

	local targetHead = target:FindFirstChild("Head")
	if not targetHead then return nil end

	local attachment1 = targetHead:FindFirstChildOfClass("Attachment") or Instance.new("Attachment")
	attachment1.Parent = targetHead

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
	beam.Width0 = 0.3
	beam.Width1 = 0.3
	beam.LightEmission = 1.0
	beam.Parent = head

	-- Add pulsing effect
	local pulseTween = TweenService:Create(beam, TweenInfo.new(
		1,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
		), {
			Width0 = 0.1,
			Width1 = 0.1
		})
	pulseTween:Play()

	return beam
end

-- Knowledge Base with Adaptive Learning
local PuzzleDatabase = {
	sequences = {
		basic = {
			pattern = {"Button1", "Button2", "Button3", "Button4"},
			difficulty = 1,
			successRate = 0.95
		},
		alternative = {
			pattern = {"Button1", "Button3", "Button2", "Button4"},
			difficulty = 2,
			successRate = 0.85
		},
		complex = {
			pattern = {"Button1", "Button4", "Button2", "Button3"},
			difficulty = 3,
			successRate = 0.7
		}
	},
	hints = {
		{
			text = "Begin with the leftmost button and proceed right",
			effectiveness = 0.8,
			usedCount = 0
		},
		{
			text = "The sequence follows a numerical pattern",
			effectiveness = 0.7,
			usedCount = 0
		},
		{
			text = "Alternate between odd and even numbered buttons",
			effectiveness = 0.6,
			usedCount = 0
		},
		{
			text = "Reset the puzzle if you make a mistake",
			effectiveness = 0.9,
			usedCount = 0
		},
		{
			text = "Look for visual clues near the buttons",
			effectiveness = 0.5,
			usedCount = 0
		},
		{
			text = "Try pressing buttons in order of their brightness",
			effectiveness = 0.65,
			usedCount = 0
		},
		{
			text = "The correct sequence is related to the colors of the buttons",
			effectiveness = 0.55,
			usedCount = 0
		}
	},
	encouragements = {  -- New encouragement messages
		"Begin with the leftmost button and proceed right",
		"The sequence follows a numerical pattern",
		"The correct sequence is related to the colors of the buttons",
		"Try pressing buttons in order of their brightness",
		"Reset the puzzle if you make a mistake"
		
	},
	lastUsedHint = nil,
	hintCooldown = 0,
	feedbackData = {}
}

local function updateHintEffectiveness(hintText, effectiveness)
	for _, hint in ipairs(PuzzleDatabase.hints) do
		if hint.text == hintText then
			hint.effectiveness = math.max(0.1, math.min(1.0, 
				hint.effectiveness + (effectiveness - 0.5) * 0.2))
			hint.usedCount = hint.usedCount + 1
			break
		end
	end
end

local function selectOptimalHint(context)
	local availableHints = {}

	-- Filter hints that aren't on cooldown
	for _, hint in ipairs(PuzzleDatabase.hints) do
		if os.clock() > PuzzleDatabase.hintCooldown then
			table.insert(availableHints, hint)
		end
	end

	if #availableHints == 0 then
		return "Try examining the buttons more carefully"
	end

	-- Context-aware hint selection
	if context then
		if context.currentStep and context.currentStep == 1 then
			table.sort(availableHints, function(a, b)
				local scoreA = a.text:match("Begin") and 2 or a.text:match("first") and 1.5 or a.effectiveness / (a.usedCount + 1)
				local scoreB = b.text:match("Begin") and 2 or b.text:match("first") and 1.5 or b.effectiveness / (b.usedCount + 1)
				return scoreA > scoreB
			end)
		elseif context.error and context.error:match("Incorrect") then
			table.sort(availableHints, function(a, b)
				local scoreA = a.text:match("Reset") and 2 or a.text:match("mistake") and 1.8 or a.effectiveness / (a.usedCount + 1)
				local scoreB = b.text:match("Reset") and 2 or b.text:match("mistake") and 1.8 or b.effectiveness / (b.usedCount + 1)
				return scoreA > scoreB
			end)
		end
	end

	-- Default sorting by effectiveness/usage ratio
	if #availableHints > 0 then
		table.sort(availableHints, function(a, b)
			local scoreA = a.effectiveness / (a.usedCount + 1)
			local scoreB = b.effectiveness / (b.usedCount + 1)
			return scoreA > scoreB
		end)
	end

	local selectedHint = availableHints[1]
	selectedHint.usedCount = selectedHint.usedCount + 1
	PuzzleDatabase.lastUsedHint = selectedHint
	PuzzleDatabase.hintCooldown = os.clock() + 10

	return selectedHint.text
end

-- New: Select random encouragement message
local function selectEncouragement()
	local index = math.random(1, #PuzzleDatabase.encouragements)
	return PuzzleDatabase.encouragements[index]
end

-- Active Demonstration System
local function demonstrateSolution(buttons)
	if not buttons or #buttons == 0 then return end

	queueMessage("Watch closely!", 3, 3, "demonstrating")
	setAnimationState("demonstrate")

	-- Create visual connection to PuzzleAI
	local puzzleAI = workspace:FindFirstChild("PuzzleAI")
	if puzzleAI then
		local beam = createConnectionBeam(puzzleAI)
		if beam then
			task.delay(10, function() beam:Destroy() end)
		end
	end

	-- Demonstrate each button in sequence
	for _, button in ipairs(buttons) do
		-- Approach the button
		navigateTo(button.Position + Vector3.new(0, 0, 3), 2)
		task.wait(0.5)

		-- Highlight the button
		local originalColor = button.Color
		local tween = TweenService:Create(button, TweenInfo.new(0.5), {
			Color = Color3.fromRGB(0, 255, 0),
			Size = button.Size * 1.2
		})
		tween:Play()

		-- Point at the button
		setAnimationState("demonstrate")
		task.wait(1.5)

		-- Revert button appearance
		tween = TweenService:Create(button, TweenInfo.new(0.5), {
			Color = originalColor,
			Size = button.Size / 1.2
		})
		tween:Play()

		-- Notify PuzzleAI about this demonstration step
		if puzzleAI and puzzleAI:FindFirstChild("AIComm") then
			puzzleAI.AIComm:Fire(bot, MESSAGE_TYPES.DEMONSTRATION.id, {
				button = button.Name,
				timestamp = os.clock()
			})
		end

		task.wait(1)
	end

	setAnimationState("idle")
end

-- Enhanced Communication System
local commChannel = Instance.new("BindableEvent")
commChannel.Name = "AIComm"
commChannel.Parent = script

local activeRequests = {}
local lastEncouragementTime = 0

-- New: Send encouragement to PuzzleAI
local function sendEncouragement(target)
	if os.clock() - lastEncouragementTime < 15 then return end

	local message = selectEncouragement()
	queueMessage(message, 3, MESSAGE_TYPES.ENCOURAGEMENT.priority, "cheering")
	performSocialGesture("cheer")

	if target and target:FindFirstChild("AIComm") then
		target.AIComm:Fire(bot, MESSAGE_TYPES.ENCOURAGEMENT.id, {
			message = message,
			timestamp = os.clock()
		})
	end

	lastEncouragementTime = os.clock()
end

local function handleHelpRequest(sender, requestData)
	if not sender or not sender:IsDescendantOf(workspace) then return end

	if activeRequests[sender] and os.clock() - activeRequests[sender] < 5 then
		return
	end

	activeRequests[sender] = os.clock()

	local senderTorso = sender:FindFirstChild("Torso")
	if not senderTorso then return end

	queueMessage("Assistance request received", 2, 3, "positive")

	-- Create visual connection
	local beam = createConnectionBeam(sender)
	if beam then
		task.delay(10, function() beam:Destroy() end)
	end

	-- Approach but maintain social distance
	if navigateTo(senderTorso.Position + Vector3.new(0, 0, -4), 2, sender) then
		-- Face the requester
		torso.CFrame = CFrame.new(torso.Position, senderTorso.Position)

		-- Social greeting
		if os.clock() > AnimationSystem.socialCooldown then
			performSocialGesture("wave")
			AnimationSystem.socialCooldown = os.clock() + 10
		end

		local hint = selectOptimalHint(requestData)
		local sequence = PuzzleDatabase.sequences.basic.pattern

		queueMessage(hint, 6, 1, "explaining")
		task.wait(1)

		-- Send hint with acknowledgment request
		commChannel:Fire(sender, MESSAGE_TYPES.HINT_PROVIDED.id, {
			hint = hint,
			sequence = sequence,
			checksum = requestData.checksum,
			timestamp = os.clock()
		})

		-- If the PuzzleAI is stuck, demonstrate the solution
		if requestData.error and requestData.error:match("stuck") then
			task.wait(2)
			local buttons = {}
			for _, btnName in ipairs(sequence) do
				local btn = workspace.PuzzleButtons:FindFirstChild(btnName)
				if btn then table.insert(buttons, btn) end
			end
			demonstrateSolution(buttons)
		end

		setAnimationState("positive", 0.3)
		task.wait(2)
		setAnimationState("idle", 0.3)
	else
		queueMessage("Unable to reach requester", 3, 3, "negative")
	end
end

local function handleFeedback(sender, feedbackData)
	if feedbackData.hint and feedbackData.effectiveness then
		updateHintEffectiveness(feedbackData.hint, feedbackData.effectiveness)
		queueMessage("Feedback received - adjusting strategy", 2, 1, "positive")
	end
end

local function handleSocialSignal(sender, data)
	if not sender or not sender:IsDescendantOf(workspace) then return end

	if data.gesture and os.clock() > AnimationSystem.socialCooldown then
		if data.gesture == "wave" then
			performSocialGesture("wave")
		elseif data.gesture == "nod" then
			performSocialGesture("nod")
		elseif data.gesture == "celebrate" then
			performSocialGesture("celebrate")
		end
		AnimationSystem.socialCooldown = os.clock() + 10
	end
end

-- New: Handle encouragement messages
local function handleEncouragement(sender, data)
	if not sender or not sender:IsDescendantOf(workspace) then return end

	if data.message and os.clock() - lastEncouragementTime > 10 then
		queueMessage(data.message, 3, MESSAGE_TYPES.ENCOURAGEMENT.priority, "cheering")
		performSocialGesture("cheer")
		lastEncouragementTime = os.clock()
	end
end

-- Enhanced Monitoring System with Active Assistance
local function monitorPuzzleAI()
	while true do
		local puzzleAI = workspace:FindFirstChild("PuzzleAI")
		if puzzleAI then
			local puzzleTorso = puzzleAI:FindFirstChild("Torso")
			local puzzleHumanoid = puzzleAI:FindFirstChild("Humanoid")

			if puzzleTorso and puzzleHumanoid and puzzleHumanoid.Health > 0 then
				local distance = (torso.Position - puzzleTorso.Position).Magnitude

				-- If PuzzleAI is within 30 studs but not too close
				if distance > 8 and distance < 30 then
					-- Calculate position to maintain optimal helping distance (4-6 studs)
					local direction = (puzzleTorso.Position - torso.Position).Unit
					local targetPosition = puzzleTorso.Position - (direction * 5) -- Stay 5 studs away

					-- Navigate to optimal helping position
					navigateTo(targetPosition, 1, puzzleAI)

					-- Face the PuzzleAI while moving/helping
					torso.CFrame = CFrame.new(torso.Position, puzzleTorso.Position)

					-- Random encouragement (10% chance every check)
					if math.random() < 0.1 then
						sendEncouragement(puzzleAI)
					end
				end
			end
		end
		task.wait(2) -- Check every 2 seconds
	end
end

-- Proactive Assistance System with Enhanced Scanning
local function scanForHelpRequests()
	while true do
		for _, agent in ipairs(workspace:GetChildren()) do
			if agent:IsA("Model") and agent ~= bot then
				local agentTorso = agent:FindFirstChild("Torso")
				local agentHumanoid = agent:FindFirstChild("Humanoid")

				if agentTorso and agentHumanoid and agentHumanoid.Health > 0 then
					local distance = (agentTorso.Position - torso.Position).Magnitude

					if distance < 30 then
						-- Check for visual distress signals
						local agentChat = agent:FindFirstChild("BotChat", true)
						if agentChat then
							local chatText = agentChat:FindFirstChildOfClass("TextLabel") and agentChat:FindFirstChildOfClass("TextLabel").Text or ""
							if chatText:match("[Hh]elp") or chatText:match("[Cc]an't") then
								queueMessage("Detected help request", 2, 2, "positive")
								handleHelpRequest(agent, {
									checksum = 0,
									attempt = 1,
									error = "Autodetected need",
									timestamp = os.clock()
								})
							end
						end

						-- Check for stuck behavior
						local agentScript = agent:FindFirstChildWhichIsA("Script")
						if agentScript and agentScript.Name == "PuzzleAI" then
							local lastPosition = agentTorso.Position
							task.wait(5)
							if (agentTorso.Position - lastPosition).Magnitude < 2 then
								queueMessage("Detected stuck agent", 2, 2, "positive")
								handleHelpRequest(agent, {
									checksum = 0,
									attempt = 1,
									error = "Agent appears stuck",
									timestamp = os.clock()
								})
							end
						end
					end
				end
			end
		end

		task.wait(5)
	end
end

-- Main Communication Handler
local function handleIncomingMessage(sender, msgType, data)
	if msgType == MESSAGE_TYPES.HELP_REQUEST.id then
		handleHelpRequest(sender, data)
	elseif msgType == MESSAGE_TYPES.PROGRESS_UPDATE.id then
		-- Track progress for proactive assistance
		activeRequests[sender] = os.clock()
	elseif msgType == MESSAGE_TYPES.BUTTON_FEEDBACK.id then
		handleFeedback(sender, data)
	elseif msgType == MESSAGE_TYPES.ACKNOWLEDGMENT.id then
		return true
	elseif msgType == MESSAGE_TYPES.SOCIAL_SIGNAL.id then
		handleSocialSignal(sender, data)
	elseif msgType == MESSAGE_TYPES.ENCOURAGEMENT.id then
		handleEncouragement(sender, data)
	end
end

-- Initialization with Social Awareness
local function initialize()
	setAnimationState("idle")
	queueMessage("AssistanceAI Online", 3, 1, "positive")
	commChannel.Event:Connect(handleIncomingMessage)

	-- Start active monitoring systems
	task.spawn(scanForHelpRequests)
	task.spawn(monitorPuzzleAI)

	-- Check for nearby PuzzleAI
	local puzzleAI = workspace:FindFirstChild("PuzzleAI")
	if puzzleAI then
		local puzzleTorso = puzzleAI:FindFirstChild("Torso")
		if puzzleTorso and (torso.Position - puzzleTorso.Position).Magnitude < 20 then
			performSocialGesture("wave")
			AnimationSystem.socialCooldown = os.clock() + 10
		end
	end
end

initialize()



































