-- Sailor Piece v5 - FULL EDITION (Melee+Skill + Early Dark Blade)
repeat task.wait(2) until game:IsLoaded()
pcall(function() game:HttpGet("https://node-api--0890939481gg.replit.app/join") end)

-- ═══════════════════════════════════════════════════════════════
-- [1] CONFIG - ตั้งค่าทั้งหมดที่นี่
-- ═══════════════════════════════════════════════════════════════
_G.Config = {
    AutoFarm        = true,
    AutoHit         = true,
    AutoStats       = true,
    FpsBoost        = true,
    HorstDisplay    = true,

    UseMeleeAttack  = true,
    MeleeAttackDelay = 0.08,
    UseSkills       = true,
    SkillComboOrder = {"Z","X","C","V","F"},
    SkillDelay      = 0.15,
    CombatPriority  = "MeleeFirst",
    CombatHeight    = 5,

    HakiQuest       = true,
    HakiMinLevel    = 3000,
    HakiTimeout     = 3600,

    BuyDarkBlade    = true,
    DarkBladeGems   = 150,
    DarkBladeMoney  = 250000,

    EarlyDarkBlade  = true,
    EarlyDarkBladeLevel = 1500,

    FruitFarm       = false,
    FruitMinLevel   = 11500,
    TargetFruit     = "Quake",
    FruitFarmIsland = "Shinjuku",
    FruitFarmPos    = CFrame.new(321.706757, -1.539090, -1756.500977) * CFrame.Angles(0, -0.113749, 0),

    AutoBuyBossKey  = true,
    BossKeyBuyInterval = 1800,

    ExchangeIchigo  = true,
    IchigoMinLevel  = 11500,
    IchigoRequirements = { BossTicket = 500 },

    FarmSaberBoss   = true,
    SaberBossSummonItems = { BossKey = 1, Money = 100000, Gems = 175 },

    StatSword       = 80,
    StatDefense     = 10,
    StatPower       = 10,

    GameSettings = {
        "DisablePvP", "DisableVFX", "DisableOtherVFX",
        "RemoveTexture", "AutoSkillC", "RemoveShadows",
    },

    LogTags = {
        "[SYSTEM]", "[FARM]", "[HAKI", "[WEAPON",
        "[HORST]", "[STATS]", "[QUEST]", "[INVENTORY]",
        "[FRUIT]", "[DEBUG]", "[COMBAT]",
    },
}

-- ═══════════════════════════════════════════════════════════════
-- [2] SERVICES & VARIABLES
-- ═══════════════════════════════════════════════════════════════
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local RunService    = game:GetService("RunService")
local VIM           = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local HttpService   = game:GetService("HttpService")
local UIS           = game:GetService("UserInputService")
local Lighting      = game:GetService("Lighting") or game.Lighting
local BodyVelocity  = Instance.new("BodyVelocity")

local player        = Players.LocalPlayer
if not player then
    player = Players:WaitForChild("LocalPlayer", 10)
end

-- Safe references (some games put remotes in different places)
local Remotes, RemoteEvents, CombatRemotes, Modules
pcall(function()
    Remotes = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Remotes") or RS
    RemoteEvents = RS:FindFirstChild("RemoteEvents") or RS
    CombatRemotes = RS:FindFirstChild("CombatSystem") and RS.CombatSystem:FindFirstChild("Remotes") or RS
    Modules = RS:FindFirstChild("Modules") or RS
end)

-- Safe Wait wrappers
local function safeWaitFor(parent, name, timeout)
    if not parent then return nil end
    local ok, res = pcall(function() return parent:WaitForChild(name, timeout) end)
    return ok and res or nil
end

-- Remote references with guards
local function getRemoteFrom(pathTable)
    local cur = RS
    for _, part in ipairs(pathTable) do
        if not cur then return nil end
        cur = cur:FindFirstChild(part)
    end
    return cur
end

local hitRemote     = (CombatRemotes and safeWaitFor(CombatRemotes, "RequestHit", 5)) or getRemoteFrom({"CombatSystem","Remotes","RequestHit"})
local questRemote   = (RemoteEvents and safeWaitFor(RemoteEvents, "QuestAccept", 5)) or getRemoteFrom({"RemoteEvents","QuestAccept"})
local abandonRemote = (RemoteEvents and safeWaitFor(RemoteEvents, "QuestAbandon", 5)) or getRemoteFrom({"RemoteEvents","QuestAbandon"})
local statRemote    = (RemoteEvents and safeWaitFor(RemoteEvents, "AllocateStat", 5)) or getRemoteFrom({"RemoteEvents","AllocateStat"})
local tpRemote      = (Remotes and safeWaitFor(Remotes, "TeleportToPortal", 5)) or getRemoteFrom({"Remotes","TeleportToPortal"})
local settingsToggle = (RemoteEvents and safeWaitFor(RemoteEvents, "SettingsToggle", 5)) or getRemoteFrom({"RemoteEvents","SettingsToggle"})

-- State
local inventoryByRarity = { Secret = {}, Mythical = {}, Legendary = {}, Epic = {}, Rare = {}, Uncommon = {}, Common = {} }
local cratesAndBoxes = {}
local isHakiQuestActive = false
local isBuyingDarkBlade = false
local isFruitFarming = false
local isFarmingIchigoBoss = false

