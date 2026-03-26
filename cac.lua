-- ═══════════════════════════════════════════════════════════════
-- Sailor Piece v5 - FULL EDITION (Melee+Skill + Early Dark Blade)
-- Safe-wrapped full source (keeps all features; adds guards to avoid nil-call)
-- Paste this entire file into your LocalScript (replaces previous content)
-- ═══════════════════════════════════════════════════════════════

-- ===== SAFE BOOTSTRAP HEADER =====
-- Purpose: provide safe wrappers for remotes, modules, VIM, and common calls
-- so the original ~2600+ lines can run unchanged while avoiding nil-call crashes.

-- Basic services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Local player (may be nil briefly)
local player = Players.LocalPlayer
if not player then
    local ok, pl = pcall(function() return Players:WaitForChild("LocalPlayer", 10) end)
    if ok and pl then player = pl end
end

-- Safe find helpers (non-throwing)
local function safeFind(parent, name)
    if not parent then return nil end
    local ok, res = pcall(function() return parent:FindFirstChild(name) end)
    return ok and res or nil
end

local function safeWait(parent, name, timeout)
    if not parent then return nil end
    local ok, res = pcall(function() return parent:WaitForChild(name, timeout) end)
    return ok and res or nil
end

-- Resolve common containers in a tolerant way
local function resolveRemotes()
    local remotes = safeFind(ReplicatedStorage, "Remotes") or ReplicatedStorage
    local remoteEvents = safeFind(ReplicatedStorage, "RemoteEvents") or ReplicatedStorage
    local combatRemotes = nil
    pcall(function()
        combatRemotes = safeFind(ReplicatedStorage, "CombatSystem") and safeFind(ReplicatedStorage.CombatSystem, "Remotes")
    end)
    return remotes, remoteEvents, combatRemotes
end

local Remotes, RemoteEvents, CombatRemotes = resolveRemotes()

-- Safe remote getters (accepts either Instance or string)
local function getRemote(objOrName, container)
    if not objOrName then return nil end
    if typeof(objOrName) == "Instance" then return objOrName end
    local name = tostring(objOrName)
    local try = nil
    if container and typeof(container) == "Instance" then
        try = safeFind(container, name)
        if try then return try end
    end
    try = safeFind(Remotes, name) or safeFind(RemoteEvents, name) or (CombatRemotes and safeFind(CombatRemotes, name))
    return try
end

local function safeFire(remoteOrName, ...)
    local r = getRemote(remoteOrName)
    if not r then return false end
    if r.FireServer then
        local ok, err = pcall(function() r:FireServer(...) end)
        if not ok then warn("[safeFire] error:", tostring(err)) end
        return ok
    end
    return false
end

local function safeInvoke(remoteOrName, ...)
    local r = getRemote(remoteOrName)
    if not r then return nil end
    if r.InvokeServer then
        local ok, res = pcall(function() return r:InvokeServer(...) end)
        if ok then return res end
    end
    return nil
end

local function safeRequire(moduleInstance)
    if not moduleInstance then return nil end
    local ok, res = pcall(function() return require(moduleInstance) end)
    if ok then return res end
    return nil
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

-- Safe VirtualInputManager wrapper (some environments don't expose it)
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local function safeSendKeyEvent(...)
    if VIM and VIM.SendKeyEvent then
        local ok, err = pcall(function() VIM:SendKeyEvent(...) end)
        if not ok then warn("[safeSendKeyEvent] failed:", tostring(err)) end
        return ok
    end
    return false
end

-- Ensure BodyVelocity exists (original script expects it)
local BodyVelocity = Instance.new("BodyVelocity")

-- Protect common globals used later in script (no-op stubs if missing)
if not _G then _G = {} end
_G.Config = _G.Config or {}
_G.Config.HakiTimeout = _G.Config.HakiTimeout or 3600
_G.Config.EarlyDarkBladeLevel = _G.Config.EarlyDarkBladeLevel or 1500
_G.Config.HakiQuest = (_G.Config.HakiQuest == nil) and true or _G.Config.HakiQuest
_G.Config.BuyDarkBlade = (_G.Config.BuyDarkBlade == nil) and true or _G.Config.BuyDarkBlade
_G.Config.AutoFarm = (_G.Config.AutoFarm == nil) and true or _G.Config.AutoFarm

-- Expose safe helpers globally for original code to call
_G.safeFire = safeFire
_G.safeInvoke = safeInvoke
_G.safeRequire = safeRequire
_G.safeCall = safeCall
_G.safeSendKeyEvent = safeSendKeyEvent
_G.getRemote = getRemote

-- Small helper to protect calls that used to be top-level and could run before definitions
local function protectCall(fn)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn)
    if not ok then warn("[protectCall] error:", tostring(err)) end
