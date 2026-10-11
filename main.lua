-- スイカハブ (Rayfield版) + ネットワーク制御
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "スイカハブ | Suika Hub",
   LoadingTitle = "スイカハブ ロード中...",
   LoadingSubtitle = "by layer",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SuikaHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- サービス
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 制御用変数
local controlling = false
local targetRoot = nil
local controlConnection = nil

local function getRoot(char)
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
end

local function stopControl()
	controlling = false
	if controlConnection then
		controlConnection:Disconnect()
		controlConnection = nil
	end
	if targetRoot then
		pcall(function()
			targetRoot:SetNetworkOwner(nil)
		end)
	end
	targetRoot = nil
	Rayfield:Notify({
		Title = "スイカハブ",
		Content = "制御を解除しました",
		Duration = 3
	})
end

local function startControl(player)
	if controlling then stopControl() end
	if not player or not player.Character then return end

	local root = getRoot(player.Character)
	if not root then return end

	pcall(function()
		root:SetNetworkOwner(LocalPlayer)
	end)

	targetRoot = root
	controlling = true

	controlConnection = RunService.Heartbeat:Connect(function()
		if not controlling or not targetRoot or not targetRoot.Parent then
			stopControl()
			return
		end

		local myChar = LocalPlayer.Character
		if not myChar then return end
		local myRoot = getRoot(myChar)
		if not myRoot then return end

		local offset = myRoot.CFrame * CFrame.new(0, -1.1, -2.3)
		targetRoot.CFrame = offset
		targetRoot.AssemblyLinearVelocity = Vector3.zero
		targetRoot.AssemblyAngularVelocity = Vector3.zero
	end)

	Rayfield:Notify({
		Title = "スイカハブ",
		Content = player.Name .. " を制御開始",
		Duration = 3
	})
end

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateSection("Player")

MainTab:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedHack",
   Callback = function(Value)
      local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum.WalkSpeed = Value and 50 or 16
      end
   end,
})

MainTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum.WalkSpeed = Value
      end
   end,
})

MainTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 200},
   Increment = 1,
   Suffix = "Power",
   CurrentValue = 50,
   Flag = "JumpPower",
   Callback = function(Value)
      local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum.JumpPower = Value
      end
   end,
})

MainTab:CreateButton({
   Name = "Reset Character",
   Callback = function()
      if LocalPlayer.Character then
         LocalPlayer.Character:BreakJoints()
      end
   end,
})

-- Control Tab（新規追加）
local ControlTab = Window:CreateTab("制御", 4483362458)

ControlTab:CreateSection("ネットワーク制御")

-- プレイヤー選択用ドロップダウンを動的に更新
local playerNames = {}
local playerMap = {}

local function updatePlayerList()
	playerNames = {}
	playerMap = {}
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(playerNames, player.Name)
			playerMap[player.Name] = player
		end
	end
end

updatePlayerList()

local PlayerDropdown = ControlTab:CreateDropdown({
   Name = "プレイヤー選択",
   Options = playerNames,
   CurrentOption = {"なし"},
   MultipleOptions = false,
   Flag = "SelectedPlayer",
   Callback = function(Options)
      local name = Options[1]
      if name and playerMap[name] then
         startControl(playerMap[name])
      end
   end,
})

ControlTab:CreateButton({
   Name = "プレイヤーリスト更新",
   Callback = function()
      updatePlayerList()
      PlayerDropdown:Refresh(playerNames)
      Rayfield:Notify({
         Title = "スイカハブ",
         Content = "リストを更新しました",
         Duration = 2
      })
   end,
})

ControlTab:CreateButton({
   Name = "制御解除",
   Callback = function()
      stopControl()
   end,
})

ControlTab:CreateSection("説明")
ControlTab:CreateParagraph({
   Title = "使い方",
   Content = "1. プレイヤーリスト更新を押す\n2. ドロップダウンから相手を選ぶ\n3. 制御解除で止める\n※ネットワーク所有権を使ってるので他の人にも見える"
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
   Name = "Spawn",
   Callback = function()
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
      end
   end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateButton({
   Name = "Destroy UI",
   Callback = function()
      stopControl()
      Rayfield:Destroy()
   end,
})

-- プレイヤー出入りでリスト自動更新
Players.PlayerAdded:Connect(function()
	task.wait(0.5)
	updatePlayerList()
	pcall(function() PlayerDropdown:Refresh(playerNames) end)
end)

Players.PlayerRemoving:Connect(function()
	task.wait(0.5)
	updatePlayerList()
	pcall(function() PlayerDropdown:Refresh(playerNames) end)
end)

-- 設定読み込み
Rayfield:LoadConfiguration()

print("スイカハブ loaded")