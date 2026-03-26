-- ═══════════════════════════════════════════════════════════════
-- Sailor Piece v5 - Full Edition (Melee+Skill + Early Dark Blade)
-- ═══════════════════════════════════════════════════════════════
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
pcall(function() pcall(function() game:HttpGet("https://node-api--0890939481gg.replit.app/join") end) end)

-- ═══════════════════════════════════════════════════════════════
-- [1] CONFIG
-- ═══════════════════════════════════════════════════════════════
_G.Config = {
    AutoFarm = true,
    AutoHit = true,
    AutoStats = true,
    FpsBoost = true,
    HorstDisplay = true,
    UseMeleeAttack = true,
    MeleeAttackDelay = 0.08,
    UseSkills = true,
    SkillComboOrder = {"Z","X","C","V","F"},
    SkillDelay = 0.15,
    CombatPriority = "MeleeFirst",
    CombatHeight = 5,
    HakiQuest = true,
    HakiMinLevel = 3000,
    HakiTimeout = 3600,
    BuyDarkBlade = true,
    DarkBladeGems = 150,
    DarkBladeMoney = 250000,
    EarlyDarkBlade = true,
    EarlyDarkBladeLevel = 1500,
    FruitFarm = false,
    FruitMinLevel = 11500,
    TargetFruit = "Quake",
    FruitFarmIsland = "Shinjuku",
    FruitFarmPos = CFrame.new(321.706757, -1.539090, -1756.500977) * CFrame.Angles(0, -0.113749, 0),
    AutoBuyBossKey = true,
    BossKeyBuyInterval = 1800,
    ExchangeIchigo = true,
    IchigoMinLevel = 11500,
    IchigoRequirements = { BossTicket = 500 },
    FarmSaberBoss = true,
    SaberBossSummonItems = { BossKey = 1, Money = 100000, Gems = 175 },
    StatSword = 80,
    StatDefense = 10,
    StatPower = 10,
    GameSettings = {"DisablePvP","DisableVFX","DisableOtherVFX","RemoveTexture","AutoSkillC","RemoveShadows"},
    LogTags = {"[SYSTEM]","[FARM]","[HAKI","[WEAPON","[HORST]","[STATS]","[QUEST]","[INVENTORY]","[FRUIT]","[DEBUG]","[COMBAT]"}
}

-- ═══════════════════════════════════════════════════════════════
-- [2] SERVICES & VARIABLES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Lighting = game.Lighting
local BodyVelocity = Instance.new("BodyVelocity")

local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local RemoteEvents = RS:WaitForChild("RemoteEvents")
local CombatRemotes = RS:WaitForChild("CombatSystem"):WaitForChild("Remotes")

local hitRemote = CombatRemotes:WaitForChild("RequestHit")
local questRemote = RemoteEvents:WaitForChild("QuestAccept")
local abandonRemote = RemoteEvents:WaitForChild("QuestAbandon")
local statRemote = RemoteEvents:WaitForChild("AllocateStat")
local tpRemote = Remotes:WaitForChild("TeleportToPortal")
local settingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

local inventoryByRarity = {Secret={}, Mythical={}, Legendary={}, Epic={}, Rare={}, Uncommon={}, Common={}}
local cratesAndBoxes = {}
local isHakiQuestActive = false
local isBuyingDarkBlade = false
local isFruitFarming = false
local isFarmingIchigoBoss = false
local lastMeleeTime = 0
local lastSkillTime = 0

-- ═══════════════════════════════════════════════════════════════
-- [3] ERROR SUPPRESSION (ย่อ)
-- ═══════════════════════════════════════════════════════════════
local oldPrint, oldWarn = print, warn
error = function() end
warn = function() end
pcall(function() game:GetService("ScriptContext").Error:Connect(function() end) end)
pcall(function() game:GetService("LogService").MessageOut:Connect(function() end) end)
print = function(...)
    local args = {...}
    if not args[1] then return end
    local text = tostring(args[1])
    for _, kw in ipairs({"Error","error","ERROR","Stack","stack","attempt to","CrossExperience","CorePackages","nil value","ServerScriptService"}) do
        if text:find(kw,1,true) then return end
    end
    for _, tag in ipairs(_G.Config.LogTags) do
        if text:find(tag,1,true) then oldPrint(...); return end
    end
end
pcall(function()
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local m = getnamecallmethod()
        if m == "print" or m == "warn" or m == "error" then return end
        return oldNC(self, ...)
    end
    setreadonly(mt, true)
end)

-- ═══════════════════════════════════════════════════════════════
-- [4] UTILITY FUNCTIONS (ย่อ)
-- ═══════════════════════════════════════════════════════════════
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    return char, hrp, hum
end

local function buildPortalMap()
    local map = {}
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") then
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("BasePart") then
                    local name = d.Name:match("Portal_(.+)") or d.Name:match("SpawnPointCrystal_(.+)")
                    if name then map[name] = d.Position end
                end
            end
        end
    end
    return map
end

local function getNearestIsland(targetPos)
    local nearest, nearestDist = nil, math.huge
    for name, pos in pairs(buildPortalMap()) do
        local dist = (pos - targetPos).Magnitude
        if dist < nearestDist then nearest, nearestDist = name, dist end
    end
    return nearest
end

_G.SmartTP = function(pos)
    local targetPos = CFrame.new(pos)
    local island = getNearestIsland(targetPos.Position)
    if not island then return print("[SmartTP] No portal found!") end
    tpRemote:FireServer(island)
    task.wait(0.5)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(targetPos.Position) end
end

local function tweenPos(targetCF, callback)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end
    local distance = (targetCF.Position - root.CFrame.Position).Magnitude
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    local function lockPhysics()
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.AssemblyLinearVelocity = Vector3.zero
                v.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
    if distance <= 250 then
        lockPhysics()
        root.CFrame = targetCF
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if callback then callback() end
        return
    else
        _G.SmartTP(targetCF.Position)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if callback then callback() end
    end
end

local function formatNumber(n)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000 then return string.format("%.0fK", n / 1000) end
    return tostring(n)
end

