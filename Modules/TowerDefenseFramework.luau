--!strict

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Framework = {}

Framework.Enemies = {} :: {Enemy}
Framework.Towers = {} :: {Tower}
Framework.Health = 100

export type Wave = {
	{
		Type: string,
		Amount: number,
		Wait: number,
		EndWaitModifier: number,
	}
}

export type TowerData = {
	Name: string,
	MaxLevel: number,
	CostPerLevel: {number},
	DamagePerLevel: {number},
	RangePerLevel: {number},
	AttackSpeedPerLevel: {number},
	BaseModel: Model,
}

export type Tower = {
	ID: number,
	Model: Model,
	TowerData: TowerData,
	Level: number,
	Attack: (Tower, Target: Enemy) -> (),
	FindTarget: (Tower, targetType: string) -> Enemy?,
}

export type Enemy = {
	ID: number,
	Model: Model,
	EnemyData: EnemyData,
	Health: number,
	SpawnTime: number,
	TakeDamage: (Enemy, Amount: number) -> (),
	Remove: (Enemy) -> (),
	Die: (Enemy, Instant: boolean?) -> (),
	ConnectToDeath: (Enemy, CallBack: () -> any) -> (),
	GetDistanceOnPath: (Enemy) -> number,
}

export type EnemyData = {
	Name: string,
	Type: string,
	Damage: number,
	Health: number,
	Speed: number,
	BaseModel: Model,
}

local HealthChangedListeners = {}

function Framework:ConnectToHealthCanged(callBack: (...any) -> any)
	table.insert(HealthChangedListeners, callBack)
end

function Framework.NewTower(Name: string, Frame: CFrame) : Tower

	local Data = require(ServerStorage:WaitForChild("Towers"):FindFirstChild(Name)) :: TowerData

	local newTower = {} :: Tower
	newTower.ID = #Framework.Towers
	newTower.Model = Data.BaseModel:Clone()
	newTower.Model.Parent = workspace
	local _, Size = newTower.Model:GetBoundingBox()
	newTower.Model:PivotTo(Frame + Vector3.new(0, Size.Y/2, 0))
	newTower.TowerData = Data
	newTower.Level = 1

	function newTower:Attack(Target: Enemy)
		Target:TakeDamage(newTower.TowerData.DamagePerLevel[self.Level])
		if not (self.Model.PrimaryPart and Target.Model.PrimaryPart) then error("No Humanoid Roots") end
		local CFrameValue = Instance.new("CFrameValue")
		CFrameValue.Value = self.Model.PrimaryPart.CFrame
		local tween = TweenService:Create(CFrameValue, TweenInfo.new(0.25), {["Value"] = CFrame.lookAt(self.Model.PrimaryPart.Position, Target.Model.PrimaryPart.Position * Vector3.new(1, 0, 1) + self.Model.PrimaryPart.Position * Vector3.new(0, 1, 0))})
		tween:Play()
		CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
			self.Model:PivotTo(CFrameValue.Value)
		end)
	end

	function newTower:FindTarget(targetType: string) : Enemy?
		local target
		local farthest = 0
		if targetType == "Farthest" then
			for _,enemy in Framework.Enemies do
				if enemy.Health <= 0 then continue end
				if not(enemy.Model.PrimaryPart) or not(self.Model.PrimaryPart) then continue end
				if ((enemy.Model.PrimaryPart.Position - self.Model.PrimaryPart.Position).Magnitude > self.TowerData.RangePerLevel[self.Level]) then continue end
				if enemy:GetDistanceOnPath() > farthest then
					target = enemy
					farthest = enemy:GetDistanceOnPath()
				end
			end
		end
		return target
	end

	Framework.Towers[newTower.ID] = newTower

	task.defer(function()
		while true do
			task.wait()
			local Closest = newTower:FindTarget("Farthest")
			if not Closest then continue end
			newTower:Attack(Closest)
			task.wait(1/newTower.TowerData.AttackSpeedPerLevel[newTower.Level])
		end
	end)

	return newTower