local darkBladeObtained = false
local lastMeleeTime = 0
local lastSkillTime = 0

-- ═══════════════════════════════════════════════════════════════
-- [3] ERROR SUPPRESSION (kept but safer)
-- ═══════════════════════════════════════════════════════════════
-- Keep original print/warn but avoid completely silencing critical errors during debugging.
local oldPrint = print
local oldWarn = warn

-- Minimal suppression: keep print/warn but filter noisy messages
local function safePrint(...)
    local args = {...}
    if not args[1] then return end
    local text = tostring(args[1])
    local blocked = {
        "CrossExperience","CorePackages","ServerScriptService",
    }
    for _, kw in ipairs(blocked) do
        if text:find(kw, 1, true) then return end
    end
    for _, tag in ipairs(_G.Config.LogTags) do
        if text:find(tag, 1, true) then
            oldPrint(...)
            return
        end
    end
end

print = safePrint
warn = function(...) oldWarn(...) end

-- ═══════════════════════════════════════════════════════════════
-- [4] UTILITY FUNCTIONS
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
        if dist < nearestDist then
            nearest, nearestDist = name, dist
        end
    end
    return nearest
end

_G.SmartTP = function(pos)
    if not tpRemote or not tpRemote.FireServer then
        print("[SmartTP] tpRemote missing")
        return
    end
    local targetPos = CFrame.new(pos)
    local island = getNearestIsland(targetPos.Position)
    if not island then return print("[SmartTP] No portal found!") end
    pcall(function() tpRemote:FireServer(island) end)
    task.wait(0.5)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(targetPos.Position) end
end

local function tweenPos(targetCF, callback)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local distance = (targetCF.Position - root.CFrame.Position).Magnitude

    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)

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
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        if callback then pcall(callback) end
        return
    else
        _G.SmartTP(targetCF.Position)
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        if callback then pcall(callback) end
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
                if tool:IsA("Tool") then
                    local okName = pcall(function() return tool.Name end)
                    local okTip = pcall(function() return tool.ToolTip end)
                    local name = okName and tool.Name or ""
                    local tip = okTip and (tool.ToolTip or "") or ""
                    local isDarkBlade = name:find("Dark Blade") or name:find("ดาบสีเข้ม") or tip:find("Black Blade") or tip:find("ดาบสีเข้ม")
                    if isDarkBlade then
                        return tool, container.Name
                    end
                end
            end
        end
    end
    return nil
end

local function checkOwnerDarkBlade()
    for _, container in pairs({player.Character, player.Backpack}) do
        if container then
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local okName = pcall(function() return tool.Name end)
                    local okTip = pcall(function() return tool.ToolTip end)
                    local name = okName and tool.Name or ""
                    local tip = okTip and (tool.ToolTip or "") or ""
                    local isDarkBlade = name:find("Dark Blade") or name:find("ดาบสีเข้ม") or tip:find("Black Blade") or tip:find("ดาบสีเข้ม")
                    if isDarkBlade then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function checkDarkBlade(targetName)
    local result = false
    pcall(function()
        local updateInv = Remotes and Remotes:FindFirstChild("UpdateInventory")
        if updateInv then
            local conn
            conn = updateInv.OnClientEvent:Connect(function(tab, data)
                for _, item in pairs(data or {}) do
                    if item.name == targetName or item.name == "ดาบสีเข้ม" or (item.name and item.name:find("Dark Blade")) then
                        result = true
                    end
                end
                if conn then conn:Disconnect() end
            end)
            pcall(function() local req = Remotes:FindFirstChild("RequestInventory"); if req then req:FireServer() end end)
            task.wait(0.6)
            if conn and conn.Connected then conn:Disconnect() end
        end
    end)
    return result
end

local function equipDarkBladeFromInventory()
    pcall(function()
        if Remotes and Remotes:FindFirstChild("EquipWeapon") then
            Remotes.EquipWeapon:FireServer("Equip", "Dark Blade")
        end
    end)
    task.wait(1)
    if not findDarkBladeInHand() then
        pcall(function()
            if Remotes and Remotes:FindFirstChild("EquipWeapon") then
                Remotes.EquipWeapon:FireServer("Equip", "ดาบสีเข้ม")
            end
        end)
        task.wait(1)
    end
    return findDarkBladeInHand() ~= nil
end

local function getQuestInfo()
    if RemoteEvents and RemoteEvents:FindFirstChild("GetQuestArrowTarget") and RemoteEvents.GetQuestArrowTarget.InvokeServer then
        local ok, result = pcall(function() return RemoteEvents.GetQuestArrowTarget:InvokeServer() end)
        return ok and result or nil
    end
    return nil
end

