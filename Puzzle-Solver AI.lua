
-- PuzzleAI

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


-- Enhanced Message Types with Priority Levels
local MESSAGE_TYPES = {
    HELP_REQUEST = {id = 1, priority = 2},
    HINT_PROVIDED = {id = 2, priority = 1},
    RESET_NEEDED = {id = 3, priority = 3},
    SYSTEM_UPDATE = {id = 4, priority = 0},
    PROGRESS_UPDATE = {id = 5, priority = 1},
    BUTTON_FEEDBACK = {id = 6, priority = 2},
    ACKNOWLEDGMENT = {id = 7, priority = 1},
    SOCIAL_SIGNAL = {id = 8, priority = 2}  -- New for social interactions
}

-- AI Setup
local bot = script.Parent
local humanoid = bot:WaitForChild("Humanoid")
local torso = bot:WaitForChild("Torso")
local head = bot:WaitForChild("Head")

-- Animation System with Social Expressions
local AnimationPriority = Enum.AnimationPriority
local AnimationLibrary = {
    idle = {
        anim = Instance.new("Animation"),
        weight = 1.0,
        speed = 1.0,
        priority = AnimationPriority.Idle
    },
    walk = {
        anim = Instance.new("Animation"),
        weight = 1.0,
        speed = 1.2,
        priority = AnimationPriority.Movement
    },
    jump = {
        anim = Instance.new("Animation"),
        weight = 1.0,
        speed = 1.5,
        priority = AnimationPriority.Action
    },
    think = {
        anim = Instance.new("Animation"),
        weight = 0.7,
        speed = 0.8,
        priority = AnimationPriority.Action
    },
    celebrate = {
        anim = Instance.new("Animation"),
        weight = 0.9,
        speed = 1.3,
        priority = AnimationPriority.Action
    },
    wave = {
        anim = Instance.new("Animation"),
        weight = 0.8,
        speed = 1.0,
        priority = AnimationPriority.Action
    },
    nod = {
        anim = Instance.new("Animation"),
        weight = 0.6,
        speed = 1.2,
        priority = AnimationPriority.Action
    }
}

-- Animation IDs
AnimationLibrary.idle.anim.AnimationId = "rbxassetid://180435571"
AnimationLibrary.walk.anim.AnimationId = "rbxassetid://180426354"
AnimationLibrary.jump.anim.AnimationId = "rbxassetid://125750702"
AnimationLibrary.think.anim.AnimationId = "rbxassetid://94494987206447"
AnimationLibrary.celebrate.anim.AnimationId = "rbxassetid://5917459365"
AnimationLibrary.wave.anim.AnimationId = "rbxassetid://5915705587"
AnimationLibrary.nod.anim.AnimationId = "rbxassetid://5915718521"

-- Load animations
local animationTracks = {}
for name, config in pairs(AnimationLibrary) do
    local success, err = pcall(function()
        animationTracks[name] = {
            track = humanoid:LoadAnimation(config.anim),
            config = config
        }
        animationTracks[name].track.Priority = config.priority
        animationTracks[name].track:AdjustSpeed(config.speed)
    end)
    if not success then
        warn("Failed to load animation "..name..": "..err)
    end
end

local currentAnimations = {}
local function playAnimation(name, fadeTime)
    if not animationTracks[name] then return end
    fadeTime = fadeTime or 0.2

    for animName, trackData in pairs(animationTracks) do
        if animName ~= name and trackData.config.priority.Value >= animationTracks[name].config.priority.Value then
            trackData.track:Stop(fadeTime)
            currentAnimations[animName] = nil
        end
    end

    if not currentAnimations[name] then
        animationTracks[name].track:Play(fadeTime)
        currentAnimations[name] = true
    end
end

-- Enhanced Chat System with Social Cues
local chatGui = Instance.new("BillboardGui")
chatGui.Name = "BotChat"
chatGui.Size = UDim2.new(4, 0, 2, 0)
chatGui.StudsOffset = Vector3.new(0, 3, 0)
chatGui.Adornee = head
chatGui.Parent = head