end

function Framework.SpawnEnemy(Name: string) : Enemy

	local Module = ServerStorage:WaitForChild("Enemies"):FindFirstChild(Name)

	if not Module then error("Enemy: '"..Name.."' Doesn't Exist") end

	local Data = require(Module) :: EnemyData

	local newEnemy = {} :: Enemy
	newEnemy.Model = Data.BaseModel:Clone()
	local _, Size = newEnemy.Model:GetBoundingBox()
	newEnemy.Model:PivotTo(workspace:WaitForChild("Path").Start.CFrame + Vector3.new(0, Size.Y/2, 0))
	newEnemy.Model.Parent = workspace
	newEnemy.EnemyData = Data
	newEnemy.ID = #Framework.Enemies + 1
	newEnemy.SpawnTime = tick()
	newEnemy.Health = Data.Health

	-- USED THE CODIFY PLUGIN TO CONVERT PREMADE UI TO CODE

	local BillboardGui = Instance.new("BillboardGui")
	BillboardGui.Active = true
	BillboardGui.Size = UDim2.new(5.00, 0.00, 1.00, 0.00)
	BillboardGui.ClipsDescendants = true
	BillboardGui.MaxDistance = 30
	BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	BillboardGui.StudsOffset = Vector3.new(0.00, 1.50, 0.00)

	local Frame = Instance.new("Frame")
	Frame.AnchorPoint = Vector2.new(0.50, 0.50)
	Frame.Size = UDim2.new(1.00, -6.00, 1.00, -6.00)
	Frame.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
	Frame.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = Color3.new(1.00, 0.22, 0.22)
	Frame.Parent = BillboardGui

	local UIStroke = Instance.new("UIStroke")
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Thickness = 3
	UIStroke.Parent = Frame

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0.10, 0.00)
	UICorner.Parent = Frame

	local CanvasGroup = Instance.new("CanvasGroup")
	CanvasGroup.BorderSizePixel = 0
	CanvasGroup.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
	CanvasGroup.AnchorPoint = Vector2.new(0.00, 0.50)
	CanvasGroup.Size = UDim2.new(1.00, 0.00, 1.00, 0.00)
	CanvasGroup.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
	CanvasGroup.GroupColor3 = Color3.new(0.22, 1.00, 0.22)
	CanvasGroup.BackgroundTransparency = 1
	CanvasGroup.Position = UDim2.new(0.00, 0.00, 0.50, 0.00)
	CanvasGroup.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Name = "Bar"
	Bar.Size = UDim2.new(0.50, 0.00, 1.00, 0.00)
	Bar.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
	Bar.BorderSizePixel = 0
	Bar.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
	Bar.Parent = CanvasGroup

	local UICorner_1 = Instance.new("UICorner")
	UICorner_1.CornerRadius = UDim.new(0.10, 0.00)
	UICorner_1.Parent = CanvasGroup

	local TextDisplay = Instance.new("TextLabel")
	TextDisplay.Name = "TextDisplay"
	TextDisplay.TextWrapped = true
	TextDisplay.BorderSizePixel = 0
	TextDisplay.TextScaled = true
	TextDisplay.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
	TextDisplay.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	TextDisplay.TextSize = 14
	TextDisplay.Size = UDim2.new(1.00, 0.00, 1.00, 0.00)
	TextDisplay.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
	TextDisplay.Text = "4/4"
	TextDisplay.TextColor3 = Color3.new(1.00, 1.00, 1.00)
	TextDisplay.BackgroundTransparency = 1
	TextDisplay.Parent = Frame

	local UIStroke_1 = Instance.new("UIStroke")
	UIStroke_1.Thickness = 3
	UIStroke_1.Parent = TextDisplay

	-- CODIFY PLUGIN END

	BillboardGui.Parent = newEnemy.Model:FindFirstChild("Head")
	BillboardGui.Enabled = false
	
	for _,V in newEnemy.Model:GetDescendants() do
		if V:IsA("BasePart") then
			V:SetNetworkOwner(nil)
		end
	end 

	local Humanoid = newEnemy.Model:FindFirstChildOfClass("Humanoid")
	if not Humanoid then error("Enemy has no humanoid") end
	Humanoid.WalkSpeed = Data.Speed
	Humanoid:MoveTo(workspace.Path.End.Position)

	Framework.Enemies[newEnemy.ID] = newEnemy
	local DeathListeners = {} :: {() -> any}

	function newEnemy:TakeDamage(Damage: number)
		self.Health -= Damage -- TODO: add logic for armor and damage modifiers
		self.Health = math.clamp(self.Health, 0, self.EnemyData.Health)
		BillboardGui.Enabled = true
		TextDisplay.Text = self.Health.."/"..self.EnemyData.Health
		local Tween = TweenService:Create(Bar, TweenInfo.new(0.15), {["Size"] = UDim2.fromScale(self.Health/self.EnemyData.Health, 1)})
		Tween:Play()
		if self.Health <= 0 then
			local deathtask = coroutine.wrap(self.Die)
			deathtask(self)
		end
	end

	function newEnemy:Die(Instant: boolean?)
		local Instant = Instant or false
		for _,callBack in DeathListeners do
			callBack()
		end
		if Instant then
			self.Model:Destroy()
			Framework.Enemies[self.ID] = nil
			return
		end
		Framework.Enemies[self.ID] = nil
		for _,V in self.Model:GetDescendants() do
			if V:IsA("BasePart") then
				V.Anchored = true
				V.CanTouch = false
				V.CanQuery = false
				local Tween = TweenService:Create(V, TweenInfo.new(1), {["Transparency"] = 1, ["Size"] = V.Size * 0.8})
				Tween:Play()
			elseif V:IsA("SpecialMesh") then
				continue
			elseif V:IsA("Humanoid") then
				V.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				V.DisplayName = ""
			else
				V:Destroy()
			end
		end
		task.wait(1.1)
		self.Model:Destroy()
	end

	function newEnemy:ConnectToDeath(callBack: () -> any)
		table.insert(DeathListeners, callBack)
	end

	function newEnemy:GetDistanceOnPath()
		return (tick() - self.SpawnTime) * self.EnemyData.Speed
	end

	task.defer(function()
		while true do
			if newEnemy.Model.PrimaryPart and (newEnemy.Model.PrimaryPart.Position - workspace.Path.End.Position).Magnitude < 2.75 then
				Framework.Health -= newEnemy.Health
				for _,CallBack in HealthChangedListeners do
					CallBack()
				end
				newEnemy:Die(true)
			end
			task.wait()
			local Humanoid = newEnemy.Model:FindFirstChildOfClass("Humanoid")
			if not Humanoid then continue end
			Humanoid:MoveTo(workspace.Path.End.Position)
		end
	end)

	return newEnemy

end

function Framework:GetClosestEnemy() : Enemy?
	local MaxDistance = 0
	local farthest = nil
	for _,Enemy in self.Enemies do
		local distance = Enemy:GetDistanceOnPath()
		if distance > MaxDistance then
			MaxDistance = distance
			farthest = Enemy
		end
	end
	return farthest
end

function Framework:SpawnWave(wave: Wave)
	coroutine.wrap(function()
		for _,WaveSection in wave do
			coroutine.wrap(function()
				for i = 1, WaveSection.Amount do
					local Enemy = Framework.SpawnEnemy(WaveSection.Type)
					task.wait(WaveSection.Wait)
				end
			end)()
			task.wait((WaveSection.Amount * WaveSection.Wait) + WaveSection.EndWaitModifier)
		end
	end)()
end

return Framework