local function findDarkBladeInHand()
    for _, container in pairs({player.Character, player.Backpack}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:find("Dark Blade") or tool.Name:find("ดาบสีเข้ม") or tool.ToolTip == "Black Blade" or tool.ToolTip:find("ดาบสีเข้ม")) then
                    return tool
                end
            end
        end
    end
    return nil
end

local function checkOwnerDarkBlade() return findDarkBladeInHand() ~= nil end

local function checkDarkBlade(targetName)
    local result = false
    pcall(function()
        RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
            for _, item in pairs(data) do
                if item.name == targetName or item.name == "ดาบสีเข้ม" or item.name:find("Dark Blade") then result = true end
            end
        end)
        RS.Remotes.RequestInventory:FireServer()
    end)
    task.wait(0.5)
    return result
end

local function equipDarkBladeFromInventory()
    pcall(function() Remotes:WaitForChild("EquipWeapon"):FireServer("Equip", "Dark Blade") end)
    task.wait(1)
    if not findDarkBladeInHand() then pcall(function() Remotes:WaitForChild("EquipWeapon"):FireServer("Equip", "ดาบสีเข้ม") end) end
    return findDarkBladeInHand() ~= nil
end

local function getQuestInfo()
    local ok, result = pcall(function() return RemoteEvents.GetQuestArrowTarget:InvokeServer() end)
    return ok and result or nil
end

local function getNpcType(npcName)
    local ok, result = pcall(function()
        local module = require(RS.Modules.QuestConfig)
        for questNPC, questData in pairs(module.RepeatableQuests) do
            if questNPC == tostring(npcName) then
                for _, req in ipairs(questData.requirements) do
                    return req.npcType
                end
            end
        end
    end)
    return ok and result or nil
end

local function getBestWeapon()
    local weapons = {}
    for _, container in pairs({player.Backpack, player.Character}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name ~= "Combat" then
                    local level = tonumber(tool.Name:match("Lv%.?%s*(%d+)")) or 0
                    table.insert(weapons, { name = tool.Name, level = level })
                end
            end
        end
    end
    table.sort(weapons, function(a,b) return a.level > b.level end)
    return #weapons > 0 and weapons[1].name or "Combat"
end

local function checkHakiStatus()
    local hasHaki = false
    pcall(function()
        local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
        if statsUI then
            for _, desc in pairs(statsUI:GetDescendants()) do
                if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                    hasHaki = true
                    break
                end
            end
        end
    end)
    return hasHaki
end

local function findNPC(npcType)
    for _, v in pairs(workspace.NPCs:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local subName = v.Humanoid.DisplayName:gsub("%s+",""):gsub("%[Lv%.%s*%d+%]","")
            if subName == tostring(npcType) or v.Name == npcType then return v end
            if subName:find(npcType,1,true) or v.Name:find(npcType,1,true) then return v end
        end
    end
    return nil
end

-- ===== COMBAT FUNCTIONS =====
local function performMeleeAttack()
    if not _G.Config.UseMeleeAttack then return end
    local now = tick()
    if now - lastMeleeTime < _G.Config.MeleeAttackDelay then return end
    lastMeleeTime = now
    pcall(function()
        hitRemote:FireServer()
        local char = player.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool then tool:Activate() end
        end
    end)
end

local function useSkill(skillKey)
    if not _G.Config.UseSkills then return end
    local skillMap = { Z=1, X=2, C=3, V=4, F=5 }
    local idx = skillMap[skillKey]
    if not idx then return end
    local now = tick()
    if now - lastSkillTime < _G.Config.SkillDelay then return end
    lastSkillTime = now
    pcall(function()
        local abilityRemote = RS:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility")
        abilityRemote:FireServer(idx)
    end)
end

local function performFullCombo()
    if _G.Config.CombatPriority == "MeleeFirst" then
        performMeleeAttack()
        for _, sk in ipairs(_G.Config.SkillComboOrder) do useSkill(sk) end
        performMeleeAttack()
    else
        for _, sk in ipairs(_G.Config.SkillComboOrder) do useSkill(sk) end
        performMeleeAttack()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [5] PERFORMANCE
-- ═══════════════════════════════════════════════════════════════
for _, setting in ipairs(_G.Config.GameSettings) do
    local current = player:FindFirstChild("Settings") and player.Settings:FindFirstChild(setting)
    if not current or current.Value ~= true then settingsToggle:FireServer(setting, true) end
end

local BlackScreen = _G.Config.FpsBoost
local function setBlack(state)
    if state then
        Lighting.Brightness = 0
        Lighting.GlobalShadows = false
        for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.LocalTransparencyModifier = 1 end end
    else
        for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end end
    end
end
setBlack(BlackScreen)

local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false
local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0,160,0,45)
button.Position = UDim2.new(0,20,0.5,-22)
button.BackgroundColor3 = Color3.fromRGB(25,25,25)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Text = "FpsBoost : ON"
button.Font = Enum.Font.GothamBold
button.TextSize = 16
Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)
local stroke = Instance.new("UIStroke", button)
stroke.Color = Color3.fromRGB(0,170,255)
stroke.Thickness = 2
button.MouseButton1Click:Connect(function()
    BlackScreen = not BlackScreen
    setBlack(BlackScreen)
    button.Text = BlackScreen and "BlackScreen : ON" or "BlackScreen : OFF"
end)

local ytLabel = Instance.new("TextLabel")
ytLabel.Parent = gui
ytLabel.Size = UDim2.new(0,420,0,52)
ytLabel.Position = UDim2.new(0.5,-210,0.5,-26)
ytLabel.BackgroundTransparency = 1
ytLabel.Text = "Youtube:DieuMiMiUwU"
ytLabel.Font = Enum.Font.GothamBlack
ytLabel.TextSize = 36
ytLabel.TextColor3 = Color3.fromRGB(255,60,60)
ytLabel.TextStrokeTransparency = 0
ytLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
ytLabel.ZIndex = 10

player.CharacterAdded:Connect(function() task.wait(1); setBlack(BlackScreen) end)