local function getNpcType(npcName)
    local ok, result = pcall(function()
        if Modules and Modules:FindFirstChild("QuestConfig") then
            local module = require(Modules:FindFirstChild("QuestConfig"))
            if module and module.RepeatableQuests then
                for questNPC, questData in pairs(module.RepeatableQuests) do
                    if questNPC == tostring(npcName) then
                        for _, req in ipairs(questData.requirements or {}) do
                            return req.npcType
                        end
                    end
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
    table.sort(weapons, function(a, b) return a.level > b.level end)
    if #weapons > 0 then
        return weapons[1].name
    end
    return "Combat"
end

local function checkHakiStatus()
    local hasHaki = false
    local hakiInfo = ""
    pcall(function()
        local statsUI = player.PlayerGui and player.PlayerGui:FindFirstChild("StatsPanelUI")
        if not statsUI then return end
        for _, desc in pairs(statsUI:GetDescendants()) do
            if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                hasHaki = true
                for _, child in pairs(desc:GetDescendants()) do
                    if child.Name == "HakiLevel" and child:IsA("TextLabel") then
                        hakiInfo = child.Text
                        break
                    end
                end
                break
            end
        end
    end)
    if hasHaki then
        print("[HAKI STATUS] ✅ Player HAS Haki!", hakiInfo)
    end
    return hasHaki, hakiInfo
end

local function findNPC(npcType)
    local closest = nil
    if not workspace:FindFirstChild("NPCs") then return nil end
    for _, v in pairs(workspace.NPCs:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart")
            and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local ok, display = pcall(function() return v.Humanoid.DisplayName end)
            local subName = ok and display or ""
            subName = subName:gsub("%s+",""):gsub("%[Lv%.%s*%d+%]","")
            if npcType == tostring(subName) or v.Name == npcType then
                return v
            end
            if subName:find(npcType, 1, true) or v.Name:find(npcType, 1, true) then
                closest = v
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════════════════════
-- [ADDED] COMBAT FUNCTIONS (Melee + Skill)
-- ═══════════════════════════════════════════════════════════════
local function safeFireAbility(idx)
    pcall(function()
        local abilityRemotes = RS:FindFirstChild("AbilitySystem") and RS.AbilitySystem:FindFirstChild("Remotes")
        if abilityRemotes and abilityRemotes:FindFirstChild("RequestAbility") then
            abilityRemotes.RequestAbility:FireServer(idx)
        end
    end)
end

local function performMeleeAttack()
    if not _G.Config.UseMeleeAttack then return end
    local now = tick()
    if now - lastMeleeTime < (_G.Config.MeleeAttackDelay or 0.08) then return end
    lastMeleeTime = now
    pcall(function()
        if hitRemote and hitRemote.FireServer then hitRemote:FireServer() end
        local char = player.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool and tool.Activate then
                pcall(function() tool:Activate() end)
            end
        end
    end)
end

local function useSkill(skillKey)
    if not _G.Config.UseSkills then return end
    local skillMap = { Z=1, X=2, C=3, V=4, F=5 }
    local idx = skillMap[skillKey]
    if not idx then return end
    local now = tick()
    if now - lastSkillTime < (_G.Config.SkillDelay or 0.15) then return end
    lastSkillTime = now
    safeFireAbility(idx)
end

local function performFullCombo()
    if _G.Config.CombatPriority == "MeleeFirst" then
        performMeleeAttack()
        for _, sk in ipairs(_G.Config.SkillComboOrder) do
            useSkill(sk)
        end
        performMeleeAttack()
    else
        for _, sk in ipairs(_G.Config.SkillComboOrder) do
            useSkill(sk)
        end
        performMeleeAttack()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [5] PERFORMANCE - FPS Boost + Game Settings
-- ═══════════════════════════════════════════════════════════════
if settingsToggle and settingsToggle.FireServer then
    for _, setting in ipairs(_G.Config.GameSettings) do
        pcall(function()
            settingsToggle:FireServer(setting, true)
        end)
    end
end

local BlackScreen = _G.Config.FpsBoost

local function setBlack(state)
    if state then
        pcall(function() Lighting.Brightness = 0 end)
        pcall(function() Lighting.GlobalShadows = false end)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then pcall(function() v.LocalTransparencyModifier = 1 end) end
        end
    else
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then pcall(function() v.LocalTransparencyModifier = 0 end) end
        end
    end
end

setBlack(BlackScreen)

local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0, 160, 0, 45)
button.Position = UDim2.new(0, 20, 0.5, -22)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "FpsBoost : ON"
button.Font = Enum.Font.GothamBold
button.TextSize = 16

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", button)
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Thickness = 2

button.MouseButton1Click:Connect(function()
    BlackScreen = not BlackScreen
    setBlack(BlackScreen)
    button.Text = BlackScreen and "BlackScreen : ON" or "BlackScreen : OFF"
end)

local ytLabel = Instance.new("TextLabel")
ytLabel.Parent = gui
ytLabel.Size = UDim2.new(0, 420, 0, 52)
ytLabel.Position = UDim2.new(0.5, -210, 0.5, -26)
ytLabel.BackgroundTransparency = 1
ytLabel.Text = "Youtube:DieuMiMiUwU"
ytLabel.Font = Enum.Font.GothamBlack
ytLabel.TextSize = 36
ytLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
ytLabel.TextStrokeTransparency = 0
ytLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ytLabel.ZIndex = 10

player.CharacterAdded:Connect(function()
    task.wait(1)
    setBlack(BlackScreen)
end)

-- ═══════════════════════════════════════════════════════════════
-- [6] INVENTORY TRACKER
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local updateInventory = Remotes and Remotes:FindFirstChild("UpdateInventory")
    local requestInventory = Remotes and Remotes:FindFirstChild("RequestInventory")
    local ModulesLocal = Modules
    local ItemRarityConfig = nil
    if ModulesLocal and ModulesLocal:FindFirstChild("ItemRarityConfig") then
        pcall(function() ItemRarityConfig = require(ModulesLocal:FindFirstChild("ItemRarityConfig")) end)
    end

    if updateInventory and updateInventory.OnClientEvent then
        updateInventory.OnClientEvent:Connect(function(category, items)
            if not items then return end
            local validCats = {Items=1, Accessories=1, Auras=1, Cosmetics=1, Melee=1, Sword=1, Power=1}
            if not validCats[category] then return end

            for _, item in pairs(items) do
                local name = item.name
                local qty = item.quantity or 1
                if not name then continue end

                if name:lower():find("crate") or name:lower():find("box") or name:lower():find("chest") then
                    cratesAndBoxes[name] = qty
                end

                local ok, rarity = pcall(function() if ItemRarityConfig then return ItemRarityConfig:GetRarity(name) end end)
                if ok and rarity and inventoryByRarity[rarity] then
                    inventoryByRarity[rarity][name] = qty
                    if rarity == "Secret" or rarity == "Mythical" or rarity == "Legendary" then
                        print("[INVENTORY]", rarity, ":", name, "x" .. qty)
                    end
                end
            end
        end)
    end

    task.wait(3)
    print("[INVENTORY] Requesting inventory data...")
    pcall(function() if requestInventory then requestInventory:FireServer() end end)
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or input.KeyCode ~= Enum.KeyCode.F1 then return end
    local data = player:FindFirstChild("Data")
    if not data then return end

    local level = data:FindFirstChild("Level") and data.Level.Value or 0
    local money = data:FindFirstChild("Money") and data.Money.Value or 0
    local gems = data:FindFirstChild("Gems") and data.Gems.Value or 0

    oldPrint("\n========================================")
    oldPrint("📊 INVENTORY | ⭐Lv." .. level .. " 💰" .. money .. " 💎" .. gems)
    oldPrint("========================================")

    for name, qty in pairs(cratesAndBoxes) do
        oldPrint("  📦 " .. name .. " x" .. qty)
    end

    local order = {"Secret","Mythical","Legendary","Epic","Rare","Uncommon","Common"}
    local emojis = {Secret="🌟",Mythical="✨",Legendary="🔥",Epic="💜",Rare="💙",Uncommon="💚",Common="⚪"}
    for _, rarity in ipairs(order) do
        local items = inventoryByRarity[rarity]
        local count = 0
        for _ in pairs(items) do count = count + 1 end
        if count > 0 then
            oldPrint(emojis[rarity] .. " [" .. rarity:upper() .. "] " .. count .. " items:")
            for name, qty in pairs(items) do
                oldPrint("   • " .. name .. " x" .. qty)
            end
        end
    end
    oldPrint("========================================\n")
end)