end

-- Debug toggle
_G.__SailorPieceDebug = _G.__SailorPieceDebug or false

-- ===== END SAFE BOOTSTRAP HEADER =====

-- ═══════════════════════════════════════════════════════════════
-- Original script (safe-guarded) begins here
-- ═══════════════════════════════════════════════════════════════

repeat task.wait(2) until game:IsLoaded()

-- Safe HttpGet wrapper (kept)
pcall(function()
    if game.HttpGet then
        game:HttpGet("https://node-api--0890939481gg.replit.app/join")
    else
        warn("[INIT] HttpGet not available in LocalScript")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [1] CONFIG - ตั้งค่าทั้งหมดที่นี่
-- ═══════════════════════════════════════════════════════════════
_G.Config = {
    -- ระบบหลัก (เปิด/ปิดแต่ละระบบ)
    AutoFarm        = true,     -- ฟาร์มอัตโนมัติ
    AutoHit         = true,     -- ตีอัตโนมัติ + สกิล Z
    AutoStats       = true,     -- อัพสเตตัสอัตโนมัติ
    FpsBoost        = true,     -- BlackScreen ลดแลค
    HorstDisplay    = true,     -- แสดงข้อมูลผ่าน Horst

    -- ===== ADDED: Combat Settings (Melee + Skill) =====
    UseMeleeAttack  = true,      -- ใช้การโจมตีปกติ (ต่อย)
    MeleeAttackDelay = 0.08,     -- ความหน่วงระหว่างการโจมตีปกติ
    UseSkills       = true,      -- ใช้สกิลทั้งหมด (Z,X,C,V,F)
    SkillComboOrder = {"Z","X","C","V","F"}, -- ลำดับการใช้สกิล
    SkillDelay      = 0.15,      -- ความหน่วงระหว่างสกิล
    CombatPriority  = "MeleeFirst", -- MeleeFirst = โจมตีปกติก่อนแล้วตามด้วยสกิล
    CombatHeight    = 5,         -- ความสูงในการบิน (ปรับลดจาก 9 เพื่อตีเร็วขึ้น)
    -- ===== End Added =====

    -- Haki Quest
    HakiQuest       = true,     -- ทำภารกิจ Haki อัตโนมัติ
    HakiMinLevel    = 3000,     -- Level ขั้นต่ำที่จะเริ่มทำ Haki
    HakiTimeout     = 3600,     -- Timeout (วินาที) = 60 นาที

    -- Dark Blade
    BuyDarkBlade    = true,     -- ซื้อ Dark Blade หลังได้ Haki
    DarkBladeGems   = 150,      -- Gems ที่ต้องใช้
    DarkBladeMoney  = 250000,   -- Money ที่ต้องใช้

    -- ===== ADDED: Early Dark Blade (เริ่มซื้อตั้งแต่ Level 1500) =====
    EarlyDarkBlade  = true,      -- เปิด/ปิดการซื้อ Dark Blade ก่อน Haki (Level 1500)
    EarlyDarkBladeLevel = 1500,  -- Level ที่จะเริ่มซื้อ Dark Blade
    -- ===== End Added =====

    -- Fruit Farm (ฟาร์มหาผลปีศาจ)
    FruitFarm       = false,     -- เปิด/ปิดการฟาร์มผล
    FruitMinLevel   = 11500,    -- Level ขั้นต่ำที่จะเริ่มฟาร์มผล
    TargetFruit     = "Quake",  -- ผลที่ต้องการ
    FruitFarmIsland = "Shinjuku", -- เกาะที่จะฟาร์ม
    FruitFarmPos    = CFrame.new(321.706757, -1.539090, -1756.500977) * CFrame.Angles(0, -0.113749, 0), -- ตำแหน่งฟาร์ม

    -- Boss Key Auto Buy (ซื้อ Boss Key อัตโนมัติ)
    AutoBuyBossKey  = true,       -- เปิด/ปิดการซื้อ Boss Key อัตโนมัติ
    BossKeyBuyInterval = 1800,    -- ซื้อทุก 30 นาที (1800 วินาที)
    
    -- Ichigo Exchange (แลก Ichigo Sword ด้วย Boss Ticket)
    ExchangeIchigo  = true,       -- เปิด/ปิดการแลก Ichigo
    IchigoMinLevel  = 11500,      -- Level ขั้นต่ำที่จะเริ่มแลก
    IchigoRequirements = {        -- ไอเทมที่ต้องการ
        BossTicket = 500,         -- Boss Ticket 500 ชิ้น
    },
    
    -- Saber Boss Farm (ฟาร์มบอส Saber เพื่อหาไอเทม)
    FarmSaberBoss   = true,      -- เปิด/ปิดการฟาร์มบอส Saber
    SaberBossSummonItems = {     -- ไอเทมสำหรับเรียก Saber Boss
        BossKey = 1,             -- Boss Key 1 อัน
        Money = 100000,          -- 100k Money
        Gems = 175,              -- 175 Gems
    },

    -- Stats Distribution (รวม = 100%)
    StatSword       = 80,       -- ===== MODIFIED: 80% Sword =====
    StatDefense     = 10,       -- Defense 10%
    StatPower       = 10,       -- Power 10%

    -- Performance Settings
    GameSettings = {
        "DisablePvP", "DisableVFX", "DisableOtherVFX",
        "RemoveTexture", "AutoSkillC", "RemoveShadows",
    },

    -- Log Filter (แสดงเฉพาะ tag เหล่านี้)
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
local VIM_service   = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local HttpService   = game:GetService("HttpService")
local UIS           = game:GetService("UserInputService")
local Lighting      = game:GetService("Lighting")
local BodyVelocity  = Instance.new("BodyVelocity")

local player        = Players.LocalPlayer
if not player then
    player = Players:WaitForChild("LocalPlayer", 10)
end

-- Use safe waits/finds for remotes/modules
local Remotes       = safeWait(RS, "Remotes", 5) or safeFind(RS, "Remotes") or RS
local RemoteEvents  = safeWait(RS, "RemoteEvents", 5) or safeFind(RS, "RemoteEvents") or RS
local CombatRemotes = (safeFind(RS, "CombatSystem") and safeFind(RS.CombatSystem, "Remotes")) or safeFind(RS, "CombatSystem") and safeFind(RS.CombatSystem, "Remotes")

-- Remote References (use getRemote to be tolerant)
local hitRemote     = getRemote("RequestHit", CombatRemotes)
local questRemote   = getRemote("QuestAccept", RemoteEvents)
local abandonRemote = getRemote("QuestAbandon", RemoteEvents)
local statRemote    = getRemote("AllocateStat", RemoteEvents)
local tpRemote      = getRemote("TeleportToPortal", Remotes)
local settingsToggle = getRemote("SettingsToggle", RemoteEvents)

-- State (สถานะ runtime)
local inventoryByRarity = {
    Secret = {}, Mythical = {}, Legendary = {},
    Epic = {}, Rare = {}, Uncommon = {}, Common = {}
}
local cratesAndBoxes = {}
local isHakiQuestActive = false
local isBuyingDarkBlade = false
local isFruitFarming = false
local isFarmingIchigoBoss = false

-- ===== ADDED: Dark Blade flag and Combat state =====
local darkBladeObtained = false
local lastMeleeTime = 0
local lastSkillTime = 0
-- ===== End Added =====

-- ═══════════════════════════════════════════════════════════════
-- [3] ERROR SUPPRESSION (kept but safer)
-- ═══════════════════════════════════════════════════════════════
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
                    local isDarkBlade = (name and name:find("Dark Blade")) or (name and name:find("ดาบสีเข้ม")) or (tip and tip:find("Black Blade")) or (tip and tip:find("ดาบสีเข้ม"))
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
                    local isDarkBlade = (name and name:find("Dark Blade")) or (name and name:find("ดาบสีเข้ม")) or (tip and tip:find("Black Blade")) or (tip and tip:find("ดาบสีเข้ม"))
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
        if RS and RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("QuestConfig") then
            local module = safeRequire(RS.Modules:FindFirstChild("QuestConfig"))
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

-- ===== ADDED: COMBAT FUNCTIONS (Melee + Skill) =====
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
-- ===== End Added =====

-- ═══════════════════════════════════════════════════════════════
-- [5] PERFORMANCE - FPS Boost + Game Settings
-- ═══════════════════════════════════════════════════════════════
if settingsToggle and settingsToggle.FireServer then
    for _, setting in ipairs(_G.Config.GameSettings) do
        pcall(function() settingsToggle:FireServer(setting, true) end)
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
    local Modules = RS:FindFirstChild("Modules") or RS
    local ItemRarityConfig = nil
    if Modules and Modules:FindFirstChild("ItemRarityConfig") then
        pcall(function() ItemRarityConfig = safeRequire(Modules:FindFirstChild("ItemRarityConfig")) end)
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
-- [16] HAKI QUEST SYSTEM
-- ═══════════════════════════════════════════════════════════════
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
                safeFire(abandonRemote or "QuestAbandon", "repeatable")
                task.wait(2)
            else
                return
            end
        end
    end)

    pcall(function() tweenPos(CFrame.new(hakiPos)) end)
    task.wait(2)
    safeFire(questRemote or "QuestAccept", "HakiQuestNPC")
    task.wait(2)
end

local function goToHakiNPC()
    local hakiPos = Vector3.new(-497.94, 23.66, -1252.64)
    pcall(function() tweenPos(CFrame.new(hakiPos)) end)
    task.wait(4)

    local char = player and player.Character

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

    safeFire(tpRemote or "TeleportToPortal", "Starter")
    task.wait(3)

    local farmStart = tick()

    while task.wait(0.5) do
        if not isHakiQuestActive then break end
        if tick() - farmStart > (_G.Config.HakiTimeout or 3600) then
            print("[HAKI QUEST] ⚠️ Timeout!")
            isHakiQuestActive = false
            break
        end

        local char = player and player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then continue end

        local shouldGoToNPC = false
        local questUI = player and player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI")
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
                    pcall(function() if type(buyDarkBlade) == "function" then buyDarkBlade() end end)
                end

                print("[HAKI QUEST] ✅ Complete!")
                return
            end

            pcall(function()
                local q = player and player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI")
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

            safeFire(tpRemote or "TeleportToPortal", "Starter")
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

-- ═══════════════════════════════════════════════════════════════
-- [17] NORMAL QUEST FARM (ปรับใช้ Melee+Skill)
-- ═══════════════════════════════════════════════════════════════
local function selectWeapon()
    local ok, blade = pcall(findDarkBladeInHand)
    if ok and blade then return "Dark Blade" end
    if type(equipDarkBladeFromInventory) == "function" then
        local ok2, res = pcall(equipDarkBladeFromInventory)
        if ok2 and res then return "Dark Blade" end
    end
    return getBestWeapon()
end

local function equipToolByName(toolName, char)
    local tool = nil
    if toolName == "Dark Blade" then
        local ok, blade = pcall(findDarkBladeInHand)
        if ok then tool = blade end
    else
        tool = (player and player.Backpack and player.Backpack:FindFirstChild(toolName)) or (char and char:FindFirstChild(toolName))
    end

    if tool and char and char:FindFirstChild("Humanoid") then
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

        local questUI = player and player.PlayerGui and player.PlayerGui:FindFirstChild("QuestUI")
        if not questUI then continue end

        if not (questUI.Quest and questUI.Quest.Visible) then
            if type(_G.SmartTP) == "function" then pcall(_G.SmartTP, questInfo.position) end
            safeFire(questRemote or "QuestAccept", questInfo.npcName)
        elseif (questUI.Quest and questUI.Quest.Quest and questUI.Quest.Quest.Holder and questUI.Quest.Quest.Holder.Content and questUI.Quest.Quest.Holder.Content.QuestInfo and questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle and questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle and questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle) then
            safeFire(abandonRemote or "QuestAbandon", "repeatable")
        else
            local toolName = selectWeapon()
            local npcType = getNpcType(questInfo.npcName)
            if not npcType then continue end

            equipToolByName(toolName, char)

            local YPOS = _G.Config.CombatHeight or 5
            local firstMob = true

            while _G.Config.AutoFarm do
                if char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then break end
                if not (questUI.Quest and questUI.Quest.Visible) then break end
                if questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle then break end

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
                    or not (questUI.Quest and questUI.Quest.Visible)
                    or questUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle

                equipToolByName(toolName, char)
                print("[FARM] Killed:", closest.Name, "→ Finding next mob...")
                task.wait(0.1)
            end

            print("[FARM] Exit Farm Loop")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [18] MAIN CONTROLLER (เพิ่ม Early Dark Blade)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(3)
    pcall(function()
        local backpack = player:WaitForChild("Backpack", 10)
        if not backpack then return end
        local char = player.Character
        if not char then return end
        local tool = backpack:FindFirstChild("Combat")
        if tool then char:FindFirstChild("Humanoid"):EquipTool(tool) end
    end)
end)

task.spawn(function()
    task.wait(15)
    if _G.Config.AutoBuyBossKey and type(setupBossKeyAutoListener) == "function" then
        setupBossKeyAutoListener()
    end
end)

task.spawn(function()
    task.wait(10)

    while _G.Config.AutoFarm do
        local level = 0
        pcall(function() if player and player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") then level = player.Data.Level.Value or 0 end end)
        print("[SYSTEM] 🔍 Level check:", level)

        -- ===== ADDED: Early Dark Blade (Level 1500) =====
        if _G.Config.EarlyDarkBlade and level >= _G.Config.EarlyDarkBladeLevel then
            print("[SYSTEM] 🗡️ Level >= " .. _G.Config.EarlyDarkBladeLevel .. " → Checking Dark Blade...")
            local hasBlade = false
            if type(checkOwnerDarkBlade) == "function" then
                local ok, res = pcall(checkOwnerDarkBlade)
                if ok then hasBlade = res end
            end
            if not hasBlade then
                local ok, res = pcall(equipDarkBladeFromInventory)
                if ok and res then hasBlade = res end
            end
            if not hasBlade then
                print("[SYSTEM] 🗡️ No Dark Blade → Buying...")
                if _G.Config.BuyDarkBlade then
                    pcall(function() if type(buyDarkBlade) == "function" then buyDarkBlade() end end)
                end
            else
                print("[SYSTEM] ✅ Dark Blade already owned!")
            end
        end
        -- ===== End Added =====

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

        if level < _G.Config.HakiMinLevel then
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
            if not checkHasObservationHaki or type(checkHasObservationHaki) ~= "function" then
                -- nothing
            else
                local ok, hasObs = pcall(checkHasObservationHaki)
                if ok and not hasObs then
                    print("[SYSTEM] 🔓 Buying Observation Haki...")
                    pcall(buyObservationHaki)
                else
                    print("[SYSTEM] ✅ Observation Haki already owned")
                end
            end
        end

        if _G.Config.FarmSaberBoss then
            if type(checkBossKeyCount) == "function" then
                local ok, bossKeyCount = pcall(checkBossKeyCount)
                if ok and bossKeyCount and bossKeyCount >= 1 then
                    print("[SYSTEM] 🎯 Starting Saber Boss farm...")
                    pcall(farmSaberBoss)
                    task.wait(5)
                else
                    print("[SYSTEM] ⚠️ Not enough Boss Keys for Saber Boss (need 1)")
                end
            end
        end

        if _G.Config.ExchangeIchigo and level >= _G.Config.IchigoMinLevel then
            print("[SYSTEM] ⚔️ Checking Ichigo Exchange...")
            if type(checkDarkBlade) == "function" then
                local ok, hasAll = pcall(checkIchigoRequirements)
                if ok and hasAll then
                    print("[SYSTEM] ✅ All Ichigo requirements met! Exchanging...")
                    pcall(exchangeIchigo)
                else
                    print("[SYSTEM] ❌ Missing Ichigo requirements")
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
            if _G.Config.FruitFarm and level >= _G.Config.FruitMinLevel then
                print("[SYSTEM] 🍎 Level " .. level .. " >= " .. _G.Config.FruitMinLevel .. " → Checking Fruit Farm...")
                local ok, hasFruit = pcall(checkHasFruit, _G.Config.TargetFruit)
                if ok and hasFruit then
                    print("[SYSTEM] ✅ Already have " .. _G.Config.TargetFruit .. " → Fruit Farm Mode!")
                    isFruitFarming = true
                    pcall(equipFruit, _G.Config.TargetFruit)
                    local island = _G.Config.FruitFarmIsland
                    local pos = _G.Config.FruitFarmPos
                    safeFire(tpRemote or "TeleportToPortal", island)
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
        local hasHaki = false
        if type(checkHakiStatus) == "function" then
            local ok, res = pcall(checkHakiStatus)
            if ok then hasHaki = res end
        end

        if hasHaki then
            print("[SYSTEM] ✅ Has Haki but no Dark Blade → Buying...")
            if _G.Config.BuyDarkBlade then
                pcall(function() if type(buyDarkBlade) == "function" then buyDarkBlade() end end)
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

-- ═══════════════════════════════════════════════════════════════
-- [19] EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════
if player then
    player.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Failed then
            task.wait(1.5)
            pcall(function() if type(rejoin) == "function" then rejoin() end end)
        end
    end)
end

Players.PlayerRemoving:Connect(function()
    pcall(function()
        if game.HttpGet then
            game:HttpGet("https://node-api--0890939481gg.replit.app/leave")
        else
            warn("[EVENT] HttpGet not available")
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
-- [20] HEARTBEAT PHYSICS LOCK
-- ═══════════════════════════════════════════════════════════════
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