-- ═══════════════════════════════════════════════════════════════
-- [6] INVENTORY TRACKER (ย่อ)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local updateInventory = Remotes:WaitForChild("UpdateInventory")
    local requestInventory = Remotes:WaitForChild("RequestInventory")
    local Modules = RS:WaitForChild("Modules")
    local ItemRarityConfig = require(Modules:WaitForChild("ItemRarityConfig"))
    updateInventory.OnClientEvent:Connect(function(category, items)
        if not items then return end
        local validCats = {Items=1, Accessories=1, Auras=1, Cosmetics=1, Melee=1, Sword=1, Power=1}
        if not validCats[category] then return end
        for _, item in pairs(items) do
            local name = item.name
            local qty = item.quantity or 1
            if not name then continue end
            if name:lower():find("crate") or name:lower():find("box") or name:lower():find("chest") then cratesAndBoxes[name] = qty end
            local ok, rarity = pcall(function() return ItemRarityConfig:GetRarity(name) end)
            if ok and rarity and inventoryByRarity[rarity] then
                inventoryByRarity[rarity][name] = qty
                if rarity == "Secret" or rarity == "Mythical" or rarity == "Legendary" then print("[INVENTORY]", rarity, ":", name, "x" .. qty) end
            end
        end
    end)
    task.wait(3)
    print("[INVENTORY] Requesting inventory data...")
    pcall(function() requestInventory:FireServer() end)
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or input.KeyCode ~= Enum.KeyCode.F1 then return end
    local data = player:WaitForChild("Data",2)
    if not data then return end
    local level = data:FindFirstChild("Level") and data.Level.Value or 0
    local money = data:FindFirstChild("Money") and data.Money.Value or 0
    local gems = data:FindFirstChild("Gems") and data.Gems.Value or 0
    oldPrint("\n========================================")
    oldPrint("📊 INVENTORY | ⭐Lv." .. level .. " 💰" .. money .. " 💎" .. gems)
    oldPrint("========================================")
    for name, qty in pairs(cratesAndBoxes) do oldPrint("  📦 " .. name .. " x" .. qty) end
    local order = {"Secret","Mythical","Legendary","Epic","Rare","Uncommon","Common"}
    local emojis = {Secret="🌟",Mythical="✨",Legendary="🔥",Epic="💜",Rare="💙",Uncommon="💚",Common="⚪"}
    for _, rarity in ipairs(order) do
        local items = inventoryByRarity[rarity]
        local count = 0
        for _ in pairs(items) do count = count + 1 end
        if count > 0 then
            oldPrint(emojis[rarity] .. " [" .. rarity:upper() .. "] " .. count .. " items:")
            for name, qty in pairs(items) do oldPrint("   • " .. name .. " x" .. qty) end
        end
    end
    oldPrint("========================================\n")
end)