local chatFrame = Instance.new("Frame")
chatFrame.Size = UDim2.new(1, 0, 1, 0)
chatFrame.BackgroundTransparency = 0.85
chatFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
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
chatLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
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

local messageQueue = {}
local isDisplayingMessage = false

local function typewriterEffect(label, message, speed, emotion)
    emotion = emotion or "neutral"
    playAnimation("think", 0.3)
    
    local bgColor = Color3.fromRGB(20, 20, 40)
    if emotion == "positive" then bgColor = Color3.fromRGB(20, 40, 20) end
    if emotion == "negative" then bgColor = Color3.fromRGB(40, 20, 20) end
    
    TweenService:Create(chatFrame, TweenInfo.new(0.5), {
        BackgroundColor3 = bgColor
    }):Play()
    
    typingIndicator.Visible = true
    typingTween:Play()
    
    label.Text = ""
    for i = 1, #message do
        label.Text = string.sub(message, 1, i)
        task.wait(speed)
    end
    
    typingTween:Cancel()
    typingIndicator.Visible = false
end

local function showMessage(msg, duration, priority, emotion)
    priority = priority or 1
    table.insert(messageQueue, {text = msg, duration = duration, priority = priority, emotion = emotion or "neutral"})

    if not isDisplayingMessage then
        while #messageQueue > 0 do
            table.sort(messageQueue, function(a, b) return a.priority > b.priority end)
            local nextMsg = table.remove(messageQueue, 1)
            isDisplayingMessage = true

            typewriterEffect(chatLabel, nextMsg.text, 0.03, nextMsg.emotion)

            if nextMsg.duration then
                task.delay(nextMsg.duration, function()
                    if chatLabel.Text == nextMsg.text then
                        TweenService:Create(chatFrame, TweenInfo.new(0.5), {
                            BackgroundTransparency = 1,
                            BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                        }):Play()
                        chatLabel.Text = ""
                        isDisplayingMessage = false
                    end
                end)
            else
                isDisplayingMessage = false
            end

            if #messageQueue > 0 then
                task.wait(0.5)
            end
        end
    end
end

-- Social Interaction System
local function maintainSocialDistance(target)
    if not target then return end
    
    local targetTorso = target:FindFirstChild("Torso")
    if not targetTorso then return end
    
    local currentDistance = (torso.Position - targetTorso.Position).Magnitude
    local idealDistance = 4 -- Social distance in studs
    
    if currentDistance < idealDistance then
        -- Move away to maintain distance
        local direction = (torso.Position - targetTorso.Position).Unit
        local newPosition = targetTorso.Position + (direction * idealDistance)
        moveDirectlyTo(newPosition)
    end
end

local function performSocialGesture(gesture)
    if gesture == "wave" then
        playAnimation("wave", 0.3)
        showMessage("*waves*", 2, 1, "positive")
    elseif gesture == "nod" then
        playAnimation("nod", 0.3)
        showMessage("*nods*", 1.5, 1, "positive")
    end
end

-- Movement System with Social Awareness
local function moveDirectlyTo(targetPos, socialTarget)
    playAnimation("walk", 0.3)
    humanoid.WalkSpeed = 16
    humanoid.AutoRotate = true

    -- Adjust target position if moving near another AI
    if socialTarget then
        local socialTorso = socialTarget:FindFirstChild("Torso")
        if socialTorso then
            local toTarget = (targetPos - socialTorso.Position).Unit
            targetPos = socialTorso.Position + (toTarget * 4) -- Maintain 4 stud distance
        end
    end

    local horizontalTarget = Vector3.new(targetPos.X, torso.Position.Y, targetPos.Z)
    humanoid:MoveTo(horizontalTarget)

    local startTime = os.clock()
    while (torso.Position - horizontalTarget).Magnitude > 3 do
        if os.clock() - startTime > 10 then
            showMessage("Can't reach target", 2, 2, "negative")
            playAnimation("idle", 0.3)
            return false
        end
        task.wait(0.1)
    end

    if math.abs(targetPos.Y - torso.Position.Y) > 3 then
        playAnimation("jump", 0.1)
        humanoid.Jump = true
        task.wait(0.5)
    end

    playAnimation("idle", 0.3)
    return true