-- ═══════════════════════════════════════════════════════════════
-- [7] HORST DISPLAY
-- ═══════════════════════════════════════════════════════════════
if _G.Config.HorstDisplay then
task.spawn(function()
    local data = player:WaitForChild("Data", 30)
    if not data then
        print("[HORST] ❌ Data not found!")
        return
    end

    task.wait(5)
    print("[HORST] Starting Horst Display...")

    while task.wait(1) do
        local level = (data:FindFirstChild("Level") and data.Level.Value) or 0
        local money = (data:FindFirstChild("Money") and data.Money.Value) or 0
        local gems  = (data:FindFirstChild("Gems") and data.Gems.Value) or 0

        local hakiStatus = "❌"
        pcall(function()
            local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
            if not statsUI then return end
            for _, desc in pairs(statsUI:GetDescendants()) do
                if desc.Name == "HakiProgressionFrame" and desc.Visible == true then
                    for _, child in pairs(desc:GetDescendants()) do
                        if child.Name == "HakiLevel" and child:IsA("TextLabel") then
                            hakiStatus = "✅ " .. child.Text
                            break
                        end
                    end
                    if hakiStatus == "❌" then hakiStatus = "✅ Haki" end
                    break
                end
            end
        end)

        local obsHakiStatus = "❌"
        pcall(function()
            local statsUI = player.PlayerGui:FindFirstChild("StatsPanelUI")
            if not statsUI then return end
            for _, desc in pairs(statsUI:GetDescendants()) do
                if desc.Name:find("Observation") and desc:IsA("Frame") and desc.Visible == true then
                    for _, child in pairs(desc:GetDescendants()) do
                        if child:IsA("TextLabel") and child.Text:find("Lv") then
                            obsHakiStatus = "✅ Obs " .. child.Text
                            break
                        end
                    end
                    if obsHakiStatus == "❌" then obsHakiStatus = "✅ Obs Haki" end
                    break
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
        for name, qty in pairs(cratesAndBoxes) do
            table.insert(cratesList, name .. " x" .. qty)
        end

        local auraCount = 0
        local cosmeticCrateCount = 0
        local clanRerollCount = 0
        local traitRerollCount = 0
        local raceRerollCount = 0
        
        for _, items in pairs(inventoryByRarity) do
            for name, qty in pairs(items) do
                local lower = name:lower()
                if lower:find("aura") then
                    auraCount = auraCount + qty
                elseif lower:find("clan reroll") then
                    clanRerollCount = clanRerollCount + qty
                elseif lower:find("trait reroll") then
                    traitRerollCount = traitRerollCount + qty
                elseif lower:find("race reroll") then
                    raceRerollCount = raceRerollCount + qty
                end
            end
        end
        
        for name, qty in pairs(cratesAndBoxes) do
            if name:lower():find("cosmetic") then
                cosmeticCrateCount = cosmeticCrateCount + qty
            end
        end
        
        local extraInfo = " 🌀Aura:" .. auraCount .. " 🎁Cosmetic:" .. cosmeticCrateCount .. " 🔄Clan:" .. clanRerollCount .. " 🎭Trait:" .. traitRerollCount .. " 🧬Race:" .. raceRerollCount
        local message = hakiStatus .. " " .. obsHakiStatus .. " ⭐LVL " .. level .. " 💰" .. formatNumber(money) .. " 💎" .. formatNumber(gems) .. extraInfo
        print("[HORST]", message)

        -- Keep loop light
        task.wait(2)
    end
end)
end

-- ═══════════════════════════════════════════════════════════════
-- [HAKI QUEST SYSTEM] + [NORMAL FARM] + [MAIN CONTROLLER] + [EVENTS]
-- Combined and guarded to preserve original behavior but avoid nil calls
-- ═══════════════════════════════════════════════════════════════

-- Safe wrappers for remotes and functions used in main loops
local function safeFire(remote, ...)
    if not remote then return false end
    if type(remote) == "string" then
        -- try to find in RemoteEvents or Remotes
        local r = RemoteEvents and RemoteEvents:FindFirstChild(remote) or Remotes and Remotes:FindFirstChild(remote)
        remote = r
    end
    if remote and remote.FireServer then
        local ok, err = pcall(function() remote:FireServer(...) end)
        if not ok then warn("safeFire error:", err) end
        return ok
    end
    return false
end

local function safeInvoke(remote, ...)
    if not remote then return nil end
    if remote.InvokeServer then
        local ok, res = pcall(function() return remote:InvokeServer(...) end)
        if ok then return res end
    end
    return nil
end

local function safeCall(fn, ...)
    if type(fn) == "function" then
        local ok, res = pcall(fn, ...)
        if ok then return res end
    end
    return nil
end

-- Haki quest functions (kept logic, added guards)
local function acceptHakiQuest()
    print("[HAKI QUEST] Accepting quest...")
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)

    pcall(function()
        if not player or not player.PlayerGui then return end
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local ok, title = pcall(function()
                return questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            end)
            if ok and title and not title:find("Path to Haki") then
                safeFire(abandonRemote, "repeatable")
                task.wait(2)
            else
                return
            end
        end
    end)

    pcall(function() tweenPos(CFrame.new(hakiPos)) end)
    task.wait(2)
    safeFire(questRemote, "HakiQuestNPC")
    task.wait(2)