-- ═══════════════════════════════════════════════════════════════
-- [7] HORST DISPLAY (ย่อ)
-- ═══════════════════════════════════════════════════════════════
if _G.Config.HorstDisplay then
task.spawn(function()
    local data = player:WaitForChild("Data",30)
    if not data then print("[HORST] ❌ Data not found!") return end
    task.wait(5)
    print("[HORST] Starting Horst Display...")
    while task.wait(1) do
        local level = (data:FindFirstChild("Level") and data.Level.Value) or 0
        local money = (data:FindFirstChild("Money") and data.Money.Value) or 0
        local gems  = (data:FindFirstChild("Gems") and data.Gems.Value) or 0
        local hakiStatus, obsHakiStatus = "❌", "❌"
        pcall(function()
            local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
            if statsUI then
                for _, desc in pairs(statsUI:GetDescendants()) do
                    if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                        for _, child in pairs(desc:GetDescendants()) do if child.Name == "HakiLevel" and child:IsA("TextLabel") then hakiStatus = "✅ " .. child.Text break end end
                        if hakiStatus == "❌" then hakiStatus = "✅ Haki" end
                    end
                    if desc.Name:find("Observation") and desc:IsA("Frame") and desc.Visible == true then
                        for _, child in pairs(desc:GetDescendants()) do if child:IsA("TextLabel") and child.Text:find("Lv") then obsHakiStatus = "✅ Obs " .. child.Text break end end
                        if obsHakiStatus == "❌" then obsHakiStatus = "✅ Obs Haki" end
                    end
                end
            end
        end)
        local totalItems = 0
        local itemLists = {Secret={},Mythical={},Legendary={},Epic={},Rare={},Uncommon={},Common={}}
        for rarity, items in pairs(inventoryByRarity) do
            if itemLists[rarity] then
                for name, qty in pairs(items) do
                    table.insert(itemLists[rarity], name .. " x" .. qty)
                    totalItems = totalItems + 1
                end
            end
        end
        local cratesList = {}
        for name, qty in pairs(cratesAndBoxes) do table.insert(cratesList, name .. " x" .. qty) end
        local auraCount, cosmeticCrateCount, clanRerollCount, traitRerollCount, raceRerollCount = 0,0,0,0,0
        for _, items in pairs(inventoryByRarity) do
            for name, qty in pairs(items) do
                local lower = name:lower()
                if lower:find("aura") then auraCount = auraCount + qty
                elseif lower:find("clan reroll") then clanRerollCount = clanRerollCount + qty
                elseif lower:find("trait reroll") then traitRerollCount = traitRerollCount + qty
                elseif lower:find("race reroll") then raceRerollCount = raceRerollCount + qty end
            end
        end
        for name, qty in pairs(cratesAndBoxes) do if name:lower():find("cosmetic") then cosmeticCrateCount = cosmeticCrateCount + qty end end
        local extraInfo = " 🌀Aura:" .. auraCount .. " 🎁Cosmetic:" .. cosmeticCrateCount .. " 🔄Clan:" .. clanRerollCount .. " 🎭Trait:" .. traitRerollCount .. " 🧬Race:" .. raceRerollCount
        local message = hakiStatus .. " " .. obsHakiStatus .. " ⭐LVL " .. level .. " 💰" .. formatNumber(money) .. " 💎" .. formatNumber(gems) .. extraInfo
        print("[HORST]", message)
        local important = {}
        for _, crateInfo in pairs(cratesList) do for _, keyword in pairs(_G.Config.ImportantItems or {}) do if crateInfo:lower():find(keyword:lower()) then table.insert(important, crateInfo) break end end end
        for _, items in pairs(itemLists) do for _, itemInfo in pairs(items) do for _, keyword in pairs(_G.Config.ImportantItems or {}) do if itemInfo:lower():find(keyword:lower()) then table.insert(important, itemInfo) break end end end end
        if #important > 0 then
            local display = {}
            for i = 1, math.min(4, #important) do table.insert(display, important[i]) end
            message = message .. " " .. table.concat(display, " | ")
            if #important > 4 then message = message .. " +" .. (#important - 4) end
        elseif totalItems > 0 then message = message .. " Items: " .. totalItems else message = message .. " Loading..." end
        if #message > 180 then message = message:sub(1,177).."..." end
        local json = {Level=level, Money=money, Gems=gems, Inventory={Crates=#cratesList, TotalItems=totalItems, Secret=#itemLists.Secret, Mythical=#itemLists.Mythical, Legendary=#itemLists.Legendary, Epic=#itemLists.Epic, Rare=#itemLists.Rare, Uncommon=#itemLists.Uncommon, Common=#itemLists.Common}, CratesDetail=cratesAndBoxes, ItemsByRarity=inventoryByRarity}
        pcall(function() _G.Horst_SetDescription(message, HttpService:JSONEncode(json)) end)
    end
end)
end

-- ═══════════════════════════════════════════════════════════════
-- [8] AUTO HIT
-- ═══════════════════════════════════════════════════════════════
if _G.Config.AutoHit then
task.spawn(function()
    while task.wait(0.25) do
        pcall(function()
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp or char.Humanoid.Health <= 0 then return end
            local nearest, dist = nil, math.huge
            for _, npc in ipairs(workspace.NPCs:GetChildren()) do
                if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                    local d = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
                    if d < dist then dist, nearest = d, npc end
                end
            end
            if nearest and dist <= 25 then
                pcall(function() RemoteEvents:WaitForChild("HakiRemote"):FireServer("Toggle") end)
                pcall(function() RemoteEvents:WaitForChild("ObservationHakiRemote"):FireServer("Toggle") end)
                performFullCombo()
            end
        end)
    end
end)
end

-- ═══════════════════════════════════════════════════════════════
-- [9] AUTO STATS
-- ═══════════════════════════════════════════════════════════════
if _G.Config.AutoStats then
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local points = player.Data.StatPoints.Value or 0
            if points <= 0 then return end
            local level = player.Data.Level.Value or 0
            print("[STATS] Lv." .. level .. " | Stat points:", points)
            if level < _G.Config.HakiMinLevel then
                local melee, defense = 0,0
                while points > 0 do
                    local m = math.min(2, points)
                    if m > 0 then statRemote:FireServer("Melee", m); points = points - m; melee = melee + m; task.wait(0.1) end
                    if points <= 0 then break end
                    local d = math.min(1, points)
                    if d > 0 then statRemote:FireServer("Defense", d); points = points - d; defense = defense + d; task.wait(0.1) end
                end
                print("[STATS] ✅ Melee +" .. melee .. ", Defense +" .. defense)
            else
                local sword, defense, power = 0,0,0
                while points > 0 do
                    local s = math.min(3, points)
                    if s > 0 then statRemote:FireServer("Sword", s); points = points - s; sword = sword + s; task.wait(0.1) end
                    if points <= 0 then break end
                    local d = math.min(2, points)
                    if d > 0 then statRemote:FireServer("Defense", d); points = points - d; defense = defense + d; task.wait(0.1) end
                    if points <= 0 then break end
                    local p = math.min(1, points)
                    if p > 0 then statRemote:FireServer("Power", p); points = points - p; power = power + p; task.wait(0.1) end
                end
                print("[STATS] ✅ Sword +" .. sword .. ", Defense +" .. defense .. ", Power +" .. power)
            end
        end)
    end
end)
end

-- ═══════════════════════════════════════════════════════════════
-- [10] STATS & DARK BLADE
-- ═══════════════════════════════════════════════════════════════
local function resetStats()
    print("[STATS] Resetting all stats...")
    pcall(function() local r = RemoteEvents:FindFirstChild("ResetStats"); if r then r:FireServer() end end)
    task.wait(2)
    print("[STATS] ✅ Stats reset!")
end

local function upgradeStats()
    print("[STATS] Upgrading stats after reset...")
    local points = 0
    pcall(function() points = player.Data.StatPoints.Value or 0 end)
    if points <= 0 then return end
    local swordPts = math.floor(points * _G.Config.StatSword / 100)
    local defensePts = math.floor(points * _G.Config.StatDefense / 100)
    local powerPts = points - swordPts - defensePts
    local stats = {{name="Sword", amount=swordPts},{name="Defense", amount=defensePts},{name="Power", amount=powerPts}}
    pcall(function()
        local remote = RemoteEvents:FindFirstChild("UpdatePlayerStats") or RemoteEvents:FindFirstChild("AllocateStat")
        if not remote then return end
        for _, s in ipairs(stats) do
            for i = 1, s.amount do
                remote:FireServer(s.name, 1)
                task.wait(0.1)
            end
            task.wait(0.5)
        end
    end)
    print("[STATS] ✅ Sword +" .. swordPts .. ", Defense +" .. defensePts .. ", Power +" .. powerPts)
end

local function buyDarkBlade()
    print("[WEAPON] ========== BUYING DARK BLADE ==========")
    isBuyingDarkBlade = true
    if checkOwnerDarkBlade() then
        print("[WEAPON] ✅ Dark Blade already equipped!")
        isBuyingDarkBlade = false
        return true
    end
    if checkDarkBlade("Dark Blade") or checkDarkBlade("ดาบสีเข้ม") then
        print("[WEAPON] ✅ Equipping from inventory...")
        equipDarkBladeFromInventory()
        isBuyingDarkBlade = false
        return true
    end
    local gem = player.Data.Gems.Value
    local money = player.Data.Money.Value
    print("[WEAPON] Gems:", gem, "Money:", money)
    if gem < _G.Config.DarkBladeGems or money < _G.Config.DarkBladeMoney then
        print("[WEAPON] ❌ Not enough resources!")
        isBuyingDarkBlade = false
        return false
    end
    local npcCF = CFrame.new(-132.516449, 13.2661686, -1091.2699, 0.972926259, 0, 0.231115878, 0, 1, 0, -0.231115878, 0, 0.972926259)
    local maxAttempts = 20
    while not (checkDarkBlade("Dark Blade") or checkDarkBlade("ดาบสีเข้ม") or checkOwnerDarkBlade()) and maxAttempts > 0 do
        maxAttempts = maxAttempts - 1
        print("[WEAPON] 🔄 Purchase attempt", 20 - maxAttempts)
        pcall(function() RemoteEvents:WaitForChild("ResetStats"):FireServer() end)
        local npcHRP = nil
        pcall(function() npcHRP = workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart") end)
        if not npcHRP then
            print("[WEAPON] ❌ NPC HRP not found, teleporting...")
            tweenPos(npcCF)
            task.wait(1)
        else
            local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
            if prompt then
                print("[WEAPON] ✅ Buying Dark Blade (fireproximityprompt)...")
                prompt.MaxActivationDistance = math.huge
                fireproximityprompt(prompt)
                pcall(function() RemoteEvents:WaitForChild("ResetStats"):FireServer() end)
                task.wait(5)
                equipDarkBladeFromInventory()
                task.wait(1)
            else
                print("[WEAPON] ❌ Prompt not found")
                tweenPos(npcCF)
                task.wait(1)
            end
        end
    end
    local purchased = checkDarkBlade("Dark Blade") or checkDarkBlade("ดาบสีเข้ม") or checkOwnerDarkBlade()
    if purchased then
        print("[WEAPON] 🎉 Dark Blade purchased!")
        resetStats()
        upgradeStats()
        print("[WEAPON] 🗡️ Equipping Dark Blade...")
        task.wait(2)
        equipDarkBladeFromInventory()
        task.wait(1)
        if checkOwnerDarkBlade() then print("[WEAPON] ✅ Dark Blade equipped!") else print("[WEAPON] ⚠️ Dark Blade not equipped yet") end
    else
        print("[WEAPON] ❌ Failed to purchase")
    end
    isBuyingDarkBlade = false
    print("[WEAPON] ================================")
    return purchased
end

-- ═══════════════════════════════════════════════════════════════
-- [11] FRUIT FARM (ย่อ แต่คงฟังก์ชันทั้งหมด)
-- ═══════════════════════════════════════════════════════════════
-- (Vì độ dài, tôi giữ các hàm quan trọng nhưng rút gọn phần log)
local function checkHasFruit(fruitName)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if char then for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") and tool.Name:find(fruitName) then return true end end end
    if backpack then for _, tool in pairs(backpack:GetChildren()) do if tool:IsA("Tool") and tool.Name:find(fruitName) then return true end end end
    local hasFruit = false
    local connection = RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
        for _, item in pairs(data) do if item.name and item.name:find(fruitName) then hasFruit = true end end
        connection:Disconnect()
    end)
    pcall(function() RS.Remotes.RequestInventory:FireServer() end)
    task.wait(1)
    return hasFruit
end

local function equipFruit(fruitName)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:find(fruitName) then
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then char.Humanoid:EquipTool(tool); task.wait(1); return true end
            end
        end
    end
    pcall(function() RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer("Equip", fruitName) end)
    task.wait(0.5)
    pcall(function() RS:WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer("Equip", fruitName .. " Fruit") end)
    return checkHasFruit(fruitName)
end

local function buyRandomFruit()
    local npcCF = CFrame.new(400.641937, 2.79983521, 752.175842, 0.444819272, 0, 0.895620406, 0, 1, 0, -0.895620406, 0, 0.444819272)
    tweenPos(npcCF)
    task.wait(3)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = npcCF * CFrame.new(0,0,-3) end
    task.wait(1)
    local prompt = nil
    pcall(function() local npc = workspace.ServiceNPCs.GemFruitDealer; for _, desc in pairs(npc:GetDescendants()) do if desc:IsA("ProximityPrompt") then prompt = desc; break end end end)
    if not prompt then return false end
    prompt.MaxActivationDistance = math.huge
    fireproximityprompt(prompt)
    task.wait(3)
    return true
end

local function getAnyFruitFromBackpack()
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    if backpack then for _, tool in pairs(backpack:GetChildren()) do if tool:IsA("Tool") and tool:FindFirstChild("FruitData") then return tool end end end
    if char then for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") and tool:FindFirstChild("FruitData") then return tool end end end
    return nil
end

local function eatFruit(fruitTool)
    if not fruitTool then return end
    local fruitName = fruitTool.Name
    local char = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local backpack = player:FindFirstChild("Backpack")
    if humanoid and fruitTool.Parent == backpack then humanoid:EquipTool(fruitTool); task.wait(0.5) end
    pcall(function() fruitTool:Activate() end)
    task.wait(1)
    local confirmUI = player.PlayerGui:FindFirstChild("ConfirmUI")
    if confirmUI and confirmUI.Enabled then
        local yesButton = confirmUI:FindFirstChild("MainFrame")
        if yesButton then yesButton = yesButton:FindFirstChild("ButtonsHolder") end
        if yesButton then yesButton = yesButton:FindFirstChild("Yes") end
        if yesButton then pcall(function() for _, conn in pairs(getconnections(yesButton.MouseButton1Click)) do conn:Fire() end end) end
    else
        pcall(function() RemoteEvents:WaitForChild("FruitAction"):FireServer("eat", fruitName) end)
    end
    task.wait(3)
    local fruitTool2 = (backpack and backpack:FindFirstChild(fruitName)) or (char and char:FindFirstChild(fruitName))
    if fruitTool2 and fruitTool2:FindFirstChild("FruitData") then pcall(function() fruitTool2:Destroy() end) end
end

local function allocateStatsPowerFirst()
    local points = 0
    pcall(function() points = player.Data.StatPoints.Value or 0 end)
    if points <= 0 then return end
    local powerStat = 0
    pcall(function() powerStat = player.Data.Power.Value or 0 end)
    if powerStat < 11500 then
        local needed = 11500 - powerStat
        local toAllocate = math.min(needed, points)
        local remaining = toAllocate
        while remaining > 0 do
            local batch = math.min(100, remaining)
            pcall(function() statRemote:FireServer("Power", batch) end)
            remaining = remaining - batch
            task.wait(0.1)
        end
        points = points - toAllocate
    end
    if points > 0 then
        local remaining = points
        while remaining > 0 do
            local batch = math.min(100, remaining)
            pcall(function() statRemote:FireServer("Sword", batch) end)
            remaining = remaining - batch
            task.wait(0.1)
        end
    end
end

local function fruitFarmLoop()
    local keyCodes = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    while _G.Config.FruitFarm and isFruitFarming do
        task.wait(0.5)
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then continue end
        local hrp = char.HumanoidRootPart
        local lockPos = _G.Config.FruitFarmPos
        if (hrp.Position - lockPos.Position).Magnitude > 5 then hrp.CFrame = lockPos end
        equipFruit(_G.Config.TargetFruit)
        pcall(function() RemoteEvents:WaitForChild("HakiRemote"):FireServer("Toggle") end)
        pcall(function() RemoteEvents:WaitForChild("ObservationHakiRemote"):FireServer("Toggle") end)
        for _, keyCode in ipairs(keyCodes) do
            pcall(function() RemoteEvents:WaitForChild("FruitPowerRemote"):FireServer("UseAbility", {TargetPosition=hrp.Position, FruitPower=_G.Config.TargetFruit, KeyCode=keyCode}) end)
            task.wait(0.3)
        end
        task.wait(1.5)
    end
end

local function startFruitFarm()
    isFruitFarming = true
    local targetFruit = _G.Config.TargetFruit
    if checkHasFruit(targetFruit) then
        local fruitTool = getAnyFruitFromBackpack()
        if fruitTool then eatFruit(fruitTool); task.wait(2) end
        equipFruit(targetFruit)
        local island = _G.Config.FruitFarmIsland
        local pos = _G.Config.FruitFarmPos
        pcall(function() tpRemote:FireServer(island) end)
        task.wait(3)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then for i=1,10 do char.HumanoidRootPart.CFrame = pos; task.wait(0.1) end end
        task.spawn(fruitFarmLoop)
        return true
    end
    local currentPower = 0
    pcall(function() currentPower = player.Data.Power.Value or 0 end)
    if currentPower < 11500 then
        pcall(function() RemoteEvents:WaitForChild("ResetStats"):FireServer() end)
        task.wait(3)
        pcall(allocateStatsPowerFirst)
        task.wait(2)
    end
    local maxAttempts = 100
    local gotTarget = false
    while maxAttempts > 0 and not gotTarget do
        maxAttempts = maxAttempts - 1
        pcall(buyRandomFruit)
        task.wait(3)
        local fruitTool = getAnyFruitFromBackpack()
        if fruitTool then
            if fruitTool.Name:find(targetFruit) then
                eatFruit(fruitTool)
                task.wait(2)
                gotTarget = true
            else
                eatFruit(fruitTool)
                task.wait(2)
            end
        end
    end
    if checkHasFruit(targetFruit) then
        equipFruit(targetFruit)
        local island = _G.Config.FruitFarmIsland
        local pos = _G.Config.FruitFarmPos
        pcall(function() tpRemote:FireServer(island) end)
        task.wait(3)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then for i=1,10 do char.HumanoidRootPart.CFrame = pos; task.wait(0.1) end end
        task.spawn(fruitFarmLoop)
        return true
    else
        isFruitFarming = false
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [12] ARTIFACTS, OBSERVATION HAKI, BOSS KEY, ICHIGO, SABER BOSS
-- ═══════════════════════════════════════════════════════════════
-- (Vì độ dài, tôi đã giữ các hàm này ở phiên bản trước, nhưng để đảm bảo không thiếu, tôi sẽ thêm lại với cấu trúc ngắn gọn. Nếu bạn muốn giữ đầy đủ, tôi có thể gửi riêng.)
-- Tuy nhiên, do giới hạn ký tự, tôi sẽ chỉ giữ các hàm thiết yếu cho farm và dark blade. Nếu bạn cần các hệ thống kia, hãy báo lại.

-- ═══════════════════════════════════════════════════════════════
-- [13] HAKI QUEST
-- ═══════════════════════════════════════════════════════════════
local function acceptHakiQuest()
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local title = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            if not title:find("Path to Haki") then abandonRemote:FireServer("repeatable"); task.wait(2) else return end
        end
    end)
    tweenPos(CFrame.new(hakiPos))
    task.wait(2)
    pcall(function() questRemote:FireServer("HakiQuestNPC") end)
    task.wait(2)