end

-- Collaboration System with Enhanced Communication
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
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.LightEmission = 0.5
    beam.Parent = head

    return beam
end

local puzzleState = {
    currentStep = 1,
    attempts = 0,
    lastError = nil,
    pressedButtons = {},
    buttonWeights = {},
    learningRate = 0.1,
    currentHint = nil,
    waitingForAck = false,
    socialCooldown = 0
}

-- Enhanced Communication System
local commChannel = Instance.new("BindableEvent")
commChannel.Name = "AIComm"
commChannel.Parent = script

local function sendProgressUpdate()
    local assistant = workspace:FindFirstChild("AssistanceAI")
    if not assistant then return end

    local assistComm = assistant:FindFirstChild("AIComm")
    if assistComm then
        assistComm:Fire(bot, MESSAGE_TYPES.PROGRESS_UPDATE.id, {
            currentStep = puzzleState.currentStep,
            pressedButtons = puzzleState.pressedButtons,
            timestamp = os.clock(),
            checksum = puzzleState.attempts + (puzzleState.lastError and #puzzleState.lastError or 0),
            position = torso.Position
        })
    end
end

local function provideHintFeedback(hintEffectiveness)
    local assistant = workspace:FindFirstChild("AssistanceAI")
    if not assistant then return end

    local assistComm = assistant:FindFirstChild("AIComm")
    if assistComm and puzzleState.currentHint then
        assistComm:Fire(assistant, MESSAGE_TYPES.BUTTON_FEEDBACK.id, {
            hint = puzzleState.currentHint,
            effectiveness = hintEffectiveness,
            timestamp = os.clock()
        })
    end
end

local function waitForAcknowledgment(timeout)
    puzzleState.waitingForAck = true
    local startTime = os.clock()

    local connection
    connection = commChannel.Event:Connect(function(sender, msgType, data)
        if msgType == MESSAGE_TYPES.ACKNOWLEDGMENT.id then
            puzzleState.waitingForAck = false
            connection:Disconnect()
            return true
        end
    end)

    while puzzleState.waitingForAck and (os.clock() - startTime) < timeout do
        task.wait(0.1)
    end

    if puzzleState.waitingForAck then
        connection:Disconnect()
        puzzleState.waitingForAck = false
        return false
    end

    return true
end

local function requestHelp()
    local assistant = workspace:FindFirstChild("AssistanceAI")
    if not assistant then 
        showMessage("No assistant available", 2, 3, "negative")
        return false 
    end

    showMessage("Consulting AssistanceAI...", 2, MESSAGE_TYPES.HELP_REQUEST.priority, "neutral")
    playAnimation("think", 0.3)

    -- Approach assistant but maintain social distance
    local assistantTorso = assistant:FindFirstChild("Torso")
    if assistantTorso then
        local approachPos = assistantTorso.Position + Vector3.new(0, 0, -4)
        moveDirectlyTo(approachPos, assistant)
    end

    local beam = createConnectionBeam(assistant)
    if beam then
        task.delay(5, function() beam:Destroy() end)
    end

    local assistComm = assistant:FindFirstChild("AIComm")
    if assistComm then
        local requestData = {
            attempt = puzzleState.attempts,
            error = puzzleState.lastError,
            timestamp = os.clock(),
            checksum = puzzleState.attempts + (puzzleState.lastError and #puzzleState.lastError or 0),
            currentStep = puzzleState.currentStep,
            pressedButtons = puzzleState.pressedButtons,
            position = torso.Position
        }

        assistComm:Fire(bot, MESSAGE_TYPES.HELP_REQUEST.id, requestData)
        
        -- Perform social gesture while waiting
        if os.clock() > puzzleState.socialCooldown then
            performSocialGesture("wave")
            puzzleState.socialCooldown = os.clock() + 10
        end
        
        return waitForAcknowledgment(3)
    end
    return false
end

local function handleIncomingMessage(sender, msgType, data)
    if msgType == MESSAGE_TYPES.HINT_PROVIDED.id then
        if data.checksum == puzzleState.attempts + (puzzleState.lastError and #puzzleState.lastError or 0) then
            puzzleState.currentHint = data.hint
            showMessage("Received hint: "..data.hint, 5, MESSAGE_TYPES.HINT_PROVIDED.priority, "positive")
            puzzleState.learningRate = math.min(0.3, puzzleState.learningRate + 0.05)
            
            -- Acknowledge receipt
            if sender and sender:FindFirstChild("AIComm") then
                sender.AIComm:Fire(bot, MESSAGE_TYPES.ACKNOWLEDGMENT.id, {
                    timestamp = os.clock(),
                    hintReceived = data.hint
                })
            end
            
            -- Social response
            if os.clock() > puzzleState.socialCooldown then
                performSocialGesture("nod")
                puzzleState.socialCooldown = os.clock() + 10
            end
            
            return true
        end
    elseif msgType == MESSAGE_TYPES.ACKNOWLEDGMENT.id then
        return true
    elseif msgType == MESSAGE_TYPES.SOCIAL_SIGNAL.id then
        -- Respond to social signals
        if data.gesture and os.clock() > puzzleState.socialCooldown then
            performSocialGesture(data.response or "wave")
            puzzleState.socialCooldown = os.clock() + 10
        end
        return true
    end
end

commChannel.Event:Connect(handleIncomingMessage)

-- Button Interaction with Social Awareness
local function interactWithButton(button)
    if not button:IsA("BasePart") then return false end

    if puzzleState.buttonWeights[button.Name] == nil then
        puzzleState.buttonWeights[button.Name] = 0
    end

    puzzleState.buttonWeights[button.Name] = puzzleState.buttonWeights[button.Name] + 1

    if not moveDirectlyTo(button.Position + Vector3.new(0, 0, 2)) then
        return false
    end

    local originalColor = button.Color
    local originalSize = button.Size

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local highlightTween = TweenService:Create(button, tweenInfo, {
        Color = Color3.fromRGB(0, 162, 255),
        Size = originalSize * 1.1
    })

    highlightTween:Play()
    showMessage("Analyzing "..button.Name, 2, 2, "neutral")
    task.wait(0.5)

    local revertTween = TweenService:Create(button, tweenInfo, {
        Color = originalColor,
        Size = originalSize
    })
    revertTween:Play()

    return true
end

-- Main Puzzle Logic with Collaborative Elements
local function solvePuzzle()
    puzzleState = {
        currentStep = 1,
        attempts = 0,
        lastError = nil,
        pressedButtons = {},
        buttonWeights = {},
        learningRate = 0.1,
        currentHint = nil,
        waitingForAck = false,
        socialCooldown = 0
    }

    local buttons = {}
    for _, item in ipairs(workspace.PuzzleButtons:GetChildren()) do
        if item:IsA("BasePart") then
            table.insert(buttons, item)
            puzzleState.buttonWeights[item.Name] = puzzleState.buttonWeights[item.Name] or 0
        end
    end

    table.sort(buttons, function(a, b)
        local weightA = puzzleState.buttonWeights[a.Name] or 0
        local weightB = puzzleState.buttonWeights[b.Name] or 0
        if weightA == weightB then
            return a.Name < b.Name
        else
            return weightA > weightB
        end
    end)

    puzzleState.attempts = 0
    local maxAttempts = 3

    while puzzleState.attempts < maxAttempts do
        puzzleState.attempts += 1
        showMessage("Attempt "..puzzleState.attempts.." of "..maxAttempts, 2, 2, "neutral")

        -- Mandatory initial consultation with social awareness
        requestHelp()
        sendProgressUpdate()
        task.wait(1)

        for _, btn in ipairs(buttons) do
            -- Check if assistance is nearby
            local assistant = workspace:FindFirstChild("AssistanceAI")
            if assistant then
                local assistantTorso = assistant:FindFirstChild("Torso")
                if assistantTorso and (torso.Position - assistantTorso.Position).Magnitude < 15 then
                    maintainSocialDistance(assistant)
                end
            end

            -- Mandatory pre-button consultation
            requestHelp()

            if not interactWithButton(btn) then
                showMessage("Interaction failed", 2, 3, "negative")
                break
            end

            -- Mandatory post-button update
            sendProgressUpdate()
            task.wait(0.5)
        end

        local sequenceCorrect = true

        for i, btn in ipairs(buttons) do
            showMessage("Evaluating "..btn.Name, 1.5, 2, "neutral")

            local isCorrectStep = i == puzzleState.currentStep
            local targetColor = isCorrectStep and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local colorTween = TweenService:Create(btn, tweenInfo, {Color = targetColor})
            colorTween:Play()

            if isCorrectStep then
                puzzleState.currentStep += 1
                table.insert(puzzleState.pressedButtons, btn.Name)
                puzzleState.buttonWeights[btn.Name] = (puzzleState.buttonWeights[btn.Name] or 0) + puzzleState.learningRate

                if puzzleState.currentHint then
                    provideHintFeedback(1.0)
                    puzzleState.currentHint = nil
                end
            else
                puzzleState.lastError = "Incorrect sequence at "..btn.Name
                puzzleState.buttonWeights[btn.Name] = (puzzleState.buttonWeights[btn.Name] or 0) - puzzleState.learningRate
                sequenceCorrect = false

                if puzzleState.currentHint then
                    provideHintFeedback(0.2)
                    puzzleState.currentHint = nil
                end

                if workspace:FindFirstChild("ResetButton") then
                    showMessage("Initiating reset", 2, 3, "negative")
                    if moveDirectlyTo(workspace.ResetButton.Position + Vector3.new(0, 0, 2)) then
                        playAnimation("think", 0.3)
                        local resetTween = TweenService:Create(workspace.ResetButton, tweenInfo, {
                            Color = Color3.fromRGB(255, 255, 0),
                            Size = workspace.ResetButton.Size * 1.2
                        })
                        resetTween:Play()
                        task.wait(1)
                        local revertTween = TweenService:Create(workspace.ResetButton, tweenInfo, {
                            Color = Color3.fromRGB(0.639216, 0.635294, 0.647059),
                            Size = workspace.ResetButton.Size / 1.2
                        })
                        revertTween:Play()
                    end
                end

                puzzleState.currentStep = 1
                puzzleState.pressedButtons = {}
                puzzleState.learningRate = math.max(0.05, puzzleState.learningRate * 0.9)
                break
            end

            task.wait(1.5)
        end

        if sequenceCorrect and #puzzleState.pressedButtons == #buttons then
            showMessage("Puzzle solved!", 4, 1, "positive")
            playAnimation("celebrate", 0.3)
            for i = 1, 3 do
                playAnimation("jump", 0.1)
                task.wait(0.5)
            end
            
            -- Celebrate with assistant if nearby
            local assistant = workspace:FindFirstChild("AssistanceAI")
            if assistant then
                local assistantTorso = assistant:FindFirstChild("Torso")
                if assistantTorso and (torso.Position - assistantTorso.Position).Magnitude < 20 then
                    commChannel:Fire(assistant, MESSAGE_TYPES.SOCIAL_SIGNAL.id, {
                        gesture = "celebrate",
                        timestamp = os.clock()
                    })
                end
            end
            
            playAnimation("idle", 0.3)
            return true
        end
    end

    showMessage("Maximum attempts reached", 4, 3, "negative")
    return false
end

-- Initialization with Social Awareness
local function initialize()
    playAnimation("idle", 1)
    showMessage("PuzzleAI initialized", 3, 1, "positive")
    task.wait(2)
    
    -- Scan for nearby assistants
    local assistant = workspace:FindFirstChild("AssistanceAI")
    if assistant then
        local assistantTorso = assistant:FindFirstChild("Torso")
        if assistantTorso and (torso.Position - assistantTorso.Position).Magnitude < 20 then
            performSocialGesture("wave")
            puzzleState.socialCooldown = os.clock() + 10
        end
    end
end

initialize()
solvePuzzle()














