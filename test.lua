if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local VU = game:GetService("VirtualUser")
local SafeGuiParent = plr:WaitForChild("PlayerGui")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui") or SafeGuiParent

-- ANTI AFK
plr.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local function CommF_(...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local comm = remotes:FindFirstChild("CommF_")
        if comm then return comm:InvokeServer(...) end
    end
    return nil
end

local function getLevel()
    local lvl = 0
    pcall(function()
        if plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level") then
            lvl = plr.Data.Level.Value
        end
    end)
    return lvl
end

local function checkRaceV3()
    local char = plr.Character
    local bp = plr:FindFirstChild("Backpack")
    
    if char and char:FindFirstChild("RaceTransformed") then
        return "V4"
    end
    
    local v3Skills = {"Last Resort", "Agility", "Water Body", "Heavenly Blood", "Heightened Senses", "Energy Core"}
    for _, skill in ipairs(v3Skills) do
        if (char and char:FindFirstChild(skill)) or (bp and bp:FindFirstChild(skill)) then
            return "V3"
        end
    end

    local v1 = CommF_("Wenlocktoad", "1")
    local v2 = CommF_("Alchemist", "1")
    return (v1 == -2 and "V3") or (v2 == -2 and "V2") or "V1"
end

-- =====================================================================
-- KIỂM TRA VŨ KHÍ LEGENDARY (YAMA, TUSHITA, CDK)
-- =====================================================================
local function checkWeapon(weaponName)
    local bp = plr:FindFirstChild("Backpack")
    local char = plr.Character
    
    if bp and bp:FindFirstChild(weaponName) then return true end
    if char and char:FindFirstChild(weaponName) then return true end
    
    local inv = CommF_("getInventory")
    if type(inv) == "table" then
        for _, item in pairs(inv) do
            if item.Name == weaponName then return true end
        end
    end
    
    return false
end

local function hasYama()
    return checkWeapon("Yama")
end

local function hasTushita()
    return checkWeapon("Tushita")
end

local function hasCDK()
    return checkWeapon("Cursed Dual Katana")
end

-- =====================================================================
-- KIỂM TRA VÀ CHUYỂN SEA
-- =====================================================================
local function getCurrentSea()
    local placeId = game.PlaceId
    if placeId == 2753915549 or placeId == 4442272183 then
        return 2 -- Sea 2
    elseif placeId == 7449423635 then
        return 3 -- Sea 3
    else
        return 1 -- Sea 1
    end
end

local function travelToSea2()
    local currentSea = getCurrentSea()
    if currentSea ~= 2 then
        print("[Travel] Đang di chuyển về Sea 2...")
        CommF_("TravelDressrosa")
        task.wait(10)
    end
end

local function travelToSea3()
    local currentSea = getCurrentSea()
    if currentSea ~= 3 then
        print("[Travel] Đang di chuyển lên Sea 3...")
        CommF_("TravelZou")
        task.wait(10)
    end
end

-- =====================================================================
-- HỆ THỐNG CHECK QUEST HAZE
-- =====================================================================
local function isDoingHazeQuest()
    local questTitle = plr.PlayerGui:FindFirstChild("Main") 
        and plr.PlayerGui.Main:FindFirstChild("Quest") 
        and plr.PlayerGui.Main.Quest:FindFirstChild("Container")
        and plr.PlayerGui.Main.Quest.Container:FindFirstChild("QuestTitle")
    
    if questTitle and questTitle.Text then
        if questTitle.Text:find("Haze") then return true end
    end
    return false
end

-- =====================================================================
-- CONFIG SYSTEM
-- =====================================================================
local config = _G.UltimateConfig or {}
local kaitunCfg = config.Kaitun or {}
local bananaCfg = config.BananaVIP or {}
local cdkCfg = config.AutoCDK or {}
local levelThreshold = config.LevelThreshold or 2500

-- =====================================================================
-- BIẾN GLOBAL CONTROL
-- =====================================================================
_G.IsDoingAutoCDK = false
_G.CDKPriority = false
_G.NeedV3First = false
_G.V3Completed = false

-- =====================================================================
-- HỆ THỐNG TỰ ĐỘNG CHẠY KAITUN (CẢI TIẾN)
-- =====================================================================
local KaitunLoaded = false

local function CanRunKaitun()
    if isDoingHazeQuest() then return true, "Đang làm quest Haze" end
    if hasCDK() then return true, "Đã có CDK" end
    return false, "Chưa có CDK và không làm quest Haze"
end

local function TryLoadKaitun()
    if not kaitunCfg.Enabled or KaitunLoaded then return end
    
    if _G.IsDoingAutoCDK or _G.NeedV3First then
        print("[Hệ Thống] Kaitun bị tạm dừng (Đang Auto CDK hoặc Farm V3)")
        return
    end
    
    local currentLvl = getLevel()
    
    if currentLvl < levelThreshold then
        KaitunLoaded = true
        print("[Hệ Thống] Kích hoạt Kaitun (Level: " .. currentLvl .. "/" .. levelThreshold .. ")")
        task.spawn(function()
            getgenv().Key = kaitunCfg.Key or ""
            getgenv().SettingFarm = kaitunCfg.SettingFarm or {}
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-kaitunBF.lua"))()
        end)
        return
    end
    
    local canRun, reason = CanRunKaitun()
    
    if canRun then
        local raceStatus = checkRaceV3()
        if raceStatus == "V3" or raceStatus == "V4" then
            KaitunLoaded = true
            print("[Hệ Thống] Kích hoạt Kaitun (" .. reason .. " + V3/V4)")
            task.spawn(function()
                getgenv().Key = kaitunCfg.Key or ""
                getgenv().SettingFarm = kaitunCfg.SettingFarm or {}
                loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-kaitunBF.lua"))()
            end)
        else
            print("[Hệ Thống] Chờ Farm V3...")
        end
    else
        print("[Hệ Thống] " .. reason)
    end
end

task.spawn(function()
    while task.wait(5) do
        TryLoadKaitun()
    end
end)

-- =====================================================================
-- AUTO CDK SYSTEM (TÍCH HỢP CODE TỪ FILE auto_cdk.txt)
-- =====================================================================
local AutoCDKLoaded = false

local function StartAutoCDK()
    if AutoCDKLoaded or not (cdkCfg and cdkCfg.Enabled) then return end
    
    AutoCDKLoaded = true
    _G.IsDoingAutoCDK = true
    _G.CDKPriority = true
    
    print("[AUTO CDK] ============================================")
    print("[AUTO CDK] BẮT ĐẦU AUTO CDK!")
    print("[AUTO CDK] ============================================")
    
    task.spawn(function()
        -- TỰ ĐỘNG LÊN SEA 3 NẾU ĐANG Ở SEA KHÁC
        travelToSea3()
        task.wait(2)
        
        -- LOAD CODE AUTO CDK TỪ FILE
        _G.Auto_DualKatana = true
        _G.TargetMastery = 350
        _G.HeightFarm = 40
        _G.AutoFarm_Bone = false
        _G.BringMob = true
        _G.CurrentSword = "Tushita"
        
        local Pos = CFrame.new(0, _G.HeightFarm, 0)
        local API_SOUL_REAPER = "http://14.174.145.113:8080/get_soulreaper.php"
        local API_CAKE_QUEEN = "http://14.174.145.113:8080/get_cakequeen.php"
        local API_PIRATE_RAID = "http://14.174.145.113:8080/get_pirateraid.php"
        
        local TweenService = game:GetService("TweenService")
        local VIM = game:GetService("VirtualInputManager")
        
        -- ==========================================
        -- HÀM CHIẾN ĐẤU
        -- ==========================================
        local Net = require(ReplicatedStorage.Modules.Net)
        local RegisterAttack = Net:RemoteEvent("RegisterAttack", true)
        local RegisterHit = Net:RemoteEvent("RegisterHit", true)
        
        local function AttackNoCoolDown()
            pcall(function()
                local char = plr.Character
                if not char or char.Humanoid.Health <= 0 then return end
                
                local targets = {}
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                        if (v.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude <= 100 then
                            table.insert(targets, {v, v.HumanoidRootPart})
                        end
                    end
                end
                
                if #targets > 0 then
                    RegisterAttack:FireServer(0)
                    RegisterHit:FireServer(targets[1][1]:FindFirstChild("Head") or targets[1][2], targets)
                    VU:CaptureController()
                    VU:ClickButton1(Vector2.new())
                    
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    if equippedTool and equippedTool:FindFirstChild("LeftClick") then
                        equippedTool.LeftClick:FireServer()
                    end
                end
            end)
        end
        
        local function EquipSword(itemName)
            local char = plr.Character
            if not char or char.Humanoid.Health <= 0 then return end

            local toolInChar = char:FindFirstChild(itemName)
            local toolInBack = plr.Backpack:FindFirstChild(itemName)

            if not toolInChar and not toolInBack then
                pcall(function() CommF_("LoadItem", itemName) end)
                task.wait(0.2)
                toolInBack = plr.Backpack:FindFirstChild(itemName)
            end

            if toolInBack and not toolInChar then
                char.Humanoid:EquipTool(toolInBack)
            end
        end
        
        local function GetMaterial(matName)
            local inv = CommF_("getInventory")
            for _, item in pairs(inv) do
                if item.Name == matName then return item.Count or 1 end
            end
            return 0
        end
        
        local function Tween2(targetCFrame)
            pcall(function()
                local char = plr.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then return end
                local Root = char.HumanoidRootPart
                local dist = (targetCFrame.Position - Root.Position).Magnitude
                if dist < 5 then Root.CFrame = targetCFrame; return end
                if not Root:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", Root)
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0, 0, 0)
                end
                if _G.CurrentTween and _G.CurrentTweenTarget and (_G.CurrentTweenTarget.Position - targetCFrame.Position).Magnitude < 10 then
                    if _G.CurrentTween.PlaybackState == Enum.PlaybackState.Playing then return end
                end
                if _G.CurrentTween then _G.CurrentTween:Cancel() end
                _G.CurrentTweenTarget = targetCFrame
                _G.CurrentTween = TweenService:Create(Root, TweenInfo.new(dist/315, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                _G.CurrentTween:Play()
            end)
        end
        
        local function SmartMove(targetCFrame)
            local dist = (targetCFrame.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist < 300 then
                Tween2(targetCFrame)
            else
                local bv = plr.Character.HumanoidRootPart:FindFirstChild("BodyVelocity")
                if bv then bv:Destroy() end
                plr.Character.HumanoidRootPart.CFrame = targetCFrame
            end
        end
        
        local function AutoHop(apiUrl, reason)
            if _G.IsHopping or (tick() - _G.LastHopTime) < 120 then return end
            _G.IsHopping = true
            _G.LastHopTime = tick()
            print("[HOP] " .. reason)
            task.spawn(function()
                local success, result = pcall(function() return game:HttpGet(apiUrl) end)
                if success and result ~= "" then
                    local data = HttpService:JSONDecode(result)
                    if type(data) == "table" and #data > 0 then
                        for _, serverId in ipairs(data) do
                            if serverId ~= game.JobId and not _G.BlacklistedServers[serverId] then
                                ReplicatedStorage:FindFirstChild("__ServerBrowser"):InvokeServer("teleport", serverId)
                                task.wait(5)
                                return
                            end
                        end
                    end
                end
                _G.IsHopping = false
            end)
        end
        
        -- ==========================================
        -- AUTO CDK LOGIC
        -- ==========================================
        local function GetMastery(swordName)
            local inv = CommF_("getInventory")
            for _, item in pairs(inv) do
                if item.Name == swordName then return item.Mastery or 0 end
            end
            return 0
        end
        
        -- VÒNG LẶP CHÍNH AUTO CDK
        while _G.Auto_DualKatana and not hasCDK() do
            pcall(function()
                local yamaMastery = GetMastery("Yama")
                local tushitaMastery = GetMastery("Tushita")
                
                print(string.format("[CDK] Yama: %d/%d | Tushita: %d/%d", yamaMastery, _G.TargetMastery, tushitaMastery, _G.TargetMastery))
                
                -- Farm Mastery nếu chưa đủ
                if yamaMastery < _G.TargetMastery then
                    _G.CurrentSword = "Yama"
                    print("[CDK] Farm Mastery Yama...")
                    _G.AutoFarm_Bone = true
                    task.wait(1)
                elseif tushitaMastery < _G.TargetMastery then
                    _G.CurrentSword = "Tushita"
                    print("[CDK] Farm Mastery Tushita...")
                    _G.AutoFarm_Bone = true
                    task.wait(1)
                else
                    _G.AutoFarm_Bone = false
                    
                    -- Kiểm tra Quest CDK
                    local cdkProgress = CommF_("CDKQuest", "Progress")
                    
                    if cdkProgress then
                        local yama = tonumber(cdkProgress.Yama) or 0
                        local tushita = tonumber(cdkProgress.Tushita) or 0
                        local good = tonumber(cdkProgress.Good) or 0
                        local kill = tonumber(cdkProgress.Kill) or 0
                        
                        print(string.format("[CDK] Progress - Yama: %d | Tushita: %d | Good: %d | Kill: %d", yama, tushita, good, kill))
                        
                        if yama == 0 then
                            print("[CDK] Làm Yama Quest...")
                            -- Logic Yama Quest (đánh Soul Reaper)
                            local sr = workspace.Enemies:FindFirstChild("Soul Reaper")
                            if sr and sr:FindFirstChild("Humanoid") and sr.Humanoid.Health > 0 then
                                EquipSword("Yama")
                                SmartMove(sr.HumanoidRootPart.CFrame * Pos)
                                sr.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                                _G.MonFarm = sr.Name
                                _G.FarmPos = sr.HumanoidRootPart.CFrame
                                AttackNoCoolDown()
                            else
                                Tween2(CFrame.new(-9495, 450, 5977))
                                if (plr.Character.HumanoidRootPart.Position - Vector3.new(-9495, 450, 5977)).Magnitude < 200 then
                                    AutoHop(API_SOUL_REAPER, "Tìm Soul Reaper")
                                end
                            end
                        elseif tushita == 0 then
                            if good == 0 then
                                print("[CDK] Làm Tushita Quest 1 (Boat Dealers)...")
                                -- Logic Tushita Q1
                                _G.DealerStep = _G.DealerStep or 1
                                local dealers = {
                                    CFrame.new(-4602.51, 16.44, -2880.99),
                                    CFrame.new(4001.18, 10.08, -2654.86),
                                    CFrame.new(-9530.76, 7.24, -8375.50)
                                }
                                local target = dealers[_G.DealerStep]
                                if target then
                                    Tween2(target)
                                    if (plr.Character.HumanoidRootPart.Position - target.Position).Magnitude <= 10 then
                                        task.wait(0.7)
                                        CommF_("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check")
                                        task.wait(0.5)
                                        CommF_("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"))
                                        task.wait(1)
                                        _G.DealerStep = _G.DealerStep + 1
                                        if _G.DealerStep > 3 then _G.DealerStep = 1 end
                                    end
                                end
                            elseif kill == 0 then
                                print("[CDK] Làm Tushita Quest 2 (Pirate Raid)...")
                                -- Logic Tushita Q2
                                if (CFrame.new(-5539, 313, -2972).Position - plr.Character.HumanoidRootPart.Position).Magnitude > 500 then
                                    Tween2(CFrame.new(-5545, 313, -2976))
                                else
                                    local p = nil
                                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                                        if v.Humanoid.Health > 0 and (v.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude < 2000 then
                                            p = v; break
                                        end
                                    end
                                    if p then
                                        SmartMove(p.HumanoidRootPart.CFrame * Pos)
                                        AttackNoCoolDown()
                                    else
                                        AutoHop(API_PIRATE_RAID, "Tìm Pirate Raid")
                                    end
                                end
                            else
                                print("[CDK] Làm Tushita Quest 3 (Cake Queen)...")
                                -- Logic Tushita Q3
                                local heav = workspace.Map:FindFirstChild("HeavenlyDimension")
                                if heav and (plr.Character.HumanoidRootPart.Position - heav.Spawn.Position).Magnitude < 3000 then
                                    local foundMob = false
                                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                                        if (string.find(v.Name, "Cursed Skeleton") or string.find(v.Name, "Heaven's Guardian")) and v.Humanoid.Health > 0 then
                                            foundMob = true
                                            EquipSword(_G.CurrentSword)
                                            SmartMove(v.HumanoidRootPart.CFrame * Pos)
                                            AttackNoCoolDown()
                                        end
                                    end
                                    
                                    if not foundMob then
                                        for i = 1, 3 do
                                            local t = heav:FindFirstChild("Torch"..i)
                                            if t and t:FindFirstChildOfClass("ProximityPrompt") and t.ProximityPrompt.Enabled then
                                                Tween2(t.CFrame)
                                                task.wait(1.5)
                                                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                                task.wait(3)
                                                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                                task.wait(0.5)
                                            end
                                        end
                                    end
                                else
                                    local cq = nil
                                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                                        if string.find(v.Name, "Cake Queen") and v.Humanoid.Health > 0 then cq = v; break end
                                    end
                                    if cq then
                                        EquipSword(_G.CurrentSword)
                                        SmartMove(cq.HumanoidRootPart.CFrame * Pos)
                                        AttackNoCoolDown()
                                    else
                                        Tween2(CFrame.new(-709, 381, -11011))
                                        if (plr.Character.HumanoidRootPart.Position - Vector3.new(-709, 381, -11011)).Magnitude < 200 then
                                            AutoHop(API_CAKE_QUEEN, "Tìm Cake Queen")
                                        end
                                    end
                                end
                            end
                        else
                            print("[CDK] Hoàn thành tất cả Quest! Đang chế CDK...")
                            task.wait(2)
                        end
                    end
                end
                
                -- Kiểm tra xem đã có CDK chưa
                if hasCDK() then
                    print("[AUTO CDK] ============================================")
                    print("[AUTO CDK] ĐÃ HOÀN THÀNH CDK!")
                    print("[AUTO CDK] ============================================")
                    _G.IsDoingAutoCDK = false
                    _G.CDKPriority = false
                    _G.Auto_DualKatana = false
                    break
                end
            end)
            task.wait(1)
        end
        
        -- GOM QUÁI (BRING MOB)
        task.spawn(function()
            while _G.Auto_DualKatana do
                pcall(function()
                    if _G.BringMob and _G.FarmPos and _G.MonFarm then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == _G.MonFarm and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                if v:FindFirstChild("HumanoidRootPart") and (v.HumanoidRootPart.Position - _G.FarmPos.Position).Magnitude <= 1500 then
                                    v.HumanoidRootPart.CFrame = _G.FarmPos
                                    v.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                                    v.HumanoidRootPart.CanCollide = false
                                    v.Humanoid:ChangeState(11)
                                    sethiddenproperty(plr, "SimulationRadius", math.huge)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end)
end

-- =====================================================================
-- HỆ THỐNG QUYẾT ĐỊNH ƯU TIÊN
-- =====================================================================
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local hasY = hasYama()
            local hasT = hasTushita()
            local hasC = hasCDK()
            local raceStatus = checkRaceV3()
            
            print(string.format("[CHECK] Yama: %s | Tushita: %s | CDK: %s | Race: %s", 
                tostring(hasY), tostring(hasT), tostring(hasC), raceStatus))
            
            -- ƯU TIÊN 1: Nếu có Yama + Tushita nhưng chưa có V3 -> Farm V3 TRƯỚC
            if hasY and hasT and not hasC then
                if raceStatus ~= "V3" and raceStatus ~= "V4" then
                    print("[Hệ Thống] ƯU TIÊN AUTO V3! (Có Yama + Tushita)")
                    _G.IsDoingAutoCDK = false
                    _G.CDKPriority = false
                    _G.NeedV3First = true
                    _G.V3Completed = false
                    
                    -- TỰ ĐỘNG VỀ SEA 2
                    travelToSea2()
                    
                    -- BẬT AUTO V3
                    _G.AutoRaceV3 = true
                    _G.AutoRaceV2 = true
                    return
                else
                    -- ĐÃ CÓ V3, ĐÁNH DẤU HOÀN THÀNH
                    if _G.NeedV3First and not _G.V3Completed then
                        print("[Hệ Thống] ĐÃ HOÀN THÀNH V3! Chuẩn bị lên Sea 3...")
                        _G.V3Completed = true
                        _G.NeedV3First = false
                        
                        -- TỰ ĐỘNG LÊN SEA 3
                        travelToSea3()
                        task.wait(5)
                    end
                end
            end
            
            -- ƯU TIÊN 2: Nếu có Yama + Tushita + V3/V4 nhưng chưa có CDK -> Farm CDK
            if hasY and hasT and not hasC and (raceStatus == "V3" or raceStatus == "V4") then
                if not _G.IsDoingAutoCDK then
                    print("[Hệ Thống] ĐỦ ĐIỀU KIỆN AUTO CDK! Bắt đầu...")
                    StartAutoCDK()
                end
                return
            end
            
            -- ƯU TIÊN 3: Đã có CDK hoặc chưa có đủ 2 thanh -> Tắt Auto CDK
            if hasC or not (hasY and hasT) then
                if _G.IsDoingAutoCDK then
                    print("[Hệ Thống] Dừng Auto CDK")
                    _G.IsDoingAutoCDK = false
                    _G.CDKPriority = false
                end
                _G.NeedV3First = false
            end
        end)
    end
end)

-- =====================================================================
-- AUTO TEAM
-- =====================================================================
task.spawn(function()
    while task.wait(1) do
        if plr and not plr.Team then
            pcall(function() CommF_("SetTeam", "Pirates") end)
        elseif plr and plr:FindFirstChild("PlayerGui") and plr.PlayerGui:FindFirstChild("ChooseTeam") then
            plr.PlayerGui.ChooseTeam.Enabled = false
        end
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then break end
    end
end)

repeat task.wait(0.5) until plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

-- =====================================================================
-- BANANA VIP CONFIG
-- =====================================================================
local AutoFindVIPBoss = bananaCfg.AutoFindVIPBoss or false
local AutoHopBoss = bananaCfg.AutoHopBoss or false
local OriginalAutoHopBoss = AutoHopBoss

task.spawn(function()
    while task.wait(1) do
        if _G.IsDoingAutoCDK then
            AutoHopBoss = false
        else
            AutoHopBoss = OriginalAutoHopBoss
        end
    end
end)

-- =====================================================================
-- KEY VERIFICATION SYSTEM (GIỐNG BANANA VIP ORIGINAL)
-- =====================================================================
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
local ADMIN_KEY = "Admin_Dep_Trai_VIP"
local GET_KEY_LINK = "http://14.174.63.243:8080/getkey/index.php?hwid=" .. HWID
local API_VERIFY = "http://14.174.63.243:8081/api/check-my-key?hwid=" .. HWID .. "&key="
local KEY_FILE = "BananaVIP_Key.txt"
local KEY_EXPIRE_MINUTES = 420

local request_func = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function verifyKeyAPI(key)
    if key == ADMIN_KEY then return {status = "success", message = "Admin"} end
    local success, response = pcall(function()
        return request_func({ Url = API_VERIFY .. key, Method = "GET" })
    end)
    if success and response.Body then
        local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if decodeSuccess then return decoded end
    end
    return {status = "error", message = "Lỗi kết nối Server"}
end

local function isKeyValid()
    if not isfile or not isfile(KEY_FILE) then return false end
    local content = readfile(KEY_FILE)
    local data = HttpService:JSONDecode(content)
    if not data or not data.key or not data.expire then return false end
    if os.time() > data.expire then return false end
    local verify = verifyKeyAPI(data.key)
    return verify.status == "success"
end

local function saveKey(key)
    local data = {key = key, expire = os.time() + KEY_EXPIRE_MINUTES * 60}
    if writefile then writefile(KEY_FILE, HttpService:JSONEncode(data)) end
end

local function requestKeyUI(callback)
    if SafeGuiParent:FindFirstChild("BananaKeyUI") then SafeGuiParent.BananaKeyUI:Destroy() end
    local UI = Instance.new("ScreenGui")
    UI.Name = "BananaKeyUI"
    UI.ResetOnSpawn = false
    UI.DisplayOrder = 99999
    UI.Parent = SafeGuiParent

    local Frame = Instance.new("Frame", UI)
    Frame.Size = UDim2.new(0, 300, 0, 160)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BorderSizePixel = 0

    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Text = "🍌 BANANA VIP + CDK 🍌"
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Color3.fromRGB(255, 200, 0)
    Title.TextSize = 16

    local Input = Instance.new("TextBox", Frame)
    Input.Size = UDim2.new(0.9, 0, 0, 35)
    Input.Position = UDim2.new(0.05, 0, 0, 40)
    Input.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Input.BorderSizePixel = 0
    Input.Text = ""
    Input.PlaceholderText = "Nhập Key..."
    Input.Font = Enum.Font.Gotham
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.TextSize = 14

    local InputCorner = Instance.new("UICorner", Input)
    InputCorner.CornerRadius = UDim.new(0, 6)

    local SubmitBtn = Instance.new("TextButton", Frame)
    SubmitBtn.Size = UDim2.new(0.4, 0, 0, 32)
    SubmitBtn.Position = UDim2.new(0.05, 0, 0, 85)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
    SubmitBtn.BorderSizePixel = 0
    SubmitBtn.Text = "✓ Xác Nhận"
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.TextSize = 13

    local SubmitCorner = Instance.new("UICorner", SubmitBtn)
    SubmitCorner.CornerRadius = UDim.new(0, 6)

    local GetKeyBtn = Instance.new("TextButton", Frame)
    GetKeyBtn.Size = UDim2.new(0.4, 0, 0, 32)
    GetKeyBtn.Position = UDim2.new(0.55, 0, 0, 85)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
    GetKeyBtn.BorderSizePixel = 0
    GetKeyBtn.Text = "🔑 Lấy Key"
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 13

    local GetKeyCorner = Instance.new("UICorner", GetKeyBtn)
    GetKeyCorner.CornerRadius = UDim.new(0, 6)

    local Status = Instance.new("TextLabel", Frame)
    Status.Size = UDim2.new(1, 0, 0, 25)
    Status.Position = UDim2.new(0, 0, 0, 125)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.Font = Enum.Font.Gotham
    Status.TextColor3 = Color3.fromRGB(255, 100, 100)
    Status.TextSize = 12

    SubmitBtn.MouseButton1Click:Connect(function()
        local key = Input.Text
        if key == "" then
            Status.Text = "⚠️ Vui lòng nhập Key!"
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        Status.Text = "⏳ Đang xác thực..."
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        local verify = verifyKeyAPI(key)
        if verify.status == "success" then
            saveKey(key)
            Status.Text = "✓ Key hợp lệ!"
            Status.TextColor3 = Color3.fromRGB(40, 200, 80)
            task.wait(1)
            UI:Destroy()
            if callback then callback() end
        else
            Status.Text = "✗ " .. (verify.message or "Key không hợp lệ!")
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        setclipboard(GET_KEY_LINK)
        Status.Text = "📋 Đã copy link lấy Key!"
        Status.TextColor3 = Color3.fromRGB(40, 200, 80)
    end)
end

if not isKeyValid() then
    print("[Hệ Thống] Key không hợp lệ!")
    requestKeyUI(function()
        print("[Hệ Thống] Key xác thực thành công!")
    end)
    return
end

print("[Hệ Thống] Key hợp lệ!")

-- =====================================================================
-- RACE MASTER SYSTEM
-- =====================================================================
task.spawn(function()
    while task.wait(2) do
        local currentLevel = getLevel()
        if currentLevel >= levelThreshold then
            print("[Race Master] Kích hoạt hệ thống Race Master...")
            
            _G.AutoReroll = {Enable = false, StopAt = {"Human", "Mink", "Cyborg"}, FragThreshold = 10000}
            _G.AutoRaceV2 = true
            _G.AutoRaceV3 = true
            _G.HumanBosses = {
                {Name = "Ice Admiral", AltName = "Ice Admiral", Pos = CFrame.new(1266, 26, -1399), Killed = false},
                {Name = "Don Swan", AltName = "Don Swan", Pos = CFrame.new(2288, 15, 863), Killed = false}
            }

            local API_NIGHT = "http://14.174.63.243:8080/api/getServersNight"
            local API_MARK_V = "http://14.174.63.243:8080/api/visited"

            local function TP(cframe)
                task.spawn(function()
                    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
                    local char = plr.Character
                    local hrp = char.HumanoidRootPart
                    local dist = (hrp.Position - cframe.Position).Magnitude
                    local dur = math.max(0.3, dist / 300)

                    local bv = Instance.new("BodyVelocity", hrp)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

                    local tween = TS:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = cframe})
                    local conn = RS.Heartbeat:Connect(function()
                        pcall(function()
                            for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
                        end)
                    end)
                    tween:Play()
                    tween.Completed:Wait()
                    conn:Disconnect()
                    if bv then bv:Destroy() end
                    task.wait(0.2)
                end)
            end

            local function ServerHopNight()
                local s, r = pcall(function() return game:HttpGet(API_NIGHT) end)
                if s and r ~= "" then
                    local d = HttpService:JSONDecode(r)
                    if type(d) == "table" then
                        for _, item in ipairs(d) do
                            local id = type(item) == "table" and item.job_id or item
                            if type(id) == "string" and id ~= "" and id ~= game.JobId then
                                pcall(function() game:HttpGet(API_MARK_V .. "?job_id=" .. id) end)
                                ReplicatedStorage:FindFirstChild("__ServerBrowser"):InvokeServer("teleport", id)
                                task.wait(4)
                            end
                        end
                    end
                end
            end

            task.spawn(function()
                while task.wait(1.5) do
                    pcall(function()
                        -- BLOCK RACE MASTER NẾU ĐANG AUTO CDK
                        if _G.IsDoingAutoCDK then
                            _G.AutoRaceV2 = false
                            _G.AutoRaceV3 = false
                            return
                        end
                        
                        -- NẾU CẦN V3 TRƯỚC THÌ CHO PHÉP CHẠY
                        if not _G.NeedV3First then
                            local currentStatus = checkRaceV3()
                            if currentStatus == "V3" or currentStatus == "V4" then
                                _G.AutoRaceV2 = false
                                _G.AutoRaceV3 = false
                                return
                            end
                        end

                        local place = game.PlaceId
                        local isSea2 = (place == 4442272183 or place == 2753915549)
                        if not isSea2 then
                            if _G.AutoRaceV2 or _G.AutoRaceV3 then
                                CommF_("TravelDressrosa")
                                task.wait(5)
                            end
                            return
                        end

                        local race = plr.Data.Race.Value

                        if _G.AutoReroll.Enable then
                            local isTarget = false
                            for _, t in ipairs(_G.AutoReroll.StopAt) do if race:find(t) then isTarget = true break end end
                            if not isTarget and plr.Data.Fragments.Value >= _G.AutoReroll.FragThreshold then
                                CommF_("BlackbeardReward", "Reroll", "1")
                                task.wait(0.5)
                                CommF_("BlackbeardReward", "Reroll", "2")
                                task.wait(2)
                                return
                            end
                        end

                        local v2S = CommF_("Alchemist", "1")
                        if _G.AutoRaceV2 and v2S ~= -2 then
                            if v2S == 0 then CommF_("Alchemist", "2")
                            elseif v2S == 1 then
                                local function Has(n)
                                    for _, v in pairs(plr.Backpack:GetChildren()) do if v.Name:find(n) then return true end end
                                    for _, v in pairs(plr.Character:GetChildren()) do if v.Name:find(n) then return true end end
                                    return false
                                end
                                if not Has("Flower 1") then
                                    if Lighting.ClockTime > 5 and Lighting.ClockTime < 17 then ServerHopNight()
                                    else local f = workspace:FindFirstChild("Flower1") or workspace:FindFirstChild("Blue Flower")
                                         if f then TP(f.CFrame) end end
                                elseif not Has("Flower 2") then
                                    local f = workspace:FindFirstChild("Flower2") or workspace:FindFirstChild("Red Flower")
                                    if f then TP(f.CFrame) end
                                elseif not Has("Flower 3") then
                                    _G.BringMob = true; _G.MonFarm = "Swan Pirate"; _G.FarmPos = CFrame.new(840, 122, 1240)
                                    TP(_G.FarmPos * CFrame.new(0, 30, 0))
                                end
                            elseif v2S == 2 then CommF_("Alchemist", "3") end
                            return
                        end

                        local v3S = CommF_("Wenlocktoad", "1")
                        if _G.AutoRaceV3 and v2S == -2 and v3S ~= -2 then
                            if v3S == 0 then CommF_("Wenlocktoad", "2")
                            elseif v3S == 2 then CommF_("Wenlocktoad", "3")
                            elseif v3S == 1 then
                                if race:find("Cyborg") then
                                    local hasF = false
                                    for _, t in pairs(plr.Character:GetChildren()) do if t:IsA("Tool") and (t.ToolTip == "Blox Fruit" or t.Name:find("Fruit")) then hasF = true break end end
                                    if not hasF then
                                        local inv = CommF_("getInventory")
                                        if type(inv) == "table" then
                                            for _, i in pairs(inv) do
                                                if i.Name:find("Rocket") or i.Name:find("Spin") or i.Name:find("Spring") then
                                                    CommF_("LoadFruit", i.Name) task.wait(1)
                                                    local tool = plr.Backpack:FindFirstChild(i.Name)
                                                    if tool then plr.Character.Humanoid:EquipTool(tool) end break
                                                end
                                            end
                                        end
                                    else CommF_("Wenlocktoad", "3") end
                                elseif race:find("Human") then
                                    local target = nil
                                    for _, b in ipairs(_G.HumanBosses) do if not b.Killed then target = b break end end
                                    if target then
                                        local bM = workspace.Enemies:FindFirstChild(target.Name) or workspace.Enemies:FindFirstChild(target.AltName or "")
                                        if bM and bM:FindFirstChild("Humanoid") and bM.Humanoid.Health > 0 then
                                            _G.CurrentAttacking = target.Name
                                            TP(bM.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                                        else
                                            if _G.CurrentAttacking == target.Name then target.Killed = true; _G.CurrentAttacking = nil
                                            else TP(target.Pos * CFrame.new(0, 30, 0)) end
                                        end
                                    else CommF_("Wenlocktoad", "3") end
                                elseif race:find("Mink") then
                                    local char = plr.Character
                                    if char and char:FindFirstChild("HumanoidRootPart") then
                                        local r = char.HumanoidRootPart; local nc, md = nil, math.huge
                                        for _, o in pairs(workspace:GetDescendants()) do
                                            if o:IsA("Part") and o.Name:lower():find("chest") and not o:GetAttribute("Collected") then
                                                local d = (o.Position - r.Position).Magnitude
                                                if d < md then md = d; nc = o end
                                            end
                                        end
                                        if nc then TP(nc.CFrame) task.wait(0.2); nc:SetAttribute("Collected", true); nc:Destroy() end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)

            task.spawn(function()
                while task.wait() do
                    if _G.BringMob and _G.FarmPos then
                        pcall(function()
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if v.Name:find(_G.MonFarm) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                    v.HumanoidRootPart.CFrame = _G.FarmPos
                                    v.HumanoidRootPart.CanCollide = false
                                    v.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                                    v.Humanoid:ChangeState(11)
                                end
                            end
                        end)
                    end
                end
            end)
            
            break 
        end
    end
end)

print("⚡ ULTIMATE BANANA VIP + AUTO CDK + RACE MASTER V3 LOADED SUCCESS! ⚡")