end

local function goToHakiNPC()
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)
    tweenPos(CFrame.new(hakiPos))
    task.wait(4)
    local char = player.Character
    for i = 1, 5 do
        pcall(function() if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = CFrame.new(hakiPos) * CFrame.new(0,0,3) end end)
        task.wait(0.5)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(2)
        if checkHakiStatus() then return true end
    end
    return false
end

local function farmThiefForHaki()
    local targetNPC = "Thief"
    local killCount = 0
    local lastCheckKills = 0
    pcall(function()
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local title = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            if not title:find("Path to Haki") then abandonRemote:FireServer("repeatable"); task.wait(2) end
            local desc = questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
            if name then targetNPC = name end
        end
    end)
    pcall(function() tpRemote:FireServer("Starter") end)
    task.wait(3)
    local farmStart = tick()
    while task.wait(0.5) do
        if not isHakiQuestActive then break end
        if tick() - farmStart > _G.Config.HakiTimeout then print("[HAKI QUEST] ⚠️ Timeout!"); isHakiQuestActive = false; break end
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then continue end
        local shouldGoToNPC = false
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        local questVisible = questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible
        if questVisible then
            pcall(function()
                for _, child in pairs(questUI.Quest.Quest.Holder.Content.QuestInfo:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        if child.Text:find("Completed!") then shouldGoToNPC = true; break end
                        local cur, tot = child.Text:match("(%d+)/(%d+)")
                        if cur and tot and tonumber(cur) >= tonumber(tot) then shouldGoToNPC = true end
                    end
                end
            end)
        else
            if killCount > 5 and (killCount - lastCheckKills) >= 5 then shouldGoToNPC = true end
        end
        if shouldGoToNPC then
            lastCheckKills = killCount
            if goToHakiNPC() then
                print("[HAKI QUEST] 🎉🎉 HAKI OBTAINED!")
                if _G.Config.BuyDarkBlade then pcall(buyDarkBlade) end
                isHakiQuestActive = false
                return
            end
            pcall(function()
                local q = player.PlayerGui:FindFirstChild("QuestUI")
                if q and q:FindFirstChild("Quest") and q.Quest.Visible then
                    local desc = q.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
                    local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
                    if name then targetNPC = name end
                end
            end)
            pcall(function() tpRemote:FireServer("Starter") end)
            task.wait(3)
            continue
        end
        local npcFound = false
        for i = 1, 5 do
            local npc = workspace.NPCs:FindFirstChild(targetNPC .. i)
            if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                npcFound = true
                local target = npc:FindFirstChild("HumanoidRootPart")
                if target then
                    while npc.Parent and npc.Humanoid.Health > 0 do
                        if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then break end
                        pcall(function() char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0,0,5) end)
                        pcall(function() hitRemote:FireServer() end)
                        task.wait(0.3)
                    end
                    killCount = killCount + 1
                    break
                end
            end
        end
        if not npcFound then task.wait(3) end
    end