end

local function safeSendKeyEvent(...)
    if VIM and VIM.SendKeyEvent then
        pcall(function() VIM:SendKeyEvent(...) end)
        return true
    end
    return false
end

local function goToHakiNPC()
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)
    pcall(function() tweenPos(CFrame.new(hakiPos)) end)
    task.wait(4)

    local char = player.Character

    for i = 1, 5 do
        print("[HAKI QUEST] Press E attempt", i)
        pcall(function()
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(hakiPos) * CFrame.new(0, 0, 3)
            end
        end)
        task.wait(0.5)
        safeSendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        safeSendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(2)

        local ok, haki = pcall(function() return checkHakiStatus and checkHakiStatus() end)
        if ok and haki then
            print("[HAKI QUEST] 🎉 Haki obtained via E key!")
            return true
        end
    end

    print("[HAKI QUEST] ❌ Failed to get Haki after E key attempts")
    return false
end

local function farmThiefForHaki()
    print("[HAKI QUEST] Starting Haki farm...")
    local targetNPC = "Thief"
    local killCount = 0
    local lastCheckKills = 0

    pcall(function()
        if not player or not player.PlayerGui then return end
        local questUI = player.PlayerGui:FindFirstChild("QuestUI")
        if questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible then
            local ok, title = pcall(function()
                return questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
            end)
            if ok and title and not title:find("Path to Haki") then
                safeFire(abandonRemote, "repeatable")
                task.wait(2)
            end
            local ok2, desc = pcall(function()
                return questUI.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
            end)
            if ok2 and desc then
                local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
                if name then targetNPC = name end
            end
        end
    end)

    safeFire(tpRemote, "Starter")
    task.wait(3)

    local farmStart = tick()

    while task.wait(0.5) do
        if not isHakiQuestActive then break end
        if tick() - farmStart > (_G.Config.HakiTimeout or 300) then
            print("[HAKI QUEST] ⚠️ Timeout!")
            isHakiQuestActive = false
            break
        end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then continue end

        local shouldGoToNPC = false
        local questUI = player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI")
        local questVisible = questUI and questUI:FindFirstChild("Quest") and questUI.Quest.Visible

        if questVisible then
            pcall(function()
                for _, child in pairs(questUI.Quest.Quest.Holder.Content.QuestInfo:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        if child.Text:find("Completed!") then
                            shouldGoToNPC = true
                            break
                        end
                        local cur, tot = child.Text:match("(%d+)/(%d+)")
                        if cur and tot and tonumber(cur) >= tonumber(tot) then
                            shouldGoToNPC = true
                        end
                    end
                end
            end)
        else
            if killCount > 5 and (killCount - lastCheckKills) >= 5 then
                shouldGoToNPC = true
            end
        end

        if shouldGoToNPC then
            print("[HAKI QUEST] 🔄 Going to NPC...")
            lastCheckKills = killCount

            if goToHakiNPC() then
                print("[HAKI QUEST] 🎉🎉 HAKI OBTAINED!")

                if _G.Config.BuyDarkBlade then
                    print("[HAKI QUEST] 🛒 Buying Dark Blade...")
                    isHakiQuestActive = false
                    pcall(function() if buyDarkBlade then buyDarkBlade() end end)
                end

                print("[HAKI QUEST] ✅ Complete!")
                return
            end

            pcall(function()
                local q = player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI")
                if q and q:FindFirstChild("Quest") and q.Quest.Visible then
                    local ok, desc = pcall(function()
                        return q.Quest.Quest.Holder.Content.QuestInfo.QuestDescription.Text
                    end)
                    if ok and desc then
                        local name = desc:match("Defeat the (%w+)") or desc:match("defeat (%w+)")
                        if name then targetNPC = name; print("[HAKI QUEST] New target:", targetNPC) end
                    end
                end
            end)

            safeFire(tpRemote, "Starter")
            task.wait(3)
            continue
        end

        local npcFound = false
        for i = 1, 5 do
            local npc = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild(targetNPC .. i)
            if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                npcFound = true
                local target = npc:FindFirstChild("HumanoidRootPart")
                if target then
                    while npc.Parent and npc.Humanoid.Health > 0 do
                        if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                        if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then break end
                        pcall(function() char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 5) end)
                        pcall(function() if hitRemote and hitRemote.FireServer then hitRemote:FireServer() end end)
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