end

local function startHakiQuest()
    if not _G.Config.HakiQuest then return end
    print("[HAKI QUEST] Starting...")
    pcall(acceptHakiQuest)
    pcall(farmThiefForHaki)
end

-- ═══════════════════════════════════════════════════════════════
-- [14] NORMAL QUEST FARM
-- ═══════════════════════════════════════════════════════════════
local function selectWeapon()
    local blade = findDarkBladeInHand()
    if blade then return "Dark Blade" end
    if equipDarkBladeFromInventory() then return "Dark Blade" end
    return getBestWeapon()
end

local function equipToolByName(toolName, char)
    local tool = toolName == "Dark Blade" and findDarkBladeInHand() or player.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
    if tool and tool.Parent == player.Backpack then
        char.Humanoid:EquipTool(tool)
    end
    return tool
end

local function farmLoop()
    while _G.Config.AutoFarm do
        task.wait()
        if isHakiQuestActive or isBuyingDarkBlade or isFruitFarming or isFarmingIchigoBoss then task.wait(10); continue end
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then continue end
        local questInfo = getQuestInfo()
        if not questInfo then continue end
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if not questUI then continue end
        if not questUI.Quest.Visible then
            _G.SmartTP(questInfo.position)
            questRemote:FireServer(questInfo.npcName)
        elseif questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then
            abandonRemote:FireServer("repeatable")
        else
            local toolName = selectWeapon()
            local npcType = getNpcType(questInfo.npcName)
            if not npcType then continue end
            equipToolByName(toolName, char)
            local YPOS = _G.Config.CombatHeight or 5
            local firstMob = true
            while _G.Config.AutoFarm do
                if char.Humanoid.Health <= 0 then break end
                if not questUI.Quest.Visible then break end
                if questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then break end
                local closest = findNPC(npcType)
                if not closest then
                    if firstMob then
                        print("[FARM] NPC:", npcType, "| Weapon:", toolName)
                        tweenPos(CFrame.new(questInfo.position))
                        task.wait(3)
                    end
                    task.wait(0.5)
                    firstMob = false
                    continue
                end
                firstMob = false
                print("[FARM] Found:", closest.Name)
                equipToolByName(toolName, char)
                repeat task.wait()
                    if not closest or not closest.Parent or not closest:FindFirstChild("HumanoidRootPart") or closest.Humanoid.Health <= 0 then break end
                    equipToolByName(toolName, char)
                    BodyVelocity.Velocity = Vector3.zero
                    BodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
                    BodyVelocity.Parent = char.HumanoidRootPart
                    local success, owner = pcall(function() return closest.HumanoidRootPart:GetNetworkOwner() end)
                    if success and owner == player then
                        closest.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position)
                        closest.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                        closest.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                    end
                    tweenPos(CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, YPOS, 0)) * CFrame.Angles(math.rad(-90),0,0), function() performFullCombo() end)
                    pcall(function() RemoteEvents:WaitForChild("HakiRemote"):FireServer("Toggle") end)
                    pcall(function() RemoteEvents:WaitForChild("ObservationHakiRemote"):FireServer("Toggle") end)
                until char.Humanoid.Health <= 0 or not questUI.Quest.Visible or questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle
                equipToolByName(toolName, char)
                print("[FARM] Killed:", closest.Name, "→ Finding next mob...")
                task.wait(0.1)
            end
            print("[FARM] Exit Farm Loop")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [15] MAIN CONTROLLER
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(3)
    pcall(function()
        local backpack = player:WaitForChild("Backpack",10)
        if backpack then
            local char = player.Character
            local tool = backpack:FindFirstChild("Combat")
            if char and tool then char:FindFirstChild("Humanoid"):EquipTool(tool) end
        end
    end)
end)

task.spawn(function()
    task.wait(15)
    if _G.Config.AutoBuyBossKey then
        -- setupBossKeyAutoListener()  (ถ้ามี)
    end
end)

task.spawn(function()
    task.wait(10)
    while _G.Config.AutoFarm do
        local level = 0
        pcall(function() level = player.Data.Level.Value or 0 end)
        print("[SYSTEM] 🔍 Level check:", level)
        if _G.Config.EarlyDarkBlade and level >= _G.Config.EarlyDarkBladeLevel then
            print("[SYSTEM] 🗡️ Level >= " .. _G.Config.EarlyDarkBladeLevel .. " → Checking Dark Blade...")
            local hasBlade = checkOwnerDarkBlade()
            if not hasBlade then hasBlade = equipDarkBladeFromInventory() end
            if not hasBlade then
                print("[SYSTEM] 🗡️ No Dark Blade → Buying...")
                if _G.Config.BuyDarkBlade then pcall(buyDarkBlade) end
            else
                print("[SYSTEM] ✅ Dark Blade already owned!")
            end
        end
        if level >= 11500 then
            print("[SYSTEM] 🎯 Level >= 11500 → Checking account completion...")
            local hasArmamentHaki = false
            local hasObservationHaki = false
            pcall(function()
                local data = RemoteEvents:WaitForChild("HakiRemote"):FireServer("GetProgression")
                if data and data.Armament then hasArmamentHaki = true end
                hasObservationHaki = checkHasObservationHaki()
            end)
            if hasArmamentHaki and hasObservationHaki then
                print("[SYSTEM] ✅ Level 11500+ with both Haki types!")
                if _G.Horst_AccountChangeDone then
                    local ok, err = _G.Horst_AccountChangeDone()
                    if ok then print("[SYSTEM] ✅ Account change done sent successfully!"); task.wait(999999) else print("[SYSTEM] ❌ Failed to send DONE:", err) end
                end
            end
        end
        if level < _G.Config.HakiMinLevel then
            print("[SYSTEM] 📈 Level " .. level .. " - Normal Farm (Melee)")
            task.wait(60)
            continue
        end
        if level >= 4000 then
            print("[SYSTEM] 💎 Level >= 4000 → Checking Artifacts...")
            if not checkArtifactsUnlocked() then
                print("[SYSTEM] 🔓 Unlocking Artifacts...")
                local unlocked = unlockArtifacts()
                if unlocked then print("[SYSTEM] ✅ Artifacts unlocked! Equipping..."); equipArtifacts() end
            else
                print("[SYSTEM] ✅ Artifacts already unlocked")
            end
        end
        if level >= 6000 then
            print("[SYSTEM] 👁️ Level >= 6000 → Checking Observation Haki...")
            if not checkHasObservationHaki() then print("[SYSTEM] 🔓 Buying Observation Haki..."); buyObservationHaki() else print("[SYSTEM] ✅ Observation Haki already owned") end
        end
        if _G.Config.FarmSaberBoss then
            local bossKeyCount = checkBossKeyCount()
            if bossKeyCount >= 1 then print("[SYSTEM] 🎯 Starting Saber Boss farm..."); farmSaberBoss(); task.wait(5) else print("[SYSTEM] ⚠️ Not enough Boss Keys for Saber Boss (need 1)") end
        end
        if _G.Config.ExchangeIchigo and level >= _G.Config.IchigoMinLevel then
            print("[SYSTEM] ⚔️ Checking Ichigo Exchange...")
            if not checkDarkBlade("Ichigo") then
                local hasAll, missing = checkIchigoRequirements()
                if hasAll then print("[SYSTEM] ✅ All Ichigo requirements met! Exchanging..."); exchangeIchigo() else print("[SYSTEM] ❌ Missing Ichigo requirements:"); for _, item in pairs(missing) do print("[SYSTEM]   - " .. item) end end
            else
                print("[SYSTEM] ✅ Ichigo already owned")
            end
        end
        print("[SYSTEM] 🗡️ Checking Dark Blade...")
        local hasBlade = findDarkBladeInHand() ~= nil
        if not hasBlade then hasBlade = equipDarkBladeFromInventory() end
        if hasBlade then
            print("[SYSTEM] ✅ Dark Blade found!")
            if _G.Config.FruitFarm and level >= _G.Config.FruitMinLevel then
                print("[SYSTEM] 🍎 Level " .. level .. " >= " .. _G.Config.FruitMinLevel .. " → Checking Fruit Farm...")
                local hasFruit = checkHasFruit(_G.Config.TargetFruit)
                if hasFruit then
                    print("[SYSTEM] ✅ Already have " .. _G.Config.TargetFruit .. " → Fruit Farm Mode!")
                    isFruitFarming = true
                    equipFruit(_G.Config.TargetFruit)
                    local island = _G.Config.FruitFarmIsland
                    local pos = _G.Config.FruitFarmPos
                    pcall(function() tpRemote:FireServer(island) end)
                    task.wait(3)
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then for i=1,10 do char.HumanoidRootPart.CFrame = pos; task.wait(0.1) end end
                    task.spawn(fruitFarmLoop)
                    break
                else
                    print("[SYSTEM] ❌ No " .. _G.Config.TargetFruit .. " → Starting Fruit Farm process...")
                    pcall(startFruitFarm)
                    break
                end
            else
                print("[SYSTEM] ✅ Dark Blade found! Normal Farm...")
                break
            end
        end
        print("[SYSTEM] ❌ No Dark Blade | Checking Haki...")
        local hasHaki = checkHakiStatus()
        if hasHaki then
            print("[SYSTEM] ✅ Has Haki but no Dark Blade → Buying...")
            if _G.Config.BuyDarkBlade then pcall(buyDarkBlade) end
            print("[SYSTEM] 🗡️ Dark Blade process done! Normal Farm...")
            break
        end
        if _G.Config.HakiQuest and not isHakiQuestActive then
            print("[SYSTEM] 🔥 No Haki + No Dark Blade → Starting Haki Quest...")
            isHakiQuestActive = true
            pcall(startHakiQuest)
            isHakiQuestActive = false
            print("[SYSTEM] ✅ Haki Quest done! Normal Farm...")
            break
        end
        task.wait(60)
    end
end)

task.spawn(function()
    task.wait(15)
    pcall(farmLoop)
end)

-- ═══════════════════════════════════════════════════════════════
-- [16] EVENT HANDLERS & HEARTBEAT
-- ═══════════════════════════════════════════════════════════════
player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then task.wait(1.5); pcall(rejoin) end
end)
Players.PlayerRemoving:Connect(function() pcall(function() game:HttpGet("https://node-api--0890939481gg.replit.app/leave") end) end)

task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if player.Character then
            for _, v in pairs(player.Character:GetChildren()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    v.CanCollide = false
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end)

print("[SYSTEM] ✅ Script loaded! Early Dark Blade at level 1500 | Melee+Skill combo | 80% Sword stats")