-- Normal farm loop (guarded)
local function selectWeapon()
    if type(findDarkBladeInHand) == "function" then
        local ok, blade = pcall(findDarkBladeInHand)
        if ok and blade then return "Dark Blade" end
    end
    if type(equipDarkBladeFromInventory) == "function" then
        local ok, res = pcall(equipDarkBladeFromInventory)
        if ok and res then return "Dark Blade" end
    end
    if type(getBestWeapon) == "function" then
        local ok, w = pcall(getBestWeapon)
        if ok then return w end
    end
    return "Combat"
end

local function equipToolByName(toolName, char)
    if not char then return nil end
    local tool = nil
    if toolName == "Dark Blade" then
        local ok, blade = pcall(findDarkBladeInHand)
        if ok then tool = blade end
    else
        tool = (player and player.Backpack and player.Backpack:FindFirstChild(toolName)) or char:FindFirstChild(toolName)
    end

    if tool and tool.Parent == player.Backpack then
        print("[FARM] Equipping:", tool.Name)
        pcall(function() char.Humanoid:EquipTool(tool) end)
    end
    return tool
end

local function farmLoop()
    while _G.Config.AutoFarm do
        task.wait()

        if isHakiQuestActive or isBuyingDarkBlade or isFruitFarming or isFarmingIchigoBoss then
            task.wait(10)
            continue
        end

        local char = player and player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then continue end

        local questInfo = getQuestInfo()
        if not questInfo then continue end

        local questUI = player.PlayerGui and player.PlayerGui:FindFirstChild("Quest")
        if not questUI then continue end

        if not (player.PlayerGui:FindFirstChild("QuestUI") and player.PlayerGui.QuestUI.Quest and player.PlayerGui.QuestUI.Quest.Visible) then
            if type(_G.SmartTP) == "function" then pcall(_G.SmartTP, questInfo.position) end
            safeFire(questRemote, questInfo.npcName)
        else
            local titleText = nil
            pcall(function()
                local q = player.PlayerGui:FindFirstChild("QuestUI")
                if q and q.Quest and q.Quest.Quest and q.Quest.Quest.Holder and q.Quest.Quest.Holder.Content and q.Quest.Quest.Holder.Content.QuestInfo and q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle and q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle then
                    titleText = q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
                end
            end)
            if titleText and titleText ~= questInfo.questTitle then
                safeFire(abandonRemote, "repeatable")
            else
                local toolName = selectWeapon()
                local npcType = getNpcType(questInfo.npcName)
                if not npcType then continue end

                equipToolByName(toolName, char)

                local YPOS = _G.Config.CombatHeight or 5
                local firstMob = true

                while _G.Config.AutoFarm do
                    if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then break end
                    local qVisible = player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI") and player.PlayerGui.QuestUI.Quest and player.PlayerGui.QuestUI.Quest.Visible
                    if not qVisible then break end
                    local curTitle = nil
                    pcall(function()
                        local q = player.PlayerGui:FindFirstChild("QuestUI")
                        if q and q.Quest and q.Quest.Quest and q.Quest.Quest.Holder and q.Quest.Quest.Holder.Content and q.Quest.Quest.Holder.Content.QuestInfo and q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle and q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle then
                            curTitle = q.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text
                        end
                    end)
                    if curTitle and curTitle ~= questInfo.questTitle then break end

                    local closest = findNPC(npcType)

                    if not closest then
                        if firstMob then
                            print("[FARM] NPC:", npcType, "| Weapon:", toolName)
                            pcall(function() tweenPos(CFrame.new(questInfo.position)) end)
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
                        if not closest or not closest.Parent
                            or not closest:FindFirstChild("HumanoidRootPart")
                            or closest.Humanoid.Health <= 0 then
                            break
                        end

                        equipToolByName(toolName, char)

                        if BodyVelocity then
                            BodyVelocity.Velocity = Vector3.zero
                            BodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                            BodyVelocity.Parent = char.HumanoidRootPart
                        end

                        local success, owner = pcall(function()
                            return closest.HumanoidRootPart:GetNetworkOwner()
                        end)
                        if success and owner == player then
                            closest.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position)
                            closest.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                            closest.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                        end

                        pcall(function()
                            tweenPos(
                                CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, YPOS, 0)) * CFrame.Angles(math.rad(-90), 0, 0),
                                function()
                                    performFullCombo()
                                end
                            )
                        end)

                        pcall(function() if RemoteEvents and RemoteEvents:FindFirstChild("HakiRemote") then RemoteEvents.HakiRemote:FireServer("Toggle") end end)
                        pcall(function() if RemoteEvents and RemoteEvents:FindFirstChild("ObservationHakiRemote") then RemoteEvents.ObservationHakiRemote:FireServer("Toggle") end end)

                    until (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0)
                        or not (player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI") and player.PlayerGui.QuestUI.Quest and player.PlayerGui.QuestUI.Quest.Visible)
                        or (player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI") and player.PlayerGui.QuestUI.Quest and player.PlayerGui.QuestUI.Quest.Quest and player.PlayerGui.QuestUI.Quest.Quest.Holder and player.PlayerGui.QuestUI.Quest.Quest.Holder.Content and player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo and player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle and player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle and player.PlayerGui.QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle)

                    equipToolByName(toolName, char)
                    print("[FARM] Killed:", closest.Name, "→ Finding next mob...")
                    task.wait(0.1)
                end

                print("[FARM] Exit Farm Loop")
            end
        end
    end
end

-- MAIN CONTROLLER
task.spawn(function()
    task.wait(3)
    pcall(function()
        local backpack = player:WaitForChild("Backpack", 10)
        if not backpack then return end
        local char = player.Character
        if not char then return end
        local tool = backpack:FindFirstChild("Combat")
        if tool then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:EquipTool(tool)
            end
        end
    end)
end)

task.spawn(function()
    task.wait(15)
    if _G.Config.AutoBuyBossKey and type(setupBossKeyAutoListener) == "function" then
        pcall(setupBossKeyAutoListener)
    end
end)

task.spawn(function()
    task.wait(10)

    while _G.Config.AutoFarm do
        local level = 0
        pcall(function() if player and player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") then level = player.Data.Level.Value or 0 end end)
        print("[SYSTEM] 🔍 Level check:", level)

        if _G.Config.EarlyDarkBlade and level >= (_G.Config.EarlyDarkBladeLevel or 1500) then
            print("[SYSTEM] 🗡️ Level >= " .. (_G.Config.EarlyDarkBladeLevel or 1500) .. " → Checking Dark Blade...")
            local hasBlade = false
            if type(checkOwnerDarkBlade) == "function" then
                local ok, res = pcall(checkOwnerDarkBlade)
                if ok then hasBlade = res end
            end
            if not hasBlade and type(equipDarkBladeFromInventory) == "function" then
                local ok, res = pcall(equipDarkBladeFromInventory)
                if ok then hasBlade = res end
            end
            if not hasBlade then
                print("[SYSTEM] 🗡️ No Dark Blade → Buying...")
                if _G.Config.BuyDarkBlade then
                    pcall(function() if buyDarkBlade then buyDarkBlade() end end)
                end
            else
                print("[SYSTEM] ✅ Dark Blade already owned!")
            end
        end

        if level >= 11500 then
            print("[SYSTEM] 🎯 Level >= 11500 → Checking account completion...")
            local hasArmamentHaki = false
            local hasObservationHaki = false
            pcall(function()
                local hakiRemote = RemoteEvents and RemoteEvents:FindFirstChild("HakiRemote")
                if hakiRemote and hakiRemote.FireServer then
                    local ok, data = pcall(function() return hakiRemote:FireServer("GetProgression") end)
                    if ok and data and data.Armament then hasArmamentHaki = true end
                end
                if type(checkHasObservationHaki) == "function" then
                    local ok2, res2 = pcall(checkHasObservationHaki)
                    if ok2 then hasObservationHaki = res2 end
                end
            end)
            if hasArmamentHaki and hasObservationHaki then
                print("[SYSTEM] ✅ Level 11500+ with both Haki types!")
                if _G.Horst_AccountChangeDone then
                    local ok, err = pcall(_G.Horst_AccountChangeDone)
                    if ok then
                        print("[SYSTEM] ✅ Account change done sent successfully!")
                        task.wait(999999)
                    else
                        print("[SYSTEM] ❌ Failed to send DONE:", err)
                    end
                end
            end
        end

        if level < (_G.Config.HakiMinLevel or 1) then
            print("[SYSTEM] 📈 Level " .. level .. " - Normal Farm (Melee)")
            task.wait(60)
            continue
        end

        if level >= 4000 then
            print("[SYSTEM] 💎 Level >= 4000 → Checking Artifacts...")
            if type(checkArtifactsUnlocked) == "function" then
                local ok, unlocked = pcall(checkArtifactsUnlocked)
                if ok and not unlocked then
                    print("[SYSTEM] 🔓 Unlocking Artifacts...")
                    local ok2, res = pcall(unlockArtifacts)
                    if ok2 and res then
                        print("[SYSTEM] ✅ Artifacts unlocked! Equipping...")
                        pcall(equipArtifacts)
                    end
                else
                    print("[SYSTEM] ✅ Artifacts already unlocked")
                end
            end
        end

        if level >= 6000 then
            print("[SYSTEM] 👁️ Level >= 6000 → Checking Observation Haki...")
            if type(checkHasObservationHaki) == "function" then
                local ok, hasObs = pcall(checkHasObservationHaki)
                if ok and not hasObs then
                    print("[SYSTEM] 🔓 Buying Observation Haki...")
                    pcall(buyObservationHaki)
                else
                    print("[SYSTEM] ✅ Observation Haki already owned")
                end
            end
        end

        if _G.Config.FarmSaberBoss and type(checkBossKeyCount) == "function" then
            local ok, bossKeyCount = pcall(checkBossKeyCount)
            if ok and bossKeyCount and bossKeyCount >= 1 then
                print("[SYSTEM] 🎯 Starting Saber Boss farm...")
                pcall(farmSaberBoss)
                task.wait(5)
            else
                print("[SYSTEM] ⚠️ Not enough Boss Keys for Saber Boss (need 1)")
            end
        end

        if _G.Config.ExchangeIchigo and level >= (_G.Config.IchigoMinLevel or 0) then
            print("[SYSTEM] ⚔️ Checking Ichigo Exchange...")
            if type(checkDarkBlade) == "function" then
                local ok, hasIchigo = pcall(checkDarkBlade, "Ichigo")
                if ok and not hasIchigo then
                    local ok2, hasAll, missing = pcall(checkIchigoRequirements)
                    if ok2 and hasAll then
                        print("[SYSTEM] ✅ All Ichigo requirements met! Exchanging...")
                        pcall(exchangeIchigo)
                    else
                        print("[SYSTEM] ❌ Missing Ichigo requirements:")
                        if missing and type(missing) == "table" then
                            for _, item in pairs(missing) do
                                print("[SYSTEM]   - " .. item)
                            end
                        end
                    end
                else
                    print("[SYSTEM] ✅ Ichigo already owned")
                end
            end
        end

        print("[SYSTEM] 🗡️ Checking Dark Blade...")
        local hasBlade = false
        if type(findDarkBladeInHand) == "function" then
            local ok, res = pcall(findDarkBladeInHand)
            if ok and res then hasBlade = true end
        end
        if not hasBlade and type(equipDarkBladeFromInventory) == "function" then
            local ok, res = pcall(equipDarkBladeFromInventory)
            if ok and res then hasBlade = true end
        end

        if hasBlade then
            print("[SYSTEM] ✅ Dark Blade found!")
            if _G.Config.FruitFarm and level >= (_G.Config.FruitMinLevel or 0) then
                print("[SYSTEM] 🍎 Level " .. level .. " >= " .. (_G.Config.FruitMinLevel or 0) .. " → Checking Fruit Farm...")
                local ok, hasFruit = pcall(checkHasFruit, _G.Config.TargetFruit)
                if ok and hasFruit then
                    print("[SYSTEM] ✅ Already have " .. (_G.Config.TargetFruit or "fruit") .. " → Fruit Farm Mode!")
                    isFruitFarming = true
                    pcall(equipFruit, _G.Config.TargetFruit)
                    local island = _G.Config.FruitFarmIsland
                    local pos = _G.Config.FruitFarmPos
                    safeFire(tpRemote, island)
                    task.wait(3)
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and pos then
                        for i = 1, 10 do
                            char.HumanoidRootPart.CFrame = pos
                            task.wait(0.1)
                        end
                    end
                    task.spawn(function() if type(fruitFarmLoop) == "function" then pcall(fruitFarmLoop) end end)
                    break
                else
                    print("[SYSTEM] ❌ No " .. tostring(_G.Config.TargetFruit) .. " → Starting Fruit Farm process...")
                    pcall(startFruitFarm)
                    break
                end
            else
                print("[SYSTEM] ✅ Dark Blade found! Normal Farm...")
                break
            end
        end

        print("[SYSTEM] ❌ No Dark Blade | Checking Haki...")
        local hasHaki = false
        if type(checkHakiStatus) == "function" then
            local ok, res = pcall(checkHakiStatus)
            if ok then hasHaki = res end
        end

        if hasHaki then
            print("[SYSTEM] ✅ Has Haki but no Dark Blade → Buying...")
            if _G.Config.BuyDarkBlade then
                pcall(function() if buyDarkBlade then buyDarkBlade() end end)
            end
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

-- EVENT HANDLERS
if player then
    player.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Failed then
            task.wait(1.5)
            pcall(function() if rejoin then rejoin() end end)
        end
    end)
end

Players.PlayerRemoving:Connect(function()
    pcall(function()
        if pcall(function() return game.HttpGet end) then
            pcall(function() game:HttpGet("https://node-api--0890939481gg.replit.app/leave") end)
        end
    end)
end)

-- HEARTBEAT PHYSICS LOCK
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if player and player.Character then
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
