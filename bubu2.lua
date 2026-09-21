--========================================================--
-- WINDUI BOOTSTRAP (UI-FIRST / FAIL-SAFE)
--========================================================--
local function MAWWW_LoadWindUI()
    local sources = {
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    }
    local lastError = "unknown error"
    local compiler = loadstring or load

    for _, url in ipairs(sources) do
        local okHttp, body = pcall(function()
            return game:HttpGet(url)
        end)
        if okHttp and type(body) == "string" and #body > 1000 then
            local okCompile, chunk = pcall(function()
                return compiler(body)
            end)
            if okCompile and type(chunk) == "function" then
                local okRun, library = pcall(chunk)
                if okRun and type(library) == "table" then
                    return library
                end
                lastError = tostring(library)
            else
                lastError = tostring(chunk)
            end
        else
            lastError = tostring(body)
        end
        task.wait(0.1)
    end

    error("[Mawww Hub] WindUI failed to load: " .. tostring(lastError))
end

local WindUI = MAWWW_LoadWindUI()

--========================================================--
-- KEY SYSTEM GATE
--========================================================--
local function MAWWW_RunKeySystem()
    local url = "https://raw.githubusercontent.com/zidniilman100106/Mawww/1190b9f749ee92374ff46b278e84e26170eeeeff/Key-System.txt"
    local compiler = loadstring or load
    local lastError = "unknown error"

    for attempt = 1, 3 do
        local okHttp, source = pcall(function()
            return game:HttpGet(url)
        end)

        if okHttp and type(source) == "string" and #source > 0 then
            local okCompile, chunk = pcall(function()
                return compiler(source)
            end)

            if okCompile and type(chunk) == "function" then
                local okRun, result = pcall(chunk)
                if okRun then
                    if result == false then
                        lastError = "Key System rejected execution."
                    else
                        return true
                    end
                else
                    lastError = tostring(result)
                end
            else
                lastError = tostring(chunk)
            end
        else
            lastError = tostring(source)
        end

        if attempt < 3 then
            task.wait(0.5)
        end
    end

    warn("[Mawww Hub] Key system failed: " .. tostring(lastError))
    return false
end

if not MAWWW_RunKeySystem() then
    error("[Mawww Hub] Main UI blocked because the key system did not complete successfully.")
end

--========================================================--
-- MAIN WINDUI WINDOW
--========================================================--
pcall(function()
    local genv = getgenv and getgenv() or _G
    local oldWindow = genv and genv.MAWWW_WindUI_Window
    if oldWindow then
        if type(oldWindow.Destroy) == "function" then
            oldWindow:Destroy()
        elseif type(oldWindow.Close) == "function" then
            oldWindow:Close()
        end
    end
end)

local function MAWWW_CreateWindow()
    local attempts = {
        function()
            return WindUI:CreateWindow({
                Title = "Mawww Hub",
                Folder = "MawwwHub_VD",
                NewElements = true,
                OpenButton = {
                    Title = "Open Mawww Hub",
                    Enabled = true,
                    Draggable = true,
                    OnlyMobile = false,
                    Scale = 0.6,
                },
            })
        end,
        function()
            return WindUI:CreateWindow({
                Title = "Mawww Hub",
                Folder = "MawwwHub_VD",
            })
        end,
        function()
            return WindUI:CreateWindow({
                Title = "Mawww Hub",
            })
        end,
    }

    local lastError
    for _, factory in ipairs(attempts) do
        local ok, result = pcall(factory)
        if ok and result then
            return result
        end
        lastError = result
    end
    error("[Mawww Hub] CreateWindow failed: " .. tostring(lastError))
end

local Window = MAWWW_CreateWindow()
do
    local genv = getgenv and getgenv() or _G
    if genv then
        genv.MAWWW_WindUI_Window = Window
    end
end

pcall(function()
    if type(Window.Open) == "function" then
        Window:Open()
    end
end)
pcall(function()
    if type(Window.SelectTab) == "function" then
        Window:SelectTab(1)
    end
end)

task.wait()
task.defer(function()
    pcall(function()
        if type(Window.Open) == "function" then Window:Open() end
    end)
end)

task.wait()

--========================================================--
-- SERVICES / PLAYER REFERENCES
--========================================================--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local LocalPlayer = Player
local PlayerGui = Player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local ICON_ID = 80159865448231
local ICON_URL = "rbxassetid://" .. tostring(ICON_ID)

local SUPPRESS_NOTIFY = false
local function notify(title, content, duration)
    if SUPPRESS_NOTIFY then return end
    local payload = { Title = title, Content = content, Icon = "info", Duration = duration or 4 }
    local ok = pcall(function() WindUI:Notify(payload) end)
    if not ok then
        pcall(function()
            payload.Desc = content
            payload.Content = nil
            WindUI:Notify(payload)
        end)
    end
end

--========================================================--
-- HELPERS
--========================================================--
local function getRoot() local c = Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = Player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function isDowned() local h = getHum(); return (not h) or h.Health <= 0 end
local function teamMatches(teamName, keyword)
    if not teamName then return false end
    return string.find(string.lower(teamName), keyword, 1, true) ~= nil
end
local function GetRole()
    if not Player.Team or not Player.Team.Name then return "Unknown" end
    local n = Player.Team.Name
    if teamMatches(n, "killer") then return "Killer" end
    if teamMatches(n, "survivor") then return "Survivor" end
    return "Lobby"
end
local function IsKiller(p) return p and p.Team and p.Team.Name and teamMatches(p.Team.Name, "killer") end
local function IsSurvivor(p) return p and p.Team and p.Team.Name and teamMatches(p.Team.Name, "survivor") end
local function GetRemotes() return ReplicatedStorage:FindFirstChild("Remotes") end

local function VD_WallCheckVisible(originPos, targetPos, targetChar, extraExcludes)
    if typeof(originPos) ~= "Vector3" or typeof(targetPos) ~= "Vector3" then return false end
    local distance = (targetPos - originPos).Magnitude
    if distance <= 0.1 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    pcall(function() params.RespectCanCollide = true end)
    local excludes = {}
    if Player.Character then table.insert(excludes, Player.Character) end
    if targetChar then table.insert(excludes, targetChar) end
    if type(extraExcludes) == "table" then
        for _, inst in ipairs(extraExcludes) do if inst then table.insert(excludes, inst) end end
    end
    params.FilterDescendantsInstances = excludes
    local samples = { targetPos }
    if targetChar then
        local seen = {}
        for _, part in ipairs({targetChar:FindFirstChild("Head"), targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso"), targetChar:FindFirstChild("HumanoidRootPart")}) do
            if part and part:IsA("BasePart") and not seen[part] then seen[part] = true; table.insert(samples, part.Position) end
        end
    end
    for _, samplePos in ipairs(samples) do
        local ray = samplePos - originPos
        local rayDist = ray.Magnitude
        if rayDist <= 0.1 then return true end
        local hit = Workspace:Raycast(originPos, ray.Unit * rayDist, params)
        if hit == nil then return true end
        if targetChar and hit.Instance and hit.Instance:IsDescendantOf(targetChar) then return true end
    end
    return false
end

--========================================================--
-- GLOBAL STATE
--========================================================--
getgenv().VD = getgenv().VD or {}
local VD = getgenv().VD
if VD.Destroyed == nil then VD.Destroyed = false end

local defaults = {
    AntiKnockdown=false, AutoWiggle=false, AutoCrouchDodge=false,
    AntiFallSlowdown=false, AntiFallDamage=false,
    Invisible=false, InvisibleNotVisual=false, InvisibleSpeed=5,
    HideSkillUI=false,
    AutoDropPallet=false, AutoDropPalletRange=0, ShowPalletDropRange=false,
    PalletReflex=false, PalletReflexRange=20,
    AutoWindowsVault=false,
    SwiftVault=false, SwiftVaultV2=false, SwiftVaultSpeed=13,
    Moonwalk=false, MoonwalkSpam=30, MoonwalkIntensity=35,
    ShowMoonwalkIcon=false, LockMoonwalkIcon=false,
    AutoSkillcheck=false, AutoSkillcheckMode="NORMAL", AutoSkillcheckBossGen=false,
    AutoParryV1=false, SURV_AutoParry=false, SURV_ParryDistance=8,
    SURV_ParryAggressive=false, SURV_ShowParryCircle=false,
    PARRY_V1_WallCheck=false, PARRY_V1_IgnoreDown=true,
    PARRY_V1_AntiFake=false, PARRY_V1_FakeWindow=3, PARRY_V1_FakeDistance=2.5,
    PARRY_V1_MinFacing=0.35, PARRY_V1_MinVelocity=2,
    PARRY_Enabled=false, PARRY_Aggressive=false, PARRY_Distance=10,
    PARRY_ShowCircle=false, PARRY_SilentParry=false, PARRY_Usemawww=true,
    PARRY_WallCheck=false, PARRY_IgnoreDown=true,
    AutoDodgeAbyss=false, AbyssDodgeDistance=20,
    AutoDodgeSpearVeil=false, SpearVeilDodgeMode="Strafe",
    SpearVeilDetectRange=50, SpearVeilDodgeDistance=18,
    SpearVeilUseRemote=true, SpearVeilShowIndicator=false,
    TOF_SilentAim=false, TOF_Laser=true, TOF_WallCheck=false,
    TOF_BlockKnocked=true, TOF_TargetMode="Killer", TOF_Key="None",
    TOF_FOV=220, TOF_MaxDist=650, TOF_HideUI=false, TOF_Minimized=false,
    TOF2_Enabled=false, TOF2_AutoFire=false, TOF2_Predict=true,
    TOF2_PredictIterations=3, TOF2_Smoothing=0.35, TOF2_WallCheck=true,
    TOF2_MaxDist=600, TOF2_FOV=180, TOF2_TargetMode="Killer", TOF2_AimPart="Torso",
    TOF2_FireRate=0.18, TOF2_ShowLaser=true, TOF2_LaserColorR=255,
    TOF2_LaserColorG=40, TOF2_LaserColorB=40, TOF2_Key="None",
    TOF2_IgnoreDown=true, TOF2_BlockKnocked=true,
    ShowParryRangeV1=false, ShowParryRangeV2=false,
    ParryV2WallCheck=true, ParryV2IgnoreDown=true,
    PredictMap=false, PredictKiller=false,
    Speed=false, SpeedValue=16, Jump=false, JumpValue=50,
    InfiniteJump=false, Noclip=false,
    AutoFlee=false, AutoFleeDist=50,
    InstantHealSelf=false, AutoHealAll=false,
    SURV_AntiKnock=false,
    FirstPersonCamera=false,
    KillerAutoAttack=false, KillerAttackRange=12,
    KillerAutoSpam=false, KillerAttackDelay=0.45,
    KillerAutoStalk=false, KillerKillAll=false,
    KillerHitbox=false, KillerHitboxSize=15,
    KillerInfLunge=false, KillerInfFrenzy=false,
    KillerInfLakeMist=false, KillerInfPursuit=false,
    KillerInfGrab=false, KillerInfAbyss=false,
    KillerInfSkill=false, KillerBypassCD=false,
    KillerBypassSkill=false,
    FakeAttack=false, FakeParry=false, FakeParryAnim="Enten",
    FakeGenEnabled=false, FakeGenPlaying=false,
    KillerDestroyPallets=false, KillerAutoKickGen=false,
    KillerAutoHook=false, KillerNoSlowdown=false, KillerAntiBlind=false,
    KillerBlockAllVaults=false, KillerAutoDropAllPallets=false, KillerBreakAllPallets=false,
    AimlockEnabled=false, AimlockVisCheck=true,
    AimlockTargetMode="Killer", AimlockAimPart="HumanoidRootPart",
    AimlockFOV=250, AimlockStrength=1, AimlockPredict=0.12,
    AimLock_Enabled=false, AimLock_MaxDistance=50, AimLock_Button=false, AimLock_Lock=false,
    VeilEnabled=false, VeilShowFOV=true, VeilShowTracker=false,
    VeilAutoPredict=true, VeilFOV=150, VeilMaxDist=400,
    VeilSpearSpeed=165, VeilGravity=103,
    VeilAuraSpearSpeed=165, VeilAuraSpearGravity=96.5,
    VeilLeadMultiplier=1.4, VeilWallCheck=false, VeilIgnoreDown=true,
    VeilShowPlayerMarkers=true, VeilShowTargetMarker=true,
    VeilShowTracer=true, VeilShowNameLabels=true,
    VeilV2Enabled=false, VeilV2ShowFOV=true, VeilV2ShowTracker=true,
    VeilV2AutoThrow=true, VeilV2WallCheck=false, VeilV2IgnoreDown=true,
    VeilV2FOV=180, VeilV2MaxDist=600,
    VeilV2SpearSpeed=170, VeilV2SpearGravity=100,
    VeilV2AuraSpearSpeed=170, VeilV2AuraSpearGravity=95,
    VeilV2LeadMultiplier=1.35, VeilV2Iterations=3,
    VeilV2FireDelay=0.05, VeilV2UseInterceptor=true,
    VeilV2ShowPlayerMarkers=true, VeilV2ShowTargetMarker=true,
    VeilV2ShowTracer=true, VeilV2ShowNameLabels=true,
    PistolEnabled=false, PistolLaser=true, PistolWallCheck=false,
    PistolBlockKnocked=true, PistolTargetMode="Killer",
    PistolAutoFire=false, PistolFireRate=0.2, PistolFOV=180,
    PistolMaxDist=500, PistolShowTracker=true,
    FlashSilentAim=false, FlashAutoFire=true, FlashFOV=200,
    FlashMaxDist=400, FlashWallCheck=false, FlashTargetMode="Killer",
    FlashTargetPart="Head", FlashRange=120, FlashSmooth=0.35, FlashLaser=true,
    FlaskSilentAim=false, FlaskLaser=false,
    ESP_Killer=false, ESP_Survivor=false, ESP_SCP=false,
    ESP_Generator=false, ESP_Window=false, ESP_Pallet=false,
    ESP_Hook=false, ESP_Distance=250, ESP_ShowName=false,
    ESP_ShowGenProgress=false, ESP_FillTransparency=70, ESP_OutlineTransparency=20,
    ESP_Status=false, ESP_StatusDistance=250,
    ESP_StatusShowKillerStun=true, ESP_StatusShowSurvivorDown=true,
    ESP_StatusShowSurvivorHook=true, ESP_StatusShowSurvivorCarry=true,
    ESP_StatusShowRepairing=true, ESP_StatusShowHealing=true,
    ESP_StatusShowBlind=true, ESP_StatusShowKillerAttack=true,
    UnlimitedZoom=false, MaxZoomDistance=1000,
    FOVEnabled=false, FOV=70,
    Fullbright=false, NO_Fog=false, WeatherTheme="Default",
    ThirdPerson=false, ShiftLock=false, InfinityZoom=false, NoCutscene=false,
    ShowPingFPS=false, HideSurvIcon=false, ShowHookCounter=false,
    MawwwtKiller=false, SpectatorCounter=false, KillerPerks=false,
    CrossEnabled=false, CrossStyle="Dot", CrossSize=3,
    CrossThickness=4, CrossGap=6, CrossPosX=0, CrossPosY=0,
    CrossColorR=255, CrossColorG=255, CrossColorB=255,
    FlingEnabled=false, FlingStrength=10000, BeatSurvivor=false, BeatKiller=false,
    AF_Enabled=false, AF_Mode="Auto",
    AF_AutoReady=true, AF_AutoRequeue=true, AF_AutoEscapeNow=true,
    AF_AutoSkill=true, AF_AutoHeal=true, AF_AutoAttack=true, AF_AutoHook=true,
    AF_StartTime=0, AF_MatchesPlayed=0, AF_LastEscapeTry=0, AF_EscapeCooldown=2, AF_Status="Idle",
    SH_Enabled=false, SH_HopAfterMatch=true, SH_RandomHop=true,
    SH_WaitingTimeout=60, SH_MinPlayers=3, SH_HopCooldown=15,
    SH_MaxRetries=5, SH_SkipVisited=true, SH_AutoResetWhenAllVisited=true,
    SH_IsHopping=false, SH_HopCount=0, SH_LastHopTime=0,
    SH_LobbyEnterTime=0, SH_LastRole="Unknown", SH_VisitedServers={},
    GenBoost=false, ShowGenBossIcon=false, LockGenBossIcon=false,
    ShowInfiniteMyersIcon=false, LockInfiniteMyersIcon=false,
    ShowBypassSkillIcon=false, LockBypassSkillIcon=false,
    RADAR_Enabled=false, RADAR_Size=150, RADAR_Range=250,
    RADAR_Transparency=0.2, RADAR_Circle=false,
    RADAR_ShowKiller=true, RADAR_ShowSurvivor=true,
    RADAR_ShowGenerator=false, RADAR_ShowPallet=false,
    RADAR_ShowHook=false, RADAR_ShowGate=false,
    RADAR_ShowWindow=false, RADAR_ShowZombie=false,
    TP_Offset=3, AntiAFK=false,
    QuickMoonwalkPosition=nil, QuickGenBossPosition=nil,
    QuickInfiniteMyersPosition=nil, QuickBypassSkillPosition=nil,
    FP_Flowstate=false, FP_QuickRecovery=false, FP_PerfectLanding=false,
    FP_AdrenalineRush=false, FP_Cooldown=10,
    SPOOF_Level="0", SPOOF_Gears="0", SPOOF_Screws="0",
    StreamerHideName=false,
    EmoteEnabled=false, SelectedEmote="Friday Night",
}
for k, v in pairs(defaults) do
    if VD[k] == nil then VD[k] = v end
end
if game.JobId and game.JobId ~= "" and VD.SH_VisitedServers then
    VD.SH_VisitedServers[game.JobId] = tick()
end

local VD_Elements = {}

--========================================================--
-- UI HELPER REGISTRY
--========================================================--
local function RegToggle(tab, text, desc, default, vdKey, extraCallback)
    if not tab then return nil end
    if vdKey and VD_Elements[vdKey] then return VD_Elements[vdKey] end
    local ok, obj = pcall(function()
        return tab:Toggle({
            Title = text, Desc = desc or "", Flag = vdKey, Value = default,
            Callback = function(v)
                VD[vdKey] = v
                if extraCallback then pcall(extraCallback, v) end
            end,
        })
    end)
    if not ok then warn("[Mawww Hub] Toggle failed:", text, obj) end
    if obj and vdKey then VD_Elements[vdKey] = obj end
    return obj
end
local function RegSlider(tab, text, desc, default, min, max, step, vdKey, extraCallback)
    if not tab then return nil end
    if vdKey and VD_Elements[vdKey] then return VD_Elements[vdKey] end
    local ok, obj = pcall(function()
        return tab:Slider({
            Title = text, Desc = desc or "", Flag = vdKey,
            Value = { Min = min, Max = max, Default = default },
            Step = step or 1,
            Callback = function(v)
                VD[vdKey] = v
                if extraCallback then pcall(extraCallback, v) end
            end,
        })
    end)
    if not ok then warn("[Mawww Hub] Slider failed:", text, obj) end
    if obj and vdKey then VD_Elements[vdKey] = obj end
    return obj
end
local function RegDropdown(tab, text, desc, values, default, multi, vdKey, extraCallback)
    if not tab then return nil end
    if vdKey and VD_Elements[vdKey] then return VD_Elements[vdKey] end
    local ok, obj = pcall(function()
        return tab:Dropdown({
            Title = text, Desc = desc or "", Flag = vdKey,
            Values = values, Value = default, Multi = multi or false,
            Callback = function(v)
                VD[vdKey] = v
                if extraCallback then pcall(extraCallback, v) end
            end,
        })
    end)
    if not ok then warn("[Mawww Hub] Dropdown failed:", text, obj) end
    if obj and vdKey then VD_Elements[vdKey] = obj end
    return obj
end
local function RegButton(tab, text, desc, callback)
    if not tab then return nil end
    local ok, obj = pcall(function()
        return tab:Button({ Title = text, Desc = desc or "", Callback = callback })
    end)
    if not ok then warn("[Mawww Hub] Button failed:", text, obj) end
    return obj
end
local function RegDivider(tab)
    if not tab then return end
    pcall(function() tab:Divider() end)
end
local function RegLabel(tab, text)
    if not tab then return end
    local ok = pcall(function() tab:Divider({ Title = text }) end)
    if not ok then pcall(function() tab:Paragraph({ Title = text }) end) end
end

local originalLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient,
}

--========================================================--
-- TABS
--========================================================--
local function MAWWW_SafeTab(title, icon)
    local attempts = {
        function() return Window:Tab({ Title = title, Icon = icon, Locked = false }) end,
        function() return Window:Tab({ Title = title, Locked = false }) end,
        function() return Window:CreateTab(title, icon) end,
        function() return Window:CreateTab(title) end,
    }
    local lastError
    for _, factory in ipairs(attempts) do
        local ok, tab = pcall(factory)
        if ok and tab then
            return tab
        end
        lastError = tab
    end
    warn("[Mawww Hub] Failed to create tab '" .. tostring(title) .. "': " .. tostring(lastError))
    return nil
end

local Tabs = {
    Player     = MAWWW_SafeTab("Player", "user"),
    Survival   = MAWWW_SafeTab("Survival", "shield"),
    Killer     = MAWWW_SafeTab("Killer", "sword"),
    Aim        = MAWWW_SafeTab("Aim", "crosshair"),
    ESP        = MAWWW_SafeTab("ESP", "eye"),
    Visual     = MAWWW_SafeTab("Visual", "palette"),
    Utility    = MAWWW_SafeTab("Utility", "wrench"),
    AutoFarm   = MAWWW_SafeTab("Auto Farm", "bot"),
    Radar      = MAWWW_SafeTab("Radar", "radar"),
    Avatar     = MAWWW_SafeTab("Avatar", "user-cog"),
    UISettings = MAWWW_SafeTab("UI Settings", "settings"),
}

pcall(function() Window:SelectTab(1) end)
pcall(function() if type(Window.Open) == "function" then Window:Open() end end)

local VD_TogglePingFPS, VD_ToggleHideSurvIcon, VD_ToggleHookCounter
local VD_ApplyHideSurvIcon, VD_RestoreHideSurvIcon, VD_UpdateHookCounter

--========================================================--
-- HIDE SKILLCHECK UI
--========================================================--
local HideSkillUIConn = nil
local function ApplyHideSkillUI()
    local pg = Player:FindFirstChild("PlayerGui")
    if not pg then return end
    local a = pg:FindFirstChild("SkillCheckPromptGui")
    local b = pg:FindFirstChild("SkillCheckPromptGui-con")
    if a and a.Enabled then a.Enabled = false end
    if b and b.Enabled then b.Enabled = false end
end
RegToggle(Tabs.Player, "Hide Skillcheck UI", "Sembunyikan GUI skillcheck", false, "HideSkillUI", function(v)
    if v then
        ApplyHideSkillUI()
        if not HideSkillUIConn then
            HideSkillUIConn = RunService.RenderStepped:Connect(function()
                if VD.HideSkillUI then pcall(ApplyHideSkillUI) end
            end)
        end
    else
        if HideSkillUIConn then HideSkillUIConn:Disconnect(); HideSkillUIConn = nil end
    end
end)

--========================================================--
-- ANTI FALL DAMAGE
--========================================================--
RegToggle(Tabs.Player, "Anti Fall Damage", "Blok remote fall damage", false, "AntiFallDamage")

--========================================================--
-- FIRST PERSON CAMERA (SURVIVOR)
--========================================================--
local FPState = { WasSet = false, Original = nil }
local function RestoreFirstPerson()
    if not FPState.WasSet then return end
    FPState.WasSet = false
    pcall(function()
        if FPState.Original then
            Player.CameraMode = FPState.Original.CameraMode or Enum.CameraMode.Classic
            Player.CameraMaxZoomDistance = FPState.Original.CameraMaxZoomDistance or 128
            Player.CameraMinZoomDistance = FPState.Original.CameraMinZoomDistance or 0.5
        else
            Player.CameraMode = Enum.CameraMode.Classic
            Player.CameraMaxZoomDistance = 128
        end
    end)
    local char = Player.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then head.LocalTransparencyModifier = 0 end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory") then
                local handle = obj:FindFirstChild("Handle")
                if handle then handle.LocalTransparencyModifier = 0 end
            end
        end
    end
    FPState.Original = nil
end
RunService.RenderStepped:Connect(function()
    pcall(function()
        if VD.FirstPersonCamera then
            local isSurvivor = Player.Team and Player.Team.Name == "Survivors"
            if isSurvivor then
                if not FPState.WasSet then
                    FPState.Original = {
                        CameraMode = Player.CameraMode,
                        CameraMaxZoomDistance = Player.CameraMaxZoomDistance,
                        CameraMinZoomDistance = Player.CameraMinZoomDistance,
                    }
                end
                if Player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
                    Player.CameraMode = Enum.CameraMode.LockFirstPerson
                end
                if Player.CameraMaxZoomDistance ~= 0 then
                    Player.CameraMaxZoomDistance = 0
                end
                local char = Player.Character
                if char then
                    local head = char:FindFirstChild("Head")
                    if head then head.LocalTransparencyModifier = 1 end
                    for _, obj in ipairs(char:GetChildren()) do
                        if obj:IsA("Accessory") then
                            local handle = obj:FindFirstChild("Handle")
                            if handle then handle.LocalTransparencyModifier = 1 end
                        end
                    end
                end
                FPState.WasSet = true
            elseif FPState.WasSet then
                RestoreFirstPerson()
            end
        elseif FPState.WasSet then
            RestoreFirstPerson()
        end
    end)
end)
RegToggle(Tabs.Visual, "First Person Camera (Survivor)", "Paksa kamera first person", false, "FirstPersonCamera", function(v)
    if not v then RestoreFirstPerson() end
end)

--========================================================--
-- SWIFT VAULT
--========================================================--
RegLabel(Tabs.Survival, "═══ Vault & Pallet Reflex ═══")
RegToggle(Tabs.Survival, "Swift Vault", "Auto vault saat dekat window", false, "SwiftVault")
RegToggle(Tabs.Survival, "Swift Vault V2", "Custom vault speed", false, "SwiftVaultV2", function(v)
    if not v then
        local char = Player.Character
        if char then pcall(function() char:SetAttribute("vaultspeed", 1) end) end
    end
end)
RegSlider(Tabs.Survival, "Vault Speed", "Kecepatan vault", 13, 10, 20, 1, "SwiftVaultSpeed")

_vaultedWindows = {}
_lastVaultScan  = 0
RunService.Heartbeat:Connect(function()
    if VD.SwiftVaultV2 then
        pcall(function()
            local char = Player.Character
            if char then char:SetAttribute("vaultspeed", (VD.SwiftVaultSpeed or 13) / 10) end
        end)
    end
    if not VD.SwiftVault then return end
    if GetRole() ~= "Survivor" then return end
    if tick() - _lastVaultScan < 0.15 then return end
    _lastVaultScan = tick()
    pcall(function()
        local char   = Player.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local hum    = char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not hum or hum.Health <= 0 then return end
        local vel = myRoot.AssemblyLinearVelocity
        if vel.Magnitude < 1 then return end
        local remotes   = ReplicatedStorage:FindFirstChild("Remotes")
        local winFolder = remotes and remotes:FindFirstChild("Window")
        local vaultEv   = winFolder and winFolder:FindFirstChild("VaultCommit")
        if not vaultEv then return end
        local windowGroups = {}
        for _, win in ipairs(Workspace:GetDescendants()) do
            if win:IsA("Model") and win.Name == "Window" then
                for _, part in ipairs(win:GetDescendants()) do
                    if part:IsA("BasePart") and (part.Name == "VaultTrigger" or part.Name == "VaultPoint") then
                        local rootWindow = part.Parent
                        if part.Name == "VaultPoint" and part.Parent and part.Parent.Name == "VaultTrigger" then
                            rootWindow = part.Parent.Parent
                        elseif part.Name == "VaultTrigger" and part.Parent then
                            rootWindow = part.Parent
                        end
                        if rootWindow then
                            windowGroups[rootWindow] = windowGroups[rootWindow] or {}
                            table.insert(windowGroups[rootWindow], part)
                        end
                    end
                end
            end
        end
        local function getVTPosition(vt)
            if vt:IsA("BasePart") then return vt.Position end
            if vt:IsA("Model") then
                if vt.PrimaryPart then return vt.PrimaryPart.Position end
                local bp = vt:FindFirstChildWhichIsA("BasePart", true)
                if bp then return bp.Position end
            end
            return nil
        end
        for rootWindow, parts in pairs(windowGroups) do
            repeat
                local allVTs = {}
                for _, child in ipairs(rootWindow:GetChildren()) do
                    if child.Name == "VaultTrigger" then table.insert(allVTs, child) end
                end
                if #allVTs == 0 then break end

                local nearestVT, nearestVTDist = nil, math.huge
                for _, vt in ipairs(allVTs) do
                    local pos = getVTPosition(vt)
                    if pos then
                        local d = (myRoot.Position - pos).Magnitude
                        if d < nearestVTDist then nearestVTDist = d; nearestVT = vt end
                    end
                end
                if not nearestVT or nearestVTDist > 6.0 then break end

                local lastUsed = _vaultedWindows[rootWindow] or 0
                if tick() - lastUsed < 3.0 then break end

                local finalTarget = nearestVT
                local winFold = ReplicatedStorage:FindFirstChild("Remotes")
                winFold = winFold and winFold:FindFirstChild("Window")
                if winFold and finalTarget then
                    local vaultEvent     = winFold:FindFirstChild("VaultEvent")
                    local vaultBindable  = winFold:FindFirstChild("Vaultbindable")
                    local fastvault      = winFold:FindFirstChild("fastvault")
                    local vaultComplete1 = winFold:FindFirstChild("VaultCompleteEventpart1")
                    local vaultComplete  = winFold:FindFirstChild("VaultCompleteEvent")
                    if vaultEvent    then pcall(function() vaultEvent:FireServer(finalTarget, true) end) end
                    if vaultBindable then pcall(function() vaultBindable:Fire(finalTarget, true) end) end
                    if fastvault     then pcall(function() fastvault:FireServer(Player) end) end
                    if vaultComplete1 then pcall(function() vaultComplete1:FireServer() end) end
                    if vaultComplete  then pcall(function() vaultComplete:FireServer(finalTarget, false) end) end
                    _vaultedWindows[rootWindow] = tick()
                end
            until true
        end
    end)
end)

--========================================================--
-- PALLET REFLEX
--========================================================--
RegToggle(Tabs.Survival, "Pallet Reflex", "Auto drop pallet saat killer dekat (reflex)", false, "PalletReflex")
RegSlider(Tabs.Survival, "Pallet Reflex Range", "Radius reflex", 20, 5, 50, 1, "PalletReflexRange")

_lastPalletDrop = 0
_lastPalletScan = 0
_usedPallets    = {}
RunService.Heartbeat:Connect(function()
    if not VD.PalletReflex then return end
    if GetRole() ~= "Survivor" then return end
    if tick() - _lastPalletScan < 0.2 then return end
    _lastPalletScan = tick()
    if tick() - _lastPalletDrop < 2.5 then return end
    pcall(function()
        local char   = Player.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local hum    = char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not hum or hum.Health <= 0 then return end
        local killerRoot = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and IsKiller(plr) and plr.Character then
                local kr = plr.Character:FindFirstChild("HumanoidRootPart")
                if kr then killerRoot = kr; break end
            end
        end
        if not killerRoot then return end
        if (myRoot.Position - killerRoot.Position).Magnitude > (VD.PalletReflexRange or 20) then return end
        local remotes    = ReplicatedStorage:FindFirstChild("Remotes")
        local palletFold = remotes and remotes:FindFirstChild("Pallet")
        local dropEvent  = palletFold and palletFold:FindFirstChild("PalletDropEvent")
        if not dropEvent then return end
        local bestPalletwrong, bestDist = nil, 8
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Palletwrong" and (obj:IsA("Model") or obj:IsA("Folder")) and not _usedPallets[obj] then
                local refPart = obj:FindFirstChild("PalletPoint") or obj:FindFirstChild("PalletPointSlide")
                if refPart and refPart:IsA("BasePart") then
                    local d = (myRoot.Position - refPart.Position).Magnitude
                    if d < bestDist then bestDist = d; bestPalletwrong = obj end
                end
            end
        end
        if bestPalletwrong then
            local fireTarget = bestPalletwrong:FindFirstChild("PalletPointSlide") or bestPalletwrong:FindFirstChild("PalletPoint")
            if fireTarget then
                pcall(function() dropEvent:FireServer(fireTarget) end)
                _usedPallets[bestPalletwrong] = true
                _lastPalletDrop = tick()
            end
        end
    end)
end)

--========================================================--
-- ANTI KNOCK
--========================================================--
function VD_GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child and child:IsA("ValueBase") then return child.Value end
    return nil
end
function VD_IsStatusActive(value)
    return value == true or (type(value) == "number" and value > 0)
end
RunService.Heartbeat:Connect(function()
    if not VD.SURV_AntiKnock or GetRole() ~= "Survivor" then return end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum then return end
    local isKnocked = VD_IsStatusActive(VD_GetGameValue(char, "Knocked"))
        or VD_IsStatusActive(VD_GetGameValue(char, "IsKnocked"))
    local isCarried = VD_IsStatusActive(VD_GetGameValue(char, "Carried"))
        or VD_IsStatusActive(VD_GetGameValue(char, "IsCarried"))
        or VD_IsStatusActive(VD_GetGameValue(char, "Grabbed"))
    if not isKnocked and not isCarried then return end
    local now = tick()
    if VD._LastAntiKnock and now - VD._LastAntiKnock < 0.3 then return end
    VD._LastAntiKnock = now
    for _, flag in ipairs({ "Knocked", "IsKnocked", "Carried", "IsCarried", "Grabbed", "Ragdolled", "Captured", "Disabled" }) do
        pcall(function()
            if char:GetAttribute(flag) ~= nil then char:SetAttribute(flag, false) end
            local obj = char:FindFirstChild(flag)
            if obj and obj:IsA("BoolValue") then obj.Value = false
            elseif obj and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then obj.Value = 0 end
        end)
    end
    pcall(function()
        hum.PlatformStand = false
        hum.Sit = false
        hum.AutoRotate = true
        if hum:GetState() == Enum.HumanoidStateType.Physics
            or hum:GetState() == Enum.HumanoidStateType.Ragdoll
            or hum:GetState() == Enum.HumanoidStateType.FallingDown
            or hum:GetState() == Enum.HumanoidStateType.PlatformStanding then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        task.defer(function()
            pcall(function()
                hum.Health = hum.MaxHealth
                hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end)
    end)
end)
RegToggle(Tabs.Player, "Anti Knock (Reflex)", "Auto pulih dari knockdown via atribut", false, "SURV_AntiKnock")

--========================================================--
-- INVISIBLE NOT VISUAL
--========================================================--
InvNV = {
    Active=false,
    Seat=nil,
    Weld=nil,
    SeatGuard=nil,
    CharacterGuard=nil,
    OriginalSpeed=nil,
    OriginalParts={},
    OriginalDecals={},
    Position=Vector3.new(-25.95, 84, 3537.55)
}

function VD_SetCharacterTransparency(character, transparency)
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            if InvNV.Active and InvNV.OriginalParts[descendant] == nil then
                InvNV.OriginalParts[descendant] = descendant.Transparency
            end
            pcall(function()
                descendant.Transparency = transparency
                descendant.LocalTransparencyModifier = 0
            end)
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            if InvNV.Active and InvNV.OriginalDecals[descendant] == nil then
                InvNV.OriginalDecals[descendant] = descendant.Transparency
            end
            pcall(function()
                descendant.Transparency = transparency
                if descendant:IsA("Decal") then
                    descendant.LocalTransparencyModifier = 0
                end
            end)
        end
    end
end

local function VD_RestoreInvisibleCharacterVisual(character)
    if not character then return end
    for part, original in pairs(InvNV.OriginalParts) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = original
                part.LocalTransparencyModifier = 0
            end)
        end
    end
    for decal, original in pairs(InvNV.OriginalDecals) do
        if decal and decal.Parent then
            pcall(function()
                decal.Transparency = original
                if decal:IsA("Decal") then decal.LocalTransparencyModifier = 0 end
            end)
        end
    end
    InvNV.OriginalParts = {}
    InvNV.OriginalDecals = {}
end

local function VD_HideInvisibleSeatVisual(seat)
    if not seat or not seat.Parent then return end
    pcall(function()
        seat.Size = Vector3.new(0.1, 0.1, 0.1)
        seat.Transparency = 1
        seat.LocalTransparencyModifier = 1
        seat.CastShadow = false
        seat.CanCollide = false
        seat.CanTouch = false
        seat.CanQuery = false
        seat.Material = Enum.Material.SmoothPlastic
    end)
end

function VD_StopInvisibleSeatGuard()
    if InvNV.SeatGuard then
        pcall(function() InvNV.SeatGuard:Disconnect() end)
        InvNV.SeatGuard = nil
    end
    if InvNV.CharacterGuard then
        pcall(function() InvNV.CharacterGuard:Disconnect() end)
        InvNV.CharacterGuard = nil
    end
end

function VD_SetInvisibleNotVisual(state)
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not hum or not root or not torso then return end

    if state then
        if InvNV.Active then
            VD_HideInvisibleSeatVisual(InvNV.Seat)
            VD_SetCharacterTransparency(char, 1)
            hum.WalkSpeed = VD.InvisibleSpeed or 16
            return
        end

        InvNV.Active = true
        InvNV.OriginalSpeed = hum.WalkSpeed
        InvNV.OriginalParts = {}
        InvNV.OriginalDecals = {}

        local savedCFrame = root.CFrame

        pcall(function() char:MoveTo(InvNV.Position) end)
        task.wait(0.15)

        local seat = Instance.new("Seat")
        seat.Name = "MAWWW_InvisibleSeat"
        seat.Anchored = false
        seat.CanCollide = false
        seat.CanTouch = false
        seat.CanQuery = false
        seat.CastShadow = false
        seat.Size = Vector3.new(0.1, 0.1, 0.1)
        seat.Transparency = 1
        seat.LocalTransparencyModifier = 1
        seat.CFrame = CFrame.new(InvNV.Position)
        seat.Parent = Workspace
        VD_HideInvisibleSeatVisual(seat)

        local weld = Instance.new("Weld")
        weld.Name = "MAWWW_InvisibleSeatWeld"
        weld.Part0 = seat
        weld.Part1 = torso
        weld.Parent = seat

        InvNV.Seat = seat
        InvNV.Weld = weld

        task.wait()
        if seat and seat.Parent then
            pcall(function() seat.CFrame = savedCFrame end)
            VD_HideInvisibleSeatVisual(seat)
        end

        VD_SetCharacterTransparency(char, 1)

        VD_StopInvisibleSeatGuard()
        InvNV.SeatGuard = RunService.Heartbeat:Connect(function()
            if not InvNV.Active then return end
            if InvNV.Seat and InvNV.Seat.Parent then
                VD_HideInvisibleSeatVisual(InvNV.Seat)
            end
        end)

        InvNV.CharacterGuard = RunService.Heartbeat:Connect(function()
            if not InvNV.Active then return end
            local current = Player.Character
            if not current then return end
            VD_SetCharacterTransparency(current, 1)
        end)

        hum.WalkSpeed = VD.InvisibleSpeed or 16
    else
        VD.InvisibleNotVisual = false
        InvNV.Active = false
        VD_StopInvisibleSeatGuard()

        if InvNV.Seat and InvNV.Seat.Parent then
            pcall(function() InvNV.Seat:Destroy() end)
        end
        InvNV.Seat = nil
        InvNV.Weld = nil

        VD_RestoreInvisibleCharacterVisual(char)
        if InvNV.OriginalSpeed then hum.WalkSpeed = InvNV.OriginalSpeed end
        InvNV.OriginalSpeed = nil
    end
end

RegToggle(Tabs.Player, "Invisible Not Visual", "FE-style invisible + hidden temporary seat", false, "InvisibleNotVisual", function(v)
    if v then
        pcall(VD_SetInvisibleNotVisual, true)
    else
        pcall(VD_SetInvisibleNotVisual, false)
    end
end)
RegSlider(Tabs.Player, "Invisible Speed", "Speed saat invisible", 5, 1, 999, 1, "InvisibleSpeed")

Player.CharacterRemoving:Connect(function()
    VD_StopInvisibleSeatGuard()
    if InvNV.Seat and InvNV.Seat.Parent then
        pcall(function() InvNV.Seat:Destroy() end)
    end
    InvNV.Active = false
    InvNV.Seat = nil
    InvNV.Weld = nil
    InvNV.OriginalParts = {}
    InvNV.OriginalDecals = {}
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if VD.InvisibleNotVisual then
        pcall(VD_SetInvisibleNotVisual, true)
    end
end)

--========================================================--
-- FAKE PERKS
--========================================================--
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "═══ Fake Perks ═══")

FP = { Conns = {}, ActiveBuffs = {}, HB = nil, LastBuffEnd = 0, CooldownTime = 10 }
function FP_Char() return Player.Character end
function FP_Hum()
    local c = FP_Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
function FP_GetTotalSpeedBuff()
    local total = 0
    for _, b in pairs(FP.ActiveBuffs) do
        if tick() < b.endTime then total = total + b.amt end
    end
    return total
end
function FP_ApplySpeedToCharacter()
    local char = FP_Char()
    local hum = FP_Hum()
    local totalBuff = FP_GetTotalSpeedBuff()
    if char then
        if totalBuff > 0 then
            char:SetAttribute("speedboost", 1 + (totalBuff / 14))
        else
            char:SetAttribute("speedboost", 1)
        end
    end
    if hum and totalBuff > 0 then hum.WalkSpeed = 16 + totalBuff end
end
function FP_EnsureHB()
    if FP.HB then return end
    FP.HB = RunService.Heartbeat:Connect(function()
        local expired = {}
        for name, b in pairs(FP.ActiveBuffs) do
            if tick() >= b.endTime then table.insert(expired, name) end
        end
        for _, name in ipairs(expired) do FP.ActiveBuffs[name] = nil end
        if #expired > 0 and FP_GetTotalSpeedBuff() <= 0 then FP.LastBuffEnd = tick() end
        FP_ApplySpeedToCharacter()
        if next(FP.ActiveBuffs) == nil then
            if FP.HB then FP.HB:Disconnect(); FP.HB = nil end
            local char = FP_Char()
            if char then char:SetAttribute("speedboost", 1) end
        end
    end)
end
function FP_TryBuff(name, amt, dur)
    if FP.ActiveBuffs[name] then return end
    if tick() - FP.LastBuffEnd < FP.CooldownTime and next(FP.ActiveBuffs) == nil then return end
    FP.ActiveBuffs[name] = { amt = amt, endTime = tick() + dur }
    FP_ApplySpeedToCharacter()
    FP_EnsureHB()
    notify("Fake Perks", "[" .. name .. "] Aktif! +" .. amt .. " Speed (" .. dur .. "s)", 3)
end
function FP_Clean(name)
    if FP.Conns[name] then
        for _, c in ipairs(FP.Conns[name]) do pcall(function() c:Disconnect() end) end
        FP.Conns[name] = nil
    end
end
function FP_Reg(name, conn)
    if not FP.Conns[name] then FP.Conns[name] = {} end
    table.insert(FP.Conns[name], conn)
end

RegSlider(Tabs.Survival, "Fake Perk Cooldown", "Cooldown semua fake perk", 10, 0, 60, 1, "FP_Cooldown", function(v) FP.CooldownTime = v end)

RegToggle(Tabs.Survival, "Fake: Flowstate", "+5 speed 3s setelah vault/slide", false, "FP_Flowstate", function(val)
    if val then
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local w = r and r:FindFirstChild("Window")
        local p = r and r:FindFirstChild("Pallet")
        local function onVaultAction()
            if not VD.FP_Flowstate then return end
            task.delay(0.5, function()
                if VD.FP_Flowstate then FP_TryBuff("Flowstate", 5, 3) end
            end)
        end
        if w then
            local vb = w:FindFirstChild("Vaultbindable")
            if vb and vb:IsA("BindableEvent") then FP_Reg("Flowstate", vb.Event:Connect(onVaultAction)) end
        end
        if p then
            local sb = p:FindFirstChild("Slidebindable")
            if sb and sb:IsA("BindableEvent") then FP_Reg("Flowstate", sb.Event:Connect(onVaultAction)) end
        end
    else
        FP_Clean("Flowstate"); FP.ActiveBuffs["Flowstate"] = nil
    end
end)

RegToggle(Tabs.Survival, "Fake: Quick Recovery", "+6 speed 3s setelah di-heal", false, "FP_QuickRecovery", function(val)
    if val then
        local function onHealed()
            if not VD.FP_QuickRecovery then return end
            FP_TryBuff("QuickRecovery", 6, 3)
        end
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        local healFolder = r and r:FindFirstChild("Healing")
        if healFolder then
            local hd = healFolder:FindFirstChild("Healdone")
            if hd and hd:IsA("BindableEvent") then FP_Reg("QuickRecovery", hd.Event:Connect(onHealed)) end
            local scv = healFolder:FindFirstChild("Skillcheckvalidated")
            if scv and scv:IsA("BindableEvent") then FP_Reg("QuickRecovery", scv.Event:Connect(onHealed)) end
        end
        local function hookHealth(c)
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                local lastHP = hum.Health
                local conn = hum.HealthChanged:Connect(function(newHP)
                    if not VD.FP_QuickRecovery then return end
                    if newHP > lastHP and (newHP >= hum.MaxHealth or (newHP - lastHP) >= 15) then onHealed() end
                    lastHP = newHP
                end)
                FP_Reg("QuickRecovery", conn)
            end
        end
        hookHealth(Player.Character)
        FP_Reg("QuickRecovery", Player.CharacterAdded:Connect(hookHealth))
    else
        FP_Clean("QuickRecovery"); FP.ActiveBuffs["QuickRecovery"] = nil
    end
end)

RegToggle(Tabs.Survival, "Fake: Perfect Landing", "+8 speed 3s setelah landing", false, "FP_PerfectLanding", function(val)
    if val then
        local function hookFall(c)
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local wasFalling = false
            local fallStart = 0
            local conn = hum.StateChanged:Connect(function(old, new)
                if not VD.FP_PerfectLanding then return end
                if new == Enum.HumanoidStateType.Freefall then
                    wasFalling = true; fallStart = tick()
                end
                if wasFalling and (new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running) then
                    local fallTime = tick() - fallStart
                    wasFalling = false
                    if fallTime >= 0.25 then FP_TryBuff("PerfectLanding", 8, 3) end
                end
            end)
            FP_Reg("PerfectLanding", conn)
        end
        hookFall(Player.Character)
        FP_Reg("PerfectLanding", Player.CharacterAdded:Connect(hookFall))
    else
        FP_Clean("PerfectLanding"); FP.ActiveBuffs["PerfectLanding"] = nil
    end
end)

RegToggle(Tabs.Survival, "Fake: Adrenaline Rush", "+4 speed 5s saat HP drop <=50", false, "FP_AdrenalineRush", function(val)
    if val then
        local function hookDamage(c)
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local lastHP = hum.Health
            local conn = hum.HealthChanged:Connect(function(newHP)
                if not VD.FP_AdrenalineRush then return end
                if newHP < lastHP and newHP <= 50 and newHP > 0 then FP_TryBuff("AdrenalineRush", 4, 5) end
                lastHP = newHP
            end)
            FP_Reg("AdrenalineRush", conn)
        end
        hookDamage(Player.Character)
        FP_Reg("AdrenalineRush", Player.CharacterAdded:Connect(hookDamage))
    else
        FP_Clean("AdrenalineRush"); FP.ActiveBuffs["AdrenalineRush"] = nil
    end
end)

--========================================================--
-- FAKE GENERATOR
--========================================================--
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "═══ Fake Generator ═══")

getgenv().MAWWW_FakeGenTrack = nil
function VD_ToggleFakeGen()
    if not VD.FakeGenEnabled then
        if getgenv().MAWWW_FakeGenTrack then
            pcall(function() getgenv().MAWWW_FakeGenTrack:Stop() end)
            getgenv().MAWWW_FakeGenTrack = nil
        end
        return
    end
    if getgenv().MAWWW_FakeGenTrack then
        pcall(function() getgenv().MAWWW_FakeGenTrack:Stop() end)
        getgenv().MAWWW_FakeGenTrack = nil
    else
        pcall(function()
            local char = Player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://83160743983246"
            local track = animator:LoadAnimation(animation)
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            getgenv().MAWWW_FakeGenTrack = track
        end)
    end
end

FakeGenButtonState = { UI=nil, Button=nil, DragLocked=false, Dragging=false, DragStart=nil, DragStartPos=nil }
function setupFakeGenBtn()
    local oldUI = PlayerGui:FindFirstChild("FakeGenUI")
    if oldUI then oldUI:Destroy() end
    FakeGenButtonState.UI = Instance.new("ScreenGui")
    FakeGenButtonState.UI.Name = "FakeGenUI"
    FakeGenButtonState.UI.ResetOnSpawn = false
    FakeGenButtonState.UI.IgnoreGuiInset = true
    FakeGenButtonState.UI.Parent = PlayerGui
    local btn = Instance.new("ImageButton")
    btn.Name = "FakeGenButton"
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(0.4, 0, 0.75, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(20, 30, 0)
    btn.BackgroundTransparency = 0.15
    btn.Visible = VD.FakeGenEnabled
    btn.ZIndex = 10
    btn.Parent = FakeGenButtonState.UI
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(150, 255, 70); s.Thickness = 2; s.Transparency = 0.2
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "FAKE\nGEN"; lbl.TextColor3 = Color3.fromRGB(200, 255, 150)
    lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBlack; lbl.ZIndex = 11
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if FakeGenButtonState.DragLocked then return end
            FakeGenButtonState.Dragging = true
            FakeGenButtonState.DragStart = input.Position
            FakeGenButtonState.DragStartPos = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if FakeGenButtonState.Dragging and not FakeGenButtonState.DragLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - FakeGenButtonState.DragStart
            btn.Position = UDim2.new(FakeGenButtonState.DragStartPos.X.Scale, FakeGenButtonState.DragStartPos.X.Offset + delta.X, FakeGenButtonState.DragStartPos.Y.Scale, FakeGenButtonState.DragStartPos.Y.Offset + delta.Y)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            FakeGenButtonState.Dragging = false
        end
    end)
    btn.MouseButton1Click:Connect(VD_ToggleFakeGen)
    FakeGenButtonState.Button = btn
end
RegToggle(Tabs.Survival, "Fake Generator", "Animasi fake gen (Press B)", false, "FakeGenEnabled", function(v)
    setupFakeGenBtn()
    if FakeGenButtonState.Button then FakeGenButtonState.Button.Visible = v end
end)
Player.CharacterAdded:Connect(function()
    if getgenv().MAWWW_FakeGenTrack then pcall(function() getgenv().MAWWW_FakeGenTrack:Stop() end); getgenv().MAWWW_FakeGenTrack = nil end
    task.wait(0.5)
    setupFakeGenBtn()
    if FakeGenButtonState.Button then FakeGenButtonState.Button.Visible = VD.FakeGenEnabled end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.B then VD_ToggleFakeGen() end
end)

--========================================================--
-- AURA HEAL
--========================================================--
InstantHealConn = nil
AutoHealAllConn = nil
function doSelfHealTrue()
    local char = Player.Character; if not char then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function() healRemote:FireServer(hrp, true) end)
end
function doSelfHealFalse()
    local char = Player.Character; if not char then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function() healRemote:FireServer(hrp, false) end)
end
function doOthersHealTrue(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    pcall(function() healRemote:FireServer(targetHRP, true) end)
end
function doOthersHealFalse(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    pcall(function() healRemote:FireServer(targetHRP, false) end)
end
function setInstantHealSelf(v)
    if v then
        local healActive = false
        if InstantHealConn then InstantHealConn:Disconnect() end
        InstantHealConn = RunService.Heartbeat:Connect(function()
            if not VD.InstantHealSelf then return end
            local myChar = Player.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myHum then return end
            if myHum.Health >= myHum.MaxHealth * 0.9 then
                if healActive then healActive = false; doSelfHealFalse() end
                return
            end
            if healActive then
                local ci = myChar:FindFirstChild("CheckInterractable")
                if ci and not ci:GetAttribute("isHealing") then healActive = false end
            end
            if not healActive then healActive = true; doSelfHealTrue() end
        end)
    else
        if InstantHealConn then InstantHealConn:Disconnect(); InstantHealConn = nil end
        pcall(doSelfHealFalse)
    end
end
function setAutoHealAll(v)
    if v then
        local activeHeals = {}
        if AutoHealAllConn then AutoHealAllConn:Disconnect() end
        AutoHealAllConn = RunService.Heartbeat:Connect(function()
            if not VD.AutoHealAll then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Player and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.9 and hrp then
                        if not activeHeals[player] then activeHeals[player] = true; doOthersHealTrue(player) end
                    else
                        if activeHeals[player] then activeHeals[player] = nil; doOthersHealFalse(player) end
                    end
                elseif activeHeals[player] then
                    activeHeals[player] = nil
                    pcall(function() doOthersHealFalse(player) end)
                end
            end
        end)
    else
        if AutoHealAllConn then AutoHealAllConn:Disconnect(); AutoHealAllConn = nil end
    end
end
RegLabel(Tabs.Survival, "═══ Aura Heal ═══")
RegToggle(Tabs.Survival, "Aura Heal (Self)", "Instant heal self (Mawww Hub style)", false, "InstantHealSelf", function(v)
    setInstantHealSelf(v)
end)
RegToggle(Tabs.Survival, "Aura Heal All", "Instant heal semua survivor", false, "AutoHealAll", function(v)
    setAutoHealAll(v)
end)

--========================================================--
-- KORLESS MORPH
--========================================================--
KorlessMorph = { Connection = nil }
function ApplyKorless()
    local function Morph()
        repeat task.wait() until Player.Character
            and Player.Character:FindFirstChild("HumanoidRootPart")
            and Player.Character:FindFirstChild("Right Leg")
        task.wait(0.1)
        local char = Player.Character
        pcall(function()
            char.Head.Transparency = 1
            local face = char.Head:FindFirstChild("face")
            if face then face:Destroy() end
            char["Right Leg"].Transparency = 1
            local mesh = Instance.new("MeshPart")
            mesh.Name = "KorlessHead"
            mesh.Size = Vector3.new(1.5, 1.5, 1.5)
            mesh.CanCollide = false
            mesh.MeshId = "rbxassetid://902942096"
            mesh.TextureID = "rbxassetid://902843398"
            mesh.CFrame = char["Right Leg"].CFrame * CFrame.new(0, 0.5, 0)
            mesh.Parent = char
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = char["Right Leg"]
            weld.Part1 = mesh
            weld.Parent = mesh
        end)
    end
    Morph()
    if KorlessMorph.Connection then KorlessMorph.Connection:Disconnect() end
    KorlessMorph.Connection = Player.CharacterAdded:Connect(function() task.wait(1); Morph() end)
end
RegLabel(Tabs.Avatar, "═══ Korless Morph (NEW) ═══")
RegButton(Tabs.Avatar, "Apply Korless", "Morph korless ke karakter", function()
    ApplyKorless()
    notify("Korless Morph", "Applied successfully!", 3)
end)
RegButton(Tabs.Avatar, "Reset Korless", "Reset korless morph", function()
    if KorlessMorph.Connection then pcall(function() KorlessMorph.Connection:Disconnect() end); KorlessMorph.Connection = nil end
    pcall(function()
        local kh = Player.Character and Player.Character:FindFirstChild("KorlessHead")
        if kh then kh:Destroy() end
    end)
    notify("Korless Morph", "Direset!", 3)
end)

--========================================================--
-- COPY AVATAR
--========================================================--
RegLabel(Tabs.Avatar, "═══ Copy Avatar (NEW) ═══")

selectedAvatarPlayer = nil
copyAvatarDropdown = RegDropdown(Tabs.Avatar, "Select Player to Copy", "Pilih player yang ingin dicopy avatarnya", (function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(list, p.Name) end end
    if #list == 0 then table.insert(list, "No players") end
    return list
end)(), "No players", false, "CopyAvatarTarget", function(v) selectedAvatarPlayer = v end)

originalAvatarCache = {}
originalAvatarSaved = false
originalHeadMeshScale = nil
standardParts = {
    Head=true, Torso=true, ["Left Arm"]=true, ["Right Arm"]=true, ["Left Leg"]=true, ["Right Leg"]=true, HumanoidRootPart=true,
    UpperTorso=true, LowerTorso=true, LeftUpperArm=true, LeftLowerArm=true, LeftHand=true,
    RightUpperArm=true, RightLowerArm=true, RightHand=true, LeftUpperLeg=true, LeftLowerLeg=true,
    LeftFoot=true, RightUpperLeg=true, RightLowerLeg=true, RightFoot=true
}
function AddAccessoryLocal(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    local accAtt = nil
    for _, v in ipairs(handle:GetChildren()) do
        if v:IsA("Attachment") then accAtt = v; break end
    end
    if not accAtt then return end
    local charAtt, targetPart = nil, nil
    local fh = char:FindFirstChild("FakeCopiedHead")
    if fh then
        local att = fh:FindFirstChild(accAtt.Name)
        if att and att:IsA("Attachment") then charAtt = att; targetPart = fh end
    end
    if not charAtt then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "FakeCopiedHead" then
                local att = part:FindFirstChild(accAtt.Name)
                if att and att:IsA("Attachment") then charAtt = att; targetPart = part; break end
            end
        end
    end
    if not charAtt then return end
    for _, v in ipairs(handle:GetChildren()) do
        if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("Script") or v:IsA("LocalScript") then
            v:Destroy()
        end
    end
    accessory.Parent = char
    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = handle; weld.Part1 = targetPart
    weld.C0 = accAtt.CFrame; weld.C1 = charAtt.CFrame
    weld.Parent = handle
end
function SaveOriginalAvatar()
    if originalAvatarSaved then return end
    local char = Player.Character; if not char then return end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Hat") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") or obj:IsA("BodyColors") then
            table.insert(originalAvatarCache, obj:Clone())
        elseif obj:IsA("BasePart") and not standardParts[obj.Name] and obj.Name ~= "FakeCopiedHead" then
            table.insert(originalAvatarCache, obj:Clone())
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        local sm = head:FindFirstChildOfClass("SpecialMesh")
        if sm then originalHeadMeshScale = sm.Scale end
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") or v:IsA("Texture") then table.insert(originalAvatarCache, v:Clone()) end
        end
    end
    originalAvatarSaved = true
end
function ApplyTargetAvatar(targetChar)
    local myChar = Player.Character
    if not myChar or not targetChar then return false end
    for _, obj in ipairs(myChar:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Hat") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") or obj:IsA("BodyColors") then
            obj:Destroy()
        elseif obj:IsA("BasePart") and not standardParts[obj.Name] and obj.Name ~= "FakeCopiedHead" then
            obj:Destroy()
        end
    end
    local myHead = myChar:FindFirstChild("Head")
    if myHead then
        for _, v in ipairs(myHead:GetChildren()) do
            if v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
        end
    end
    local targetHead = targetChar:FindFirstChild("Head")
    if targetHead and myHead then
        myHead.Transparency = 1
        local oldFake = myChar:FindFirstChild("FakeCopiedHead")
        if oldFake then oldFake:Destroy() end
        local fakeHead = targetHead:Clone()
        fakeHead.Name = "FakeCopiedHead"
        fakeHead.CanCollide = false; fakeHead.Massless = true
        local targetBc = targetChar:FindFirstChildOfClass("BodyColors")
        if targetBc then fakeHead.Color = targetBc.HeadColor3 else fakeHead.Color = targetHead.Color end
        local mySm = myHead:FindFirstChildOfClass("SpecialMesh")
        if mySm then mySm.Scale = Vector3.new(0, 0, 0) end
        myHead.LocalTransparencyModifier = 1
        for _, v in ipairs(fakeHead:GetChildren()) do
            if v:IsA("Motor6D") or v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
        end
        fakeHead.Parent = myChar
        local hw = Instance.new("Weld")
        hw.Name = "FakeHeadWeld"
        hw.Part0 = myHead; hw.Part1 = fakeHead
        hw.C0 = CFrame.new(); hw.C1 = CFrame.new()
        hw.Parent = fakeHead
    end
    for _, obj in ipairs(targetChar:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Hat") then AddAccessoryLocal(myChar, obj:Clone())
        elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") or obj:IsA("BodyColors") then
            obj:Clone().Parent = myChar
        elseif obj:IsA("BasePart") and not standardParts[obj.Name] and obj.Name ~= "FakeCopiedHead" then
            local clone = obj:Clone()
            for _, v in ipairs(clone:GetDescendants()) do
                if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
            end
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
            local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
            if targetRoot and myRoot then
                local offset = targetRoot.CFrame:Inverse() * obj.CFrame
                clone.CFrame = myRoot.CFrame * offset
                local wc = Instance.new("WeldConstraint")
                wc.Part0 = clone; wc.Part1 = myRoot
                wc.Parent = clone
            end
            clone.Parent = myChar
        end
    end
    return true
end
RegButton(Tabs.Avatar, "Apply Copy Avatar", "Copy avatar player yang dipilih", function()
    if not selectedAvatarPlayer or selectedAvatarPlayer == "" or selectedAvatarPlayer == "No players" then
        notify("Copy Avatar", "Pilih player dulu!", 3); return
    end
    local targetPlayer = Players:FindFirstChild(selectedAvatarPlayer)
    if targetPlayer and targetPlayer.Character then
        pcall(SaveOriginalAvatar)
        if ApplyTargetAvatar(targetPlayer.Character) then
            notify("Copy Avatar", "Berhasil copy avatar " .. targetPlayer.Name .. "!", 3)
        else
            notify("Copy Avatar", "Gagal mengcopy avatar!", 3)
        end
    else
        notify("Copy Avatar", "Player / Character tidak ditemukan!", 3)
    end
end)
RegButton(Tabs.Avatar, "Reset Copy Avatar", "Kembalikan avatar original", function()
    local char = Player.Character
    if not char or not originalAvatarSaved then
        notify("Reset Avatar", "Tidak ada data original avatar tersimpan!", 3); return
    end
    pcall(function()
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") or obj:IsA("BodyColors") then
                obj:Destroy()
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChildOfClass("Decal")
            if face then face:Destroy() end
            local oldFake = char:FindFirstChild("FakeCopiedHead")
            if oldFake then oldFake:Destroy() end
            head.Transparency = 0; head.LocalTransparencyModifier = 0
            local mySm = head:FindFirstChildOfClass("SpecialMesh")
            if mySm and originalHeadMeshScale then mySm.Scale = originalHeadMeshScale
            elseif mySm then mySm.Scale = Vector3.new(1.25, 1.25, 1.25) end
        end
        for _, obj in ipairs(originalAvatarCache) do
            local clone = obj:Clone()
            if clone:IsA("Decal") then if head then clone.Parent = head end
            elseif clone:IsA("Accessory") then AddAccessoryLocal(char, clone)
            else clone.Parent = char end
        end
    end)
    notify("Copy Avatar", "Avatar dikembalikan ke semula!", 3)
end)

--========================================================--
-- SPOOF STATS + STREAMER MODE + EMOTE
--========================================================--
RegLabel(Tabs.Avatar, "═══ Spoof Stats (NEW) ═══")
spoofLevel, spoofGears, spoofScrews = "0", "0", "0"
RegButton(Tabs.Avatar, "Set Level: Klik untuk ubah", "Spoof level (default 0)", function()
    VD.SPOOF_Level = tostring(tonumber(VD.SPOOF_Level or 0) + 10)
    notify("Spoof Level", "Set ke: " .. VD.SPOOF_Level, 2)
end)
RegButton(Tabs.Avatar, "Set Gears: Klik untuk ubah", "Spoof gears (default 0)", function()
    VD.SPOOF_Gears = tostring(tonumber(VD.SPOOF_Gears or 0) + 10)
    notify("Spoof Gears", "Set ke: " .. VD.SPOOF_Gears, 2)
end)
RegButton(Tabs.Avatar, "Set Screws: Klik untuk ubah", "Spoof screws (default 0)", function()
    VD.SPOOF_Screws = tostring(tonumber(VD.SPOOF_Screws or 0) + 10)
    notify("Spoof Screws", "Set ke: " .. VD.SPOOF_Screws, 2)
end)
RegButton(Tabs.Avatar, "Apply Spoof Data", "Terapkan spoof", function()
    pcall(function()
        Player:SetAttribute("Level", tonumber(VD.SPOOF_Level) or 0)
        Player:SetAttribute("Gears", tonumber(VD.SPOOF_Gears) or 0)
        Player:SetAttribute("Screws", tonumber(VD.SPOOF_Screws) or 0)
        notify("Spoof Data", "Level, Gears, Screws diperbarui", 3)
    end)
end)

RegLabel(Tabs.Avatar, "═══ Streamer Mode (NEW) ═══")
StreamerHideNameConn = nil
function shouldHideNameObject(object)
    local ok, isTextObj = pcall(function() return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") end)
    if not ok or not isTextObj then return false end
    local text = ""; pcall(function() text = tostring(object.Text or "") end)
    return text == Player.Name or text == Player.DisplayName or text:find(Player.Name, 1, true) ~= nil
end
RegToggle(Tabs.Avatar, "Hide Own Name (Streamer)", "Sembunyikan nama sendiri di UI", false, "StreamerHideName", function(enabled)
    if StreamerHideNameConn then pcall(function() StreamerHideNameConn:Disconnect() end); StreamerHideNameConn = nil end
    local pg = Player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local function process(object)
        if shouldHideNameObject(object) then object.Visible = not enabled end
    end
    for _, descendant in ipairs(pg:GetDescendants()) do process(descendant) end
    if enabled then
        StreamerHideNameConn = pg.DescendantAdded:Connect(function(object) task.defer(process, object) end)
    end
end)

RegLabel(Tabs.Avatar, "═══ Player Emote (NEW) ═══")
EmoteOptions = {"Friday Night","WarCry","24 Hour Cinderella","Applause","Arm Swing","Backflip","California Girls","Christmas Spirit","Floating Rest","Ghoul","Griddy","Kyoufuu","OnePlays","Vulnerable"}
SelectedAnim, SelectedSound = "rbxassetid://83229063951016", "rbxassetid://85355610204255"
currentTrack, currentSound = nil, nil
function SelectEmoteData(value)
    if value == "Friday Night" then SelectedAnim = "rbxassetid://83229063951016"; SelectedSound = "rbxassetid://85355610204255"
    elseif value == "WarCry" then SelectedAnim = "rbxassetid://82600868380136"; SelectedSound = "rbxassetid://120101930689931"
    elseif value == "24 Hour Cinderella" then SelectedAnim = "rbxassetid://137195203725366"; SelectedSound = "rbxassetid://121099446613414"
    elseif value == "Applause" then SelectedAnim = "rbxassetid://96328361165090"; SelectedSound = "rbxassetid://115490787020749"
    elseif value == "Arm Swing" then SelectedAnim = "rbxassetid://80552139463944"; SelectedSound = "rbxassetid://74216458932348"
    elseif value == "Backflip" then SelectedAnim = "rbxassetid://74705617908505"; SelectedSound = nil
    elseif value == "California Girls" then SelectedAnim = "rbxassetid://123552803041504"; SelectedSound = "rbxassetid://87899327891544"
    elseif value == "Christmas Spirit" then SelectedAnim = "rbxassetid://137859761110514"; SelectedSound = nil
    elseif value == "Floating Rest" then SelectedAnim = "rbxassetid://114593021219597"; SelectedSound = nil
    elseif value == "Ghoul" then SelectedAnim = "rbxassetid://130415594909401"; SelectedSound = "rbxassetid://123004139176580"
    elseif value == "Griddy" then SelectedAnim = "rbxassetid://75586690784894"; SelectedSound = nil
    elseif value == "Kyoufuu" then SelectedAnim = "rbxassetid://137322894494527"; SelectedSound = "rbxassetid://129064643026442"
    elseif value == "OnePlays" then SelectedAnim = "rbxassetid://140625405103474"; SelectedSound = "rbxassetid://94749073728335"
    elseif value == "Vulnerable" then SelectedAnim = "rbxassetid://121773684313913"; SelectedSound = "rbxassetid://135265751184744" end
end
function PlayEmote()
    local char = Player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    if currentTrack then currentTrack:Stop(); currentTrack = nil end
    if currentSound then currentSound:Destroy(); currentSound = nil end
    if SelectedAnim then
        local anim = Instance.new("Animation"); anim.AnimationId = SelectedAnim
        currentTrack = hum:LoadAnimation(anim); currentTrack.Looped = true; currentTrack:Play()
    end
    if SelectedSound then
        currentSound = Instance.new("Sound"); currentSound.SoundId = SelectedSound
        currentSound.Looped = true; currentSound.Volume = 2; currentSound.Parent = hrp; currentSound:Play()
    end
end
function StopEmote()
    if currentTrack then currentTrack:Stop(); currentTrack = nil end
    if currentSound then currentSound:Destroy(); currentSound = nil end
end
RegToggle(Tabs.Avatar, "Enable Emote", "Play selected emote", false, "EmoteEnabled", function(v)
    if v then PlayEmote() else StopEmote() end
end)
RegDropdown(Tabs.Avatar, "Select Emote", "Pilih emote", EmoteOptions, "Friday Night", false, "SelectedEmote", function(v)
    VD.SelectedEmote = v
    SelectEmoteData(v)
    if VD.EmoteEnabled then PlayEmote() end
end)

--========================================================--
-- AIM LOCK
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "═══ Aim Lock (NEW) ═══")
AimLockState = { Active=false, CurrentTarget=nil, ButtonGui=nil, Button=nil, ButtonLabel=nil }
function VD_AimLock_IsSurvivor(p) return p.Team and p.Team.Name == "Survivors" end
function VD_AimLock_IsDowned(character)
    if not character then return true end
    if character:GetAttribute("Knocked") == true then return true end
    if character:GetAttribute("IsHooked") == true then return true end
    local hum = character:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end
function VD_AimLock_GetClosest()
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local maxDist = VD.AimLock_MaxDistance or 50
    local bestTarget, bestDistance = nil, maxDist + 1
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character and VD_AimLock_IsSurvivor(other) then
            if not VD_AimLock_IsDowned(other.Character) then
                local oHrp = other.Character:FindFirstChild("HumanoidRootPart")
                local oHum = other.Character:FindFirstChildOfClass("Humanoid")
                if oHrp and oHum and oHum.Health > 0 then
                    local distance = (oHrp.Position - hrp.Position).Magnitude
                    if distance <= maxDist and distance < bestDistance then
                        bestDistance = distance; bestTarget = oHrp
                    end
                end
            end
        end
    end
    return bestTarget
end
function VD_RefreshAimLockButton()
    local btn = AimLockState.Button
    if not (btn and btn.Parent) then return end
    btn.BackgroundColor3 = AimLockState.Active and Color3.fromRGB(185, 50, 50) or Color3.fromRGB(20, 0, 30)
    if AimLockState.ButtonLabel and AimLockState.ButtonLabel.Parent then
        AimLockState.ButtonLabel.Text = AimLockState.Active and "ON" or "OFF"
    end
end
function VD_SetAimLockActive(state)
    AimLockState.Active = state and true or false
    if not AimLockState.Active then AimLockState.CurrentTarget = nil end
    VD_RefreshAimLockButton()
end
function VD_DestroyAimLockButton()
    if AimLockState.ButtonGui then pcall(function() AimLockState.ButtonGui:Destroy() end) end
    AimLockState.ButtonGui = nil; AimLockState.Button = nil; AimLockState.ButtonLabel = nil
end
function VD_CreateAimLockButton()
    local pg = Player:FindFirstChild("PlayerGui"); if not pg then return end
    if AimLockState.ButtonGui and AimLockState.ButtonGui.Parent then VD_RefreshAimLockButton(); return end
    local old = pg:FindFirstChild("MAWWW_AimLockButton"); if old then pcall(function() old:Destroy() end) end
    local sg = Instance.new("ScreenGui")
    sg.Name = "MAWWW_AimLockButton"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999998; sg.Parent = pg
    local btn = Instance.new("ImageButton")
    btn.Name = "AimLockButton"; btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(0.88, 0, 0.55, 0); btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(20, 0, 30); btn.BackgroundTransparency = 0.15
    btn.Visible = true; btn.ZIndex = 10; btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stk = Instance.new("UIStroke", btn); stk.Color = Color3.fromRGB(255, 70, 70); stk.Thickness = 2; stk.Transparency = 0.2
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "OFF"; lbl.TextColor3 = Color3.new(1,1,1); lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBlack; lbl.ZIndex = 11
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            moved = false
            if VD.AimLock_Lock then return end
            dragging = true; dragStart = input.Position; startPos = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if VD.AimLock_Lock then return end
        if not dragging or not dragStart or not startPos then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    btn.MouseButton1Click:Connect(function()
        if moved then return end
        VD_SetAimLockActive(not AimLockState.Active)
    end)
    AimLockState.ButtonGui = sg; AimLockState.Button = btn; AimLockState.ButtonLabel = lbl
    VD_RefreshAimLockButton()
end
RegToggle(Tabs.Aim, "Aim Lock (Target Lock)", "Lock ke survivor terdekat", false, "AimLock_Enabled", function(v)
    if v then VD_CreateAimLockButton() else VD_SetAimLockActive(false); VD_DestroyAimLockButton() end
end)
RegToggle(Tabs.Aim, "Lock Aim Lock Button", "Kunci posisi tombol", false, "AimLock_Lock")
RegSlider(Tabs.Aim, "Aim Lock Max Distance", "Jarak maksimal target", 50, 10, 200, 1, "AimLock_MaxDistance")
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.B and VD.AimLock_Enabled then
        VD_SetAimLockActive(not AimLockState.Active)
    end
end)
RunService.RenderStepped:Connect(function()
    if not AimLockState.Active or not VD.AimLock_Enabled then
        AimLockState.CurrentTarget = nil; return
    end
    local targetPart = VD_AimLock_GetClosest()
    if not targetPart then AimLockState.CurrentTarget = nil; return end
    AimLockState.CurrentTarget = targetPart
    pcall(function()
        local cam = Workspace.CurrentCamera
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
    end)
end)

--========================================================--
-- ADVANCED CROSSHAIR OFFSET
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "═══ Crosshair Position Offset (NEW) ═══")
RegSlider(Tabs.Aim, "Crosshair Pos X Offset", "Offset X", 0, -500, 500, 1, "CrossPosX", function(v)
    VD.CrossPosX = v
end)
RegSlider(Tabs.Aim, "Crosshair Pos Y Offset", "Offset Y", 0, -500, 500, 1, "CrossPosY", function(v)
    VD.CrossPosY = v
end)

--========================================================--
-- SILENT AIM FLASK (CURE) + FLASK LASER
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "═══ Silent Aim Flask / Cure (NEW) ═══")

getgenv().MAWWW_CureFlaskLaserThread = nil
getgenv().MAWWW_CureFlaskLaserPart = nil
function MAWWW_UpdateCureFlaskLaser()
    local char = Player.Character; if not char then return end
    local targetPos, originPos = nil, nil
    local closest, minDst = nil, math.huge
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local hand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
        originPos = hand and hand.Position or hrp.Position
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                if not v.Character:GetAttribute("IsKiller") then
                    local dst = (v.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if dst < minDst then minDst = dst; closest = v end
                end
            end
        end
    end
    if closest then targetPos = closest.Character.HumanoidRootPart.Position end
    local actionActive = false
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("LocalScript") and child:GetAttribute("action") == true then actionActive = true; break end
    end
    if originPos and targetPos and actionActive then
        if not getgenv().MAWWW_CureFlaskLaserPart then
            local laser = Instance.new("Part")
            laser.Name = "FlaskSilentAimLaser"; laser.Anchored = true; laser.CanCollide = false
            laser.CanTouch = false; laser.CastShadow = false
            laser.Material = Enum.Material.Neon; laser.Color = Color3.fromRGB(0, 100, 255)
            laser.Transparency = 0; laser.Parent = Workspace
            getgenv().MAWWW_CureFlaskLaserPart = laser
        end
        local dist = (targetPos - originPos).Magnitude
        if dist > 0.1 then
            local laser = getgenv().MAWWW_CureFlaskLaserPart
            laser.Size = Vector3.new(0.16, 0.16, dist)
            laser.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
            laser.Transparency = 0
        end
    else
        if getgenv().MAWWW_CureFlaskLaserPart then getgenv().MAWWW_CureFlaskLaserPart.Transparency = 1 end
    end
end
function MAWWW_StartCureFlaskLaser()
    if getgenv().MAWWW_CureFlaskLaserThread then return end
    getgenv().MAWWW_CureFlaskLaserThread = RunService.RenderStepped:Connect(function()
        if not VD.FlaskLaser then
            if getgenv().MAWWW_CureFlaskLaserPart then pcall(function() getgenv().MAWWW_CureFlaskLaserPart:Destroy() end); getgenv().MAWWW_CureFlaskLaserPart = nil end
            if getgenv().MAWWW_CureFlaskLaserThread then getgenv().MAWWW_CureFlaskLaserThread:Disconnect(); getgenv().MAWWW_CureFlaskLaserThread = nil end
            return
        end
        pcall(MAWWW_UpdateCureFlaskLaser)
    end)
end
RegToggle(Tabs.Aim, "Silent Aim Flask (Cure)", "Auto-aim flask ke survivor terdekat", false, "Killer_SilentAimFlask", function(v)
end)
RegToggle(Tabs.Aim, "Flask Laser (Cure)", "Tampilkan laser flask", false, "FlaskLaser", function(v)
    if v then pcall(MAWWW_StartCureFlaskLaser)
    else
        if getgenv().MAWWW_CureFlaskLaserThread then getgenv().MAWWW_CureFlaskLaserThread:Disconnect(); getgenv().MAWWW_CureFlaskLaserThread = nil end
        if getgenv().MAWWW_CureFlaskLaserPart then pcall(function() getgenv().MAWWW_CureFlaskLaserPart:Destroy() end); getgenv().MAWWW_CureFlaskLaserPart = nil end
    end
end)

--========================================================--
-- ADVANCED FLASHLIGHT SILENT AIM
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "═══ Advanced Silent Aim Flashlight (NEW) ═══")
RegToggle(Tabs.Aim, "Flashlight Laser (Advanced)", "Tampilkan laser flashlight", true, "FlashLaser")
RegDropdown(Tabs.Aim, "Flashlight Target Part", "Body part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", false, "FlashTargetPart")
RegSlider(Tabs.Aim, "Flashlight Range (Adv)", "Range", 120, 20, 250, 1, "FlashRange")
RegSlider(Tabs.Aim, "Flashlight Smoothness (Adv)", "Smoothness", 0.35, 0.05, 1, 0.01, "FlashSmooth")

--========================================================--
-- KILLER UTILITIES - BLOCK VAULTS / DROP ALL PALLETS / BREAK ALL PALLETS / BEAT KILLER
--========================================================--
RegDivider(Tabs.Killer)
RegLabel(Tabs.Killer, "═══ Killer Utilities (NEW) ═══")
RegToggle(Tabs.Killer, "Block All Vaults", "Fire VaultEvent ke semua vault", false, "KillerBlockAllVaults")
RegToggle(Tabs.Killer, "Auto Drop All Pallets", "Fire PalletDropEvent ke semua pallet", false, "KillerAutoDropAllPallets")
RegToggle(Tabs.Killer, "Break All Pallets (TP + Break)", "TP ke semua pallet dan hancurkan", false, "KillerBreakAllPallets")

getgenv().MAWWW_LastVaultBlockTime = 0
getgenv().MAWWW_LastPalletBlockTime = 0
getgenv().MAWWW_LastPalletBlockDropTime = 0
getgenv().MAWWW_IsBlockingPallets = false

function MAWWW_BlockAllVaults()
    if not VD.KillerBlockAllVaults or GetRole() ~= "Killer" then return end
    local now = tick()
    if now - getgenv().MAWWW_LastVaultBlockTime < 1.5 then return end
    getgenv().MAWWW_LastVaultBlockTime = now
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local vaultEvent = remotes and remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultEvent")
        if not vaultEvent then return end
        local map = Workspace:FindFirstChild("Map")
        local vaultsFolder = map and map:FindFirstChild("Vaults")
        if vaultsFolder then
            for _, vault in ipairs(vaultsFolder:GetChildren()) do
                for _, part in ipairs(vault:GetChildren()) do
                    if part:IsA("BasePart") then
                        pcall(function() vaultEvent:FireServer(part, true) end)
                    end
                end
            end
        end
    end)
end

function MAWWW_BlockAllPalletDrops()
    if not VD.KillerAutoDropAllPallets or GetRole() ~= "Killer" then return end
    local now = tick()
    if now - getgenv().MAWWW_LastPalletBlockTime < 2 then return end
    getgenv().MAWWW_LastPalletBlockTime = now
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local palletFold = remotes and remotes:FindFirstChild("Pallet")
        local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
        if not dropEvent then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name == "Palletwrong" and (obj:IsA("Model") or obj:IsA("Folder")) then
                local target = obj:FindFirstChild("PalletPointSlide") or obj:FindFirstChild("PalletPoint")
                if target then pcall(function() dropEvent:FireServer(target) end) end
            end
        end
    end)
end

function MAWWW_ForceUnstuck(char)
    pcall(function()
        char:SetAttribute("Immobile", nil)
        char:SetAttribute("immobile", nil)
        char:SetAttribute("IsStunned", nil)
        char:SetAttribute("isStunned", nil)
        char:SetAttribute("Pursuit", nil)
        char:SetAttribute("pursuit", nil)
    end)
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed <= 0 then hum.WalkSpeed = 16 end
    end)
end

function MAWWW_BlockPalletDrop()
    if not VD.KillerBreakAllPallets or GetRole() ~= "Killer" then return end
    if getgenv().MAWWW_IsBlockingPallets then return end
    local now = tick()
    if now - getgenv().MAWWW_LastPalletBlockDropTime < 4 then return end
    getgenv().MAWWW_LastPalletBlockDropTime = now
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local stunned = char:GetAttribute("IsStunned") or char:GetAttribute("isStunned")
    local immobile = char:GetAttribute("Immobile") or char:GetAttribute("immobile")
    local carrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
    if stunned or immobile or carrying then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local palletFold = remotes and remotes:FindFirstChild("Pallet")
        local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
        local jasonFold = palletFold and palletFold:FindFirstChild("Jason")
        local destroyGlobal = jasonFold and jasonFold:FindFirstChild("Destroy-Global")
        local breakCommit = jasonFold and jasonFold:FindFirstChild("PalletBreakCommit")
        local destroySingle = jasonFold and jasonFold:FindFirstChild("Destroy")
        if not dropEvent or not destroyGlobal or not breakCommit then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        local function collectTargets()
            local targets, seen = {}, {}
            for _, obj in ipairs(map:GetDescendants()) do
                if obj.Name == "Palletwrong" and (obj:IsA("Model") or obj:IsA("Folder")) then
                    local target = obj:FindFirstChild("PalletPointSlide") or obj:FindFirstChild("PalletPoint")
                    if target and target:IsA("BasePart") and not seen[target] then
                        table.insert(targets, target); seen[target] = true
                    end
                end
            end
            return targets
        end
        local targets = collectTargets()
        if #targets == 0 then return end
        getgenv().MAWWW_IsBlockingPallets = true
        local hum = char:FindFirstChildOfClass("Humanoid")
        local origWalkSpeed = hum and hum.WalkSpeed or 16
        task.spawn(function()
            pcall(function()
                local originalCF = root.CFrame
                local function processPallet(target)
                    if not target or not target.Parent then return end
                    pcall(function()
                        dropEvent:FireServer(target); task.wait(0.12)
                        root.CFrame = target.CFrame + Vector3.new(0, 2, 0); task.wait(0.15)
                        destroyGlobal:FireServer(target); breakCommit:FireServer(target)
                        if destroySingle then destroySingle:FireServer(target) end
                        task.wait(0.12); MAWWW_ForceUnstuck(char)
                    end)
                end
                for _, target in ipairs(targets) do processPallet(target) end
                task.wait(0.1); pcall(function() root.CFrame = originalCF end)
                MAWWW_ForceUnstuck(char)
                task.wait(0.5)
                local remaining = collectTargets()
                if #remaining > 0 then
                    originalCF = root.CFrame
                    for _, target in ipairs(remaining) do processPallet(target) end
                    task.wait(0.1); pcall(function() root.CFrame = originalCF end)
                end
                task.wait(0.1); MAWWW_ForceUnstuck(char)
                if hum then pcall(function() hum.WalkSpeed = origWalkSpeed end) end
            end)
            task.spawn(function()
                for i = 1, 10 do
                    task.wait(0.1)
                    if char and char.Parent then
                        MAWWW_ForceUnstuck(char)
                        if hum and hum.WalkSpeed <= 0 then pcall(function() hum.WalkSpeed = origWalkSpeed end) end
                    end
                end
            end)
            getgenv().MAWWW_IsBlockingPallets = false
        end)
    end)
end

RegToggle(Tabs.Killer, "Beat Killer (Auto Chase)", "Auto chase & kill survivor", false, "BeatKiller")
function MAWWW_BeatGameKiller()
    if not VD.BeatKiller then VD._KillerTarget = nil; return end
    if GetRole() ~= "Killer" then VD._KillerTarget = nil; return end
    local root = getRoot(); if not root then return end
    local target = VD._KillerTarget
    local needNewTarget = true
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        local th = target.Character:FindFirstChildOfClass("Humanoid")
        if tr and th and th.MaxHealth > 0 and (th.Health / th.MaxHealth) > 0.25 then
            needNewTarget = false
        else VD._KillerTarget = nil end
    end
    if needNewTarget then
        local survivors = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and IsSurvivor(plr) and plr.Character then
                local pr = plr.Character:FindFirstChild("HumanoidRootPart")
                local ph = plr.Character:FindFirstChildOfClass("Humanoid")
                if pr and ph and ph.MaxHealth > 0 and (ph.Health / ph.MaxHealth) > 0.25 then table.insert(survivors, plr) end
            end
        end
        if #survivors > 0 then
            local closest, closestDist = nil, math.huge
            for _, plr in ipairs(survivors) do
                local pr = plr.Character:FindFirstChild("HumanoidRootPart")
                local dist = (pr.Position - root.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = plr end
            end
            VD._KillerTarget = closest; target = closest
        else VD._KillerTarget = nil; return end
    end
    if not target or not target.Character then return end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local th = target.Character:FindFirstChildOfClass("Humanoid")
    if not tr or not th then VD._KillerTarget = nil; return end
    if th.MaxHealth <= 0 or (th.Health / th.MaxHealth) <= 0.25 then VD._KillerTarget = nil; return end
    for _, part in ipairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
    end
    local dir = (root.Position - tr.Position).Unit
    if dir.Magnitude ~= dir.Magnitude then dir = Vector3.new(1, 0, 0) end
    root.CFrame = CFrame.new(tr.Position + dir * 3 + Vector3.new(0, 1, 0), tr.Position)
    pcall(function()
        local r = GetRemotes()
        local a = r and r:FindFirstChild("Attacks")
        local ba = a and a:FindFirstChild("BasicAttack")
        if ba then ba:FireServer(false) end
    end)
end

task.spawn(function()
    while not VD.Destroyed do
        pcall(MAWWW_BlockAllVaults)
        pcall(MAWWW_BlockAllPalletDrops)
        pcall(MAWWW_BlockPalletDrop)
        pcall(MAWWW_BeatGameKiller)
        task.wait(0.15)
    end
end)

--========================================================--
-- INFINITE LUNGE
--========================================================--
VD_OriginalLungeBoost = nil
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.3)
        local char = Player.Character
        if char then
            if VD.KillerInfLunge then
                if char:GetAttribute("lungeboost") ~= 999999 then
                    VD_OriginalLungeBoost = char:GetAttribute("lungeboost") or 1
                    pcall(function() char:SetAttribute("lungeboost", 999999) end)
                end
            else
                if VD_OriginalLungeBoost then
                    pcall(function() char:SetAttribute("lungeboost", VD_OriginalLungeBoost) end)
                    VD_OriginalLungeBoost = nil
                end
            end
        end
    end
end)

--========================================================--
-- RADAR - extended object types
--========================================================--
RegDivider(Tabs.Radar)
RegLabel(Tabs.Radar, "═══ Extended Radar Filters (NEW) ═══")
RegToggle(Tabs.Radar, "Show Generator", "Generator di radar", false, "RADAR_ShowGenerator")
RegToggle(Tabs.Radar, "Show Pallet", "Pallet di radar", false, "RADAR_ShowPallet")
RegToggle(Tabs.Radar, "Show Hook", "Hook di radar", false, "RADAR_ShowHook")
RegToggle(Tabs.Radar, "Show Gate", "Gate di radar", false, "RADAR_ShowGate")
RegToggle(Tabs.Radar, "Show Window", "Window di radar", false, "RADAR_ShowWindow")
RegToggle(Tabs.Radar, "Show Zombie", "Zombie di radar", false, "RADAR_ShowZombie")

RadarCache = { Generators={}, Gates={}, Hooks={}, Pallets={}, Windows={}, Zombies={} }
function RadarScanMap()
    local map = Workspace:FindFirstChild("Map"); if not map then return end
    for k in pairs(RadarCache) do RadarCache[k] = {} end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") then
            local part = obj:FindFirstChild("HitBox", true) or obj:FindFirstChild("GeneratorPoint", true) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local n = obj.Name
                if n == "Generator" then table.insert(RadarCache.Generators, { model=obj, part=part })
                elseif n == "Gate" or n == "ExitGate" or obj:FindFirstChild("ExitLever") then table.insert(RadarCache.Gates, { model=obj, part=part })
                elseif n == "Hook" then table.insert(RadarCache.Hooks, { model=obj, part=part })
                elseif n == "Palletwrong" or n:lower():find("pallet") then table.insert(RadarCache.Pallets, { model=obj, part=part })
                elseif n == "Window" then table.insert(RadarCache.Windows, { model=obj, part=part })
                elseif n:lower():find("scp") or n:lower():find("zombie") then table.insert(RadarCache.Zombies, { model=obj, part=part })
                end
            end
        end
    end
end
RadarScanMap()
task.spawn(function()
    while not VD.Destroyed do
        task.wait(5)
        if VD.RADAR_Enabled then pcall(RadarScanMap) end
    end
end)

--========================================================--
-- KILLER PERKS DISPLAY
--========================================================--
MAWWW_KillerPerkNames = {
    MawwwtInLine = "Mawwwt in Line", ["Mawwwt in Line"] = "Mawwwt in Line",
    EchoLocation = "Echo Location", ["Echo Location"] = "Echo Location",
    KingsScourge = "King's Scourge", KingScourge = "King's Scourge", ["King's Scourge"] = "King's Scourge",
}
function MAWWW_EscapeRichText(text)
    text = tostring(text or "")
    text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    return text
end
function MAWWW_FormatPerkName(name)
    name = tostring(name or "")
    if MAWWW_KillerPerkNames[name] then return MAWWW_KillerPerkNames[name] end
    local clean = name:gsub("_", " "):gsub("-", " ")
    clean = clean:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"):gsub("(%d)(%a)", "%1 %2")
    clean = clean:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return clean ~= "" and clean or "Unknown Perk"
end
function MAWWW_GetKillerPlayer()
    for _, plr in ipairs(Players:GetPlayers()) do
        local tn = plr.Team and plr.Team.Name
        if tn and tn:lower():find("killer") then return plr end
    end
    return nil
end
function MAWWW_ParseWorkspacePerkName(name)
    name = tostring(name or "")
    local perkName, level = name:match("^(.+)%s+(%d+)$")
    if not perkName then return nil end
    perkName = perkName:gsub("^%s+", ""):gsub("%s+$", "")
    if perkName == "" then return nil end
    local lower = perkName:lower()
    local excluded = { head=true, torso=true, humanoid=true, ["left arm"]=true, ["right arm"]=true, ["left leg"]=true, ["right leg"]=true, humanoidrootpart=true }
    if excluded[lower] then return nil end
    return perkName, level
end
function MAWWW_ReadPerksFromWorkspace(killer)
    if not killer then return {} end
    local char = killer.Character or Workspace:FindFirstChild(killer.Name) or Workspace:FindFirstChild(killer.DisplayName)
    if not char then return {} end
    local result, seen = {}, {}
    local function addPerk(raw, displayName, level)
        if not raw then return end
        raw = tostring(raw)
        if raw == "" or raw == "nil" or seen[raw] then return end
        if raw:lower():find("template") then return end
        seen[raw] = true
        table.insert(result, { Raw=raw, Name=displayName and tostring(displayName) or MAWWW_FormatPerkName(raw), Level=level and tostring(level) or nil })
    end
    local function scanAttrs(inst)
        if not inst.GetAttributes then return end
        local attrs = inst:GetAttributes()
        for key, value in pairs(attrs) do
            local lowerKey = tostring(key):lower()
            if lowerKey:find("perk") then
                if type(value) == "string" then addPerk(value)
                elseif value == true then addPerk(key)
                elseif type(value) == "number" and lowerKey:find("level") then
                    local baseName = tostring(key):gsub("[Ll]evel", ""):gsub("[Pp]erk", "")
                    if baseName ~= "" then addPerk(baseName, nil, value) end
                end
            end
        end
    end
    local function readValueObject(inst)
        if inst:IsA("StringValue") then return inst.Value
        elseif inst:IsA("IntValue") or inst:IsA("NumberValue") then return inst.Name, inst.Value
        elseif inst:IsA("BoolValue") and inst.Value == true then return inst.Name end
        return nil
    end
    local function isPerkContainer(inst)
        local name = inst.Name:lower()
        return name == "perks" or name == "killerperks" or name == "equippedperks" or name == "equippedkillerperks" or name:find("perkfolder") ~= nil or name:find("perklist") ~= nil
    end
    scanAttrs(char)
    for _, child in ipairs(char:GetChildren()) do
        local perkName, level = MAWWW_ParseWorkspacePerkName(child.Name)
        if perkName then addPerk(child.Name, perkName, level) end
    end
    for _, inst in ipairs(char:GetDescendants()) do
        scanAttrs(inst)
        if isPerkContainer(inst) then
            for _, child in ipairs(inst:GetChildren()) do
                local value, level = readValueObject(child)
                addPerk(value or child.Name, nil, level)
            end
        else
            local lowerName = inst.Name:lower()
            if lowerName:find("perk") then
                local value, level = readValueObject(inst)
                addPerk(value or inst.Name, nil, level)
            end
        end
    end
    table.sort(result, function(a, b) return tostring(a.Name) < tostring(b.Name) end)
    return result
end
function MAWWW_BuildKillerPerksText()
    local killer = MAWWW_GetKillerPlayer()
    local killerName = killer and (killer.DisplayName or killer.Name) or "Unknown"
    local perks = MAWWW_ReadPerksFromWorkspace(killer)
    if #perks == 0 then
        for _, plr in ipairs(Players:GetPlayers()) do
            local candidatePerks = MAWWW_ReadPerksFromWorkspace(plr)
            if #candidatePerks > 0 then
                killer = plr; killerName = plr.DisplayName or plr.Name; perks = candidatePerks; break
            end
        end
    end
    local lines = { 'Killer Perks [<font color="rgb(255,80,80)">' .. MAWWW_EscapeRichText(killerName) .. '</font>]' }
    if #perks == 0 then
        table.insert(lines, '<font color="rgb(255,204,80)">- Waiting for perk data...</font>')
    else
        for i = 1, math.min(#perks, 4) do
            local perk = perks[i]
            local levelText = perk.Level and (" lvl " .. tostring(perk.Level)) or ""
            table.insert(lines, '<font color="rgb(255,204,80)">- ' .. MAWWW_EscapeRichText(perk.Name) .. MAWWW_EscapeRichText(levelText) .. '</font>')
        end
    end
    return table.concat(lines, "\n"), #perks
end
getgenv().MAWWW_KillerPerksRunning = false
getgenv().MAWWW_KillerPerksGui = nil
function StartKillerPerksDisplay()
    if getgenv().MAWWW_KillerPerksRunning then return end
    getgenv().MAWWW_KillerPerksRunning = true
    task.spawn(function()
        while VD.VIS_KillerPerks and getgenv().MAWWW_KillerPerksRunning do
            local text = MAWWW_BuildKillerPerksText()
            if getgenv().MAWWW_UpdateInfoOverlayKillerPerks then
                pcall(getgenv().MAWWW_UpdateInfoOverlayKillerPerks, text)
            end
            task.wait(1)
        end
    end)
end
function StopKillerPerksDisplay()
    getgenv().MAWWW_KillerPerksRunning = false
end

--========================================================--
-- ANTI FALL DAMAGE HOOK (via __namecall)
--========================================================--
if typeof(hookmetamethod) == "function" then
    pcall(function()
        local mt = getrawmetatable(game)
        if mt and mt.__namecall then
            local oldNamecall = mt.__namecall
            if setreadonly then setreadonly(mt, false) end
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" and not checkcaller() then
                    if VD.AntiFallDamage then
                        local ok, name = pcall(function() return self.Name:lower() end)
                        if ok and (name:find("falldamage") or name:find("fall") or name:find("ragdollfall")) then
                            return
                        end
                    end
                    if VD.Killer_SilentAimFlask then
                        local ok, name = pcall(function() return self.Name end)
                        if ok and name == "ThrowFlask" then
                            local args = {...}
                            local closest = nil
                            local minDst = math.huge
                            local myPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
                            if myPos then
                                for _, v in pairs(Players:GetPlayers()) do
                                    if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                        if not v.Character:GetAttribute("IsKiller") then
                                            local dst = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
                                            if dst < minDst then minDst = dst; closest = v end
                                        end
                                    end
                                end
                            end
                            if closest then
                                local targetPos = closest.Character.HumanoidRootPart.Position
                                if args[2] and typeof(args[2]) == "Vector3" then
                                    args[1] = (targetPos - args[2]).Unit
                                end
                                setnamecallmethod(method)
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            if setreadonly then setreadonly(mt, true) end
        end
    end)
end

--========================================================--
-- PLAYER TAB (Survivor abilities)
--========================================================--
RegLabel(Tabs.Survival, "═══ Survivor Abilities ═══")
RegToggle(Tabs.Survival, "Anti Knockdown", "Auto recover dari knockdown", false, "AntiKnockdown")
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.AntiKnockdown then
            local hum = getHum()
            if hum then
                if hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Dead or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                end
            end
        end
    end
end)
RegToggle(Tabs.Survival, "Auto Wiggle", "Auto escape saat carried", false, "AutoWiggle")
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.AutoWiggle then
            local char = Player.Character
            if char then
                local carried = (char:FindFirstChild("IsCarried") and char.IsCarried.Value) or (char:FindFirstChild("IsCarrying") and char.IsCarrying.Value)
                if carried then
                    local remotes = GetRemotes()
                    local carry = remotes and remotes:FindFirstChild("Carry")
                    local ev = carry and carry:FindFirstChild("SelfUnHookEvent")
                    if ev then for _=1,5 do pcall(function() ev:FireServer() end) end end
                end
            end
        end
    end
end)
LastCrouchTime = 0
function TriggerCrouch()
    if tick() - LastCrouchTime < 0.5 then return end
    LastCrouchTime = tick()
    local sm = PlayerGui:FindFirstChild("Survivor-mob")
    local ctrl = sm and sm:FindFirstChild("Controls")
    local btn = ctrl and ctrl:FindFirstChild("Crouch")
    if btn then
        pcall(function() btn:Activate() end)
        if typeof(firesignal) == "function" then
            pcall(function() firesignal(btn.MouseButton1Down) end)
            pcall(function() firesignal(btn.MouseButton1Click) end)
        end
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
        end)
    end
end
RegToggle(Tabs.Survival, "Auto Crouch Dodge", "Auto crouch saat killer attack", false, "AutoCrouchDodge")
hookedDodge = setmetatable({}, {__mode = "k"})
task.spawn(function()
    while not VD.Destroyed do
        task.wait(1)
        if VD.AutoCrouchDodge then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and IsKiller(p) and p.Character and not hookedDodge[p.Character] then
                    hookedDodge[p.Character] = true
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local anim = hum and hum:FindFirstChildOfClass("Animator")
                    if anim then
                        anim.AnimationPlayed:Connect(function(track)
                            if not VD.AutoCrouchDodge then return end
                            local id = track.Animation and track.Animation.AnimationId:match("%d+")
                            if id == "80411309607666" then
                                local myRoot = getRoot()
                                local kRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot and kRoot and (kRoot.Position - myRoot.Position).Magnitude <= 40 then
                                    task.spawn(TriggerCrouch)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end)
AntiFallState = { lastFreefall = 0, restoring = false, lastRemoteFire = 0 }
FALL_SLOW_ATTRS = {"FallSlow","FallingSlow","FallingSlowdown","FallSlowdown","SlowdownActive","StunFall","LandSlow","LandSlowdown","FallingStun","FallStun","LandingSlow","IsSlowed","Slowed","Slow","FallStunActive","LandingRecovery"}
FALL_SLOW_REMOTE_NAMES = {"CancelFall","FallRecover","LandRecover","ResetSlow","ClearSlow","CancelStun","LandingRecover","Recover","FallCancel","CancelSlowdown","RemoveSlow","ClearStun","LandingCancel","FallStun","EndFall"}
FALL_SLOW_FOLDERS = { "Player","Movement","Character","PlayerActions","Game","Actions","Status","Effects","Slowdown" }
function ClearFallSlowdown(hum, char)
    if hum then
        if hum.WalkSpeed > 0 and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        if hum.JumpPower > 0 and hum.JumpPower < 50 then hum.JumpPower = 50 end
    end
    if char then
        pcall(function()
            for _, a in ipairs(FALL_SLOW_ATTRS) do
                if char:GetAttribute(a) == true then char:SetAttribute(a, false) end
            end
        end)
    end
end
function FireFallRecoveryRemotes()
    local now = tick()
    if now - AntiFallState.lastRemoteFire < 0.8 then return end
    AntiFallState.lastRemoteFire = now
    pcall(function()
        local remotes = GetRemotes(); if not remotes then return end
        for _, folderName in ipairs(FALL_SLOW_FOLDERS) do
            local folder = remotes:FindFirstChild(folderName)
            if folder then
                for _, evName in ipairs(FALL_SLOW_REMOTE_NAMES) do
                    local ev = folder:FindFirstChild(evName)
                    if ev and ev:IsA("RemoteEvent") then pcall(function() ev:FireServer() end) end
                end
            end
        end
        for _, evName in ipairs(FALL_SLOW_REMOTE_NAMES) do
            local ev = remotes:FindFirstChild(evName)
            if ev and ev:IsA("RemoteEvent") then pcall(function() ev:FireServer() end) end
        end
    end)
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.AntiFallSlowdown then
            local char = Player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local st = hum:GetState(); local now = tick()
                    if st == Enum.HumanoidStateType.Freefall then
                        AntiFallState.lastFreefall = now
                        if hum.WalkSpeed > 0 and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                    elseif st == Enum.HumanoidStateType.Landed then
                        if (now - AntiFallState.lastFreefall) < 2.0 then
                            ClearFallSlowdown(hum, char)
                            if not AntiFallState.restoring then
                                AntiFallState.restoring = true
                                FireFallRecoveryRemotes()
                                task.delay(1.0, function() AntiFallState.restoring = false end)
                            end
                        end
                    end
                    local slowed = false
                    for _, a in ipairs(FALL_SLOW_ATTRS) do
                        if char:GetAttribute(a) == true then slowed = true; break end
                    end
                    if slowed and st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping and st ~= Enum.HumanoidStateType.Landed then
                        ClearFallSlowdown(hum, char)
                        FireFallRecoveryRemotes()
                    end
                end
            end
        end
    end
end)
RegToggle(Tabs.Survival, "Anti Fall Slowdown", "Remove landing slowdown", false, "AntiFallSlowdown")

--========================================================--
-- ABYSS DODGE + SPEAR VEIL (backport)
--========================================================--
ABYSS_ANIM_ID = "103714321340288"
hookedAbyss = setmetatable({}, {__mode = "k"})
task.spawn(function()
    while not VD.Destroyed do
        task.wait(1)
        if VD.AutoDodgeAbyss then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and IsKiller(p) and p.Character and not hookedAbyss[p.Character] then
                    hookedAbyss[p.Character] = true
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local anim = hum and hum:FindFirstChildOfClass("Animator")
                    if anim then
                        anim.AnimationPlayed:Connect(function(track)
                            if not VD.AutoDodgeAbyss then return end
                            local id = track.Animation and track.Animation.AnimationId:match("%d+")
                            if id == ABYSS_ANIM_ID then
                                local myRoot = getRoot()
                                local kRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot and kRoot and (kRoot.Position - myRoot.Position).Magnitude <= (VD.AbyssDodgeDistance or 20) then
                                    task.spawn(TriggerCrouch)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end)
RegToggle(Tabs.Survival, "Auto Dodge Abyss", "Dodge abyssal burst", false, "AutoDodgeAbyss")
RegSlider(Tabs.Survival, "Abyss Dodge Distance", "Trigger distance", 20, 5, 50, 1, "AbyssDodgeDistance")

SpearVeil = (function()
    local State = { LastDodge = 0, Dodging = false, TrackedSpears = setmetatable({}, {__mode = "k"}), KillersHooked = setmetatable({}, {__mode = "k"}), DescConn = nil, IndicatorPart = nil, SpearRemoteHooked = false, DODGE_COOLDOWN = 0.35, HIT_RADIUS = 3.5, HIT_VERT = 6, MAX_TRACK = 6 }
    local function IsSpearPart(obj)
        if not obj or not obj:IsA("BasePart") then return false end
        local n = string.lower(obj.Name or ""); if n == "" then return false end
        if n:find("spear",1,true) then return true end
        if n:find("veil",1,true) then return true end
        if n:find("projectile",1,true) then return true end
        if n:find("javelin",1,true) then return true end
        if n:find("harpoon",1,true) then return true end
        local sz = obj.Size
        if obj.AssemblyLinearVelocity.Magnitude > 40 and sz.X < 2 and sz.Y < 2 and sz.Z > 2 then return true end
        return false
    end
    local function WillHitMe(spearPart)
        local myChar = Player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot or not spearPart or not spearPart.Parent then return false end
        local myPos = myRoot.Position; local spearPos = spearPart.Position
        local vel = spearPart.AssemblyLinearVelocity; if vel.Magnitude < 3 then return false end
        local maxRange = tonumber(VD.SpearVeilDetectRange) or 50
        if (spearPos - myPos).Magnitude > maxRange then return false end
        local dir = vel.Unit; local toMe = myPos - spearPos
        local projLen = toMe:Dot(dir)
        if projLen < 0 or projLen > maxRange then return false end
        local closestPt = spearPos + dir * projLen
        local hDist = Vector3.new(myPos.X - closestPt.X, 0, myPos.Z - closestPt.Z).Magnitude
        local speed = math.max(vel.Magnitude, 1); local tArrive = projLen / speed
        local dropY = 0.5 * workspace.Gravity * tArrive * tArrive
        local vDist = math.abs(myPos.Y - (closestPt.Y - dropY))
        return hDist <= State.HIT_RADIUS and vDist <= State.HIT_VERT
    end
    local function ExecuteDodge(spearPart)
        local now = tick()
        if now - State.LastDodge < State.DODGE_COOLDOWN or State.Dodging then return end
        State.LastDodge = now; State.Dodging = true
        task.spawn(function()
            local myChar = Player.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not hum then State.Dodging = false; return end
            local spearVel = (spearPart and spearPart.Parent) and spearPart.AssemblyLinearVelocity or myRoot.CFrame.LookVector * 50
            local flat = Vector3.new(spearVel.X, 0, spearVel.Z)
            if flat.Magnitude < 0.1 then flat = myRoot.CFrame.LookVector end
            flat = flat.Unit
            local perp = Vector3.new(-flat.Z, 0, flat.X)
            if math.random() < 0.5 then perp = -perp end
            local mode = VD.SpearVeilDodgeMode or "Strafe"
            if mode == "Jump" then
                local origJP = hum.JumpPower; hum.JumpPower = 120
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                task.wait(0.2); if hum and hum.Parent then hum.JumpPower = origJP end
            elseif mode == "Crouch" then task.spawn(TriggerCrouch)
            elseif mode == "Teleport" then
                local dist = tonumber(VD.SpearVeilDodgeDistance) or 18
                local target = myRoot.Position + perp * dist
                pcall(function() myRoot.CFrame = CFrame.new(target + Vector3.new(0, 2, 0)) end)
            else
                local origSpeed = hum.WalkSpeed; hum.WalkSpeed = 90
                local t0 = tick()
                while tick() - t0 < 0.28 do
                    if not myRoot.Parent or not hum.Parent then break end
                    myRoot.CFrame = myRoot.CFrame + perp * 2.2
                    task.wait()
                end
                if hum and hum.Parent then hum.WalkSpeed = origSpeed end
            end
            task.wait(0.15); State.Dodging = false
        end)
    end
    local function TrackSpear(spearPart)
        if not spearPart or not spearPart.Parent or State.TrackedSpears[spearPart] then return end
        State.TrackedSpears[spearPart] = true
        local startTick = tick()
        while spearPart.Parent and VD.AutoDodgeSpearVeil do
            if tick() - startTick > State.MAX_TRACK then break end
            if WillHitMe(spearPart) then ExecuteDodge(spearPart); break end
            task.wait(0.015)
        end
        State.TrackedSpears[spearPart] = nil
    end
    local function StartWatcher()
        if State.DescConn then return end
        State.DescConn = Workspace.DescendantAdded:Connect(function(obj)
            if not VD.AutoDodgeSpearVeil then return end
            if IsSpearPart(obj) then task.spawn(function() TrackSpear(obj) end)
            elseif obj:IsA("Model") or obj:IsA("Folder") then
                task.spawn(function()
                    task.wait(0.03); if not obj.Parent then return end
                    for _, d in ipairs(obj:GetDescendants()) do
                        if IsSpearPart(d) then TrackSpear(d) end
                    end
                end)
            end
        end)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if IsSpearPart(obj) then task.spawn(function() TrackSpear(obj) end) end
        end
    end
    local function HookKillerAnimation(kChar)
        if not kChar or State.KillersHooked[kChar] then return end
        State.KillersHooked[kChar] = true
        local hum = kChar:FindFirstChildOfClass("Humanoid"); if not hum then State.KillersHooked[kChar] = nil; return end
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 3)
        if not animator then State.KillersHooked[kChar] = nil; return end
        kChar.AncestryChanged:Connect(function(_, parent) if not parent then State.KillersHooked[kChar] = nil end end)
        animator.AnimationPlayed:Connect(function(track)
            if not VD.AutoDodgeSpearVeil or not track.Animation then return end
            local name = string.lower(track.Animation.Name or "")
            if name:find("spear",1,true) or name:find("throw",1,true) or name:find("veil",1,true) or name:find("lunge",1,true) then
                task.spawn(function()
                    local kRoot = kChar:FindFirstChild("HumanoidRootPart"); if not kRoot then return end
                    local maxRange = tonumber(VD.SpearVeilDetectRange) or 50
                    for _ = 1, 40 do
                        if not VD.AutoDodgeSpearVeil or not kChar.Parent then return end
                        task.wait(0.025)
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if IsSpearPart(obj) and (obj.Position - kRoot.Position).Magnitude < maxRange then TrackSpear(obj); return end
                        end
                    end
                end)
            end
        end)
    end
    local function SetupKiller(p)
        if p == Player or not IsKiller(p) then return end
        if p.Character then HookKillerAnimation(p.Character) end
        p.CharacterAdded:Connect(function(c) task.wait(0.5); HookKillerAnimation(c) end)
    end
    local function HookSpearRemote()
        if State.SpearRemoteHooked then return end
        pcall(function()
            local remotes = GetRemotes()
            local items = remotes and remotes:FindFirstChild("Items")
            local spear = items and items:FindFirstChild("Spear")
            if not spear then return end
            for _, ev in ipairs(spear:GetChildren()) do
                if ev:IsA("RemoteEvent") then
                    pcall(function()
                        ev.OnClientEvent:Connect(function(...)
                            if not VD.AutoDodgeSpearVeil or not VD.SpearVeilUseRemote then return end
                            task.spawn(function()
                                local maxRange = tonumber(VD.SpearVeilDetectRange) or 50
                                for _ = 1, 30 do
                                    if not VD.AutoDodgeSpearVeil then return end
                                    task.wait(0.02)
                                    local myRoot = getRoot(); if not myRoot then return end
                                    for _, obj in ipairs(Workspace:GetDescendants()) do
                                        if IsSpearPart(obj) and (obj.Position - myRoot.Position).Magnitude <= maxRange then TrackSpear(obj); return end
                                    end
                                end
                            end)
                        end)
                    end)
                end
            end
            State.SpearRemoteHooked = true
        end)
    end
    local function HookNamecall()
        if typeof(hookmetamethod) ~= "function" then return end
        pcall(function()
            local mt = getrawmetatable(game); if not mt then return end
            local old = mt.__namecall; if not old then return end
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" and self and self.Name then
                    local n = string.lower(tostring(self.Name))
                    if (n:find("spear",1,true) or n:find("veil",1,true)) and VD.AutoDodgeSpearVeil then
                        task.spawn(function()
                            local maxRange = tonumber(VD.SpearVeilDetectRange) or 50
                            for _ = 1, 30 do
                                if not VD.AutoDodgeSpearVeil then return end
                                task.wait(0.02)
                                local myRoot = getRoot(); if not myRoot then return end
                                for _, obj in ipairs(Workspace:GetDescendants()) do
                                    if IsSpearPart(obj) and (obj.Position - myRoot.Position).Magnitude <= maxRange then TrackSpear(obj); return end
                                end
                            end
                        end)
                    end
                end
                return old(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end
    local function EnsureIndicator()
        if not VD.SpearVeilShowIndicator then
            if State.IndicatorPart and State.IndicatorPart.Parent then State.IndicatorPart:Destroy() end
            State.IndicatorPart = nil; return
        end
        if State.IndicatorPart and State.IndicatorPart.Parent then return end
        local p = Instance.new("Part")
        p.Name = "MawwwSpearVeilRange"; p.Shape = Enum.PartType.Cylinder
        p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
        p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 40, 40)
        p.Transparency = 0.55; p.Size = Vector3.new(0.15, 24, 24); p.Parent = Workspace
        State.IndicatorPart = p
    end
    local function UpdateIndicator()
        if not VD.SpearVeilShowIndicator then EnsureIndicator(); return end
        EnsureIndicator()
        local p = State.IndicatorPart; if not p or not p.Parent then return end
        local myRoot = getRoot(); if not myRoot then p.Transparency = 1; return end
        local r = tonumber(VD.SpearVeilDetectRange) or 50
        local size = math.max(r, 0.5) * 2
        p.Size = Vector3.new(0.15, size, size)
        p.CFrame = CFrame.new(myRoot.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
        p.Transparency = 0.55; p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 40, 40)
    end
    task.spawn(function()
        while not VD.Destroyed do
            task.wait(3)
            if VD.AutoDodgeSpearVeil then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and IsKiller(p) and p.Character then HookKillerAnimation(p.Character) end
                end
                HookSpearRemote()
            end
        end
    end)
    StartWatcher(); HookSpearRemote(); HookNamecall()
    for _, p in ipairs(Players:GetPlayers()) do SetupKiller(p) end
    Players.PlayerAdded:Connect(SetupKiller)
    RunService.RenderStepped:Connect(function() pcall(UpdateIndicator) end)
    return { State = State, HookSpearRemote = HookSpearRemote }
end)()

RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "Auto Dodge Spear Veil")
RegToggle(Tabs.Survival, "Auto Dodge Spear Veil", "Auto dodge incoming spears", false, "AutoDodgeSpearVeil", function(v)
    if v then
        pcall(function() SpearVeil.HookSpearRemote() end)
        notify("Auto Dodge Spear Veil", "AKTIF — Mode: " .. (VD.SpearVeilDodgeMode or "Strafe") .. " | Range: " .. tostring(VD.SpearVeilDetectRange or 50), 3)
    else
        notify("Auto Dodge Spear Veil", "Nonaktif", 2)
    end
end)
RegDropdown(Tabs.Survival, "Spear Veil Dodge Mode", "Dodge style", {"Strafe", "Jump", "Crouch", "Teleport"}, "Strafe", false, "SpearVeilDodgeMode")
RegSlider(Tabs.Survival, "Spear Detect Range (Max 400)", "Detection radius", 50, 4, 400, 1, "SpearVeilDetectRange")
RegSlider(Tabs.Survival, "Spear Dodge Distance", "Teleport distance", 18, 5, 50, 1, "SpearVeilDodgeDistance")
RegToggle(Tabs.Survival, "Use Remote Intercept", "Hook spear remote", true, "SpearVeilUseRemote")
RegToggle(Tabs.Survival, "Show Detect Range Circle", "Show range indicator", false, "SpearVeilShowIndicator")

--========================================================--
-- Pallet Drop
--========================================================--
LastPalletDrop = 0
ActionLock = { lastParry = 0, lastPallet = 0, parryBusy = false }
PalletCache = { List = {}, Timer = 0 }
function GetActiveParryRange()
    if VD.SURV_AutoParry then return tonumber(VD.SURV_ParryDistance) or 8 end
    return 0
end
function GetCachedPalletPoints()
    local now = tick()
    if now - PalletCache.Timer < 3 then return PalletCache.List end
    PalletCache.List = {}; PalletCache.Timer = now
    local map = Workspace:FindFirstChild("Map") or Workspace
    for _, obj in ipairs(map:GetDescendants()) do
        if obj.Name == "Palletwrong" and (obj:IsA("Model") or obj:IsA("Folder")) then
            local t = obj:FindFirstChild("PalletPointSlide") or obj:FindFirstChild("PalletPoint")
            if t and t:IsA("BasePart") then table.insert(PalletCache.List, t) end
        end
    end
    return PalletCache.List
end
function ActivatePalletAction()
    local sm = PlayerGui:FindFirstChild("Survivor-mob")
    local ctrl = sm and sm:FindFirstChild("Controls")
    local btn = ctrl and (ctrl:FindFirstChild("action") or ctrl:FindFirstChild("Action"))
    if btn then
        pcall(function() btn:Activate() end)
        if typeof(firesignal) == "function" then
            pcall(function() firesignal(btn.MouseButton1Down) end)
            task.wait(0.01)
            pcall(function() firesignal(btn.MouseButton1Up) end)
        end
        return true
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return true
end
function FirePalletDropRemote(palletPoint)
    if not palletPoint then return false end
    local fired = false
    pcall(function()
        local remotes = GetRemotes()
        local pallet = remotes and remotes:FindFirstChild("Pallet")
        local dropEvent = pallet and pallet:FindFirstChild("PalletDropEvent")
        if dropEvent then dropEvent:FireServer(palletPoint); fired = true end
    end)
    return fired
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.AutoDropPallet and GetRole() == "Survivor" then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local range = tonumber(VD.AutoDropPalletRange) or 0
            local parryRange = GetActiveParryRange()
            local parryJustFired = (tick() - ActionLock.lastParry) < 0.4
            if root and hum and hum.Health > 0 and range > 0 and not ActionLock.parryBusy and not parryJustFired and (tick() - LastPalletDrop > 1) then
                local kRoot, killerDist = nil, math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player and IsKiller(plr) and plr.Character then
                        local kr = plr.Character:FindFirstChild("HumanoidRootPart")
                        if kr then
                            local d = (kr.Position - root.Position).Magnitude
                            if d < killerDist then killerDist = d; kRoot = kr end
                        end
                    end
                end
                if kRoot and killerDist <= range + 4 then
                    local inParryZone = (parryRange > 0) and (killerDist <= parryRange + 0.5)
                    if not inParryZone then
                        local nearest, nearestDist = nil, math.huge
                        for _, p in ipairs(GetCachedPalletPoints()) do
                            if p.Parent then
                                local d = (p.Position - root.Position).Magnitude
                                if d < nearestDist then nearestDist = d; nearest = p end
                            end
                        end
                        if nearest and nearestDist <= range then
                            FirePalletDropRemote(nearest)
                            task.spawn(ActivatePalletAction)
                            LastPalletDrop = tick(); ActionLock.lastPallet = tick()
                        end
                    end
                end
            end
        end
    end
end)
RegToggle(Tabs.Survival, "Auto Pallet Dropdown", "Drop pallet when killer near", false, "AutoDropPallet")
RegSlider(Tabs.Survival, "Pallet Drop Range", "Drop radius", 0, 0, 30, 1, "AutoDropPalletRange")
RegToggle(Tabs.Survival, "Show Pallet Drop Range", "Show range ring", false, "ShowPalletDropRange")

-- Pallet Range Indicator (Neon Red Ring)
PalletRangeIndicator = { Part = nil, Attachments = {}, Beams = {} }
PALLET_RING_SEGMENTS = 64
PALLET_RING_WIDTH = 0.16
PALLET_RING_TRANSPARENCY = 0.05
PALLET_RING_Y_OFFSET = 0.08
function DestroyPalletRangeIndicator()
    for _, beam in ipairs(PalletRangeIndicator.Beams) do pcall(function() if beam then beam:Destroy() end end) end
    for _, attachment in ipairs(PalletRangeIndicator.Attachments) do pcall(function() if attachment then attachment:Destroy() end end) end
    PalletRangeIndicator.Beams = {}; PalletRangeIndicator.Attachments = {}
    if PalletRangeIndicator.Part then pcall(function() if PalletRangeIndicator.Part.Parent then PalletRangeIndicator.Part:Destroy() end end) end
    PalletRangeIndicator.Part = nil
end
function EnsurePalletRangeIndicator()
    if not VD.ShowPalletDropRange then
        if PalletRangeIndicator.Part then DestroyPalletRangeIndicator() end
        return false
    end
    if PalletRangeIndicator.Part and PalletRangeIndicator.Part.Parent then return true end
    DestroyPalletRangeIndicator()
    local center = Instance.new("Part")
    center.Name = "MawwwPalletRange"; center.Anchored = true; center.CanCollide = false
    center.CanTouch = false; center.CanQuery = false; center.CastShadow = false
    center.Transparency = 1; center.Size = Vector3.new(0.2, 0.2, 0.2); center.Locked = true; center.Parent = Workspace
    local attachments = {}
    for i = 1, PALLET_RING_SEGMENTS do
        local attachment = Instance.new("Attachment")
        attachment.Name = "PalletRangePoint_" .. tostring(i); attachment.Parent = center
        attachments[i] = attachment
    end
    local beams = {}
    local red = ColorSequence.new(Color3.fromRGB(255, 20, 20))
    for i = 1, PALLET_RING_SEGMENTS do
        local nextIndex = (i % PALLET_RING_SEGMENTS) + 1
        local beam = Instance.new("Beam")
        beam.Name = "PalletRangeBeam_" .. tostring(i)
        beam.Attachment0 = attachments[i]; beam.Attachment1 = attachments[nextIndex]
        beam.Color = red; beam.Width0 = PALLET_RING_WIDTH; beam.Width1 = PALLET_RING_WIDTH
        beam.Transparency = NumberSequence.new(PALLET_RING_TRANSPARENCY)
        beam.LightEmission = 1; beam.LightInfluence = 0; beam.FaceCamera = true
        beam.Segments = 1; beam.Enabled = true; beam.Parent = center
        beams[i] = beam
    end
    PalletRangeIndicator.Part = center; PalletRangeIndicator.Attachments = attachments; PalletRangeIndicator.Beams = beams
    return true
end
function UpdatePalletRangeIndicator()
    if not VD.ShowPalletDropRange then
        if PalletRangeIndicator.Part then DestroyPalletRangeIndicator() end
        return
    end
    if not EnsurePalletRangeIndicator() then return end
    local center = PalletRangeIndicator.Part
    if not center or not center.Parent then return end
    local myRoot = getRoot()
    if not myRoot then
        for _, beam in ipairs(PalletRangeIndicator.Beams) do beam.Enabled = false end
        return
    end
    local range = tonumber(VD.AutoDropPalletRange) or 0
    if range <= 0 then
        for _, beam in ipairs(PalletRangeIndicator.Beams) do beam.Enabled = false end
        return
    end
    local radius = math.max(range, 0.5)
    center.CFrame = CFrame.new(myRoot.Position - Vector3.new(0, 2.5, 0))
    for i, attachment in ipairs(PalletRangeIndicator.Attachments) do
        local angle = ((i - 1) / PALLET_RING_SEGMENTS) * (math.pi * 2)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        attachment.Position = Vector3.new(x, PALLET_RING_Y_OFFSET, z)
    end
    for _, beam in ipairs(PalletRangeIndicator.Beams) do
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 20, 20))
        beam.Width0 = PALLET_RING_WIDTH; beam.Width1 = PALLET_RING_WIDTH
        beam.Transparency = NumberSequence.new(PALLET_RING_TRANSPARENCY)
        beam.LightEmission = 1; beam.LightInfluence = 0; beam.FaceCamera = true; beam.Enabled = true
    end
end
RunService.RenderStepped:Connect(function() pcall(UpdatePalletRangeIndicator) end)

--========================================================--
-- Auto Windows Vault
--========================================================--
LastVault = 0
RegToggle(Tabs.Survival, "Auto Windows Vault", "Auto vault windows", false, "AutoWindowsVault")
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.AutoWindowsVault then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and tick() - LastVault > 1 then
                local found = false
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    local n = obj.Name
                    if (obj:IsA("Model") or obj:IsA("BasePart")) and (n == "Window" or string.find(n, "Window") or string.find(n, "window")) then
                        local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                        if (pos - root.Position).Magnitude <= 6 then found = true; break end
                    end
                end
                if found then
                    LastVault = tick()
                    local sm = PlayerGui:FindFirstChild("Survivor-mob")
                    local ctrl = sm and sm:FindFirstChild("Controls")
                    local btn = ctrl and (ctrl:FindFirstChild("action") or ctrl:FindFirstChild("Action"))
                    if btn then
                        pcall(function() btn:Activate() end)
                        if typeof(firesignal) == "function" then pcall(function() firesignal(btn.MouseButton1Down) end) end
                    else
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end)
                    end
                end
            end
        end
    end
end)

--========================================================--
-- Auto Skillcheck
--========================================================--
SC = { busy=false, lastGoal=nil, active=false, lastLine=nil, lastTick=nil, randomMode=nil, randomGoal=nil, instantGoal=nil, instantBusy=false }
AutoSkillcheckRandomPool = {"NORMAL", "PERFECT", "INSTANT"}
BossSC = { checks = {}, lastCleanup = 0, enabled = false }
function SC_Press()
    local pressed = false
    local sm = PlayerGui:FindFirstChild("Survivor-mob")
    local controls = sm and sm:FindFirstChild("Controls")
    local action = controls and controls:FindFirstChild("action")
    if action and action:IsA("GuiButton") and action.Visible then
        pcall(function() action:Activate() pressed = true end)
        if typeof(firesignal) == "function" then
            pcall(function()
                firesignal(action.MouseButton1Down)
                task.wait(0.008)
                firesignal(action.MouseButton1Up)
                pressed = true
            end)
        end
    end
    if not pressed then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.008)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            pressed = true
        end)
    end
    return pressed
end
function SC_Get()
    for _, name in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local gui = PlayerGui:FindFirstChild(name, true)
        if gui then
            local check = gui:FindFirstChild("Check", true)
            if check and check.Visible then
                local line = check:FindFirstChild("Line", true)
                local goal = check:FindFirstChild("Goal", true)
                if line and goal then return line, goal end
            end
        end
    end
end
function SC_GetAll()
    local checks = {}
    for _, name in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local gui = PlayerGui:FindFirstChild(name, true)
        if gui then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc.Name == "Check" and desc.Visible then
                    local line = desc:FindFirstChild("Line", true)
                    local goal = desc:FindFirstChild("Goal", true)
                    if line and goal then
                        table.insert(checks, { key = tostring(desc:GetFullName()), line = line, goal = goal, frame = desc })
                    end
                end
            end
        end
    end
    return checks
end
function SC_Delta(a,b) local d=(b-a)%360; if d>180 then d=d-360 end; return d end
function SC_InZone(r,a,b) r=r%360; a=a%360; b=b%360; if a<=b then return r>=a and r<=b end; return r>=a or r<=b end
function SC_Crossed(prev,now,a,b)
    if SC_InZone(now,a,b) then return true end
    if prev==nil then return false end
    local d=SC_Delta(prev,now)
    local steps=math.max(2,math.min(60,math.ceil(math.abs(d))))
    for i=1,steps do if SC_InZone((prev+d*i/steps)%360,a,b) then return true end end
    return false
end
function SC_Reset() SC.active=false; SC.busy=false; SC.lastGoal=nil; SC.lastLine=nil; SC.lastTick=nil; SC.randomMode=nil; SC.randomGoal=nil; SC.instantGoal=nil; SC.instantBusy=false end
function SC_SelectRandom(gr)
    if SC.randomGoal == nil or math.abs(SC_Delta(SC.randomGoal,gr)) > 5 then
        SC.randomMode = AutoSkillcheckRandomPool[math.random(1,#AutoSkillcheckRandomPool)]
        SC.randomGoal = gr
    end
    return SC.randomMode
end
function SC_Normal(line,goal,lr,gr,now)
    if not SC.active then SC.active=true; SC.lastGoal=gr; SC.lastLine=lr; SC.lastTick=now; return end
    if SC.lastGoal and math.abs(SC_Delta(SC.lastGoal,gr))>5 then SC.lastGoal=gr; SC.lastLine=nil; SC.lastTick=nil; SC.busy=false; return end
    SC.lastGoal=gr
    if SC.busy then SC.lastLine=lr; SC.lastTick=now; return end
    if SC.lastLine and SC.lastTick then
        if SC_Crossed(SC.lastLine,lr,gr+104,gr+109) then
            SC.busy=true
            task.spawn(function() task.wait(0.025); SC_Press(); task.delay(0.08,function() SC.busy=false end) end)
        end
    end
    SC.lastLine=lr; SC.lastTick=now
end
function SC_Perfect(line,goal,lr,gr,now)
    if not SC.active then SC.active=true; SC.lastGoal=gr; SC.lastLine=lr; SC.lastTick=now; return end
    if SC.lastGoal and math.abs(SC_Delta(SC.lastGoal,gr))>5 then SC.lastGoal=gr; SC.lastLine=nil; SC.lastTick=nil; SC.busy=false; return end
    SC.lastGoal=gr
    if SC.busy then SC.lastLine=lr; SC.lastTick=now; return end
    if SC.lastLine and SC.lastTick then
        if SC_Crossed(SC.lastLine,lr,gr+104,gr+108) then
            SC.busy=true; SC_Press(); task.delay(0.08,function() SC.busy=false end)
        end
    end
    SC.lastLine=lr; SC.lastTick=now
end
function SC_Instant(line,goal,lr,gr)
    if SC.instantGoal and math.abs(SC_Delta(SC.instantGoal,gr))<=5 then return end
    if SC.instantBusy then return end
    SC.instantGoal=gr; SC.instantBusy=true
    pcall(function() line.Rotation=goal.Rotation+109 end)
    task.spawn(function() SC_Press(); task.wait(0.18); SC.instantBusy=false end)
end
function BossSC_ProcessCheck(check, mode)
    local key, line, goal = check.key, check.line, check.goal
    if not BossSC.checks[key] then BossSC.checks[key] = { lastLine = nil, lastTick = nil, busy = false, goalSnapshot = nil } end
    local st = BossSC.checks[key]
    local lr = (tonumber(line.Rotation) or 0) % 360
    local gr = (tonumber(goal.Rotation) or 0) % 360
    if st.goalSnapshot and math.abs(SC_Delta(st.goalSnapshot, gr)) > 5 then st.lastLine, st.lastTick, st.busy, st.goalSnapshot = nil, nil, false, gr; return end
    st.goalSnapshot = gr
    if st.busy then st.lastLine = lr; st.lastTick = os.clock(); return end
    local effectiveMode = (mode == "RANDOM") and "PERFECT" or mode
    if effectiveMode == "INSTANT" then
        if st.lastLine and st.lastTick and SC_Crossed(st.lastLine, lr, gr + 104, gr + 108) then
            st.busy = true
            pcall(function() line.Rotation = goal.Rotation + 109 end)
            task.spawn(function() SC_Press(); task.wait(0.18); if BossSC.checks[key] then BossSC.checks[key].busy = false end end)
        end
        st.lastLine = lr; st.lastTick = os.clock(); return
    end
    local zoneStart = gr + 104
    local zoneEnd = (effectiveMode == "PERFECT") and (gr + 108) or (gr + 109)
    if st.lastLine and st.lastTick and SC_Crossed(st.lastLine, lr, zoneStart, zoneEnd) then
        st.busy = true; SC_Press()
        task.delay(0.08, function() if BossSC.checks[key] then BossSC.checks[key].busy = false end end)
    end
    st.lastLine = lr; st.lastTick = os.clock()
end
function BossSC_Cleanup(activeKeys)
    local now = os.clock()
    if now - BossSC.lastCleanup < 0.5 then return end
    BossSC.lastCleanup = now
    for key, _ in pairs(BossSC.checks) do if not activeKeys[key] then BossSC.checks[key] = nil end end
end
function BossSC_ResetAll() BossSC.checks = {} end
RunService.RenderStepped:Connect(function()
    if VD.AutoSkillcheck then
        local line, goal = SC_Get()
        if line and goal then
            local lr = (tonumber(line.Rotation) or 0) % 360
            local gr = (tonumber(goal.Rotation) or 0) % 360
            local mode = VD.AutoSkillcheckMode
            if mode == "RANDOM" then mode = SC_SelectRandom(gr) end
            if mode == "INSTANT" then SC_Instant(line, goal, lr, gr)
            elseif mode == "PERFECT" then SC_Perfect(line, goal, lr, gr, os.clock())
            else SC_Normal(line, goal, lr, gr, os.clock()) end
        else SC_Reset() end
    end
    if VD.AutoSkillcheckBossGen and VD.AutoSkillcheck then
        local allChecks = SC_GetAll()
        if #allChecks > 0 then
            local activeKeys = {}
            for _, check in ipairs(allChecks) do
                activeKeys[check.key] = true
                pcall(BossSC_ProcessCheck, check, VD.AutoSkillcheckMode)
            end
            BossSC_Cleanup(activeKeys)
        else BossSC_ResetAll() end
    elseif not VD.AutoSkillcheckBossGen then BossSC_ResetAll() end
end)
RegToggle(Tabs.Survival, "Auto Skillcheck", "Auto press skillcheck", false, "AutoSkillcheck")
RegDropdown(Tabs.Survival, "Skillcheck Mode", "Press mode", {"NORMAL", "PERFECT", "INSTANT", "RANDOM"}, "NORMAL", false, "AutoSkillcheckMode")
RegToggle(Tabs.Survival, "Boss Gen / Kings Scourge", "Multi skillcheck support", false, "AutoSkillcheckBossGen")

--========================================================--
-- Invisible Mode
--========================================================--
InvisibleState = { Active = false, PartData = {}, DecalData = {}, EffectData = {}, Humanoid = nil, OriginalHumDDT = nil, RenderConn = nil, DescConn = nil, CharConn = nil, LastFullScan = 0, ExtraWorkspaceParts = {}, WorkspaceScanTick = 0 }
function Inv_Snapshot(d)
    if not d or not d.Parent then return end
    if d:IsA("BasePart") then
        if InvisibleState.PartData[d] == nil then InvisibleState.PartData[d] = { Transparency = d.Transparency, LocalTransparencyModifier= d.LocalTransparencyModifier, CanCollide = d.CanCollide } end
        d.Transparency = 1; d.LocalTransparencyModifier = 1; d.CanCollide = false
    elseif d:IsA("Decal") or d:IsA("Texture") then
        if InvisibleState.DecalData[d] == nil then InvisibleState.DecalData[d] = { Transparency = d.Transparency } end
        d.Transparency = 1
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
        if InvisibleState.EffectData[d] == nil then InvisibleState.EffectData[d] = { Enabled = d.Enabled } end
        d.Enabled = false
    elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Gui3d") then
        if InvisibleState.EffectData[d] == nil then InvisibleState.EffectData[d] = { Enabled = d.Enabled } end
        d.Enabled = false
    end
end
function Inv_ScanAll()
    local char = Player.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do Inv_Snapshot(d) end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum ~= InvisibleState.Humanoid then
            InvisibleState.Humanoid = hum
            InvisibleState.OriginalHumDDT = hum.DisplayDistanceType
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end
    local mirror = Workspace:FindFirstChild(Player.Name)
    if mirror then
        for _, d in ipairs(mirror:GetDescendants()) do
            Inv_Snapshot(d)
            if d:IsA("BasePart") and not InvisibleState.ExtraWorkspaceParts[d] then InvisibleState.ExtraWorkspaceParts[d] = true end
        end
    end
end
function Inv_RestoreAll()
    for p, data in pairs(InvisibleState.PartData) do
        if p and p.Parent then pcall(function() p.Transparency = data.Transparency; p.LocalTransparencyModifier = data.LocalTransparencyModifier; p.CanCollide = data.CanCollide end) end
    end
    for d, data in pairs(InvisibleState.DecalData) do if d and d.Parent then pcall(function() d.Transparency = data.Transparency end) end end
    for e, data in pairs(InvisibleState.EffectData) do if e and e.Parent then pcall(function() e.Enabled = data.Enabled end) end end
    if InvisibleState.Humanoid and InvisibleState.Humanoid.Parent and InvisibleState.OriginalHumDDT ~= nil then pcall(function() InvisibleState.Humanoid.DisplayDistanceType = InvisibleState.OriginalHumDDT end) end
    InvisibleState.PartData = {}; InvisibleState.DecalData = {}; InvisibleState.EffectData = {}
    InvisibleState.Humanoid = nil; InvisibleState.OriginalHumDDT = nil
    InvisibleState.ExtraWorkspaceParts = {}
end
function Inv_Enforce()
    for p, _ in pairs(InvisibleState.PartData) do
        if p and p.Parent then
            if p.Transparency ~= 1 then p.Transparency = 1 end
            if p.LocalTransparencyModifier ~= 1 then p.LocalTransparencyModifier = 1 end
            if p.CanCollide then p.CanCollide = false end
        end
    end
    for d, _ in pairs(InvisibleState.DecalData) do if d and d.Parent and d.Transparency ~= 1 then d.Transparency = 1 end end
    for e, _ in pairs(InvisibleState.EffectData) do if e and e.Parent and e.Enabled then e.Enabled = false end end
    local mirror = Workspace:FindFirstChild(Player.Name)
    if mirror then
        for _, d in ipairs(mirror:GetDescendants()) do
            if d:IsA("BasePart") then
                if d.Transparency ~= 1 then d.Transparency = 1 end
                if d.LocalTransparencyModifier ~= 1 then d.LocalTransparencyModifier = 1 end
                if d.CanCollide then d.CanCollide = false end
            elseif d:IsA("Decal") and d.Transparency ~= 1 then d.Transparency = 1 end
        end
    end
end
function Inv_BindDescendants()
    if InvisibleState.DescConn then pcall(function() InvisibleState.DescConn:Disconnect() end); InvisibleState.DescConn = nil end
    local char = Player.Character; if not char then return end
    InvisibleState.DescConn = char.DescendantAdded:Connect(function(d)
        if not InvisibleState.Active then return end
        task.defer(function() if InvisibleState.Active then Inv_Snapshot(d) end end)
    end)
end
function Inv_Start()
    if InvisibleState.Active then return end
    InvisibleState.Active = true
    InvisibleState.PartData = {}; InvisibleState.DecalData = {}; InvisibleState.EffectData = {}
    InvisibleState.Humanoid = nil; InvisibleState.OriginalHumDDT = nil
    InvisibleState.LastFullScan = 0; InvisibleState.ExtraWorkspaceParts = {}; InvisibleState.WorkspaceScanTick = 0
    Inv_ScanAll(); Inv_BindDescendants()
    if InvisibleState.RenderConn then pcall(function() InvisibleState.RenderConn:Disconnect() end) end
    InvisibleState.RenderConn = RunService.RenderStepped:Connect(function()
        if not InvisibleState.Active then return end
        Inv_Enforce()
        local now = tick()
        if now - InvisibleState.LastFullScan > 0.4 then InvisibleState.LastFullScan = now; Inv_ScanAll() end
    end)
    if not InvisibleState.CharConn then
        InvisibleState.CharConn = Player.CharacterAdded:Connect(function(newChar)
            task.wait(0.4); if not InvisibleState.Active then return end
            InvisibleState.PartData = {}; InvisibleState.DecalData = {}; InvisibleState.EffectData = {}
            InvisibleState.Humanoid = nil; InvisibleState.OriginalHumDDT = nil
            InvisibleState.ExtraWorkspaceParts = {}
            Inv_ScanAll(); Inv_BindDescendants()
        end)
    end
end
function Inv_Stop()
    if not InvisibleState.Active then return end
    InvisibleState.Active = false
    if InvisibleState.RenderConn then pcall(function() InvisibleState.RenderConn:Disconnect() end); InvisibleState.RenderConn = nil end
    if InvisibleState.DescConn then pcall(function() InvisibleState.DescConn:Disconnect() end); InvisibleState.DescConn = nil end
    Inv_RestoreAll()
end
RegToggle(Tabs.Visual, "Invisible Mode (Full Hidden)", "Fully hide your character", false, "Invisible", function(v)
    if v then Inv_Start(); notify("Invisible", "ON — kamu tidak terlihat oleh player lain.", 3)
    else Inv_Stop(); notify("Invisible", "OFF — visibilitas dikembalikan normal.", 3) end
end)

--========================================================--
-- AUTO PARRY V1
--========================================================--
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "Auto Parry V1 (Anti-Fake Hit)")

AutoParryModule = (function()
    local NEON_BLUE = Color3.fromRGB(0, 180, 255)
    local Ring = { Folder = nil, Dashes = {}, RotCFs = {}, Offsets = {}, Radius = 0, LastX = math.huge, LastY = math.huge, LastZ = math.huge, LastAlpha = -1, Visible = false }
    local function DestroyRing()
        if Ring.Folder then pcall(function() if Ring.Folder and Ring.Folder.Parent then Ring.Folder:Destroy() end end) end
        Ring.Folder = nil; Ring.Dashes = {}; Ring.RotCFs = {}; Ring.Offsets = {}
        Ring.Radius = 0; Ring.LastX = math.huge; Ring.LastY = math.huge; Ring.LastZ = math.huge
        Ring.LastAlpha = -1; Ring.Visible = false
    end
    local function BuildRing(radius)
        DestroyRing()
        if not radius or radius <= 0 then return end
        local folder = Instance.new("Folder"); folder.Name = "MawwwParryV1Ring"
        local dashCount = math.clamp(math.floor(radius * 8), 36, 160)
        local slotLength = (2 * math.pi * radius) / dashCount
        local dashLength = slotLength * 0.62; local dashThickness = 0.08
        local dashes = table.create(dashCount); local rotCFs = table.create(dashCount); local offsets = table.create(dashCount)
        for i = 1, dashCount do
            local part = Instance.new("Part")
            part.Name = "Dash" .. i; part.Anchored = true; part.CanCollide = false
            part.CanTouch = false; part.CanQuery = false; part.CastShadow = false
            part.Material = Enum.Material.Neon; part.Color = NEON_BLUE
            part.Transparency = 0.15; part.Size = Vector3.new(dashThickness, dashThickness, dashLength)
            part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
            part.Parent = folder
            local angle = ((i - 1) / dashCount) * math.pi * 2
            local cosA = math.cos(angle); local sinA = math.sin(angle)
            local tangent = Vector3.new(-sinA, 0, cosA)
            rotCFs[i] = CFrame.lookAt(Vector3.zero, tangent)
            offsets[i] = Vector3.new(cosA * radius, 0, sinA * radius)
            dashes[i] = part
        end
        folder.Parent = Workspace
        Ring.Folder = folder; Ring.Dashes = dashes; Ring.RotCFs = rotCFs; Ring.Offsets = offsets
        Ring.Radius = radius; Ring.Visible = true
    end
    local function UpdateRing(myRoot)
        if not Ring.Folder or not Ring.Folder.Parent or not myRoot then return end
        local dashes = Ring.Dashes; local dashCount = #dashes
        if dashCount == 0 then return end
        local center = myRoot.Position - Vector3.new(0, (myRoot.Size.Y * 0.5) + 0.12, 0)
        local pulse = (math.sin(tick() * 3.0) + 1) * 0.5
        local alpha = 0.05 + (1 - pulse) * 0.20
        local dx = math.abs(center.X - Ring.LastX); local dy = math.abs(center.Y - Ring.LastY); local dz = math.abs(center.Z - Ring.LastZ)
        local dA = math.abs(alpha - Ring.LastAlpha)
        if dx < 0.02 and dy < 0.02 and dz < 0.02 and dA < 0.005 then return end
        Ring.LastX = center.X; Ring.LastY = center.Y; Ring.LastZ = center.Z; Ring.LastAlpha = alpha
        local rotCFs = Ring.RotCFs; local offsets = Ring.Offsets
        for i = 1, dashCount do
            local dash = dashes[i]
            if dash and dash.Parent then
                local off = offsets[i]
                local worldPos = Vector3.new(center.X + off.X, center.Y, center.Z + off.Z)
                dash.CFrame = rotCFs[i] + worldPos; dash.Color = NEON_BLUE
                dash.Transparency = alpha; dash.Material = Enum.Material.Neon; dash.CanCollide = false
            end
        end
    end
    local function SetParryVisual(visible, radius)
        if not visible then
            if Ring.Folder then for _, d in ipairs(Ring.Dashes) do if d and d.Parent then d.Transparency = 1 end end end
            return
        end
        if Ring.Radius ~= (radius or 8) or not Ring.Folder or not Ring.Folder.Parent then BuildRing(radius or 8) end
    end
    local function VD_UpdateParryRange()
        if not VD.SURV_ShowParryCircle then
            if Ring.Folder then for _, d in ipairs(Ring.Dashes) do if d and d.Parent then d.Transparency = 1 end end end
            return
        end
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local radius = tonumber(VD.SURV_ParryDistance) or 8
        if not Ring.Folder or Ring.Radius ~= radius then BuildRing(radius) end
        UpdateRing(root)
    end
    local State = { ParryCooldown = false, CooldownThread = nil, CooldownEnd = 0, CooldownDuration = 60, LastParryTime = 0, PendingTarget = nil, PendingTimestamp = 0, FakeSuspects = {}, ParryOK = 0, ParryFail = 0, FakeBlocked = 0 }
    local Attached = setmetatable({}, { __mode = "k" })
    local VD_ATTACK_ANIMS = {
        ["rbxassetid://113255068724446"]=true, ["rbxassetid://74968262036854"]=true, ["rbxassetid://110355011987939"]=true,
        ["rbxassetid://139369275981139"]=true, ["rbxassetid://132817836308238"]=true, ["rbxassetid://129784271201071"]=true,
        ["rbxassetid://133963973694098"]=true, ["rbxassetid://117042998468241"]=true, ["rbxassetid://105374834496520"]=true,
        ["rbxassetid://111920872708571"]=true, ["rbxassetid://78432063483146"]=true, ["rbxassetid://118907603246885"]=true,
        ["rbxassetid://138720291317243"]=true, ["rbxassetid://115244153053858"]=true, ["rbxassetid://130593238885843"]=true,
        ["rbxassetid://122812055447896"]=true, ["rbxassetid://78935059863801"]=true, ["rbxassetid://135002183282873"]=true,
        ["rbxassetid://121216847022485"]=true,
    }
    local function IsAttackAnimId(animId) if not animId then return false end; return VD_ATTACK_ANIMS[animId] == true end
    local function IsSafeToParry(char)
        if not char then return false end
        local state = char:GetAttribute("State")
        if state == "Downed" or state == "Dead" then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return false end
        return true
    end
    local function IsDownedKiller(kChar)
        if not kChar then return false end
        local st = kChar:GetAttribute("State")
        if st == "Downed" or st == "Dead" then return true end
        local kh = kChar:FindFirstChildOfClass("Humanoid")
        if kh and kh.Health <= 0 then return true end
        return false
    end
    local function WallCheck(originPos, targetPos, targetChar)
        if not VD.PARRY_V1_WallCheck then return true end
        return VD_WallCheckVisible(originPos, targetPos, targetChar)
    end
    local function IsFakeSuspect(plr)
        if not VD.PARRY_V1_AntiFake then return false end
        local exp = State.FakeSuspects[plr]
        if not exp then return false end
        if tick() >= exp then State.FakeSuspects[plr] = nil; return false end
        return true
    end
    local function FlagFakeSuspect(plr, dur)
        if not VD.PARRY_V1_AntiFake or not plr then return end
        dur = tonumber(dur) or tonumber(VD.PARRY_V1_FakeWindow) or 3
        State.FakeSuspects[plr] = tick() + dur
    end
    local function IsKillerStillAttacking(kChar)
        if not kChar then return false end
        local hum = kChar:FindFirstChildOfClass("Humanoid")
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if not anim then return false end
        for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
            local id = t.Animation and t.Animation.AnimationId
            if IsAttackAnimId(id) then return true end
        end
        return false
    end
    local function ValidateAttack(kChar, kHRP, myHRP)
        if not VD.PARRY_V1_AntiFake then return true end
        local dist = (myHRP.Position - kHRP.Position).Magnitude
        local maxValid = (tonumber(VD.SURV_ParryDistance) or 8) + 3
        if dist > maxValid then return false, "far" end
        local toMe = (myHRP.Position - kHRP.Position)
        local flatTo = Vector3.new(toMe.X, 0, toMe.Z)
        local kLook = kHRP.CFrame.LookVector
        local flatLook = Vector3.new(kLook.X, 0, kLook.Z)
        if flatTo.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
            local dot = flatLook.Unit:Dot(flatTo.Unit)
            local minFacing = tonumber(VD.PARRY_V1_MinFacing) or 0.35
            if dot < minFacing then return false, "facing" end
        end
        local kv = kHRP.AssemblyLinearVelocity.Magnitude
        local minV = tonumber(VD.PARRY_V1_MinVelocity) or 2
        local minDist = tonumber(VD.PARRY_V1_FakeDistance) or 2.5
        if kv < minV and dist > minDist then return false, "static" end
        return true
    end
    local function ExecuteParry(targetPlr)
        if State.ParryCooldown or ActionLock.parryBusy then return end
        ActionLock.parryBusy = true; ActionLock.lastParry = tick()
        State.LastParryTime = tick(); State.PendingTarget = targetPlr; State.PendingTimestamp= tick()
        pcall(function()
            local remotes = GetRemotes()
            local items = remotes and remotes:FindFirstChild("Items")
            local dagger = items and items:FindFirstChild("Parrying Dagger")
            local parry = dagger and dagger:FindFirstChild("parry")
            if parry and parry:IsA("RemoteEvent") then parry:FireServer() end
            local sm = PlayerGui:FindFirstChild("Survivor-mob")
            local ctrl = sm and sm:FindFirstChild("Controls")
            local btn = ctrl and ctrl:FindFirstChild("Gui-mob")
            if btn and btn.Visible and typeof(firesignal) == "function" then
                pcall(function() firesignal(btn.MouseButton1Down); firesignal(btn.MouseButton1Up) end)
            end
        end)
        task.delay(0.25, function() ActionLock.parryBusy = false end)
    end
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        local items = remotes and remotes:WaitForChild("Items", 5)
        local dagger = items and items:WaitForChild("Parrying Dagger", 5)
        local prRes = dagger and dagger:WaitForChild("parryResult", 5)
        if not prRes then return end
        prRes.OnClientEvent:Connect(function(success, duration)
            local cdDur = tonumber(duration) or (success and 90 or 60)
            if State.CooldownThread then pcall(task.cancel, State.CooldownThread) end
            State.ParryCooldown = true; State.CooldownEnd = tick() + cdDur; State.CooldownDuration = cdDur
            State.CooldownThread = task.delay(cdDur, function() State.ParryCooldown = false end)
            if VD.PARRY_V1_AntiFake and not success then
                local target = State.PendingTarget
                local elapsed = tick() - (State.PendingTimestamp or 0)
                if target and elapsed < 1.5 then
                    local kChar = target.Character
                    if kChar and not IsKillerStillAttacking(kChar) then
                        FlagFakeSuspect(target); State.FakeBlocked = State.FakeBlocked + 1
                    end
                end
                State.ParryFail = State.ParryFail + 1
            elseif success then State.ParryOK = State.ParryOK + 1 end
            State.PendingTarget = nil
        end)
    end)
    local function HandleAttackAttempt(plr, kChar)
        if not VD.AutoParryV1 or not VD.SURV_AutoParry then return end
        if State.ParryCooldown or not plr or plr == Player then return end
        if VD.PARRY_V1_IgnoreDown and IsDownedKiller(kChar) then return end
        if IsFakeSuspect(plr) or isDowned() or not IsSafeToParry(Player.Character) then return end
        local myChar = Player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local kHRP = kChar and kChar:FindFirstChild("HumanoidRootPart")
        if not myHRP or not kHRP then return end
        if VD.PARRY_V1_WallCheck and not WallCheck(myHRP.Position, kHRP.Position, kChar) then return end
        local ok, reason = ValidateAttack(kChar, kHRP, myHRP)
        if not ok then
            if reason == "facing" or reason == "far" then FlagFakeSuspect(plr, 1.5) end
            return
        end
        local distTrigger = tonumber(VD.SURV_ParryDistance) or 8
        local startDistance = (myHRP.Position - kHRP.Position).Magnitude
        if VD.SURV_ParryAggressive then
            local aggressiveRadius = 12; local detectRadius = distTrigger + 5
            if startDistance > detectRadius then return end
            if startDistance <= aggressiveRadius then ExecuteParry(plr)
            else
                local tracker; local startTime = os.clock()
                tracker = RunService.Heartbeat:Connect(function()
                    if os.clock() - startTime >= 1.5 or State.ParryCooldown or not myHRP.Parent or not kHRP.Parent or isDowned() then
                        if tracker then tracker:Disconnect() end; return
                    end
                    if (myHRP.Position - kHRP.Position).Magnitude <= aggressiveRadius then
                        ExecuteParry(plr); if tracker then tracker:Disconnect() end
                    end
                end)
            end
        else
            if startDistance > distTrigger then return end
            local flatDelta = Vector3.new(myHRP.Position.X - kHRP.Position.X, 0, myHRP.Position.Z - kHRP.Position.Z)
            if flatDelta.Magnitude > 0.1 then
                local dir = flatDelta.Unit
                local kLookFlat = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z)
                if kLookFlat.Magnitude > 0.1 and kLookFlat.Unit:Dot(dir) < 0.6 then FlagFakeSuspect(plr, 1.5); return end
            end
            ExecuteParry(plr)
        end
    end
    local function AttachParrySensor(kChar, plr)
        if not kChar or Attached[kChar] then return end
        Attached[kChar] = true
        local humanoid = kChar:FindFirstChildOfClass("Humanoid") or kChar:WaitForChild("Humanoid", 5)
        if not humanoid then Attached[kChar] = nil; return end
        local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
        if not animator then Attached[kChar] = nil; return end
        kChar.AncestryChanged:Connect(function(_, parent) if not parent then Attached[kChar] = nil end end)
        animator.AnimationPlayed:Connect(function(track)
            local animId = track.Animation and track.Animation.AnimationId or ""
            if IsAttackAnimId(animId) then HandleAttackAttempt(plr, kChar) end
        end)
    end
    local function TryAttachParry(p) if p ~= Player and IsKiller(p) and p.Character then AttachParrySensor(p.Character, p) end end
    local function SetupParryPlayer(p)
        if p == Player then return end
        p.CharacterAdded:Connect(function() TryAttachParry(p) end)
        if p.Character then TryAttachParry(p) end
    end
    for _, p in pairs(Players:GetPlayers()) do SetupParryPlayer(p) end
    Players.PlayerAdded:Connect(SetupParryPlayer)
    task.spawn(function()
        while not VD.Destroyed do task.wait(5); for _, p in pairs(Players:GetPlayers()) do TryAttachParry(p) end end
    end)
    local function EnsureParryRender()
        if VD.SURV_AutoParry or VD.SURV_ShowParryCircle then
            if not getgenv().VD_ParryRenderConnection then
                getgenv().VD_ParryRenderConnection = RunService.RenderStepped:Connect(function() pcall(VD_UpdateParryRange) end)
            end
        else
            if getgenv().VD_ParryRenderConnection then pcall(function() getgenv().VD_ParryRenderConnection:Disconnect() end); getgenv().VD_ParryRenderConnection = nil end
            if Ring.Folder then for _, d in ipairs(Ring.Dashes) do if d and d.Parent then d.Transparency = 1 end end end
        end
    end
    return {
        VD_UpdateParryRange = VD_UpdateParryRange, Ring = Ring, DestroyRing = DestroyRing,
        EnsureParryRender = EnsureParryRender, SetParryVisual = SetParryVisual, State = State,
        SetAutoParry = function(state) VD.SURV_AutoParry = state == true; VD.AutoParryV1 = state == true; EnsureParryRender() end,
    }
end)()
function VD_SetAutoParry(state) AutoParryModule.SetAutoParry(state) end
function VD_EnsureParryRender() AutoParryModule.EnsureParryRender() end

RegToggle(Tabs.Survival, "Auto Parry V1 (Anti-Fake Hit)", "Auto parry with fake hit detection", false, "AutoParryV1", function(v)
    VD.AutoParryV1 = v; VD_SetAutoParry(v)
    if v then notify("Auto Parry V1", "AKTIF! " .. (VD.SURV_ParryAggressive and "Aggressive" or "Normal") .. " | Anti-Fake: " .. (VD.PARRY_V1_AntiFake and "ON" or "OFF"), 3)
    else notify("Auto Parry V1", "Nonaktif", 2) end
end)
RegToggle(Tabs.Survival, "V1 Aggressive Mode (Predict)", "Predictive parry", false, "SURV_ParryAggressive")
RegToggle(Tabs.Survival, "V1 Wall Check", "Require line of sight", false, "PARRY_V1_WallCheck")
RegToggle(Tabs.Survival, "V1 Ignore Downed Killer", "Skip downed killers", true, "PARRY_V1_IgnoreDown")
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "Anti Fake Hit V1")
RegToggle(Tabs.Survival, "Enable Anti Fake Hit (V1)", "Detect fake attacks", true, "PARRY_V1_AntiFake")
RegSlider(Tabs.Survival, "Fake Suspect Window (s)", "Suspect duration", 3, 1, 10, 1, "PARRY_V1_FakeWindow")
RegSlider(Tabs.Survival, "Min Fake Distance (studs)", "Min distance for fake", 2.5, 0.5, 10, 0.5, "PARRY_V1_FakeDistance")
RegSlider(Tabs.Survival, "Min Facing Dot (0-1)", "Min facing dot", 0.35, 0, 1, 0.05, "PARRY_V1_MinFacing")
RegSlider(Tabs.Survival, "Min Killer Velocity", "Min velocity", 2, 0, 20, 1, "PARRY_V1_MinVelocity")
RegSlider(Tabs.Survival, "V1 Parry Distance Trigger", "Trigger distance", 8, 2, 25, 1, "SURV_ParryDistance", function(v)
    VD.SURV_ParryDistance = v
    if AutoParryModule and AutoParryModule.SetParryVisual then pcall(AutoParryModule.SetParryVisual, VD.SURV_ShowParryCircle, v) end
end)
RegToggle(Tabs.Survival, "V1 Show Parry Range (Neon Blue Ring)", "Show range circle", false, "SURV_ShowParryCircle", function(v)
    VD.SURV_ShowParryCircle = v; VD_EnsureParryRender()
    if v then
        pcall(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then AutoParryModule.VD_UpdateParryRange() end
        end)
        notify("Parry Range V1", "Ring NEON BIRU ditampilkan!", 2)
    else
        if AutoParryModule and AutoParryModule.Ring then
            for _, d in ipairs(AutoParryModule.Ring.Dashes) do if d and d.Parent then d.Transparency = 1 end end
        end
        notify("Parry Range V1", "Ring disembunyikan", 2)
    end
end)

--========================================================--
-- AUTO PARRY V2
--========================================================--
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "Auto Parry V2 (Advanced)")

ParryV2 = (function()
    local LocalPlayer = Player
    local NEON_PURPLE_V2 = Color3.fromRGB(180, 60, 255)
    local State = { LastParry = 0, ActiveAttackers = {}, CircleFolder = nil, CircleDashes = {}, CircleRotCFs = {}, CircleOffsets = {}, CircleRadius = 0, CircleBuiltForDagger = false, CircleLastX = math.huge, CircleLastY = math.huge, CircleLastZ = math.huge, CircleLastAlpha = -1, CircleLastR = -1, CircleLastG = -1, CircleLastB = -1 }
    local Cooldown = { OnCooldown = false, CooldownEnd = 0, CooldownDuration = 0, WaitingForResult = false, WaitingStart = 0, WaitTimeout = 2.0, FallbackCooldown = 60, MaxCooldown = 90, FailureCooldown = 1.5, TimeoutCooldown = 0.5, LastFiredAt = 0, IsSilenced = false, JustFired = false, ManualDetect = false, ManualIgnoreWindow = 0.35 }
    local parryResultRemote, parryFireRemote
    pcall(function()
        local remotes = GetRemotes()
        if remotes then
            local items = remotes:FindFirstChild("Items")
            if items then
                local dagger = items:FindFirstChild("Parrying Dagger")
                if dagger then
                    parryResultRemote = dagger:FindFirstChild("parryResult")
                    parryFireRemote = dagger:FindFirstChild("parry")
                end
            end
        end
    end)
    local KillerAttackAnims = {
        ["78432063483146"]="attack", ["121216847022485"]="attack", ["74968262036854"]="attack",
        ["132817836308238"]="attack", ["82666958311998"]="attack", ["111920872708571"]="attack",
        ["106871536134254"]="attack", ["109402730355822"]="attack", ["130593238885843"]="attack",
        ["138720291317243"]="attack", ["139369275981139"]="attack", ["133963973694098"]="attack",
        ["78935059863801"]="attack", ["118907603246885"]="lungehold", ["135002183282873"]="lungehold",
        ["113255068724446"]="lungehold", ["129784271201071"]="lungehold", ["105374834496520"]="lungehold",
        ["117070354890871"]="lungehold", ["115244153053858"]="lungehold", ["110355011987939"]="lungehold",
        ["117042998468241"]="lungehold", ["122812055447896"]="lungehold",
    }
    local function StartCooldown(duration)
        duration = math.clamp(tonumber(duration) or 0, 0, Cooldown.MaxCooldown)
        if duration <= 0 then duration = Cooldown.TimeoutCooldown end
        Cooldown.OnCooldown = true; Cooldown.CooldownDuration = duration
        Cooldown.CooldownEnd = os.clock() + duration; Cooldown.WaitingForResult = false
        Cooldown.JustFired = false; Cooldown.ManualDetect = false
    end
    local function ClearCooldown()
        Cooldown.OnCooldown = false; Cooldown.CooldownEnd = 0; Cooldown.CooldownDuration = 0
        Cooldown.WaitingForResult = false; Cooldown.JustFired = false; Cooldown.ManualDetect = false
    end
    local function IsOnCooldown()
        if not Cooldown.OnCooldown then return false end
        if os.clock() >= Cooldown.CooldownEnd then ClearCooldown(); return false end
        return true
    end
    if parryResultRemote then
        parryResultRemote.OnClientEvent:Connect(function(success, cooldown)
            if not Cooldown.WaitingForResult and not Cooldown.JustFired then return end
            local cd = tonumber(cooldown) or 0
            if cd > 0 then StartCooldown(math.min(cd, Cooldown.MaxCooldown))
            elseif success then StartCooldown(Cooldown.FallbackCooldown)
            else StartCooldown(Cooldown.FailureCooldown) end
        end)
    end
    local function HookSilenced(char)
        if not char then return end
        Cooldown.IsSilenced = CollectionService:HasTag(char, "Silenced")
    end
    CollectionService:GetInstanceAddedSignal("Silenced"):Connect(function(inst) if inst == LocalPlayer.Character then Cooldown.IsSilenced = true end end)
    CollectionService:GetInstanceRemovedSignal("Silenced"):Connect(function(inst) if inst == LocalPlayer.Character then Cooldown.IsSilenced = false end end)
    LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); HookSilenced(char) end)
    if LocalPlayer.Character then HookSilenced(LocalPlayer.Character) end
    local CharCache = { Char = nil, Root = nil, Hum = nil, UpperTorso = nil, CheckInt = nil }
    local function GetCharCache()
        local char = LocalPlayer.Character
        if char ~= CharCache.Char then
            CharCache.Char = char; CharCache.Root = nil; CharCache.Hum = nil
            CharCache.UpperTorso = nil; CharCache.CheckInt = nil
        end
        if not char then return CharCache end
        if not CharCache.Root then CharCache.Root = char:FindFirstChild("HumanoidRootPart") end
        if not CharCache.Hum then CharCache.Hum = char:FindFirstChildOfClass("Humanoid") end
        if not CharCache.UpperTorso then CharCache.UpperTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
        if not CharCache.CheckInt then CharCache.CheckInt = char:FindFirstChild("CheckInterractable") end
        return CharCache
    end
    local DaggerCache = { Value = false, LastCheck = 0, Interval = 0.05 }
    local function IsDaggerModel(inst)
        if not inst then return false end
        if inst:IsA("Model") or inst:IsA("Tool") or inst:IsA("Accessory") then return true end
        return false
    end
    local function IsEquippedDagger()
        local now = os.clock()
        if now - DaggerCache.LastCheck < DaggerCache.Interval then return DaggerCache.Value end
        DaggerCache.LastCheck = now
        local has = false
        local char = LocalPlayer.Character
        if char and IsDaggerModel(char:FindFirstChild("Parrying Dagger")) then has = true end
        if not has then
            local wsChar = Workspace:FindFirstChild(LocalPlayer.Name)
            if wsChar and IsDaggerModel(wsChar:FindFirstChild("Parrying Dagger")) then has = true end
        end
        DaggerCache.Value = has; return has
    end
    LocalPlayer.CharacterAdded:Connect(function() DaggerCache.Value = false; DaggerCache.LastCheck = 0 end)
    local CheckAttrs = {"isVaulting","isSliding","isDroppingPallet","isRepairing","isHealing","isUnhooking","isExiting"}
    local function IsBusy()
        local cc = GetCharCache()
        if not cc.Char then return true end
        if LocalPlayer:GetAttribute("IsDead") then return true end
        if cc.Char:GetAttribute("IsCarried") then return true end
        if cc.Char:GetAttribute("IsHooked") then return true end
        local root = cc.Root
        if root and CollectionService:HasTag(root, "doing action") then return true end
        local ci = cc.CheckInt
        if ci then for i = 1, #CheckAttrs do if ci:GetAttribute(CheckAttrs[i]) then return true end end end
        return false
    end
    local function IsDownedKiller(killerChar)
        if not killerChar then return false end
        local st = killerChar:GetAttribute("State")
        if st == "Downed" or st == "Dead" then return true end
        local kh = killerChar:FindFirstChildOfClass("Humanoid")
        if kh and kh.Health <= 0 then return true end
        return false
    end
    local function WallCheck(originPos, targetPos, targetChar)
        if not VD.PARRY_WallCheck then return true end
        return VD_WallCheckVisible(originPos, targetPos, targetChar)
    end
    local function CanFire()
        if not IsEquippedDagger() then return false end
        if Cooldown.IsSilenced then return false end
        if IsOnCooldown() then return false end
        if Cooldown.WaitingForResult then return false end
        if IsBusy() then return false end
        return true
    end
    local function ExecuteMobile()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui and type(firesignal) == "function" then
            local mobRoot = pGui:FindFirstChild("Survivor-mob")
            local controls = mobRoot and mobRoot:FindFirstChild("Controls")
            if controls then
                local candidatePaths = { "Gui-mob", "action", "Gui-mobile", "Gui_mob", "Parry", "parry" }
                for _, btnName in ipairs(candidatePaths) do
                    local btn = controls:FindFirstChild(btnName, true)
                    if btn and btn:IsA("GuiButton") and btn.Visible then
                        local ok = pcall(function()
                            firesignal(btn.MouseButton1Down)
                            task.delay(0.04, function()
                                if btn and btn.Parent then
                                    pcall(function() firesignal(btn.MouseButton1Up) end)
                                    pcall(function() firesignal(btn.MouseButton1Click) end)
                                end
                            end)
                        end)
                        if ok then return true end
                    end
                end
            end
        end
        if parryFireRemote and parryFireRemote:IsA("RemoteEvent") then return pcall(function() parryFireRemote:FireServer() end) end
        return false
    end
    local function ExecutePC()
        return pcall(function()
            VirtualInputManager:SendMouseMoveEvent(0, 0, game)
            task.wait(0.003)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 2, true, game, 0)
            task.wait(0.035)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 2, false, game, 0)
        end)
    end
    local function ExecuteSilent()
        if parryFireRemote and parryFireRemote:IsA("RemoteEvent") then return pcall(function() parryFireRemote:FireServer() end) end
        return false
    end
    local function Execute()
        if not CanFire() then return false end
        State.LastParry = os.clock(); Cooldown.LastFiredAt = os.clock()
        Cooldown.WaitingForResult = true; Cooldown.WaitingStart = os.clock()
        Cooldown.JustFired = true; Cooldown.ManualDetect = false
        local fired
        if VD.PARRY_SilentParry then fired = ExecuteSilent()
        elseif isMobile then fired = ExecuteMobile()
        else fired = ExecutePC() end
        if not fired then
            Cooldown.WaitingForResult = false; Cooldown.JustFired = false
            StartCooldown(Cooldown.TimeoutCooldown); return false
        end
        return true
    end
    local function DestroyCircle()
        if State.CircleFolder then pcall(function() if State.CircleFolder and State.CircleFolder.Parent then State.CircleFolder:Destroy() end end) end
        State.CircleFolder = nil; State.CircleDashes = {}; State.CircleRotCFs = {}; State.CircleOffsets = {}
        State.CircleRadius = 0; State.CircleBuiltForDagger = false
        State.CircleLastX = math.huge; State.CircleLastY = math.huge; State.CircleLastZ = math.huge
        State.CircleLastAlpha = -1; State.CircleLastR = -1; State.CircleLastG = -1; State.CircleLastB = -1
    end
    local function ForceRedraw()
        State.CircleLastX = math.huge; State.CircleLastY = math.huge; State.CircleLastZ = math.huge
        State.CircleLastAlpha = -1; State.CircleLastR = -1; State.CircleLastG = -1; State.CircleLastB = -1
    end
    local function BuildCircle(radius)
        DestroyCircle()
        local folder = Instance.new("Folder"); folder.Name = "MawwwParryV2Circle"
        local dashCount = math.clamp(math.floor(radius * 6), 24, 120)
        local slotLength = (2 * math.pi * radius) / dashCount
        local dashLength = slotLength * 0.55; local dashThickness = 0.03
        local dashes = table.create(dashCount); local rotCFs = table.create(dashCount); local offsets = table.create(dashCount)
        for i = 1, dashCount do
            local part = Instance.new("Part")
            part.Name = "Dash" .. i; part.Anchored = true; part.CanCollide = false
            part.CanTouch = false; part.CanQuery = false; part.CastShadow = false
            part.Material = Enum.Material.Neon; part.Color = NEON_PURPLE_V2
            part.Transparency = 0; part.Size = Vector3.new(dashThickness, dashThickness, dashLength)
            part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
            part.Parent = folder
            local angle = ((i - 1) / dashCount) * math.pi * 2
            local cosA = math.cos(angle); local sinA = math.sin(angle)
            local tangent = Vector3.new(-sinA, 0, cosA)
            rotCFs[i] = CFrame.lookAt(Vector3.zero, tangent); offsets[i] = Vector3.new(cosA * radius, 0, sinA * radius)
            dashes[i] = part
        end
        folder.Parent = Workspace
        State.CircleFolder = folder; State.CircleDashes = dashes
        State.CircleRotCFs = rotCFs; State.CircleOffsets = offsets
        State.CircleRadius = radius; State.CircleBuiltForDagger = true
        ForceRedraw()
    end
    local function UpdateCircle(myRoot)
        if not State.CircleFolder or not State.CircleFolder.Parent then return end
        local dashes = State.CircleDashes; local dashCount = #dashes
        if dashCount == 0 then return end
        local center = myRoot.Position - Vector3.new(0, (myRoot.Size.Y * 0.5) + 0.15, 0)
        local busy = IsBusy(); local onCd = Cooldown.OnCooldown
        local targetColor
        if busy then targetColor = Color3.fromRGB(255, 20, 20)
        elseif onCd then targetColor = Color3.fromRGB(255, 140, 0)
        else targetColor = NEON_PURPLE_V2 end
        local targetTransparency = 0
        if onCd then
            local period = 0.55
            local phase = (os.clock() % period) / period
            local pulse = (math.cos(phase * math.pi * 2) + 1) * 0.5
            targetTransparency = (1 - pulse) * 0.85
        end
        local rotCFs = State.CircleRotCFs; local offsets = State.CircleOffsets
        for i = 1, dashCount do
            local dash = dashes[i]
            if dash and dash.Parent then
                local off = offsets[i]
                local worldPos = Vector3.new(center.X + off.X, center.Y, center.Z + off.Z)
                dash.CFrame = rotCFs[i] + worldPos; dash.Color = targetColor
                dash.Transparency = targetTransparency; dash.Material = Enum.Material.Neon; dash.CanCollide = false
            end
        end
    end
    local function GetAnimType(track)
        if not track or not track.Animation then return nil end
        local animId = track.Animation.AnimationId or ""
        local numId = animId:match("%d+") or ""
        local name = string.lower(track.Animation.Name or "")
        local v = KillerAttackAnims[animId]
        if v then return v end
        if numId ~= "" then v = KillerAttackAnims[numId]; if v then return v end end
        if string.find(name, "lunge", 1, true) or string.find(name, "charge", 1, true) then return "lungehold" end
        if string.find(name, "attack", 1, true) or string.find(name, "slash", 1, true) or string.find(name, "swing", 1, true) or string.find(name, "stab", 1, true) or string.find(name, "melee", 1, true) then return "attack" end
        return nil
    end
    local function HookAnimatorOnChar(plr, char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 3)
        if not animator then return end
        animator.AnimationPlayed:Connect(function(track)
            if not VD.PARRY_Enabled then return end
            if not IsEquippedDagger() then return end
            local animType = GetAnimType(track)
            if animType then
                State.ActiveAttackers[plr] = { char = char, track = track, type = animType, registeredAt = os.clock() }
            end
        end)
    end
    local function HookKillerPlayer(plr)
        if plr == LocalPlayer then return end
        if plr.Character then HookAnimatorOnChar(plr, plr.Character) end
        plr.CharacterAdded:Connect(function(char) task.wait(0.5); HookAnimatorOnChar(plr, char) end)
    end
    for _, plr in ipairs(Players:GetPlayers()) do HookKillerPlayer(plr) end
    Players.PlayerAdded:Connect(HookKillerPlayer)
    local lastPoll = 0
    local POLL_INTERVAL = 0.05
    local function PollAttacks()
        if not VD.PARRY_Enabled then return end
        if not IsEquippedDagger() then return end
        local now = os.clock()
        if now - lastPoll < POLL_INTERVAL then return end
        lastPoll = now
        local allPlayers = Players:GetPlayers()
        for i = 1, #allPlayers do
            local plr = allPlayers[i]
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local tracks = hum:GetPlayingAnimationTracks()
                        for j = 1, #tracks do
                            local track = tracks[j]
                            local animType = GetAnimType(track)
                            if animType then
                                local existing = State.ActiveAttackers[plr]
                                if not existing or existing.track ~= track then
                                    State.ActiveAttackers[plr] = { char = char, track = track, type = animType, registeredAt = now }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local lastCleanup = 0
    local CLEANUP_INTERVAL = 1.0
    local function CleanupAttackers()
        local now = os.clock()
        if now - lastCleanup < CLEANUP_INTERVAL then return end
        lastCleanup = now
        for plr, data in pairs(State.ActiveAttackers) do
            if not plr or not plr.Parent or not data.track or not data.track.IsPlaying then State.ActiveAttackers[plr] = nil end
        end
    end
    local function CheckAndParry(killerChar)
        if IsOnCooldown() or Cooldown.WaitingForResult or Cooldown.IsSilenced then return end
        if not IsEquippedDagger() then return end
        if VD.PARRY_IgnoreDown and IsDownedKiller(killerChar) then return end
        local cc = GetCharCache()
        local myRoot = cc.UpperTorso or cc.Root
        local killerPart = killerChar and (killerChar:FindFirstChild("UpperTorso") or killerChar:FindFirstChild("Torso") or killerChar:FindFirstChild("HumanoidRootPart"))
        if not myRoot or not killerPart then return end
        if VD.PARRY_WallCheck and not WallCheck(myRoot.Position, killerPart.Position, killerChar) then return end
        local dist = (myRoot.Position - killerPart.Position).Magnitude
        if VD.PARRY_Aggressive then
            local ping = math.clamp(LocalPlayer:GetNetworkPing(), 0, 0.3)
            local killerRoot = killerChar:FindFirstChild("HumanoidRootPart") or killerPart
            local killerVel = killerRoot.AssemblyLinearVelocity
            local flatVel = Vector3.new(killerVel.X, 0, killerVel.Z)
            local predictedPos = killerPart.Position + (flatVel * ping)
            local predictedDist = (myRoot.Position - predictedPos).Magnitude
            if predictedDist <= ((VD.PARRY_Distance or 10) + 2.5) then
                local dirToMe = (myRoot.Position - killerPart.Position).Unit
                if flatVel.Magnitude > 6 and flatVel.Unit:Dot(dirToMe) > 0.4 then Execute(); return end
            end
        end
        if dist <= (VD.PARRY_Distance or 10) then Execute() end
    end
    local function CheckProximityThreats()
        if not VD.PARRY_Enabled or not IsEquippedDagger() then return end
        if IsOnCooldown() or Cooldown.WaitingForResult or Cooldown.IsSilenced then return end
        local cc = GetCharCache()
        local myRoot = cc.Root or cc.UpperTorso
        if not myRoot then return end
        local maxDist = tonumber(VD.PARRY_Distance) or 10
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and IsKiller(plr) and plr.Character then
                local kChar = plr.Character
                if not (VD.PARRY_IgnoreDown and IsDownedKiller(kChar)) then
                    local kRoot = kChar:FindFirstChild("HumanoidRootPart")
                    if kRoot then
                        local delta = myRoot.Position - kRoot.Position
                        local dist = delta.Magnitude
                        if dist <= maxDist + 3 then
                            local flatDelta = Vector3.new(delta.X, 0, delta.Z)
                            local flatVel = Vector3.new(kRoot.AssemblyLinearVelocity.X, 0, kRoot.AssemblyLinearVelocity.Z)
                            local closing = flatDelta.Magnitude > 0.1 and flatVel:Dot(flatDelta.Unit) or 0
                            local facing = 0
                            local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z)
                            if flatDelta.Magnitude > 0.1 and look.Magnitude > 0.1 then facing = look.Unit:Dot(flatDelta.Unit) end
                            local threatening = dist <= maxDist and (closing >= 4 or flatVel.Magnitude < 2) and facing >= 0.20
                            if threatening then
                                CheckAndParry(kChar)
                                if Cooldown.WaitingForResult then return end
                            end
                        end
                    end
                end
            end
        end
    end
    local function UpdateLogic()
        local myChar = LocalPlayer.Character
        if not myChar or not VD.PARRY_Enabled then return end
        if not IsEquippedDagger() then
            if next(State.ActiveAttackers) then State.ActiveAttackers = {} end
            return
        end
        if Cooldown.WaitingForResult then
            if os.clock() - Cooldown.WaitingStart > Cooldown.WaitTimeout then
                Cooldown.WaitingForResult = false; Cooldown.JustFired = false; Cooldown.ManualDetect = false
                StartCooldown(Cooldown.TimeoutCooldown)
            end
        end
        if IsOnCooldown() or Cooldown.WaitingForResult then return end
        PollAttacks(); CleanupAttackers(); CheckProximityThreats()
        if Cooldown.WaitingForResult then return end
        for plr, data in pairs(State.ActiveAttackers) do
            if plr and plr.Parent and data.track and data.track.IsPlaying then
                local shouldCheck = false
                if data.type == "attack" then if data.track.TimePosition < 0.35 then shouldCheck = true end
                elseif data.type == "lungehold" then shouldCheck = true end
                if shouldCheck then CheckAndParry(data.char); if Cooldown.WaitingForResult then break end end
            else State.ActiveAttackers[plr] = nil end
        end
    end
    local function UpdateCircleLogic()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if VD.PARRY_ShowCircle and myRoot then
            if not State.CircleFolder or State.CircleRadius ~= (VD.PARRY_Distance or 10) or not State.CircleFolder.Parent then BuildCircle(VD.PARRY_Distance or 10) end
            UpdateCircle(myRoot)
        else if State.CircleFolder then DestroyCircle() end end
    end
    local lastLogic, lastCircle = 0, 0
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastCircle >= 0.033 then lastCircle = now; pcall(UpdateCircleLogic) end
        if now - lastLogic >= 0.05 then lastLogic = now; pcall(UpdateLogic) end
    end)
    return { DestroyCircle = DestroyCircle, ForceRedraw = ForceRedraw, State = State, Cooldown = Cooldown }
end)()

RegToggle(Tabs.Survival, "Enable Auto Parry V2", "Advanced auto parry", false, "PARRY_Enabled")
RegToggle(Tabs.Survival, "V2 Aggressive Predict", "Predictive parry", false, "PARRY_Aggressive")
RegSlider(Tabs.Survival, "V2 Parry Distance", "Trigger distance", 10, 4, 30, 1, "PARRY_Distance")
RegToggle(Tabs.Survival, "V2 Silent Parry (No Animation)", "Silent parry", false, "PARRY_SilentParry")
RegToggle(Tabs.Survival, "V2 Show Parry Range (Neon Purple)", "Show range circle", false, "PARRY_ShowCircle")
RegToggle(Tabs.Survival, "[NEW] V2 Wall Check", "Require line of sight", false, "PARRY_WallCheck")
RegToggle(Tabs.Survival, "[NEW] V2 Ignore Downed Killer", "Skip downed killers", true, "PARRY_IgnoreDown")

--========================================================--
-- Movement & Moonwalk
--========================================================--
RegDivider(Tabs.Player)
RegLabel(Tabs.Player, "Movement & Moonwalk")
MoonwalkConn = nil
function startMoonwalk()
    if MoonwalkConn then MoonwalkConn:Disconnect(); MoonwalkConn = nil end
    MoonwalkConn = RunService.RenderStepped:Connect(function()
        local char = Player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not VD.Moonwalk or (not humanoid) or humanoid.Health <= 0 then
            if humanoid then
                if humanoid.AutoRotate == false then humanoid.AutoRotate = true end
                if humanoid.WalkSpeed == 13 then humanoid.WalkSpeed = 16 end
            end
            return
        end
        local cam = workspace.CurrentCamera
        if not (hrp and cam) then return end
        if humanoid.AutoRotate then humanoid.AutoRotate = false end
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 0.001 then return end
        flat = flat.Unit
        local spamSpeed = tonumber(VD.MoonwalkSpam) or 30
        local intensity = tonumber(VD.MoonwalkIntensity) or 35
        local angle = math.sin(tick() * spamSpeed) * intensity
        local baseCF = CFrame.new(hrp.Position, hrp.Position + flat)
        hrp.CFrame = baseCF * CFrame.Angles(0, math.rad(angle), 0)
    end)
end
getgenv().MAWWW_StartMoonwalk = startMoonwalk
RegToggle(Tabs.Player, "Moonwalk", "Enable moonwalk", false, "Moonwalk")
RegSlider(Tabs.Player, "Moonwalk Spam Speed", "Spam speed", 30, 1, 50, 1, "MoonwalkSpam")
RegSlider(Tabs.Player, "Moonwalk Intensity", "Rotation intensity", 35, 1, 50, 1, "MoonwalkIntensity")
RegToggle(Tabs.Player, "Show Moonwalk Icon", "Show quick toggle icon", false, "ShowMoonwalkIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)
RegToggle(Tabs.Player, "Lock Moonwalk Icon", "Lock icon position", false, "LockMoonwalkIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)

originalCanCollide = {}
RunService.Stepped:Connect(function()
    if VD.Noclip then
        local char = Player.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    if originalCanCollide[d] == nil then originalCanCollide[d] = d.CanCollide end
                    d.CanCollide = false
                end
            end
        end
    end
end)
function VD_DisableNoclip()
    for part, cc in pairs(originalCanCollide) do if part and part.Parent then pcall(function() part.CanCollide = cc end) end end
    originalCanCollide = {}
end
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if VD.Speed and hum.WalkSpeed ~= VD.SpeedValue then hum.WalkSpeed = VD.SpeedValue end
        if VD.Jump and hum.JumpPower ~= VD.JumpValue then hum.JumpPower = VD.JumpValue end
    end
end)
UserInputService.JumpRequest:Connect(function()
    local hum = getHum()
    if VD.InfiniteJump and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
RegToggle(Tabs.Player, "Enable Speed", "Custom walkspeed", false, "Speed", function(v) if not v then local hum = getHum(); if hum then hum.WalkSpeed = 16 end end end)
RegSlider(Tabs.Player, "WalkSpeed", "Speed value", 16, 16, 120, 1, "SpeedValue")
RegToggle(Tabs.Player, "Jump Hack", "Custom jump power", false, "Jump", function(v) if not v then local hum = getHum(); if hum then hum.JumpPower = 50 end end end)
RegSlider(Tabs.Player, "Jump Power", "Jump value", 50, 50, 300, 1, "JumpValue")
RegToggle(Tabs.Player, "Infinite Jump", "Allow infinite jumps", false, "InfiniteJump")
RegToggle(Tabs.Player, "Noclip", "Walk through walls", false, "Noclip", function(v) if not v then VD_DisableNoclip() end end)

--========================================================--
-- Fling & Predict
--========================================================--
RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Fling")
function VD_FlingNearest()
    if not VD.FlingEnabled then return end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d = (tr.Position - root.Position).Magnitude; if d < closestDist then closestDist = d; closest = plr end end
        end
    end
    if closest and closest.Character then
        local tr = closest.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local orig = root.CFrame
            for _ = 1, 10 do
                root.CFrame = tr.CFrame
                root.Velocity = Vector3.new(VD.FlingStrength, VD.FlingStrength/2, VD.FlingStrength)
                root.RotVelocity = Vector3.new(9999, 9999, 9999)
                task.wait()
            end
            root.CFrame = orig; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
        end
    end
end
function VD_FlingAll()
    if not VD.FlingEnabled then return end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local orig = root.CFrame
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                for _ = 1, 5 do
                    root.CFrame = tr.CFrame
                    root.Velocity = Vector3.new(VD.FlingStrength, VD.FlingStrength/2, VD.FlingStrength)
                    root.RotVelocity = Vector3.new(9999, 9999, 9999)
                    task.wait()
                end
            end
        end
    end
    root.CFrame = orig; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
end
RegToggle(Tabs.Utility, "Enable Fling", "Fling nearby players", false, "FlingEnabled")
RegSlider(Tabs.Utility, "Fling Strength", "Fling power", 10000, 1000, 50000, 1000, "FlingStrength")
RegButton(Tabs.Utility, "Fling Nearest", "Fling closest player", function() pcall(VD_FlingNearest) end)
RegButton(Tabs.Utility, "Fling All", "Fling all players", function() pcall(VD_FlingAll) end)

RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Predict")
PredictState = { CurrentMap = "Waiting...", CurrentKiller = "Waiting..." }
function GetMapNameFromWorkspace()
    local mapFolder = Workspace:FindFirstChild("Map"); if not mapFolder then return nil end
    local names = {"title", "Title", "MapName", "Name"}
    local attrs = mapFolder:GetAttributes()
    for _, n in ipairs(names) do if attrs[n] ~= nil then return tostring(attrs[n]) end end
    for _, child in ipairs(mapFolder:GetChildren()) do
        local cAttrs = child:GetAttributes()
        for _, n in ipairs(names) do if cAttrs[n] ~= nil then return tostring(cAttrs[n]) end end
    end
    return nil
end
function GetNextKillerFromAttributes()
    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local allow = p:GetAttribute("AllowKiller")
            local chance = p:GetAttribute("KillerChance")
            local kystMark = p:GetAttribute("KystInLine")
            local score = 0
            if allow == true then score = score + 1000 end
            if typeof(chance) == "number" then score = score + chance end
            if kystMark == true then score = score + 500 end
            table.insert(candidates, {Player = p, Score = score})
        end
    end
    table.sort(candidates, function(a, b) return a.Score > b.Score end)
    if candidates[1] and candidates[1].Score > 0 then return candidates[1].Player end
    return nil
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(1)
        if VD.PredictMap then
            local mapName = GetMapNameFromWorkspace()
            if mapName and mapName ~= "" and mapName ~= PredictState.CurrentMap then PredictState.CurrentMap = mapName; notify("Predict Map", "Map: " .. mapName, 3) end
        end
        if VD.PredictKiller then
            local nextKiller = GetNextKillerFromAttributes()
            local name = nextKiller and (nextKiller.DisplayName or nextKiller.Name) or "Unknown"
            if name ~= PredictState.CurrentKiller then PredictState.CurrentKiller = name; notify("Next Killer", "Next Killer: " .. name, 3) end
        end
    end
end)
RegToggle(Tabs.Utility, "Predict Map", "Predict next map", false, "PredictMap")
RegToggle(Tabs.Utility, "Next Killer", "Predict next killer", false, "PredictKiller")
RegButton(Tabs.Utility, "Refresh Prediction", "Refresh prediction data", function()
    PredictState.CurrentMap = ""; PredictState.CurrentKiller = ""
    notify("Predict", "Prediction refreshed", 2)
end)
RegButton(Tabs.Utility, "Clear Prediction", "Clear prediction data", function()
    PredictState.CurrentMap = ""; PredictState.CurrentKiller = ""
    notify("Predict", "Prediction cleared", 2)
end)

--========================================================--
-- SURVIVAL TAB
--========================================================--
RegLabel(Tabs.Survival, "═══ Survivor Actions ═══")
LastFlee = 0
RegToggle(Tabs.Survival, "Auto Flee Killer", "Auto flee from killer", false, "AutoFlee")
RegSlider(Tabs.Survival, "Flee Distance", "Flee trigger distance", 50, 15, 80, 1, "AutoFleeDist")
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.2)
        if VD.AutoFlee then
            local root = getRoot()
            if root then
                local kRoot
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and IsKiller(p) and p.Character then kRoot = p.Character:FindFirstChild("HumanoidRootPart"); break end
                end
                if kRoot and (kRoot.Position - root.Position).Magnitude <= VD.AutoFleeDist and tick() - LastFlee > 0.1 then
                    local bestPoint, bestDist = nil, 0
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and string.match(obj.Name, "^GeneratorPoint%d+$") then
                            local d = (obj.Position - kRoot.Position).Magnitude
                            if d > bestDist then bestDist = d; bestPoint = obj end
                        end
                    end
                    if bestPoint then LastFlee = tick(); root.CFrame = bestPoint.CFrame + Vector3.new(0, 5, 0) end
                end
            end
        end
    end
end)
RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "Healing / Aura Heal")

RegLabel(Tabs.Survival, "Auto Escape")
function VD_FindFinishLine()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if (n == "finishline" or n == "fininshline" or n == "exitgate" or n == "exitzone" or n:find("finish") or n:find("exit")) and obj:IsA("BasePart") then return obj end
    end
    return nil
end
function VD_DoEscape()
    local root = getRoot(); if not root then return false end
    local finish = VD_FindFinishLine()
    if finish then
        pcall(function() root.CFrame = CFrame.new(finish.Position + Vector3.new(0, 3, 0)) end)
        task.wait(0.05)
        if firetouchinterest then
            pcall(function() firetouchinterest(root, finish, 0) end)
            pcall(function() firetouchinterest(root, finish, 1) end)
        end
    end
    pcall(function()
        local r = GetRemotes()
        local g = r and r:FindFirstChild("Game")
        local ev = g and g:FindFirstChild("PlayerActionEvent")
        if ev then ev:FireServer("ESCAPED", 200); task.wait(0.05); ev:FireServer("ESCAPED", 200) end
    end)
    return true
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        if VD.BeatSurvivor and GetRole() == "Survivor" then pcall(VD_DoEscape) end
    end
end)
RegToggle(Tabs.Survival, "Beat Survivor (Auto Escape)", "Auto escape the map", false, "BeatSurvivor")
RegButton(Tabs.Survival, "Escape Now", "Force escape now", function() pcall(VD_DoEscape); notify("Escape", "Trying to escape...", 2) end)

--========================================================--
-- KILLER TAB
--========================================================--
RegLabel(Tabs.Killer, "═══ Killer Basic ═══")
RegToggle(Tabs.Killer, "Auto Attack", "Auto attack nearby survivors", false, "KillerAutoAttack")
RegSlider(Tabs.Killer, "Attack Range", "Attack distance", 12, 5, 20, 1, "KillerAttackRange")
RegToggle(Tabs.Killer, "Auto Spam Attack", "Spam attack continuously", false, "KillerAutoSpam")
RegSlider(Tabs.Killer, "Attack Delay", "Delay between attacks", 0.45, 0.1, 1, 0.05, "KillerAttackDelay")
RegToggle(Tabs.Killer, "Auto Stalk", "Auto stalk nearest survivor", false, "KillerAutoStalk")
RegToggle(Tabs.Killer, "Auto Kill All", "Auto kill all survivors", false, "KillerKillAll")
RegToggle(Tabs.Killer, "Hitbox Expand", "Expand hitbox for easier hits", false, "KillerHitbox")
RegSlider(Tabs.Killer, "Hitbox Size", "Hitbox size", 15, 5, 40, 1, "KillerHitboxSize")

task.spawn(function()
    while not VD.Destroyed do
        task.wait(VD.KillerAttackDelay)
        if VD.KillerAutoAttack and GetRole() == "Killer" then
            local root = getRoot()
            if root then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and IsSurvivor(p) and p.Character then
                        local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if tRoot and tHum and tHum.Health > 0 and (tRoot.Position - root.Position).Magnitude <= VD.KillerAttackRange then
                            pcall(function()
                                local r = GetRemotes()
                                local a = r and r:FindFirstChild("Attacks")
                                local b = a and a:FindFirstChild("BasicAttack")
                                if b then b:FireServer(false) end
                            end)
                            break
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(VD.KillerAttackDelay)
        if VD.KillerAutoSpam and GetRole() == "Killer" then
            pcall(function()
                local r = GetRemotes()
                local a = r and r:FindFirstChild("Attacks")
                local b = a and a:FindFirstChild("BasicAttack")
                if b then b:FireServer(false) end
            end)
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        if VD.KillerAutoStalk and GetRole() == "Killer" then
            local root = getRoot()
            if root then
                local closest, closestDist = nil, 150
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and IsSurvivor(p) and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 30 then
                            local d = (hrp.Position - root.Position).Magnitude
                            if d < closestDist then closestDist = d; closest = p end
                        end
                    end
                end
                if closest then
                    pcall(function()
                        local r = GetRemotes()
                        local k = r and r:FindFirstChild("Killers")
                        local st = k and k:FindFirstChild("Stalker")
                        local ev = st and st:FindFirstChild("StartStalking")
                        if ev then ev:FireServer(closest) end
                    end)
                end
            end
        end
    end
end)
task.spawn(function()
    local KillerTarget = nil
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.KillerKillAll and GetRole() == "Killer" then
            local root = getRoot()
            if root then
                if not KillerTarget or not KillerTarget:FindFirstChild("Humanoid") or KillerTarget.Humanoid.Health <= 35 then
                    local closest, shortest = nil, math.huge
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= Player and IsSurvivor(plr) and plr.Character then
                            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                            if hum and hrp and hum.Health > 30 then
                                local d = (hrp.Position - root.Position).Magnitude
                                if d < shortest then shortest = d; closest = plr.Character end
                            end
                        end
                    end
                    KillerTarget = closest
                end
                if KillerTarget then
                    local targetHRP = KillerTarget:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        local targetPos = targetHRP.Position + (targetHRP.AssemblyLinearVelocity * 0.15)
                        local behind = targetHRP.CFrame.LookVector * -3
                        root.CFrame = CFrame.new(targetPos + behind, targetPos)
                    end
                    pcall(function()
                        local r = GetRemotes()
                        local a = r and r:FindFirstChild("Attacks")
                        local b = a and a:FindFirstChild("BasicAttack")
                        if b then b:FireServer(false) end
                    end)
                end
            end
        end
    end
end)
OriginalHitboxSizes = {}
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.2)
        if VD.KillerHitbox and GetRole() == "Killer" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and IsSurvivor(p) and p.Character then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        if not OriginalHitboxSizes[p] then OriginalHitboxSizes[p] = root.Size end
                        local sz = VD.KillerHitboxSize
                        root.Size = Vector3.new(sz, sz, sz); root.CanCollide = false; root.Transparency = 0.7
                    end
                elseif OriginalHitboxSizes[p] then
                    local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if root then root.Size = OriginalHitboxSizes[p]; root.Transparency = 1; root.CanCollide = true end
                    OriginalHitboxSizes[p] = nil
                end
            end
        else
            for p, orig in pairs(OriginalHitboxSizes) do
                local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if root then root.Size = orig; root.Transparency = 1; root.CanCollide = true end
            end
            OriginalHitboxSizes = {}
        end
    end
end)

RegDivider(Tabs.Killer)
RegLabel(Tabs.Killer, "Killer Abilities")
RegToggle(Tabs.Killer, "Infinite Lunge", "Unlimited lunge boost", false, "KillerInfLunge")
RegToggle(Tabs.Killer, "Infinite Frenzy (Jeff)", "Unlimited frenzy", false, "KillerInfFrenzy")
RegToggle(Tabs.Killer, "Infinite Lake Mist (Jason)", "Unlimited lake mist", false, "KillerInfLakeMist")
RegToggle(Tabs.Killer, "Infinite Pursuit (Jason)", "Unlimited pursuit", false, "KillerInfPursuit")
RegToggle(Tabs.Killer, "Infinite Grab (Myers)", "Unlimited grab", false, "KillerInfGrab")
RegToggle(Tabs.Killer, "Show Infinite Myers Icon", "Show quick toggle icon", false, "ShowInfiniteMyersIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)
RegToggle(Tabs.Killer, "Lock Infinite Myers Icon", "Lock icon position", false, "LockInfiniteMyersIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)
RegToggle(Tabs.Killer, "Infinite Abyssal Burst", "Unlimited abyssal burst", false, "KillerInfAbyss")
RegToggle(Tabs.Killer, "Infinite Skill (Hidden)", "Unlimited hidden skill", false, "KillerInfSkill")
RegToggle(Tabs.Killer, "Bypass All Cooldowns", "Bypass all cooldowns", false, "KillerBypassCD")
RegToggle(Tabs.Killer, "Anti Blind (Flashlight)", "Ignore flashlight blind", false, "KillerAntiBlind")

RegToggle(Tabs.Killer, "Show Bypass Skill Icon", "Show Bypass Skill quick toggle icon", false, "ShowBypassSkillIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)
RegToggle(Tabs.Killer, "Lock Bypass Skill Icon", "Lock Bypass Skill icon position", false, "LockBypassSkillIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)

task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        local char = Player.Character
        if char then
            if VD.KillerInfLunge then pcall(function() char:SetAttribute("lungeboost", 999999) end)
            else pcall(function() if char:GetAttribute("lungeboost") == 999999 then char:SetAttribute("lungeboost", 1) end end) end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.2)
        if VD.KillerInfFrenzy and GetRole() == "Killer" then
            local char = Player.Character
            if char and char:GetAttribute("Frenzy") ~= true then pcall(function() char:SetAttribute("Frenzy", true) end) end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.35)
        if VD.KillerInfLakeMist and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"LakeMistCharges", "LakeMistUses", "MistCharges"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v < 999 then char:SetAttribute(attr, 999) end
                    end
                    for _, attr in ipairs({"LakeMistCooldown", "MistCooldown", "LakeMistCD"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                    local remotes = GetRemotes()
                    local killers = remotes and remotes:FindFirstChild("Killers")
                    local jason = killers and (killers:FindFirstChild("Jason") or killers:FindFirstChild("LakeMist"))
                    if jason then
                        local cancel = jason:FindFirstChild("CancelLakeMist") or jason:FindFirstChild("RefreshLakeMist")
                        if cancel and cancel:IsA("RemoteEvent") then pcall(function() cancel:FireServer() end) end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.35)
        if VD.KillerInfPursuit and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"PursuitCharges", "PursuitUses", "PursuitActive", "PursuitCD"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil then
                            if type(v) == "number" and v > 0 then char:SetAttribute(attr, 0)
                            elseif type(v) == "boolean" and v == false then char:SetAttribute(attr, true) end
                        end
                    end
                    for _, attr in ipairs({"PursuitCooldown", "PursuitCD"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.35)
        if VD.KillerInfGrab and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"GrabCharges", "GrabUses", "GrabTier", "GrabLevel"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v < 3 then char:SetAttribute(attr, 3) end
                    end
                    for _, attr in ipairs({"GrabCooldown", "GrabCD"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                    local remotes = GetRemotes()
                    local killers = remotes and remotes:FindFirstChild("Killers")
                    local myers = killers and (killers:FindFirstChild("Myers") or killers:FindFirstChild("Michael"))
                    if myers then
                        local tier = myers:FindFirstChild("SetTier") or myers:FindFirstChild("Upgrade")
                        if tier and tier:IsA("RemoteEvent") then pcall(function() tier:FireServer(3) end) end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.35)
        if VD.KillerInfAbyss and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"AbyssCharges", "AbyssalCharges", "BurstCharges", "AbyssalUses"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v < 999 then char:SetAttribute(attr, 999) end
                    end
                    for _, attr in ipairs({"AbyssCooldown", "AbyssalCooldown", "BurstCooldown"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        if VD.KillerInfSkill and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"SkillCharges", "AbilityCharges", "SpecialCharges", "HiddenCharges"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v < 999 then char:SetAttribute(attr, 999) end
                    end
                    for _, attr in ipairs({"SkillCooldown", "AbilityCooldown", "SpecialCooldown", "HiddenCooldown"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.25)
        if VD.KillerBypassCD and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                pcall(function()
                    for _, attr in ipairs({"SkillCooldown","AbilityCooldown","SpecialCooldown","AttackCooldown","LungeCooldown","FrenzyCooldown","PursuitCooldown","LakeMistCooldown","GrabCooldown","AbyssCooldown","HookCooldown","StalkCooldown"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then char:SetAttribute(attr, 0) end
                    end
                    for _, a in ipairs(char:GetAttributes()) do
                        if type(a) == "string" and a:lower():find("cooldown") then
                            local v = char:GetAttribute(a)
                            if type(v) == "number" and v > 0 then char:SetAttribute(a, 0) end
                        end
                    end
                end)
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.KillerAntiBlind and GetRole() == "Killer" then
            pcall(function()
                local char = Player.Character
                if char then
                    char:SetAttribute("Blindness", 0); char:SetAttribute("Blind", false)
                    char:SetAttribute("IsBlinded", false); char:SetAttribute("FlashBlind", false)
                end
                local pg = Player:FindFirstChild("PlayerGui")
                if pg then
                    for _, gui in ipairs(pg:GetChildren()) do
                        if gui:IsA("ScreenGui") then
                            local ln = gui.Name:lower()
                            if ln:find("blind") or ln:find("flash") then gui.Enabled = false end
                        end
                    end
                end
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("ColorCorrectionEffect") and v.Brightness < -0.3 then v.Brightness = 0 end
                end
            end)
        end
    end
end)

RegDivider(Tabs.Killer)
RegLabel(Tabs.Killer, "Bypass Skill (All Killers)")

getgenv().BYPASS_HiddenLeapBypassThread = nil
function BYPASS_StartHiddenCooldownBypass()
    if getgenv().BYPASS_HiddenLeapBypassThread then return end
    getgenv().BYPASS_HiddenLeapBypassThread = task.spawn(function()
        local leapFunction, m2Function
        local function scanGC()
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and islclosure(v) then
                        local info
                        pcall(function() info = debug.getinfo(v) end)
                        if info then
                            if info.name == "tryActivate" then leapFunction = v
                            elseif info.name == "playM2Animation" then m2Function = v end
                        end
                    end
                    if leapFunction and m2Function then break end
                end
            end)
        end
        scanGC()
        local lastScan = os.clock()
        while task.wait(0.1) do
            if not (VD.KillerBypassSkill and VD.KillerInfSkill) then break end
            if not (leapFunction and m2Function) then
                local now = os.clock()
                if now - lastScan >= 2 then lastScan = now; scanGC() end
            end
            if leapFunction then
                pcall(function()
                    for i, val in pairs(debug.getupvalues(leapFunction)) do
                        if type(val) == "boolean" and val == true then debug.setupvalue(leapFunction, i, false) end
                    end
                end)
            end
            if m2Function then
                pcall(function()
                    for i, val in pairs(debug.getupvalues(m2Function)) do
                        if type(val) == "boolean" and val == true then debug.setupvalue(m2Function, i, false) end
                    end
                end)
            end
        end
        getgenv().BYPASS_HiddenLeapBypassThread = nil
    end)
end

getgenv().Bypass_HiddenLeapBypassThread = nil

function BYPASS_StartHiddenCooldownBypass()
    if getgenv().Bypass_HiddenLeapBypassThread then return end
    getgenv().Bypass_HiddenLeapBypassThread = task.spawn(function()
        local leapFunction, m2Function, toggleFunc, pursuitFunc
        local function scanGC()
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and islclosure(v) then
                        local info
                        pcall(function() info = debug.getinfo(v) end)
                        if info then
                            if info.name == "tryActivate" then
                                leapFunction = v
                            elseif info.name == "playM2Animation" then
                                m2Function = v
                            end
                        end
                    end
                    if leapFunction and m2Function then break end
                end
            end)
        end

        scanGC()

        local lastScan = os.clock()
        while task.wait(0.1) do
            if not VD.KillerInfLunge then
                break
            end

            if not (leapFunction and m2Function) then
                local now = os.clock()
                if now - lastScan >= 2 then
                    lastScan = now
                    scanGC()
                end
            end

            if leapFunction then
                pcall(function()
                    for i, val in pairs(debug.getupvalues(leapFunction)) do
                        if type(val) == "boolean" and val == true then
                            debug.setupvalue(leapFunction, i, false)
                        end
                    end
                end)
            end
            if m2Function then
                pcall(function()
                    for i, val in pairs(debug.getupvalues(m2Function)) do
                        if type(val) == "boolean" and val == true then
                            debug.setupvalue(m2Function, i, false)
                        end
                    end
                end)
            end
        end
        getgenv().BYPASSS_HiddenLeapBypassThread = nil
    end)
end

function BYPASS_StopHiddenCooldownBypass()
end

--========================================================--
-- INF GRAB (MYERS)
--========================================================--
MyersGrabData = {
    Enabled = false,
    UI = nil,
    Button = nil,
    DragLocked = false,
    Dragging = false,
    DragStart = nil,
    DragStartPos = nil,
    HotkeyCode = Enum.KeyCode.H,
}

function getMyersTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local candidates = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(candidates, {
                    player = player,
                    dist   = (hrp.Position - myHRP.Position).Magnitude,
                    health = hum.Health
                })
            end
        end
    end
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    for _, c in ipairs(candidates) do
        return c.player
    end
    return nil
end

function doMyersGrab()
    if not MyersGrabData.Enabled then return end
    local target = getMyersTarget()
    if not target or not target.Character then return end
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        ReplicatedStorage.Remotes.Killers.Stalker.grab:FireServer(target.Character)
    end)
end

function setupMyersGrabBtn()
    local oldUI = LocalPlayer.PlayerGui:FindFirstChild("MyersGrabUI")
    if oldUI then oldUI:Destroy() end

    MyersGrabData.UI = Instance.new("ScreenGui")
    MyersGrabData.UI.Name = "MyersGrabUI"
    MyersGrabData.UI.ResetOnSpawn = false
    MyersGrabData.UI.IgnoreGuiInset = true
    MyersGrabData.UI.Parent = LocalPlayer:WaitForChild("PlayerGui")

    MyersGrabData.Button = Instance.new("ImageButton")
    MyersGrabData.Button.Name = "MyersGrabButton"
    MyersGrabData.Button.Size = UDim2.new(0, 60, 0, 60)
    MyersGrabData.Button.Position = UDim2.new(0.7, 0, 0.75, 0)
    MyersGrabData.Button.AnchorPoint = Vector2.new(0.5, 0.5)
    MyersGrabData.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MyersGrabData.Button.BackgroundTransparency = 0.15
    MyersGrabData.Button.AutoButtonColor = true
    MyersGrabData.Button.Visible = false
    MyersGrabData.Button.ZIndex = 10
    MyersGrabData.Button.Parent = MyersGrabData.UI
    Instance.new("UICorner", MyersGrabData.Button).CornerRadius = UDim.new(1, 0)

    local s = Instance.new("UIStroke", MyersGrabData.Button)
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 2; s.Transparency = 0.2

    local lbl = Instance.new("TextLabel", MyersGrabData.Button)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "GRAB"
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBlack
    lbl.ZIndex = 11

    local function applyShine(obj, baseColor)
        local grad = Instance.new("UIGradient", obj)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, baseColor),
            ColorSequenceKeypoint.new(0.4, baseColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.6, baseColor),
            ColorSequenceKeypoint.new(1, baseColor)
        })
        grad.Rotation = 45
        grad.Offset = Vector2.new(-1, -1)

        task.spawn(function()
            local TweenService = game:GetService("TweenService")
            local ti = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
            local tw = TweenService:Create(grad, ti, { Offset = Vector2.new(1, 1) })
            tw:Play()
        end)
    end

    applyShine(MyersGrabData.Button, Color3.fromRGB(45, 45, 45))
    applyShine(lbl, Color3.fromRGB(204, 204, 204))
    applyShine(s, Color3.fromRGB(204, 204, 204))

    MyersGrabData.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if MyersGrabData.DragLocked then return end
            MyersGrabData.Dragging = true
            MyersGrabData.DragStart = input.Position
            MyersGrabData.DragStartPos = MyersGrabData.Button.Position
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if MyersGrabData.Dragging and not MyersGrabData.DragLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - MyersGrabData.DragStart
            MyersGrabData.Button.Position = UDim2.new(
                MyersGrabData.DragStartPos.X.Scale, MyersGrabData.DragStartPos.X.Offset + delta.X,
                MyersGrabData.DragStartPos.Y.Scale, MyersGrabData.DragStartPos.Y.Offset + delta.Y
            )
        end
    end)

    MyersGrabData.Button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            MyersGrabData.Dragging = false
        end
    end)

    MyersGrabData.Button.MouseButton1Click:Connect(doMyersGrab)
end

pcall(setupMyersGrabBtn)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(setupMyersGrabBtn)
    if MyersGrabData.Button then
        MyersGrabData.Button.Visible = MyersGrabData.Enabled
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == MyersGrabData.HotkeyCode and MyersGrabData.Enabled then
        doMyersGrab()
    end
end)

function setMyersGrab(v)
    MyersGrabData.Enabled = v
    if MyersGrabData.Button then
        MyersGrabData.Button.Visible = v
    end
end

function setMyersDragLocked(v)
    MyersGrabData.DragLocked = v
end

--========================================================--
-- Bypass Slasher
--========================================================--
getgenv().MAWWW_SlasherCooldownBypassThread = nil

function MAWWW_StartSlasherCooldownBypass()
    if getgenv().MAWWW_SlasherCooldownBypassThread then return end

    pcall(function()
        local b = true
        local mt = debug.getmetatable(b)
        if not mt then
            mt = {}
            debug.setmetatable(b, mt)
        end
        if setreadonly then setreadonly(mt, false) end
        mt.__div = function() return 0 end
        mt.__mul = function() return 0 end
        mt.__add = function() return 0 end
        mt.__sub = function() return 0 end
        if setreadonly then setreadonly(mt, true) end
    end)

    getgenv().MAWWW_SlasherCooldownBypassThread = task.spawn(function()
        local toggleFunc = nil
        local pursuitHandler = nil

        local function scanGCForSlasher()
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and islclosure(v) then
                        local consts = debug.getconstants(v)
                        local hasOffset, hasLinear, hasAction, hasTweenInfo = false, false, false, false
                        local hasPursuit, hasWalkSpeed = false, false

                        for _, c in pairs(consts) do
                            if c == "Offset" then hasOffset = true end
                            if c == "Linear" then hasLinear = true end
                            if c == "action" then hasAction = true end
                            if c == "TweenInfo" then hasTweenInfo = true end
                            if c == "Pursuit" then hasPursuit = true end
                            if c == "WalkSpeed" then hasWalkSpeed = true end
                        end

                        if hasOffset and hasLinear and hasAction and hasTweenInfo and not hasPursuit then
                            toggleFunc = v
                        end

                        if hasPursuit and hasTweenInfo and hasAction and hasWalkSpeed then
                            pursuitHandler = v
                        end
                    end
                    if toggleFunc and pursuitHandler then break end
                end
            end)
        end

        scanGCForSlasher()
        local lastScan = os.clock()

        while task.wait(0.1) do
            if not VD.KillerInfLakeMist and not VD.KillerInfPursuit then
                break
            end

            if not (toggleFunc and pursuitHandler) then
                if os.clock() - lastScan >= 2 then
                    scanGCForSlasher()
                    lastScan = os.clock()
                end
            end

            if toggleFunc and VD.KillerInfLakeMist then
                pcall(function()
                    debug.setupvalue(toggleFunc, 6, false)
                    debug.setupvalue(toggleFunc, 10, false)
                end)
            end

            if pursuitHandler and VD.KillerInfPursuit then
                pcall(function()
                    debug.setupvalue(pursuitHandler, 5, false)
                    debug.setupvalue(pursuitHandler, 6, false)
                end)
            end
        end

        getgenv().MAWWW_SlasherCooldownBypassThread = nil
    end)
end

function MAWWW_StopSlasherCooldownBypass()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local jason = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Killers") and rs.Remotes.Killers:FindFirstChild("Jason")
        if jason then
            if not VD.KillerInfLakeMist then
                local lm = jason:FindFirstChild("LakeMist")
                if lm then lm:FireServer(false) end
            end
            if not VD.KillerInfPursuit then
                local ps = jason:FindFirstChild("Pursuit")
                if ps then ps:FireServer(false) end
            end
        end
    end)
end

--========================================================--
-- BYPASS COOLDOWN (Abyss)
--========================================================--
getgenv().MAWWW_AbyssCooldownBypassConnection = nil
getgenv().MAWWW_CorruptHandlerFunc = nil

function MAWWW_StartAbyssCooldownBypass()
    if not getgenv().MAWWW_CorruptHandlerFunc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and islclosure(v) then
                local constants = debug.getconstants(v)
                if table.find(constants, "corrupt") and table.find(constants, "Immobile") then
                    getgenv().MAWWW_CorruptHandlerFunc = v
                    break
                end
            end
        end
    end

    if not getgenv().MAWWW_CorruptHandlerFunc then
        return
    end

    if getgenv().MAWWW_AbyssCooldownBypassConnection then
        getgenv().MAWWW_AbyssCooldownBypassConnection:Disconnect()
    end

    getgenv().MAWWW_AbyssCooldownBypassConnection = RunService.Heartbeat:Connect(function()
        if not VD.KillerInfAbyss then return end
        if getgenv().MAWWW_CorruptHandlerFunc then
            local upvalues = debug.getupvalues(getgenv().MAWWW_CorruptHandlerFunc)
            for idx, val in pairs(upvalues) do
                if type(val) == "boolean" then
                    if val == false then
                        debug.setupvalue(getgenv().MAWWW_CorruptHandlerFunc, idx, true)
                    end
                end
            end
        end
    end)
end

function MAWWW_StopAbyssCooldownBypass()
    if getgenv().MAWWW_AbyssCooldownBypassConnection then
        getgenv().MAWWW_AbyssCooldownBypassConnection:Disconnect()
        getgenv().MAWWW_AbyssCooldownBypassConnection = nil
    end
end

--========================================================--
-- BYPASS COOLDOWN (Jeff / The Killer)
--========================================================--
getgenv().MAWWW_JeffCooldownBypassThread = nil

function MAWWW_StartJeffCooldownBypass()
    if getgenv().MAWWW_JeffCooldownBypassThread then return end
    getgenv().MAWWW_JeffCooldownBypassThread = task.spawn(function()
        local rs = game:GetService("RunService")
        local player = game:GetService("Players").LocalPlayer

        while task.wait() do
            if not VD.KillerInfFrenzy then
                break
            end
            pcall(function()
                local char = player.Character
                if char and char:GetAttribute("Frenzy") ~= true then
                    char:SetAttribute("Frenzy", true)
                end
            end)
        end

        getgenv().MAWWW_JeffCooldownBypassThread = nil
    end)
end

function MAWWW_StopJeffCooldownBypass()
    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character
        if char and char:GetAttribute("Frenzy") == true then
            char:SetAttribute("Frenzy", false)

            local killer = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes"):FindFirstChild("Killers"):FindFirstChild("Killer")
            if killer then
                local deact = killer:FindFirstChild("Deactivatefromclient")
                if deact then
                    deact:FireServer()
                end
            end
        end
    end)
end

--========================================================--
-- KING SOURCE BYPASS (NEW ADDITION)
--========================================================--
getgenv().MAWWW_KingSourceThread = nil
function MAWWW_StartKingSourceBypass()
    if getgenv().MAWWW_KingSourceThread then return end
    getgenv().MAWWW_KingSourceThread = task.spawn(function()
        while not VD.Destroyed do
            task.wait(0.2)
            if not (VD.KillerBypassSkill or VD.KillerBypassCD or VD.KillerInfSkill) then continue end
            local char = Player.Character
            if char then
                pcall(function()
                    -- Bypass Attributes for King's Scourge
                    for _, attr in ipairs({"KingCooldown", "ScourgeCooldown", "KingCharge", "ScourgeCharge", "KingSkillCooldown", "KingsScourgeCooldown"}) do
                        local v = char:GetAttribute(attr)
                        if v ~= nil and type(v) == "number" and v > 0 then
                            char:SetAttribute(attr, 0)
                        end
                    end
                    
                    -- Bypass Remotes for King's Scourge / King
                    local remotes = GetRemotes()
                    if remotes then
                        local killers = remotes:FindFirstChild("Killers")
                        if killers then
                            local kingFolder = killers:FindFirstChild("King") or killers:FindFirstChild("KingsScourge") or killers:FindFirstChild("Scourge")
                            if kingFolder then
                                for _, ev in ipairs(kingFolder:GetChildren()) do
                                    if ev:IsA("RemoteEvent") then
                                        pcall(function() ev:FireServer() end)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
        getgenv().MAWWW_KingSourceThread = nil
    end)
end

function SetAllKillerNoCooldown(enabled)
    enabled = enabled and true or false
    VD.KillerBypassSkill = enabled
    VD.KillerInfLunge = enabled
    VD.KillerInfFrenzy = enabled
    VD.KillerInfLakeMist = enabled
    VD.KillerInfPursuit = enabled
    VD.KillerInfGrab = enabled
    VD.KillerInfAbyss = enabled
    VD.KillerInfSkill = enabled

    if enabled then
        pcall(MAWWW_StartAbyssCooldownBypass)
        pcall(BYPASS_StartHiddenCooldownBypass)
        pcall(MAWWW_StartJeffCooldownBypass)
        pcall(MAWWW_StartSlasherCooldownBypass)
        pcall(MAWWW_StartKingSourceBypass)
        pcall(setMyersGrab, true)
    else
        pcall(MAWWW_StopAbyssCooldownBypass)
        pcall(MAWWW_StopJeffCooldownBypass)
        pcall(MAWWW_StopSlasherCooldownBypass)
        pcall(setMyersGrab, false)
    end

    if getgenv().MAWWW_QuickRefresh then
        pcall(getgenv().MAWWW_QuickRefresh)
    end
end
getgenv().MAWWW_SetAllKillerNoCooldown = SetAllKillerNoCooldown

RegToggle(Tabs.Killer, "Bypass Skill (All Killers)", "Enable all killer bypasses", false, "KillerBypassSkill", function(v)
    pcall(SetAllKillerNoCooldown, v)
end)

RegButton(Tabs.Killer, "Myers Grab Now (Hotkey H)", "Force Myers grab", function()
    if MyersGrabData.Enabled then
        pcall(doMyersGrab)
    else
        pcall(function() notify("Myers Grab", "Enable 'Bypass Skill (All Killers)' first.", 3) end)
    end
end)

--========================================================--
-- Counter Hacks
--========================================================--
RegDivider(Tabs.Killer)
RegLabel(Tabs.Killer, "Counter Hacks")
FakeParryAnims = {
    ["Enten"] = "rbxassetid://127096285501517", ["Stopwatch"] = "rbxassetid://81793464499285",
    ["Fih"] = "rbxassetid://123307242865945", ["BloodShield"] = "rbxassetid://75939529748815",
}
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.3)
        if VD.FakeAttack and GetRole() == "Killer" then
            local char = Player.Character
            if char then
                local Animator = char:FindFirstChild("Humanoid") and char.Humanoid:FindFirstChild("Animator")
                if Animator then
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    local near = false
                    if myRoot then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= Player and IsSurvivor(p) then
                                local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                                if r and (myRoot.Position - r.Position).Magnitude <= 15 then near = true; break end
                            end
                        end
                    end
                    if near then
                        pcall(function()
                            local bait = Instance.new("Animation")
                            bait.AnimationId = "rbxassetid://117042998468241"
                            local track = Animator:LoadAnimation(bait)
                            track:Play(); track:AdjustWeight(0); task.wait(0.05); track:Stop()
                        end)
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.4)
        if VD.FakeParry and GetRole() == "Survivor" then
            local char = Player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local anim = hum:FindFirstChildOfClass("Animator")
                    if anim then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = FakeParryAnims[VD.FakeParryAnim] or FakeParryAnims["Enten"]
                        pcall(function()
                            local track = anim:LoadAnimation(animation)
                            track.Priority = Enum.AnimationPriority.Action
                            track:Play()
                        end)
                    end
                end
            end
        end
    end
end)
RegToggle(Tabs.Killer, "Fake Attack (Bait Auto-Parry)", "Fake attack animation", false, "FakeAttack")
RegToggle(Tabs.Killer, "Fake Parry (Animation Only)", "Fake parry animation", false, "FakeParry")
RegDropdown(Tabs.Killer, "Fake Parry Animation", "Animation style", {"Enten", "Stopwatch", "Fih", "BloodShield"}, "Enten", false, "FakeParryAnim")

RegDivider(Tabs.Killer)
RegLabel(Tabs.Killer, "Killer Utilities")
RegToggle(Tabs.Killer, "Destroy Pallets", "Auto destroy pallets", false, "KillerDestroyPallets")
RegToggle(Tabs.Killer, "Auto Kick Generator", "Auto kick generators", false, "KillerAutoKickGen")
RegToggle(Tabs.Killer, "Auto Hook", "Auto hook carried survivor", false, "KillerAutoHook")
RegToggle(Tabs.Killer, "No Slowdown", "Ignore slowdown", false, "KillerNoSlowdown")

IsBreakingPallet = false
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.KillerDestroyPallets and GetRole() == "Killer" and not IsBreakingPallet then
            local char = Player.Character
            local root = getRoot()
            if char and root then
                local stunned = char:GetAttribute("IsStunned"); local immobile = char:GetAttribute("Immobile"); local carrying = char:GetAttribute("IsCarrying")
                if not (stunned or immobile or carrying) then
                    local pts = CollectionService:GetTagged("PalletPointSlide")
                    local nearest, minDist = nil, 6
                    for _, p in ipairs(pts) do
                        if p:IsA("BasePart") then
                            local d = (p.Position - root.Position).Magnitude
                            if d < minDist then minDist = d; nearest = p end
                        end
                    end
                    if nearest then
                        IsBreakingPallet = true
                        task.spawn(function()
                            pcall(function()
                                local r = GetRemotes()
                                local pf = r and r:FindFirstChild("Pallet")
                                local j = pf and pf:FindFirstChild("Jason")
                                if j then
                                    local dg = j:FindFirstChild("Destroy-Global"); local commit = j:FindFirstChild("PalletBreakCommit")
                                    if dg then dg:FireServer(nearest) end
                                    if commit then commit:FireServer(nearest) end
                                end
                            end)
                            task.wait(1); IsBreakingPallet = false
                        end)
                    end
                end
            end
        end
    end
end)
IsBreakingGen = false
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.3)
        if VD.KillerAutoKickGen and GetRole() == "Killer" and not IsBreakingGen then
            local char = Player.Character
            local root = getRoot()
            if char and root then
                local stunned = char:GetAttribute("IsStunned"); local immobile = char:GetAttribute("Immobile"); local carrying = char:GetAttribute("IsCarrying")
                if not (stunned or immobile or carrying) then
                    local pts = CollectionService:GetTagged("GeneratorPoint")
                    local nearest, minDist = nil, 6
                    for _, p in ipairs(pts) do
                        if p:IsA("BasePart") then
                            local genModel = p.Parent
                            if genModel then
                                local progress = genModel:GetAttribute("RepairProgress") or 0
                                local kickcount = genModel:GetAttribute("kickcount") or 0
                                if progress > 0 and progress < 100 and kickcount <= 7 then
                                    local d = (p.Position - root.Position).Magnitude
                                    if d < minDist then minDist = d; nearest = p end
                                end
                            end
                        end
                    end
                    if nearest then
                        IsBreakingGen = true
                        task.spawn(function()
                            pcall(function()
                                local r = GetRemotes()
                                local g = r and r:FindFirstChild("Generator")
                                if g then
                                    local ev = g:FindFirstChild("BreakGenEvent"); local cm = g:FindFirstChild("BreakGenCommit")
                                    if ev then ev:FireServer(nearest) end
                                    if cm then cm:FireServer(nearest) end
                                end
                            end)
                            task.wait(1); IsBreakingGen = false
                        end)
                    end
                end
            end
        end
    end
end)
IsAutoHooking = false
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.3)
        if VD.KillerAutoHook and GetRole() == "Killer" and not IsAutoHooking then
            local root = getRoot(); local char = Player.Character
            if root and char then
                local isCarrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
                if isCarrying then
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        local closestHook, hDist = nil, math.huge
                        for _, obj in ipairs(map:GetDescendants()) do
                            if obj:IsA("Model") and obj.Name == "Hook" then
                                local hp = obj:FindFirstChildWhichIsA("BasePart", true)
                                if hp then
                                    local d = (hp.Position - root.Position).Magnitude
                                    if d < hDist then hDist = d; closestHook = obj end
                                end
                            end
                        end
                        if closestHook then
                            IsAutoHooking = true
                            task.spawn(function()
                                local hp = closestHook:FindFirstChildWhichIsA("BasePart", true)
                                if hp then
                                    root.CFrame = hp.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.4)
                                    pcall(function()
                                        local carryFolder = GetRemotes():FindFirstChild("Carry")
                                        local ev = carryFolder and carryFolder:FindFirstChild("HookEvent")
                                        local commit = carryFolder and carryFolder:FindFirstChild("HookCommit")
                                        if ev then ev:FireServer(hp) end
                                        if commit then commit:FireServer(hp) end
                                    end)
                                end
                                task.wait(1); IsAutoHooking = false
                            end)
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.KillerNoSlowdown and GetRole() == "Killer" then
            local hum = getHum()
            if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        end
    end
end)

--========================================================--
-- AIM TAB
--========================================================--
RegLabel(Tabs.Aim, "═══ Aimlock ═══")
Aimlock = { Holding = false }
CachedSCPAimlock = {}
for _, obj in ipairs(Workspace:GetDescendants()) do if string.find(string.lower(obj.Name), "scp") then CachedSCPAimlock[obj] = true end end
Workspace.DescendantAdded:Connect(function(obj) if string.find(string.lower(obj.Name), "scp") then CachedSCPAimlock[obj] = true end end)
Workspace.DescendantRemoving:Connect(function(obj) CachedSCPAimlock[obj] = nil end)
function isVisibleAimlock(part)
    local cam = workspace.CurrentCamera
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Player.Character}
    local origin = cam.CFrame.Position
    local direction = (part.Position - origin)
    local result = workspace:Raycast(origin, direction, rp)
    if not result then return true end
    return result.Instance:IsDescendantOf(part.Parent)
end
function getClosestAimlockTarget()
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, shortest = nil, VD.AimlockFOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Team then
            local valid = false
            if VD.AimlockTargetMode == "Killer" and IsKiller(p) then valid = true
            elseif VD.AimlockTargetMode == "Survivor" and IsSurvivor(p) then valid = true end
            if valid then
                local hrp = p.Character:FindFirstChild(VD.AimlockAimPart)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local pos, visible = cam:WorldToViewportPoint(hrp.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then
                            if not (VD.AimlockVisCheck and not isVisibleAimlock(hrp)) then
                                shortest = dist; closest = hrp
                            end
                        end
                    end
                end
            end
        end
    end
    if VD.AimlockTargetMode == "SCP" then
        for obj in pairs(CachedSCPAimlock) do
            if obj and obj.Parent then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    local pos, visible = cam:WorldToViewportPoint(part.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then shortest = dist; closest = part end
                    end
                end
            end
        end
    end
    return closest
end
RunService.RenderStepped:Connect(function()
    if not VD.AimlockEnabled or not Aimlock.Holding then return end
    local cam = workspace.CurrentCamera
    local target = getClosestAimlockTarget()
    if not target then return end
    local pos = target.Position
    if VD.AimlockPredict > 0 then pos = pos + (target.AssemblyLinearVelocity * VD.AimlockPredict) end
    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, pos), VD.AimlockStrength)
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Aimlock.Holding = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Aimlock.Holding = false end
end)
RegToggle(Tabs.Aim, "Enable Aimlock (Hold RMB)", "Aimlock on right mouse", false, "AimlockEnabled")
RegToggle(Tabs.Aim, "Visibility Check", "Require line of sight", true, "AimlockVisCheck")
RegDropdown(Tabs.Aim, "Target Mode", "Target team", {"Killer", "Survivor", "SCP"}, "Killer", false, "AimlockTargetMode")
RegDropdown(Tabs.Aim, "Target Part", "Body part", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, "HumanoidRootPart", false, "AimlockAimPart")
RegSlider(Tabs.Aim, "FOV", "Aimlock FOV", 250, 50, 1000, 10, "AimlockFOV")
RegSlider(Tabs.Aim, "Strength", "Aim strength", 1, 0.1, 1, 0.05, "AimlockStrength")
RegSlider(Tabs.Aim, "Prediction", "Prediction time", 0.12, 0, 1, 0.01, "AimlockPredict")

--========================================================--
-- Shared Veil Visuals
--========================================================--
VeilSharedVisuals = (function()
    local V = { FOVOutline = nil, FOVFill = nil, TracerLine = nil, TargetOutline = nil, TargetFill = nil, PlayerCircles = {}, NameLabels = {}, HasDrawing = false, LastFovRadius = -1 }
    pcall(function() if typeof(Drawing) == "table" and Drawing.new then V.HasDrawing = true end end)
    local COLORS = { FOV = Color3.fromRGB(0, 220, 255), FOVFill = Color3.fromRGB(0, 220, 255), Player = Color3.fromRGB(255, 255, 255), Target = Color3.fromRGB(255, 0, 0), Tracer = Color3.fromRGB(255, 255, 255), Label = Color3.fromRGB(60, 255, 60), LabelEnemy = Color3.fromRGB(255, 90, 90) }
    local function InitDrawing()
        if not V.HasDrawing then return end
        if not V.FOVOutline then V.FOVOutline = Drawing.new("Circle"); V.FOVOutline.Color = COLORS.FOV; V.FOVOutline.Thickness = 2; V.FOVOutline.Filled = false; V.FOVOutline.Transparency= 0.85; V.FOVOutline.Visible = false end
        if not V.FOVFill then V.FOVFill = Drawing.new("Circle"); V.FOVFill.Color = COLORS.FOVFill; V.FOVFill.Thickness = 1; V.FOVFill.Filled = false; V.FOVFill.Transparency = 0.12; V.FOVFill.Visible = false end
        if not V.TracerLine then V.TracerLine = Drawing.new("Line"); V.TracerLine.Color = COLORS.Tracer; V.TracerLine.Thickness = 1.5; V.TracerLine.Transparency = 0.75; V.TracerLine.Visible = false end
        if not V.TargetOutline then V.TargetOutline = Drawing.new("Circle"); V.TargetOutline.Color = COLORS.Target; V.TargetOutline.Thickness = 2; V.TargetOutline.Filled = false; V.TargetOutline.Transparency = 1; V.TargetOutline.Visible = false end
        if not V.TargetFill then V.TargetFill = Drawing.new("Circle"); V.TargetFill.Color = COLORS.Target; V.TargetFill.Thickness = 1; V.TargetFill.Filled = false; V.TargetFill.Transparency = 0.4; V.TargetFill.Visible = false end
    end
    local function GetPlayerCircle(plr)
        if not V.HasDrawing then return nil end
        local c = V.PlayerCircles[plr]; if c then return c end
        local outline = Drawing.new("Circle"); outline.Color = COLORS.Player; outline.Thickness = 1.5; outline.Filled = false; outline.Transparency = 1; outline.Visible = false
        local fill = Drawing.new("Circle"); fill.Color = COLORS.Player; fill.Thickness = 1; fill.Filled = false; fill.Transparency = 0.25; fill.Visible = false
        c = { outline = outline, fill = fill }; V.PlayerCircles[plr] = c; return c
    end
    local function GetNameLabel(plr)
        local label = V.NameLabels[plr]; if label and label.Parent then return label end
        local char = plr.Character; if not char then return nil end
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then return nil end
        local bb = Instance.new("BillboardGui")
        bb.Name = "Veil_NameLabel"; bb.Size = UDim2.new(0, 240, 0, 22); bb.StudsOffset = Vector3.new(0, 3.2, 0); bb.AlwaysOnTop = true; bb.Adornee = head; bb.Parent = head
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Text"; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency= 1
        lbl.TextColor3 = COLORS.Label; lbl.TextStrokeTransparency= 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextSize = 14; lbl.Font = Enum.Font.GothamBold; lbl.Text = plr.Name; lbl.Parent = bb
        V.NameLabels[plr] = bb; return bb
    end
    function V.UpdateFOV(center, radius, visible)
        InitDrawing(); if not V.HasDrawing then return end
        if V.FOVOutline then V.FOVOutline.Position = center; V.FOVOutline.Radius = radius; V.FOVOutline.Visible = visible end
        if V.FOVFill then V.FOVFill.Position = center; V.FOVFill.Radius = radius; V.FOVFill.Visible = visible end
        V.LastFovRadius = radius
    end
    function V.UpdateTarget(screenPos, radius, visible)
        InitDrawing(); if not V.HasDrawing then return end
        if V.TargetOutline then V.TargetOutline.Position = screenPos; V.TargetOutline.Radius = radius; V.TargetOutline.Visible = visible end
        if V.TargetFill then V.TargetFill.Position = screenPos; V.TargetFill.Radius = radius; V.TargetFill.Visible = visible end
    end
    function V.UpdateTracer(fromPos, toPos, visible)
        InitDrawing(); if not V.HasDrawing then return end
        if V.TracerLine then V.TracerLine.From = fromPos; V.TracerLine.To = toPos; V.TracerLine.Visible = visible end
    end
    function V.UpdatePlayerMarker(plr, screenPos, radius, visible)
        local c = GetPlayerCircle(plr); if not c then return end
        if c.outline then c.outline.Position = screenPos; c.outline.Radius = radius; c.outline.Visible = visible end
        if c.fill then c.fill.Position = screenPos; c.fill.Radius = radius; c.fill.Visible = visible end
    end
    function V.HideAllPlayerMarkers()
        for _, c in pairs(V.PlayerCircles) do
            if c.outline then c.outline.Visible = false end
            if c.fill then c.fill.Visible = false end
        end
    end
    function V.UpdateNameLabel(plr, text, visible, isTarget)
        if not visible then local lbl = V.NameLabels[plr]; if lbl then lbl.Enabled = false end; return end
        local bb = GetNameLabel(plr); if not bb then return end
        bb.Enabled = true
        local lbl = bb:FindFirstChild("Text")
        if lbl then lbl.Text = text; lbl.TextColor3 = isTarget and COLORS.LabelEnemy or COLORS.Label end
    end
    function V.HideAllNameLabels() for _, bb in pairs(V.NameLabels) do if bb then bb.Enabled = false end end end
    function V.HideAll()
        if not V.HasDrawing then V.HideAllNameLabels(); return end
        if V.FOVOutline then V.FOVOutline.Visible = false end
        if V.FOVFill then V.FOVFill.Visible = false end
        if V.TracerLine then V.TracerLine.Visible = false end
        if V.TargetOutline then V.TargetOutline.Visible = false end
        if V.TargetFill then V.TargetFill.Visible = false end
        V.HideAllPlayerMarkers(); V.HideAllNameLabels()
    end
    function V.CleanupPlayer(plr)
        local c = V.PlayerCircles[plr]
        if c then
            if c.outline then pcall(function() c.outline:Remove() end) end
            if c.fill then pcall(function() c.fill:Remove() end) end
            V.PlayerCircles[plr] = nil
        end
        local bb = V.NameLabels[plr]
        if bb then pcall(function() bb:Destroy() end); V.NameLabels[plr] = nil end
    end
    Players.PlayerRemoving:Connect(function(p) V.CleanupPlayer(p) end)
    return V
end)()

--========================================================--
-- Silent Veil V1
--========================================================--
VeilState = { target = nil, lookVector = nil, velHistory = {} }
function Veil_IsSurvivorVeil(p) if not p or not p.Team or not p.Team.Name then return false end; return string.find(string.lower(p.Team.Name), "survivor", 1, true) ~= nil end
function Veil_solvePitch(p, d, dy)
    d = math.max(d, 0.1)
    local s2 = p.v0 * p.v0
    local root = s2 * s2 - p.g * (p.g * d * d + 2 * dy * s2)
    if root < 0 then root = 0 end
    local tanTheta = (s2 - math.sqrt(root)) / (p.g * d)
    local theta = math.atan(tanTheta)
    local cosT = math.max(math.cos(theta), 0.001)
    local t = d / (p.v0 * cosT)
    return theta, t
end
function Veil_getCharacterVelocity(char)
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root or not root:IsA("BasePart") then return Vector3.zero end
    local now = os.clock()
    local last = VeilState.velHistory[char]
    local measured = Vector3.zero
    if last and now - last.t > 0.02 then
        measured = (root.Position - last.pos) / (now - last.t)
        if measured.Magnitude > 150 then measured = last.smooth or Vector3.zero end
    end
    local smooth = last and last.smooth or measured
    smooth = smooth:Lerp(measured, 0.65)
    VeilState.velHistory[char] = { pos = root.Position, t = now, smooth = smooth }
    if smooth.Magnitude < 1 then return Vector3.zero end
    return Vector3.new(smooth.X, 0, smooth.Z)
end
Players.PlayerRemoving:Connect(function(p) if p.Character then VeilState.velHistory[p.Character] = nil end end)
function Veil_WallCheck(origin, targetPos, targetChar)
    if not VD.VeilWallCheck then return true end
    return VD_WallCheckVisible(origin, targetPos, targetChar)
end
function Veil_UpdateAimbot()
    if GetRole() ~= "Killer" then VeilState.target = nil; VeilState.lookVector = nil; VeilSharedVisuals.HideAll(); return end
    local cam = Workspace.CurrentCamera; if not cam then return end
    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local showFov = VD.VeilShowFOV and VD.VeilEnabled
    VeilSharedVisuals.UpdateFOV(center, VD.VeilFOV or 150, showFov)
    if not VD.VeilEnabled then VeilState.target = nil; VeilState.lookVector = nil; VeilSharedVisuals.HideAll(); return end
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then VeilSharedVisuals.HideAll(); return end
    local nearest, bestDist = nil, math.huge
    local bestStudDist = VD.VeilMaxDist or 400
    local detected = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and Veil_IsSurvivorVeil(p) and p.Character then
            local pc = p.Character
            local isDown = pc:GetAttribute("Knocked") == true or pc:GetAttribute("HookProgressDepleting") == true or pc:GetAttribute("IsHooked") == true
            local hum = pc:FindFirstChildOfClass("Humanoid")
            local targetPart = pc:FindFirstChild("UpperTorso") or pc:FindFirstChild("Torso") or pc:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and targetPart then
                local inFOV = true
                if VD.VeilIgnoreDown and isDown then inFOV = false end
                if inFOV and not Veil_WallCheck(hrp.Position, targetPart.Position, pc) then inFOV = false end
                local sp, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if inFOV and onScreen and sp.Z > 0 then
                    local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    local studDist = (targetPart.Position - hrp.Position).Magnitude
                    if screenDist <= (VD.VeilFOV or 150) and studDist <= bestStudDist then
                        table.insert(detected, { plr = p, char = pc, hum = hum, targetPart= targetPart, scrPos = Vector2.new(sp.X, sp.Y), studDist = studDist, health = math.floor(hum.Health / hum.MaxHealth * 100 + 0.5) })
                        if screenDist < bestDist then bestDist = screenDist; nearest = p end
                    end
                end
            end
        end
    end
    local showMarkers = VD.VeilShowPlayerMarkers; local showNames = VD.VeilShowNameLabels; local showTarget = VD.VeilShowTargetMarker; local showTracer = VD.VeilShowTracer
    local isTargetPlr = nearest
    for _, info in ipairs(detected) do
        local plr = info.plr
        local isTarget = (plr == isTargetPlr)
        if showMarkers then
            local rad = math.clamp(1500 / math.max(info.studDist, 1), 10, 55)
            local col = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
            if VeilSharedVisuals.PlayerCircles[plr] then
                local c = VeilSharedVisuals.PlayerCircles[plr]
                if c.outline then c.outline.Color = col end
                if c.fill then c.fill.Color = col end
            end
            VeilSharedVisuals.UpdatePlayerMarker(plr, info.scrPos, rad, true)
        else VeilSharedVisuals.UpdatePlayerMarker(plr, Vector2.new(0,0), 0, false) end
        if showNames then
            local labelText = string.format("%s [%d%%] [%dm]", plr.DisplayName or plr.Name, info.health, math.floor(info.studDist))
            VeilSharedVisuals.UpdateNameLabel(plr, labelText, true, isTarget)
        else VeilSharedVisuals.UpdateNameLabel(plr, "", false, false) end
    end
    local detectedSet = {}
    for _, info in ipairs(detected) do detectedSet[info.plr] = true end
    for plr, _ in pairs(VeilSharedVisuals.PlayerCircles) do
        if not detectedSet[plr] then
            VeilSharedVisuals.UpdatePlayerMarker(plr, Vector2.new(0,0), 0, false)
            VeilSharedVisuals.UpdateNameLabel(plr, "", false, false)
        end
    end
    if nearest and nearest.Character then
        local tpPart = nearest.Character:FindFirstChild("UpperTorso") or nearest.Character:FindFirstChild("Torso") or nearest.Character:FindFirstChild("HumanoidRootPart")
        if tpPart then
            local tp = tpPart.Position
            local hand = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
            local origin = (hand and hand:IsA("BasePart")) and hand.Position or hrp.Position
            local dir = tp - origin
            local dist = dir.Magnitude
            if dist > 0.1 and dist <= (VD.VeilMaxDist or 400) then
                local isAuraActive = char:GetAttribute("special") == true
                local prof
                if isAuraActive then prof = { v0 = VD.VeilAuraSpearSpeed or 165, g = VD.VeilAuraSpearGravity or 96.5, windup = 0.10, latency = 0.04, maxlead = 25, scale = VD.VeilLeadMultiplier or 1.4 }
                else prof = { v0 = VD.VeilSpearSpeed or 165, g = VD.VeilGravity or 103, windup = 0.10, latency = 0.04, maxlead = 45, scale = VD.VeilLeadMultiplier or 1.4 } end
                local aimPoint = tp
                if VD.VeilAutoPredict then
                    local vel = Veil_getCharacterVelocity(nearest.Character)
                    if vel.Magnitude > 0.5 then
                        local h0 = Vector3.new(dir.X, 0, dir.Z)
                        local _, tFlight = Veil_solvePitch(prof, h0.Magnitude, dir.Y)
                        local ping = 0.08
                        pcall(function() ping = math.clamp(Player:GetNetworkPing(), 0, 0.35) end)
                        local delay = tFlight + prof.windup + ping + prof.latency
                        for _ = 1, 2 do
                            local lead = vel * delay * prof.scale
                            local maxLead = math.clamp(dist * 0.6, 3, prof.maxlead)
                            if lead.Magnitude > maxLead then lead = lead.Unit * maxLead end
                            aimPoint = tp + lead
                            local ad = aimPoint - origin
                            local ah = Vector3.new(ad.X, 0, ad.Z)
                            local _, t2 = Veil_solvePitch(prof, math.max(ah.Magnitude, 0.1), ad.Y)
                            delay = t2 + prof.windup + ping + prof.latency
                        end
                    end
                end
                if VD.VeilWallCheck then
                    local predictedVisible = VD_WallCheckVisible(origin, aimPoint, nil)
                    if not predictedVisible then aimPoint = tp end
                    if not VD_WallCheckVisible(origin, aimPoint, nearest.Character) then
                        VeilState.target = nil; VeilState.lookVector = nil
                        VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
                        VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false); return
                    end
                end
                local adir = aimPoint - origin
                local ah = Vector3.new(adir.X, 0, adir.Z)
                local ahDist = ah.Magnitude
                local pitch = Veil_solvePitch(prof, ahDist, adir.Y)
                if ahDist > 0.001 then VeilState.lookVector = ah.Unit * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
                else VeilState.lookVector = adir.Unit end
                VeilState.target = nearest
                if showTarget and tpPart then
                    local sp, vis = cam:WorldToViewportPoint(tpPart.Position)
                    if vis and sp.Z > 0 then
                        local rad = math.clamp(1500 / math.max(dist, 1), 14, 60)
                        VeilSharedVisuals.UpdateTarget(Vector2.new(sp.X, sp.Y), rad, true)
                        if showTracer then
                            local bottomCenter = Vector2.new(center.X, viewport.Y)
                            VeilSharedVisuals.UpdateTracer(bottomCenter, Vector2.new(sp.X, sp.Y), true)
                        else VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false) end
                    else
                        VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
                        VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
                    end
                else
                    VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
                    VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
                end
            end
        end
    else
        VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
        VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
        VeilState.target = nil; VeilState.lookVector = nil
    end
end
VeilHookState = { remoteHooked = false }
function Veil_setupInterceptor()
    if VeilHookState.remoteHooked then return end
    if typeof(hookmetamethod) ~= "function" then return end
    task.spawn(function()
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" then
                    if (self.Name == "Spearthrow" or self.Name == "Spear" or self.Name == "Throw") and VD.VeilEnabled and typeof(VeilState.lookVector) == "Vector3" and GetRole() == "Killer" then
                        local args = {...}
                        if typeof(args[1]) == "Vector3" then args[1] = VeilState.lookVector end
                        return oldNamecall(self, unpack(args))
                    end
                end
                return oldNamecall(self, ...)
            end)
            VeilHookState.remoteHooked = true
        end)
    end)
end
Veil_setupInterceptor()
RunService.RenderStepped:Connect(function() pcall(Veil_UpdateAimbot) end)
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Silent Veil V1")
RegToggle(Tabs.Aim, "Enable Silent Veil V1", "Silent spear aim", false, "VeilEnabled")
RegToggle(Tabs.Aim, "V1 Show FOV Circle (Cyan)", "Show FOV circle", true, "VeilShowFOV")
RegToggle(Tabs.Aim, "V1 Show Player Circle Markers", "Show player markers", true, "VeilShowPlayerMarkers")
RegToggle(Tabs.Aim, "V1 Show Target Marker (Red)", "Show target marker", true, "VeilShowTargetMarker")
RegToggle(Tabs.Aim, "V1 Show Tracer / Aim Line", "Show tracer line", true, "VeilShowTracer")
RegToggle(Tabs.Aim, "V1 Show Name + HP + Distance", "Show name labels", true, "VeilShowNameLabels")
RegToggle(Tabs.Aim, "V1 Auto Predict", "Auto predict movement", true, "VeilAutoPredict")
RegToggle(Tabs.Aim, "[NEW] V1 Wall Check", "Require line of sight", false, "VeilWallCheck")
RegToggle(Tabs.Aim, "[NEW] V1 Ignore Downed", "Skip downed survivors", true, "VeilIgnoreDown")
RegSlider(Tabs.Aim, "V1 FOV Size", "FOV radius", 150, 50, 500, 10, "VeilFOV")
RegSlider(Tabs.Aim, "V1 Max Distance", "Max target distance", 400, 50, 400, 10, "VeilMaxDist")
RegSlider(Tabs.Aim, "V1 Spear Speed", "Spear speed", 165, 50, 400, 5, "VeilSpearSpeed")
RegSlider(Tabs.Aim, "V1 Spear Gravity", "Spear gravity", 103, 10, 300, 5, "VeilGravity")
RegSlider(Tabs.Aim, "V1 Aura Spear Speed", "Aura spear speed", 165, 50, 400, 5, "VeilAuraSpearSpeed")
RegSlider(Tabs.Aim, "V1 Aura Spear Gravity", "Aura spear gravity", 96, 10, 300, 5, "VeilAuraSpearGravity")
RegSlider(Tabs.Aim, "V1 Lead Multiplier", "Lead multiplier", 1.4, 0.1, 5, 0.1, "VeilLeadMultiplier")

--========================================================--
-- Crosshair
--========================================================--
CrosshairGui = nil
function VD_UpdateCrosshair()
    if CrosshairGui then pcall(function() CrosshairGui:Destroy() end); CrosshairGui = nil end
    if not VD.CrossEnabled then return end
    local style = VD.CrossStyle; local size = tonumber(VD.CrossSize) or 3; local gap = tonumber(VD.CrossGap) or 6
    local thick = tonumber(VD.CrossThickness) or 4
    local color = Color3.fromRGB(VD.CrossColorR, VD.CrossColorG, VD.CrossColorB)
    CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "MAWWW_Crosshair"; CrosshairGui.DisplayOrder = 999999
    CrosshairGui.IgnoreGuiInset = true; CrosshairGui.Parent = PlayerGui
    local centerFrame = Instance.new("Frame")
    centerFrame.BackgroundTransparency = 1
    centerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerFrame.Size = UDim2.new(0, 0, 0, 0); centerFrame.Parent = CrosshairGui
    if style == "Dot" then
        local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Size = UDim2.new(0, size * 2, 0, size * 2)
        dot.BackgroundColor3 = color; dot.BorderSizePixel = 0
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = dot
        dot.Parent = centerFrame
    elseif style == "Plus" or style == "X" then
        local length = size * 3
        for i = 1, 4 do
            local line = Instance.new("Frame"); line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.BackgroundColor3 = color; line.BorderSizePixel = 0
            local angle = (i - 1) * 90; if style == "X" then angle = angle + 45 end
            line.Rotation = angle; line.Size = UDim2.new(0, length, 0, thick)
            local rad = math.rad(angle); local dist = gap + (length / 2)
            line.Position = UDim2.new(0, math.floor(math.cos(rad) * dist + 0.5), 0, math.floor(math.sin(rad) * dist + 0.5))
            line.Parent = centerFrame
        end
    elseif style == "Box" then
        local half = gap + size * 2
        local t = Instance.new("Frame"); t.BackgroundColor3 = color; t.BorderSizePixel = 0
        t.AnchorPoint = Vector2.new(0.5, 0.5); t.Size = UDim2.new(0, half * 2 + thick, 0, thick)
        t.Position = UDim2.new(0, 0, 0, -half); t.Parent = centerFrame
        local b = t:Clone(); b.Position = UDim2.new(0, 0, 0, half); b.Parent = centerFrame
        local l = Instance.new("Frame"); l.BackgroundColor3 = color; l.BorderSizePixel = 0
        l.AnchorPoint = Vector2.new(0.5, 0.5); l.Size = UDim2.new(0, thick, 0, half * 2 - thick)
        l.Position = UDim2.new(0, -half, 0, 0); l.Parent = centerFrame
        local r = l:Clone(); r.Position = UDim2.new(0, half, 0, 0); r.Parent = centerFrame
    end
end
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Crosshair")
RegToggle(Tabs.Aim, "Enable Crosshair", "Show crosshair", false, "CrossEnabled", function(v) pcall(VD_UpdateCrosshair) end)
RegDropdown(Tabs.Aim, "Style", "Crosshair style", {"Dot", "Plus", "X", "Box"}, "Dot", false, "CrossStyle", function(v) pcall(VD_UpdateCrosshair) end)
RegSlider(Tabs.Aim, "Size", "Crosshair size", 3, 1, 30, 1, "CrossSize", function(v) pcall(VD_UpdateCrosshair) end)
RegSlider(Tabs.Aim, "Thickness", "Crosshair thickness", 4, 1, 20, 1, "CrossThickness", function(v) pcall(VD_UpdateCrosshair) end)
RegSlider(Tabs.Aim, "Gap", "Crosshair gap", 6, 0, 50, 1, "CrossGap", function(v) pcall(VD_UpdateCrosshair) end)
pcall(function()
    Tabs.Aim:Colorpicker({
        Title = "Crosshair Color", Flag = "CrossColorPicker", Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c)
            VD.CrossColorR = math.floor(c.R * 255); VD.CrossColorG = math.floor(c.G * 255); VD.CrossColorB = math.floor(c.B * 255)
            pcall(VD_UpdateCrosshair)
        end,
    })
end)

--========================================================--
-- Veil V2
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Silent Veil V2 (Advanced)")

VeilV2 = (function()
    local State = { target = nil, lookVector = nil, velHistory = {}, lastThrow = 0 }
    local function IsSurvivorTarget(p) if not p or not p.Team or not p.Team.Name then return false end; return string.find(string.lower(p.Team.Name), "survivor", 1, true) ~= nil end
    local function IsDownedChar(char)
        if not char then return false end
        if char:GetAttribute("Knocked") == true then return true end
        if char:GetAttribute("HookProgressDepleting") == true then return true end
        if char:GetAttribute("IsHooked") == true then return true end
        local state = char:GetAttribute("State"); return state == "Downed" or state == "Dead"
    end
    local function WallCheck(origin, targetPos, targetChar)
        if not VD.VeilV2WallCheck then return true end
        return VD_WallCheckVisible(origin, targetPos, targetChar)
    end
    local function SolvePitch(v0, g, d, dy)
        d = math.max(d, 0.1)
        local s2 = v0 * v0
        local root = s2 * s2 - g * (g * d * d + 2 * dy * s2)
        if root < 0 then root = 0 end
        local tanTheta = (s2 - math.sqrt(root)) / (g * d)
        local theta = math.atan(tanTheta); local cosT = math.max(math.cos(theta), 0.001); local t = d / (v0 * cosT)
        return theta, t
    end
    local function GetVelocity(char)
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root or not root:IsA("BasePart") then return Vector3.zero end
        local now = os.clock(); local last = State.velHistory[char]; local measured = Vector3.zero
        if last and now - last.t > 0.02 then
            measured = (root.Position - last.pos) / (now - last.t)
            if measured.Magnitude > 200 then measured = last.smooth or Vector3.zero end
        end
        local smooth = last and last.smooth or measured; smooth = smooth:Lerp(measured, 0.7)
        State.velHistory[char] = { pos = root.Position, t = now, smooth = smooth }
        if smooth.Magnitude < 1 then return Vector3.zero end
        return Vector3.new(smooth.X, 0, smooth.Z)
    end
    Players.PlayerRemoving:Connect(function(p) if p.Character then State.velHistory[p.Character] = nil end end)
    local function GetSpearRemote()
        local remotes = GetRemotes()
        local items = remotes and remotes:FindFirstChild("Items")
        local spear = items and items:FindFirstChild("Spear")
        if not spear then return nil end
        return spear:FindFirstChild("Spearthrow") or spear:FindFirstChild("Throw")
    end
    local function GetGunObject(char)
        if not char then return nil end
        local spear = char:FindFirstChild("Spear", true); if spear then return spear end
        return char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
    end
    local function PickAllTargets()
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return {}, nil end
        local cam = Workspace.CurrentCamera; if not cam then return {}, nil end
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local hand = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        local origin = (hand and hand:IsA("BasePart")) and hand.Position or hrp.Position
        local list = {}; local nearest, bestScreen = nil, math.huge
        local fov = tonumber(VD.VeilV2FOV) or 180; local maxDist = tonumber(VD.VeilV2MaxDist) or 600
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and IsSurvivorTarget(p) and p.Character then
                local pc = p.Character
                if not (VD.VeilV2IgnoreDown and IsDownedChar(pc)) then
                    local hum = pc:FindFirstChildOfClass("Humanoid")
                    local part = pc:FindFirstChild("UpperTorso") or pc:FindFirstChild("Torso") or pc:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and part then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on and sp.Z > 0 then
                            local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            local studDist = (part.Position - hrp.Position).Magnitude
                            if screenDist <= fov and studDist <= maxDist then
                                local visible = true
                                if VD.VeilV2WallCheck then visible = VD_WallCheckVisible(origin, part.Position, pc) end
                                if visible then
                                    table.insert(list, { plr = p, char = pc, hum = hum, targetPart = part, scrPos = Vector2.new(sp.X, sp.Y), studDist = studDist, health = math.floor(hum.Health / math.max(hum.MaxHealth, 1) * 100 + 0.5), screenDist = screenDist })
                                    if screenDist < bestScreen then bestScreen = screenDist; nearest = p end
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(list, function(a, b) if a.screenDist == b.screenDist then return a.studDist < b.studDist end; return a.screenDist < b.screenDist end)
        if list[1] then nearest = list[1].plr end
        return list, nearest
    end
    local function ComputeAim(targetPlr)
        if not targetPlr or not targetPlr.Character then return nil end
        local char = Player.Character; if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local targetPart = targetPlr.Character:FindFirstChild("UpperTorso") or targetPlr.Character:FindFirstChild("Torso") or targetPlr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetPart then return nil end
        local hand = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        local origin = (hand and hand:IsA("BasePart")) and hand.Position or hrp.Position
        local tp = targetPart.Position; local dir = tp - origin
        if dir.Magnitude < 0.1 then return nil end
        if not WallCheck(origin, tp, targetPlr.Character) then return nil end
        local isAura = char:GetAttribute("special") == true
        local prof
        if isAura then prof = { v0 = VD.VeilV2AuraSpearSpeed or 170, g = VD.VeilV2AuraSpearGravity or 95, windup = 0.09, latency = 0.04, maxlead = 30, scale = VD.VeilV2LeadMultiplier or 1.35 }
        else prof = { v0 = VD.VeilV2SpearSpeed or 170, g = VD.VeilV2SpearGravity or 100, windup = 0.09, latency = 0.04, maxlead = 50, scale = VD.VeilV2LeadMultiplier or 1.35 } end
        local aimPoint = tp
        local vel = GetVelocity(targetPlr.Character)
        if vel.Magnitude > 0.5 then
            local h0 = Vector3.new(dir.X, 0, dir.Z)
            local _, tFlight = SolvePitch(prof.v0, prof.g, h0.Magnitude, dir.Y)
            local ping = 0.08
            pcall(function() ping = math.clamp(Player:GetNetworkPing(), 0, 0.35) end)
            local delay = tFlight + prof.windup + ping + prof.latency
            local iters = math.max(1, tonumber(VD.VeilV2Iterations) or 3)
            local studDist = dir.Magnitude
            for _ = 1, iters do
                local lead = vel * delay * prof.scale
                local maxLead = math.clamp(studDist * 0.6, 3, prof.maxlead)
                if lead.Magnitude > maxLead then lead = lead.Unit * maxLead end
                aimPoint = tp + lead
                local ad = aimPoint - origin
                local ah = Vector3.new(ad.X, 0, ad.Z)
                local _, t2 = SolvePitch(prof.v0, prof.g, math.max(ah.Magnitude, 0.1), ad.Y)
                delay = t2 + prof.windup + ping + prof.latency
            end
        end
        if VD.VeilV2WallCheck then
            if not VD_WallCheckVisible(origin, aimPoint, nil) then aimPoint = tp end
            if not VD_WallCheckVisible(origin, aimPoint, targetPlr.Character) then return nil end
        end
        local adir = aimPoint - origin
        local ah = Vector3.new(adir.X, 0, adir.Z); local ahDist = ah.Magnitude
        local pitch = SolvePitch(prof.v0, prof.g, ahDist, adir.Y)
        local look
        if ahDist > 0.001 then look = ah.Unit * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
        else look = adir.Unit end
        return { target = targetPlr, origin = origin, aimPoint = aimPoint, look = look, char = char }
    end
    local function FireSpear(aim)
        if not aim or typeof(aim.look) ~= "Vector3" then return false end
        local remote = GetSpearRemote(); if not remote or not remote:IsA("RemoteEvent") then return false end
        local magnitude = aim.look.Magnitude
        if magnitude < 0.95 or magnitude > 1.05 then aim.look = aim.look.Unit end
        local gun = GetGunObject(aim.char); if not gun then return false end
        return pcall(function() remote:FireServer(gun, aim.look.Unit) end)
    end
    local function Update()
        if not VD.VeilV2Enabled then State.target = nil; State.lookVector = nil; VeilSharedVisuals.HideAll(); return end
        if GetRole() ~= "Killer" then VeilSharedVisuals.HideAll(); return end
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then VeilSharedVisuals.HideAll(); return end
        local cam = Workspace.CurrentCamera; if not cam then return end
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        VeilSharedVisuals.UpdateFOV(center, VD.VeilV2FOV or 180, VD.VeilV2ShowFOV ~= false)
        local all, nearest = PickAllTargets()
        local showMarkers = VD.VeilV2ShowPlayerMarkers; local showNames = VD.VeilV2ShowNameLabels
        local showTarget = VD.VeilV2ShowTargetMarker; local showTracer = VD.VeilV2ShowTracer
        for _, info in ipairs(all) do
            local isTgt = (info.plr == nearest)
            if showMarkers then
                local rad = math.clamp(1500 / math.max(info.studDist, 1), 10, 55)
                local col = isTgt and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
                local c = VeilSharedVisuals.PlayerCircles[info.plr]
                if c then if c.outline then c.outline.Color = col end; if c.fill then c.fill.Color = col end end
                VeilSharedVisuals.UpdatePlayerMarker(info.plr, info.scrPos, rad, true)
            else VeilSharedVisuals.UpdatePlayerMarker(info.plr, Vector2.new(0,0), 0, false) end
            if showNames then
                local label = string.format("%s [%d%%] [%dm]", info.plr.DisplayName or info.plr.Name, info.health, math.floor(info.studDist))
                VeilSharedVisuals.UpdateNameLabel(info.plr, label, true, isTgt)
            else VeilSharedVisuals.UpdateNameLabel(info.plr, "", false, false) end
        end
        local detectedSet = {}
        for _, info in ipairs(all) do detectedSet[info.plr] = true end
        for plr, _ in pairs(VeilSharedVisuals.PlayerCircles) do
            if not detectedSet[plr] then
                VeilSharedVisuals.UpdatePlayerMarker(plr, Vector2.new(0,0), 0, false)
                VeilSharedVisuals.UpdateNameLabel(plr, "", false, false)
            end
        end
        if not nearest then
            VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
            VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
            State.target = nil; State.lookVector = nil; return
        end
        local aim = ComputeAim(nearest)
        if not aim then
            VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
            VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false); return
        end
        State.target = aim.target; State.lookVector = aim.look
        local tp = aim.target.Character and (aim.target.Character:FindFirstChild("UpperTorso") or aim.target.Character:FindFirstChild("Torso") or aim.target.Character:FindFirstChild("HumanoidRootPart"))
        if showTarget and tp then
            local sp, vis = cam:WorldToViewportPoint(tp.Position)
            if vis and sp.Z > 0 then
                local rad = math.clamp(1500 / math.max((tp.Position - hrp.Position).Magnitude, 1), 14, 60)
                VeilSharedVisuals.UpdateTarget(Vector2.new(sp.X, sp.Y), rad, true)
                if showTracer then
                    local bottomCenter = Vector2.new(center.X, cam.ViewportSize.Y)
                    VeilSharedVisuals.UpdateTracer(bottomCenter, Vector2.new(sp.X, sp.Y), true)
                else VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false) end
            else
                VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
                VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
            end
        else
            VeilSharedVisuals.UpdateTarget(Vector2.new(0,0), 0, false)
            VeilSharedVisuals.UpdateTracer(Vector2.new(0,0), Vector2.new(0,0), false)
        end
        if VD.VeilV2AutoThrow then
            local now = os.clock()
            if now - State.lastThrow >= (VD.VeilV2FireDelay or 0.05) then State.lastThrow = now; FireSpear(aim) end
        end
    end
    if typeof(hookmetamethod) == "function" then
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" and (self.Name == "Spearthrow" or self.Name == "Spear" or self.Name == "Throw") and VD.VeilV2Enabled and VD.VeilV2UseInterceptor and typeof(State.lookVector) == "Vector3" then
                    local args = {...}
                    if typeof(args[1]) == "Vector3" then args[1] = State.lookVector
                    elseif typeof(args[2]) == "Vector3" then args[2] = State.lookVector end
                    return oldNamecall(self, unpack(args))
                end
                return oldNamecall(self, ...)
            end)
        end)
    end
    RunService.RenderStepped:Connect(function() pcall(Update) end)
    return { State = State }
end)()

RegToggle(Tabs.Aim, "Enable Silent Veil V2", "Advanced silent spear aim", false, "VeilV2Enabled")
RegToggle(Tabs.Aim, "V2 Auto Throw", "Auto throw spears", true, "VeilV2AutoThrow")
RegToggle(Tabs.Aim, "V2 Use Namecall Interceptor", "Intercept remote calls", true, "VeilV2UseInterceptor")
RegToggle(Tabs.Aim, "V2 Wall Check", "Require line of sight", false, "VeilV2WallCheck")
RegToggle(Tabs.Aim, "V2 Ignore Downed", "Skip downed survivors", true, "VeilV2IgnoreDown")
RegToggle(Tabs.Aim, "V2 Show FOV Circle (Cyan)", "Show FOV circle", true, "VeilV2ShowFOV")
RegToggle(Tabs.Aim, "V2 Show Player Circle Markers", "Show player markers", true, "VeilV2ShowPlayerMarkers")
RegToggle(Tabs.Aim, "V2 Show Target Marker (Red)", "Show target marker", true, "VeilV2ShowTargetMarker")
RegToggle(Tabs.Aim, "V2 Show Tracer / Aim Line", "Show tracer line", true, "VeilV2ShowTracer")
RegToggle(Tabs.Aim, "V2 Show Name + HP + Distance", "Show name labels", true, "VeilV2ShowNameLabels")
RegSlider(Tabs.Aim, "V2 FOV", "FOV radius", 180, 50, 500, 10, "VeilV2FOV")
RegSlider(Tabs.Aim, "V2 Max Distance", "Max target distance", 600, 50, 1000, 10, "VeilV2MaxDist")
RegSlider(Tabs.Aim, "V2 Spear Speed", "Spear speed", 170, 50, 400, 5, "VeilV2SpearSpeed")
RegSlider(Tabs.Aim, "V2 Spear Gravity", "Spear gravity", 100, 10, 300, 5, "VeilV2SpearGravity")
RegSlider(Tabs.Aim, "V2 Aura Spear Speed", "Aura spear speed", 170, 50, 400, 5, "VeilV2AuraSpearSpeed")
RegSlider(Tabs.Aim, "V2 Aura Spear Gravity", "Aura spear gravity", 95, 10, 300, 5, "VeilV2AuraSpearGravity")
RegSlider(Tabs.Aim, "V2 Lead Multiplier", "Lead multiplier", 1.35, 0.1, 5, 0.05, "VeilV2LeadMultiplier")
RegSlider(Tabs.Aim, "V2 Predict Iterations", "Prediction iterations", 3, 1, 6, 1, "VeilV2Iterations")
RegSlider(Tabs.Aim, "V2 Fire Delay (s)", "Fire delay", 0.05, 0.02, 1, 0.01, "VeilV2FireDelay")

--========================================================--
-- SILENT PISTOL / TOF V1 (SAFE IMPORT)
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Silent Pistol / TOF V1 (Imported)")

local MAWWW_ToFInstalled = false
local MAWWW_ToFInstallError = nil

local function MAWWW_InstallToFV1()
    local function _ToFNotify(title, content, duration)
        pcall(function() notify(title, content, duration or 2) end)
    end
    local function _ToFGetGuiParent()
        local ok, parent = pcall(function()
            if type(gethui) == "function" then return gethui() end
            return PlayerGui
        end)
        return (ok and parent) or PlayerGui
    end

    local MAWWW_ToFState = {
    Connection = nil,
    LaserBeam = nil,
    TargetGui = nil,
    InputBegan = nil,
    InputEnded = nil,
    TouchInput = nil,
    IsAiming = false,
    SavedUIPos = UDim2.new(0.5, -120, 0, 110),
    SCPCache = {},
    SCPCacheTimer = 0,
}

local MAWWW_ToFKeyCodes = {
    None = nil,
    Q = Enum.KeyCode.Q,
    E = Enum.KeyCode.E,
    R = Enum.KeyCode.R,
    T = Enum.KeyCode.T,
    F = Enum.KeyCode.F,
    G = Enum.KeyCode.G,
    H = Enum.KeyCode.H,
    J = Enum.KeyCode.J,
    K = Enum.KeyCode.K,
    L = Enum.KeyCode.L,
    X = Enum.KeyCode.X,
    Z = Enum.KeyCode.Z,
}

local function MAWWW_ToFGetEvent()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local tof = items and items:FindFirstChild("Twist of Fate")
    local fire = tof and tof:FindFirstChild("Fire")
    if fire and fire:IsA("RemoteEvent") then
        return fire
    end
    return nil
end

local function MAWWW_ToFGetGunObject()
    local char = LocalPlayer.Character
    if not char then return nil end

    local baseToF = char:FindFirstChild("Twist of Fate", true)
    if not baseToF then return nil end

    local rightArm = baseToF:FindFirstChild("Right Arm")
    if rightArm then
        local gunPart = rightArm:FindFirstChild("gun")
        if gunPart then return gunPart end

        local emperorGun = rightArm:FindFirstChild("EmperorGun")
        if emperorGun then return emperorGun end
    end

    return baseToF
end

local function MAWWW_ToFIsTargetVisible(originPos, targetPos, targetCharacter)
    local direction = targetPos - originPos
    local distance = direction.Magnitude
    if distance < 0.1 then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local excludeList = {}
    local localChar = LocalPlayer.Character
    if localChar then table.insert(excludeList, localChar) end
    if targetCharacter and targetCharacter ~= localChar then table.insert(excludeList, targetCharacter) end
    if MAWWW_ToFState.LaserBeam then table.insert(excludeList, MAWWW_ToFState.LaserBeam) end

    rayParams.FilterDescendantsInstances = excludeList

    local result = workspace:Raycast(originPos, direction.Unit * distance, rayParams)
    return result == nil
end

local function MAWWW_ToFGetSCPs()
    if tick() - MAWWW_ToFState.SCPCacheTimer < 0.5 then
        return MAWWW_ToFState.SCPCache
    end

    local newTargets = {}
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        for _, container in pairs(mapFolder:GetDescendants()) do
            if container:IsA("Model") then
                local attributes = container:GetAttributes()
                if container:GetAttribute("CorpseCreated0492") or next(attributes) ~= nil then
                    local root = container:FindFirstChild("HumanoidRootPart")
                    if root then table.insert(newTargets, root) end
                end
            end
        end
    end

    MAWWW_ToFState.SCPCache = newTargets
    MAWWW_ToFState.SCPCacheTimer = tick()
    return MAWWW_ToFState.SCPCache
end

local function MAWWW_ToFGetTargetPosition()
    local gunObj = MAWWW_ToFGetGunObject()
    local char = LocalPlayer.Character
    if not (gunObj and char) then return nil, nil, nil, nil end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil, nil end

    local myPos = hrp.Position
    local originPos
    if char:GetAttribute("IsCarried") then
        originPos = hrp.Position + (hrp.CFrame.LookVector * 2)
    else
        pcall(function()
            originPos = gunObj:IsA("BasePart") and gunObj.Position
                or (gunObj:FindFirstChildOfClass("BasePart") and gunObj:FindFirstChildOfClass("BasePart").Position)
        end)
        originPos = originPos or Vector3.new(myPos.X, myPos.Y + 1.5, myPos.Z)
    end

    local function predictTarget(torso, targetCharacter)
        local targetPos = torso.Position
        if VD.TOF_WallCheck and not MAWWW_ToFIsTargetVisible(originPos, targetPos, targetCharacter) then
            return nil, nil, nil, nil
        end

        local targetVel = Vector3.new(0, 0, 0)
        local rootPart = targetCharacter and (targetCharacter:FindFirstChild("HumanoidRootPart") or torso)
        if rootPart then targetVel = rootPart.Velocity end

        local directionRaw = targetPos - originPos
        local distance = directionRaw.Magnitude
        if distance < 0.1 then return nil, nil, nil, nil end
        if distance < 5 then return directionRaw.Unit, gunObj, originPos, targetPos end

        local travelTime = distance / 400
        local predictedPos = targetPos + (targetVel * travelTime)
        for _ = 1, 2 do
            local newDist = (predictedPos - originPos).Magnitude
            travelTime = newDist / 400
            predictedPos = targetPos + (targetVel * travelTime)
        end

        local finalDirection = predictedPos - originPos
        if finalDirection.Magnitude < 0.1 then return nil, nil, nil, nil end

        return finalDirection.Unit, gunObj, originPos, predictedPos
    end

    local targetMode = VD.TOF_TargetMode or "Killer"
    if targetMode == "Killer" then
        local closestTorso, closestChar, shortestDist = nil, nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" and player.Character then
                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if torso then
                    local dist = (myPos - torso.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTorso = torso
                        closestChar = player.Character
                    end
                end
            end
        end
        if not closestTorso then return nil, nil, nil, nil end
        return predictTarget(closestTorso, closestChar)
    elseif targetMode == "Survivors" then
        local bestTorso, bestChar, bestDot = nil, nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if torso then
                    local dirToTarget = torso.Position - cam.CFrame.Position
                    if dirToTarget.Magnitude > 0.1 then
                        local dot = camLook:Dot(dirToTarget.Unit)
                        if dot > 0.5 and dot > bestDot then
                            bestDot = dot
                            bestTorso = torso
                            bestChar = player.Character
                        end
                    end
                end
            end
        end
        if not bestTorso then return nil, nil, nil, nil end
        return predictTarget(bestTorso, bestChar)
    elseif targetMode == "Zombie" then
        local bestPart, bestDot = nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector

        for _, root in ipairs(MAWWW_ToFGetSCPs()) do
            if root and root.Parent then
                local dirToTarget = root.Position - cam.CFrame.Position
                if dirToTarget.Magnitude > 0.1 then
                    local dot = camLook:Dot(dirToTarget.Unit)
                    if dot > 0.5 and dot > bestDot then
                        bestDot = dot
                        bestPart = root
                    end
                end
            end
        end
        if not bestPart then return nil, nil, nil, nil end
        return predictTarget(bestPart, bestPart.Parent)
    end

    return nil, nil, nil, nil
end

local function MAWWW_ToFUpdateLaser(originPos, targetPos)
    if not MAWWW_ToFState.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 50, 50)
        laser.Parent = workspace
        MAWWW_ToFState.LaserBeam = laser
    end

    local dist = (targetPos - originPos).Magnitude
    MAWWW_ToFState.LaserBeam.Size = Vector3.new(0.05, 0.05, dist)
    MAWWW_ToFState.LaserBeam.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
    MAWWW_ToFState.LaserBeam.Transparency = 0
end

local function MAWWW_ToFClearLaser()
    if MAWWW_ToFState.LaserBeam then
        pcall(function() MAWWW_ToFState.LaserBeam:Destroy() end)
        MAWWW_ToFState.LaserBeam = nil
    end
end

local AimConfig = {
    Pistol_BlockKnocked = true,
}

local function IsDowned(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    local state = char:GetAttribute("State")
    return state == "Downed" or state == "Dead"
end

local function MAWWW_ToFGetMobileShootButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local survivorMob = playerGui and playerGui:FindFirstChild("Survivor-mob")
    local controls = survivorMob and survivorMob:FindFirstChild("Controls")
    local guiMob = controls and controls:FindFirstChild("Gui-mob")
    if not guiMob then return nil end

    local directNames = { "attack", "Attack", "shoot", "Shoot", "fire", "Fire" }
    for _, name in ipairs(directNames) do
        local btn = guiMob:FindFirstChild(name, true)
        if btn and btn:IsA("GuiObject") then return btn end
    end

    for _, obj in ipairs(guiMob:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible then
            return obj
        end
    end

    return guiMob:IsA("GuiObject") and guiMob or nil
end

local function MAWWW_ToFIsTouchOnShootButton(input)
    local shootButton = MAWWW_ToFGetMobileShootButton()
    if not (shootButton and shootButton.Visible) then return false end

    local pos = input.Position
    local absPos = shootButton.AbsolutePosition
    local absSize = shootButton.AbsoluteSize

    return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
end

local function MAWWW_ToFDoShoot()
    if not VD.TOF_SilentAim then return end

    AimConfig.Pistol_BlockKnocked = VD.TOF_BlockKnocked ~= false
    local char = LocalPlayer.Character
    if char then
        if AimConfig.Pistol_BlockKnocked and IsDowned(char) then
            return
        end
    end

    local targetDirection, gunObject, originPos, targetPos = MAWWW_ToFGetTargetPosition()
    if not (targetDirection and gunObject and targetPos and originPos) then return end

    local tofEvent = MAWWW_ToFGetEvent()
    if not tofEvent then return end

    local freshDirection = targetPos - originPos
    if freshDirection.Magnitude < 0.1 then return end

    pcall(function()
        tofEvent:FireServer(gunObject, freshDirection.Unit)
    end)
end

local MAWWW_ToFModeButtons = {}
local function MAWWW_ToFRefreshTargetButtons()
    local modes = {
        Killer = { Color3.fromRGB(180, 45, 45), Color3.fromRGB(255, 180, 180) },
        Survivors = { Color3.fromRGB(25, 80, 150), Color3.fromRGB(160, 210, 255) },
        Zombie = { Color3.fromRGB(120, 80, 10), Color3.fromRGB(255, 210, 100) },
    }

    for modeName, btn in pairs(MAWWW_ToFModeButtons) do
        if btn and btn.Parent then
            local active = modeName == (VD.TOF_TargetMode or "Killer")
            local colors = modes[modeName]
            btn.BackgroundColor3 = active and colors[1] or Color3.fromRGB(30, 32, 40)
            btn.TextColor3 = active and colors[2] or Color3.fromRGB(155, 160, 175)
        end
    end
end

local function MAWWW_ToFSetTargetMode(modeName, notify)
    if modeName ~= "Killer" and modeName ~= "Survivors" and modeName ~= "Zombie" then return end
    VD.TOF_TargetMode = modeName
    MAWWW_ToFRefreshTargetButtons()
    if notify then _ToFNotify("Target Mode", modeName, 1) end
end

local function MAWWW_ToFCreateTargetSelectorUI()
    local parent = _ToFGetGuiParent()
    if not parent then return end
    if MAWWW_ToFState.TargetGui and MAWWW_ToFState.TargetGui.Parent then return end

    local old = parent:FindFirstChild("ToFTargetSelector")
    if old then pcall(function() old:Destroy() end) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ToFTargetSelector"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 180, 0, 126)
    frame.Position = MAWWW_ToFState.SavedUIPos
    frame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(96, 72, 160)
    stroke.Thickness = 1

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    header.BorderSizePixel = 0
    header.Parent = frame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local headerDiv = Instance.new("Frame")
    headerDiv.Size = UDim2.new(1, 0, 0, 1)
    headerDiv.Position = UDim2.new(0, 0, 1, -1)
    headerDiv.BackgroundColor3 = Color3.fromRGB(48, 42, 72)
    headerDiv.BorderSizePixel = 0
    headerDiv.Parent = header

    local dragArea = Instance.new("Frame")
    dragArea.Size = UDim2.new(1, -34, 1, 0)
    dragArea.BackgroundTransparency = 1
    dragArea.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 28, 1, 0)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.fromRGB(185, 190, 205)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.Parent = header

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, -44, 1, 0)
    headerLbl.Position = UDim2.new(0, 10, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Text = "TOF TARGET MODE"
    headerLbl.TextColor3 = Color3.fromRGB(210, 215, 230)
    headerLbl.Font = Enum.Font.GothamBold
    headerLbl.TextSize = 10
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Parent = header

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -16, 0, 86)
    btnContainer.Position = UDim2.new(0, 8, 0, 34)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = frame

    local layout = Instance.new("UIListLayout", btnContainer)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minimizeBtn.Text = isMinimized and "+" or "-"
        btnContainer.Visible = not isMinimized
        frame.Size = isMinimized and UDim2.new(0, 180, 0, 28) or UDim2.new(0, 180, 0, 126)
    end)

    local modes = {
        { Internal = "Killer", Display = "KILLER        K" },
        { Internal = "Survivors", Display = "SURVIVOR      J" },
        { Internal = "Zombie", Display = "ZOMBIE        L" },
    }

    MAWWW_ToFModeButtons = {}
    for i, mode in ipairs(modes) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Text = mode.Display
        btn.TextXAlignment = Enum.TextXAlignment.Center
        btn.LayoutOrder = i
        btn.Parent = btnContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(58, 62, 78)
        btnStroke.Thickness = 1

        btn.MouseButton1Click:Connect(function()
            MAWWW_ToFSetTargetMode(mode.Internal, false)
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                MAWWW_ToFSetTargetMode(mode.Internal, false)
            end
        end)

        MAWWW_ToFModeButtons[mode.Internal] = btn
    end
    MAWWW_ToFRefreshTargetButtons()

    local dragging = false
    local dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = frame.Position
            dragging = true
        end
    end)
    dragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            frame.Position = newPos
            MAWWW_ToFState.SavedUIPos = newPos
        end
    end)

    MAWWW_ToFState.TargetGui = gui
end

local function MAWWW_ToFDestroyTargetSelectorUI()
    if MAWWW_ToFState.TargetGui then
        pcall(function() MAWWW_ToFState.TargetGui:Destroy() end)
        MAWWW_ToFState.TargetGui = nil
    end
    MAWWW_ToFModeButtons = {}
end

local function MAWWW_ToFStartConnection()
    if MAWWW_ToFState.Connection then return end
    MAWWW_ToFState.Connection = RunService.Heartbeat:Connect(function()
        if not VD.TOF_SilentAim or not MAWWW_ToFState.IsAiming then
            if MAWWW_ToFState.LaserBeam then MAWWW_ToFState.LaserBeam.Transparency = 1 end
            return
        end

        local _, _, originPos, targetPos = MAWWW_ToFGetTargetPosition()
        if originPos and targetPos then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and not char:GetAttribute("IsCarried") then
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                end
            end)

            if VD.TOF_Laser then
                MAWWW_ToFUpdateLaser(originPos, targetPos)
            elseif MAWWW_ToFState.LaserBeam then
                MAWWW_ToFState.LaserBeam.Transparency = 1
            end
        elseif MAWWW_ToFState.LaserBeam then
            MAWWW_ToFState.LaserBeam.Transparency = 1
        end
    end)
end

local function MAWWW_ToFStopConnection()
    if MAWWW_ToFState.Connection then
        pcall(function() MAWWW_ToFState.Connection:Disconnect() end)
        MAWWW_ToFState.Connection = nil
    end
    MAWWW_ToFState.IsAiming = false
    MAWWW_ToFClearLaser()
end

local function MAWWW_ToFDisconnectInputs()
    if MAWWW_ToFState.InputBegan then pcall(function() MAWWW_ToFState.InputBegan:Disconnect() end) end
    if MAWWW_ToFState.InputEnded then pcall(function() MAWWW_ToFState.InputEnded:Disconnect() end) end
    MAWWW_ToFState.InputBegan = nil
    MAWWW_ToFState.InputEnded = nil
end

local MAWWW_SetToFSilentAim

local function MAWWW_ToFEnsureInputs()
    if not MAWWW_ToFState.InputBegan then
        MAWWW_ToFState.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end

            local keyCode = MAWWW_ToFKeyCodes[VD.TOF_Key or "None"]
            if keyCode and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode then
                MAWWW_SetToFSilentAim(not VD.TOF_SilentAim)
                return
            end

            if not VD.TOF_SilentAim then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and MAWWW_ToFIsTouchOnShootButton(input)) then
                MAWWW_ToFState.IsAiming = true
                if input.UserInputType == Enum.UserInputType.Touch then
                    MAWWW_ToFState.TouchInput = input
                end
                MAWWW_ToFDoShoot()
                return
            end

            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.K then
                    MAWWW_ToFSetTargetMode("Killer", true)
                elseif input.KeyCode == Enum.KeyCode.J then
                    MAWWW_ToFSetTargetMode("Survivors", true)
                elseif input.KeyCode == Enum.KeyCode.L then
                    MAWWW_ToFSetTargetMode("Zombie", true)
                end
            end
        end)
    end
    if not MAWWW_ToFState.InputEnded then
        MAWWW_ToFState.InputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and input == MAWWW_ToFState.TouchInput) then
                MAWWW_ToFState.IsAiming = false
                if input == MAWWW_ToFState.TouchInput then MAWWW_ToFState.TouchInput = nil end
                if MAWWW_ToFState.LaserBeam then MAWWW_ToFState.LaserBeam.Transparency = 1 end
            end
        end)
    end
end

MAWWW_SetToFSilentAim = function(enabled)
    VD.TOF_SilentAim = enabled and true or false
    MAWWW_ToFEnsureInputs()
    if VD.TOF_SilentAim then
        MAWWW_ToFCreateTargetSelectorUI()
        MAWWW_ToFStartConnection()
    else
        MAWWW_ToFDestroyTargetSelectorUI()
        MAWWW_ToFStopConnection()
    end
end

MAWWW_ToFEnsureInputs()
getgenv().MAWWW_SetToFSilentAim = MAWWW_SetToFSilentAim
getgenv().MAWWW_ToFClearLaser = MAWWW_ToFClearLaser
getgenv().MAWWW_ToFSetTargetMode = MAWWW_ToFSetTargetMode
end


local function MAWWW_EnsureToFV1()
    if MAWWW_ToFInstalled then return true end
    local ok, err = pcall(MAWWW_InstallToFV1)
    if not ok then
        MAWWW_ToFInstallError = tostring(err)
        warn("[MawwwHub][TOF V1] Safe install failed: " .. MAWWW_ToFInstallError)
        return false
    end
    MAWWW_ToFInstalled = true
    return true
end

TofV1New = {
    SetEnabled = function(enabled)
        if enabled then
            if not MAWWW_EnsureToFV1() then
                VD.TOF_SilentAim = false
                return false
            end
            local setter = getgenv().MAWWW_SetToFSilentAim
            if type(setter) == "function" then
                local ok = pcall(setter, true)
                if not ok then
                    VD.TOF_SilentAim = false
                    return false
                end
            end
            return true
        end
        local setter = getgenv().MAWWW_SetToFSilentAim
        if type(setter) == "function" then
            pcall(setter, false)
        else
            VD.TOF_SilentAim = false
        end
        return true
    end,
    Cleanup = function()
        local setter = getgenv().MAWWW_SetToFSilentAim
        if type(setter) == "function" then pcall(setter, false) end
        VD.TOF_SilentAim = false
    end,
}

RegToggle(Tabs.Aim, "Silent Pistol / TOF V1", "Imported V1 — Killer / Survivor / Zombie, prediction, wall check, laser, mobile shooting.", false, "TOF_SilentAim", function(v)
    local ok = pcall(function()
        local success = TofV1New.SetEnabled(v)
        if success == false and v then
            notify("TOF V1", "Gagal mengaktifkan TOF V1; UI tetap aman.", 3)
        elseif v then
            notify("TOF V1", "ON — imported V1 aktif", 2)
        else
            notify("TOF V1", "OFF", 2)
        end
    end)
    if not ok then
        VD.TOF_SilentAim = false
    end
end)

RegDropdown(Tabs.Aim, "TOF V1 Target Mode", "Target yang dipilih oleh V1", {"Killer", "Survivors", "Zombie"}, "Killer", false, "TOF_TargetMode", function(v)
    if MAWWW_ToFInstalled then pcall(getgenv().MAWWW_ToFSetTargetMode, v, false) end
end)
RegToggle(Tabs.Aim, "TOF V1 Laser", "Tampilkan laser target", true, "TOF_Laser")
RegToggle(Tabs.Aim, "TOF V1 Wall Check", "Lewati target di balik dinding", false, "TOF_WallCheck")
RegToggle(Tabs.Aim, "TOF V1 Block When Downed", "Jangan menembak saat knocked/downed", true, "TOF_BlockKnocked")
RegDropdown(Tabs.Aim, "TOF V1 Toggle Key", "Tombol toggle aim", {"None","Q","E","R","T","F","G","H","J","K","L","X","Z"}, "None", false, "TOF_Key")

--========================================================--
-- SILENT PISTOL / TOF V2
--========================================================--
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Silent Pistol / TOF V2")

ToFV2 = (function()
    local AimConfig = {
        Aim_Silent = false,
        Pistol_BlockKnocked = true,
        Pistol_Target = "Killer",
        Pistol_FOVMode = true,
        Pistol_ShowFOV = false,
        Pistol_FOV = 180,
        AIM_TargetPart = "Torso",
        HideSilentLaser = false,
        LockAim = false,
    }

    local State = {
        Enabled = false,
        IsCharging = false,
        LockedTarget = nil,
        TouchInput = nil,
        Laser = nil,
        FOV = nil,
        Connections = {},
    }

    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local function isDowned(char)
        if not char then return false end
        return char:GetAttribute("Knocked") == true
            or char:GetAttribute("IsHooked") == true
            or char:GetAttribute("IsCarried") == true
            or char:GetAttribute("State") == "Downed"
            or char:GetAttribute("State") == "Dead"
    end

    local function isKiller(player)
        return player and player.Team and player.Team.Name == "Killer"
    end

    local function targetPart(char)
        if not char then return nil end
        if AimConfig.AIM_TargetPart == "Head" then
            return char:FindFirstChild("Head")
        elseif AimConfig.AIM_TargetPart == "Root" then
            return char:FindFirstChild("HumanoidRootPart")
        end
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end

    local function syncConfig()
        AimConfig.Pistol_Target = (VD.TOF2_TargetMode == "Survivors") and "Survivor" or "Killer"
        AimConfig.AIM_TargetPart = VD.TOF2_AimPart or "Torso"
        AimConfig.Pistol_FOV = tonumber(VD.TOF2_FOV) or 180
        AimConfig.Pistol_ShowFOV = VD.TOF2_ShowLaser == true and false or false
        AimConfig.Pistol_BlockKnocked = VD.TOF2_BlockKnocked ~= false
        AimConfig.HideSilentLaser = VD.TOF2_ShowLaser == false
        AimConfig.Pistol_FOVMode = true
    end

    local function getTarget()
        syncConfig()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        if AimConfig.Pistol_BlockKnocked and isDowned(myChar) then return nil end

        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local mouse = UIS:GetMouseLocation()
        local closest = AimConfig.Pistol_FOVMode and AimConfig.Pistol_FOV or math.huge
        local best = nil

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local valid = false
                if AimConfig.Pistol_Target == "Killer" then
                    valid = isKiller(player)
                elseif AimConfig.Pistol_Target == "Survivor" or AimConfig.Pistol_Target == "Survivors" then
                    valid = not isKiller(player)
                end

                if valid then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    local part = targetPart(player.Character)
                    if hum and hum.Health > 0 and part and not isDowned(player.Character) then
                        local screen, onScreen = camera:WorldToViewportPoint(part.Position)
                        if onScreen or not AimConfig.Pistol_FOVMode then
                            local distance = AimConfig.Pistol_FOVMode
                                and (Vector2.new(screen.X, screen.Y) - mouse).Magnitude
                                or (part.Position - myRoot.Position).Magnitude
                            if distance < closest then
                                closest = distance
                                best = part
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function ensureLaser()
        if State.Laser then return State.Laser end
        local ok, part = pcall(Instance.new, "Part")
        if not ok or not part then return nil end
        part.Name = "Mawww_TOFV2_Laser"
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 0, 0)
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Anchored = true
        part.CastShadow = false
        part.Size = Vector3.new(0.05, 0.05, 1)
        part.Transparency = 1
        State.Laser = part
        return part
    end

    local function ensureFOV()
        if State.FOV then return State.FOV end
        local ok, circle = pcall(Drawing.new, "Circle")
        if not ok or not circle then return nil end
        circle.Thickness = 1.5
        circle.Filled = false
        circle.Visible = false
        State.FOV = circle
        return circle
    end

    local function getWeaponArg(char)
        local tof = char and char:FindFirstChild("Twist of Fate")
        if not tof then return nil end
        local arm = tof:FindFirstChild("Right Arm")
        if arm then
            return arm:FindFirstChild("EmperorGun")
                or arm:FindFirstChild("gun")
                or arm
        end
        return tof
    end

    local function fire()
        if not State.Enabled then return end
        local char = LocalPlayer.Character
        if not char or (AimConfig.Pistol_BlockKnocked and isDowned(char)) then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local target = State.LockedTarget or getTarget()
        local weapon = getWeaponArg(char)
        if not root or not target or not weapon then return end

        local startPos = root.Position
        local targetPos = target.Position
        local velocity = target.AssemblyLinearVelocity
        velocity = Vector3.new(velocity.X, 0, velocity.Z)
        local distance = (targetPos - startPos).Magnitude
        local speed = 400
        local predicted = targetPos + velocity * (distance / speed)
        local direction = ((predicted + Vector3.new(0, -2, 0)) - startPos)
        if direction.Magnitude <= 0 then return end
        direction = direction.Unit

        pcall(function()
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            local items = remotes and remotes:FindFirstChild("Items")
            local item = items and items:FindFirstChild("Twist of Fate")
            local remote = item and item:FindFirstChild("Fire")
            if remote then
                remote:FireServer(weapon, direction)
            end
        end)
    end

    local function clearVisuals()
        if State.Laser then State.Laser.Parent = nil end
        if State.FOV then State.FOV.Visible = false end
    end

    local function disconnect()
        for _, c in pairs(State.Connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(State.Connections)
        State.IsCharging = false
        State.LockedTarget = nil
        State.TouchInput = nil
        clearVisuals()
    end

    local function update()
        if not State.Enabled then
            clearVisuals()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        if State.IsCharging and AimConfig.LockAim and State.LockedTarget
            and State.LockedTarget.Parent then
            local targetHum = State.LockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            if targetHum and targetHum.Health > 0 then
                pcall(function()
                    camera.CFrame = camera.CFrame:Lerp(
                        CFrame.lookAt(camera.CFrame.Position, State.LockedTarget.Position), 0.15
                    )
                end)
            end
        end

        if State.IsCharging then
            if VD.TOF2_AutoFire then
                pcall(fire)
            end
            local target = getTarget()
            if target then
                local char = LocalPlayer.Character
                local arm = char and (char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand"))
                local startPos = arm and arm.Position or (char and char:GetPivot().Position)
                if startPos then
                    local velocity = target.AssemblyLinearVelocity
                    velocity = Vector3.new(velocity.X, 0, velocity.Z)
                    local distance = (target.Position - startPos).Magnitude
                    local predicted = target.Position + velocity * (distance / 400)
                    local endPos = predicted + Vector3.new(0, -1.2, 0)
                    local laser = ensureLaser()
                    if laser then
                        laser.Parent = workspace
                        laser.Transparency = AimConfig.HideSilentLaser and 1 or 0
                        local len = (endPos - startPos).Magnitude
                        if len > 0 then
                            laser.Size = Vector3.new(0.05, 0.05, len)
                            laser.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -len / 2)
                        end
                    end
                end
            else
                if State.Laser then State.Laser.Parent = nil end
            end
        else
            if State.Laser then State.Laser.Parent = nil end
        end

        if AimConfig.Pistol_ShowFOV and AimConfig.Pistol_FOVMode then
            local circle = ensureFOV()
            if circle then
                circle.Visible = true
                circle.Radius = AimConfig.Pistol_FOV
                circle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            end
        elseif State.FOV then
            State.FOV.Visible = false
        end
    end

    local function connectInputs()
        if next(State.Connections) then return end

        State.Connections.InputBegan = UIS.InputBegan:Connect(function(input, processed)
            local touch = input.UserInputType == Enum.UserInputType.Touch
            if processed and not touch then return end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                State.IsCharging = true
                State.LockedTarget = getTarget()
            elseif touch then
                State.IsCharging = true
                State.TouchInput = input
                State.LockedTarget = getTarget()
            end
        end)

        State.Connections.InputEnded = UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if State.IsCharging then
                    State.IsCharging = false
                    fire()
                end
                State.LockedTarget = nil
            elseif input.UserInputType == Enum.UserInputType.Touch and input == State.TouchInput then
                State.IsCharging = false
                State.TouchInput = nil
                fire()
                State.LockedTarget = nil
            end
        end)

        State.Connections.Render = RunService.RenderStepped:Connect(function()
            pcall(update)
        end)
    end

    local function setEnabled(enabled)
        State.Enabled = enabled and true or false
        if State.Enabled then
            connectInputs()
        else
            disconnect()
        end
    end

    return {
        State = State,
        SetEnabled = setEnabled,
        Fire = fire,
        Cleanup = disconnect,
    }
end)()

RegToggle(Tabs.Aim, "Silent Pistol / TOF V2", "Source TOF V2 silent aim", false, "TOF2_Enabled", function(v)
    pcall(function()
        ToFV2.SetEnabled(v)
    end)
end)

RegDropdown(Tabs.Aim, "V2 Target Mode", "Target team", {"Killer", "Survivors"}, "Killer", false, "TOF2_TargetMode")
RegDropdown(Tabs.Aim, "V2 Aim Part", "Aim body part", {"Torso", "Head", "Root"}, "Torso", false, "TOF2_AimPart")
RegToggle(Tabs.Aim, "V2 Auto Fire", "Auto fire", false, "TOF2_AutoFire")
RegToggle(Tabs.Aim, "V2 Prediction", "Enable prediction", true, "TOF2_Predict")
RegSlider(Tabs.Aim, "V2 Predict Iterations", "Prediction iterations", 3, 1, 6, 1, "TOF2_PredictIterations")
RegToggle(Tabs.Aim, "V2 Wall Check", "Require line of sight", true, "TOF2_WallCheck")
RegToggle(Tabs.Aim, "V2 Block When Downed", "Block when downed", true, "TOF2_BlockKnocked")
RegToggle(Tabs.Aim, "V2 Ignore Downed Target", "Skip downed targets", true, "TOF2_IgnoreDown")
RegToggle(Tabs.Aim, "V2 Show Laser", "Show laser", true, "TOF2_ShowLaser")
RegSlider(Tabs.Aim, "V2 Max Distance", "Max distance", 600, 50, 1000, 10, "TOF2_MaxDist")
RegSlider(Tabs.Aim, "V2 FOV", "FOV radius", 180, 30, 500, 10, "TOF2_FOV")
RegSlider(Tabs.Aim, "V2 Fire Rate (s)", "Fire rate", 0.18, 0.05, 1, 0.01, "TOF2_FireRate")
RegSlider(Tabs.Aim, "V2 Laser R", "Laser red", 255, 0, 255, 1, "TOF2_LaserColorR")
RegSlider(Tabs.Aim, "V2 Laser G", "Laser green", 40, 0, 255, 1, "TOF2_LaserColorG")
RegSlider(Tabs.Aim, "V2 Laser B", "Laser blue", 40, 0, 255, 1, "TOF2_LaserColorB")

RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Flashlight Silent Aim")
FlashAim = (function()
    local State = { Target=nil, LastFire=0 }
    local function TeamHas(p, keyword) if not p or not p.Team or not p.Team.Name then return false end; return string.find(string.lower(p.Team.Name), keyword, 1, true) ~= nil end
    local function IsDownedChar(c) if not c then return false end; local s = c:GetAttribute("State"); return s == "Downed" or s == "Dead" end
    local function PickTarget()
        local char = Player.Character; if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
        local cam = Workspace.CurrentCamera; if not cam then return nil end
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local keyword = (VD.FlashTargetMode == "Survivors") and "survivor" or "killer"
        local best, bestMetric = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and TeamHas(p, keyword) then
                local pc = p.Character
                if not IsDownedChar(pc) then
                    local hum = pc:FindFirstChildOfClass("Humanoid")
                    local part = pc:FindFirstChild("UpperTorso") or pc:FindFirstChild("Torso") or pc:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and part then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on and sp.Z > 0 then
                            local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            local stud = (part.Position - hrp.Position).Magnitude
                            if sd <= (VD.FlashFOV or 200) and stud <= (VD.FlashMaxDist or 400) and sd < bestMetric then bestMetric = sd; best = part end
                        end
                    end
                end
            end
        end
        return best
    end
    local function WallCheck(origin, target)
        if not VD.FlashWallCheck then return true end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excl = {}
        if Player.Character then table.insert(excl, Player.Character) end
        params.FilterDescendantsInstances = excl
        local dir = target - origin; local dist = dir.Magnitude
        if dist < 0.1 then return true end
        return Workspace:Raycast(origin, dir.Unit * dist, params) == nil
    end
    local function DoFire()
        local target = State.Target or PickTarget(); if not target then return end
        State.Target = target
        local char = Player.Character
        local origin = char and char:FindFirstChild("HumanoidRootPart"); if not origin then return end
        if not WallCheck(origin.Position, target.Position) then return end
        local dir = (target.Position - origin.Position).Unit
        pcall(function()
            local remotes = GetRemotes(); if not remotes then return end
            local items = remotes:FindFirstChild("Items")
            local fl = items and (items:FindFirstChild("Flashlight") or items:FindFirstChild("Torch"))
            if fl then
                local fire = fl:FindFirstChild("Fire") or fl:FindFirstChild("Shine") or fl:FindFirstChild("Aim")
                if fire then fire:FireServer(dir); return end
            end
            local playerFolder = remotes:FindFirstChild("Player")
            if playerFolder then
                local ev = playerFolder:FindFirstChild("FlashlightAim") or playerFolder:FindFirstChild("AimFlashlight")
                if ev then ev:FireServer(dir); return end
            end
        end)
    end
    local function Update()
        if not VD.FlashSilentAim then State.Target = nil; return end
        local tgt = PickTarget(); State.Target = tgt
        if VD.FlashAutoFire and tgt then
            local now = os.clock()
            if now - State.LastFire >= 0.2 then State.LastFire = now; pcall(DoFire) end
        end
    end
    RunService.RenderStepped:Connect(function() pcall(Update) end)
    return { State = State, DoFire = DoFire }
end)()
RegToggle(Tabs.Aim, "Flashlight Silent Aim", "Silent aim flashlight", false, "FlashSilentAim")
RegToggle(Tabs.Aim, "Flashlight Auto Fire", "Auto fire flashlight", true, "FlashAutoFire")
RegToggle(Tabs.Aim, "Flashlight Wall Check", "Require line of sight", false, "FlashWallCheck")
RegDropdown(Tabs.Aim, "Flashlight Target Mode", "Target team", {"Killer", "Survivors"}, "Killer", false, "FlashTargetMode")
RegSlider(Tabs.Aim, "Flashlight FOV", "FOV radius", 200, 30, 500, 10, "FlashFOV")
RegSlider(Tabs.Aim, "Flashlight Max Distance", "Max distance", 400, 50, 1000, 10, "FlashMaxDist")

-- Flask Silent Aim
RegDivider(Tabs.Aim)
RegLabel(Tabs.Aim, "Flask Silent Aim")
RegToggle(Tabs.Aim, "Flask Silent Aim", "Silent aim flask", false, "FlaskSilentAim")
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self.Name == "ThrowFlask" and VD.FlaskSilentAim then
            local args = {...}
            local closest = nil; local minDst = math.huge
            local myRoot = getRoot(); local myPos = myRoot and myRoot.Position
            if myPos then
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= Player and v.Character then
                        local vRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        if vRoot and not IsKiller(v) then
                            local dst = (vRoot.Position - myPos).Magnitude
                            if dst < minDst then minDst = dst; closest = v end
                        end
                    end
                end
            end
            if closest and closest.Character then
                local tp = closest.Character:FindFirstChild("HumanoidRootPart")
                if tp and args[2] and typeof(args[2]) == "Vector3" then args[1] = (tp.Position - args[2]).Unit end
            end
            setnamecallmethod("FireServer")
            return old(self, unpack(args))
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

--========================================================--
-- ESP TAB
--========================================================--
RegLabel(Tabs.ESP, "═══ ESP Targets ═══")
ESPObjects = {}; local ESPNames = {}; local ESPGenProgress = {}
CachedGenerators, CachedWindows, CachedPallets, CachedHooks = {}, {}, {}, {}
CachedSCP = {}
ESP_Colors = {
    Killer=Color3.fromRGB(255,0,0), Survivor=Color3.fromRGB(0,255,100), SCP=Color3.fromRGB(180,0,255),
    Generator=Color3.fromRGB(255,170,0), Pallet=Color3.fromRGB(74,255,181),
    Window=Color3.fromRGB(74,180,255), Hook=Color3.fromRGB(255,100,100), Lobby=Color3.fromRGB(255,215,0),
}
function cacheObject(obj)
    if obj.Name == "Generator" then CachedGenerators[obj] = true
    elseif obj.Name == "Window" then CachedWindows[obj] = true
    elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then CachedPallets[obj] = true
    elseif obj.Name == "Hook" then CachedHooks[obj] = true end
end
for _, obj in ipairs(Workspace:GetDescendants()) do
    cacheObject(obj)
    if string.find(string.lower(obj.Name), "scp") then CachedSCP[obj] = true end
end
Workspace.DescendantAdded:Connect(function(obj)
    cacheObject(obj)
    if string.find(string.lower(obj.Name), "scp") then CachedSCP[obj] = true end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    CachedSCP[obj] = nil; CachedGenerators[obj] = nil; CachedWindows[obj] = nil; CachedPallets[obj] = nil; CachedHooks[obj] = nil
    if ESPObjects[obj] then ESPObjects[obj]:Destroy() ESPObjects[obj] = nil end
end)
function removeESP(obj) if ESPObjects[obj] then ESPObjects[obj]:Destroy() ESPObjects[obj] = nil end end
function createESP(obj, color)
    if not obj then return end
    local fillT = (tonumber(VD.ESP_FillTransparency) or 70) / 100
    local outlineT = (tonumber(VD.ESP_OutlineTransparency) or 20) / 100
    if fillT < 0 then fillT = 0 elseif fillT > 1 then fillT = 1 end
    if outlineT < 0 then outlineT = 0 elseif outlineT > 1 then outlineT = 1 end
    if ESPObjects[obj] and ESPObjects[obj].Parent then
        ESPObjects[obj].FillColor = color; ESPObjects[obj].OutlineColor = color
        ESPObjects[obj].FillTransparency = fillT; ESPObjects[obj].OutlineTransparency = outlineT
        return
    end
    local h = Instance.new("Highlight")
    h.FillColor = color; h.OutlineColor = color
    h.FillTransparency = fillT; h.OutlineTransparency = outlineT
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = obj
    ESPObjects[obj] = h
end
function createNameBillboard(char)
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then return end
    if ESPNames[char] and ESPNames[char].Parent then
        local lbl = ESPNames[char]:FindFirstChild("NameLabel")
        if lbl then
            local plr = Players:GetPlayerFromCharacter(char)
            lbl.Text = plr and (plr.DisplayName or plr.Name) or char.Name
        end
        return
    end
    local bb = Instance.new("BillboardGui")
    bb.Name = "MWD_ESPName"; bb.Size = UDim2.new(0, 200, 0, 22); bb.StudsOffset = Vector3.new(0, 3.2, 0); bb.AlwaysOnTop = true
    bb.Adornee = head; bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.Name = "NameLabel"; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = char.Name; lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 14; lbl.Font = Enum.Font.GothamBold; lbl.Parent = bb
    ESPNames[char] = bb
end
function removeNameBillboard(char) if ESPNames[char] then pcall(function() ESPNames[char]:Destroy() end); ESPNames[char] = nil end end
function updateNameBillboard(char)
    if not char or not ESPNames[char] then return end
    local plr = Players:GetPlayerFromCharacter(char); if not plr then return end
    local lbl = ESPNames[char]:FindFirstChild("NameLabel")
    if lbl then lbl.Text = plr.DisplayName or plr.Name end
end
function createGenProgressBillboard(gen)
    if not gen then return end
    if ESPGenProgress[gen] and ESPGenProgress[gen].Parent then
        local lbl = ESPGenProgress[gen]:FindFirstChild("ProgressLabel")
        if lbl then
            local progress = gen:GetAttribute("RepairProgress") or 0; progress = math.floor(progress)
            local kickcount = gen:GetAttribute("kickcount") or 0
            lbl.Text = string.format("Progress: %d%%", progress)
            if progress >= 100 then lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
            elseif kickcount > 0 then lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            else lbl.TextColor3 = Color3.fromRGB(255, 170, 0) end
        end
        return
    end
    local adornee = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true); if not adornee then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "MWD_GenProgress"; bb.Size = UDim2.new(0, 160, 0, 20); bb.StudsOffset = Vector3.new(0, 3.2, 0); bb.AlwaysOnTop = true
    bb.Adornee = adornee; bb.Parent = adornee
    local lbl = Instance.new("TextLabel")
    lbl.Name = "ProgressLabel"; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "Progress: 0%"; lbl.TextColor3 = Color3.fromRGB(255, 170, 0)
    lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 14; lbl.Font = Enum.Font.GothamBold; lbl.Parent = bb
    ESPGenProgress[gen] = bb
end
function removeGenProgressBillboard(gen) if ESPGenProgress[gen] then pcall(function() ESPGenProgress[gen]:Destroy() end); ESPGenProgress[gen] = nil end end
function updateESP()
    local root = getRoot(); if not root then return end
    local myRole = GetRole(); local isLobby = (myRole == "Lobby" or myRole == "Unknown")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - root.Position).Magnitude
                    if distance <= VD.ESP_Distance then
                        local showESP = false
                        if isLobby then
                            if VD.ESP_Survivor or VD.ESP_Killer then
                                local color
                                if VD.ESP_Killer and not VD.ESP_Survivor then color = ESP_Colors.Killer
                                elseif VD.ESP_Survivor and not VD.ESP_Killer then color = ESP_Colors.Survivor
                                else color = ESP_Colors.Lobby end
                                createESP(char, color); showESP = true
                            else removeESP(char) end
                        else
                            if VD.ESP_Survivor and teamMatches(p.Team and p.Team.Name, "survivor") then createESP(char, ESP_Colors.Survivor); showESP = true
                            elseif VD.ESP_Killer and teamMatches(p.Team and p.Team.Name, "killer") then createESP(char, ESP_Colors.Killer); showESP = true
                            else removeESP(char) end
                        end
                        if VD.ESP_ShowName and showESP then createNameBillboard(char); updateNameBillboard(char)
                        else removeNameBillboard(char) end
                    else removeESP(char); removeNameBillboard(char) end
                end
            else removeESP(char); removeNameBillboard(char) end
        end
    end
    if VD.ESP_SCP then
        for obj in pairs(CachedSCP) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                if pos and (pos - root.Position).Magnitude <= VD.ESP_Distance then createESP(obj, ESP_Colors.SCP)
                else removeESP(obj) end
            end
        end
    else for obj in pairs(CachedSCP) do removeESP(obj) end end
    if VD.ESP_Generator then
        for obj in pairs(CachedGenerators) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                if pos and (pos - root.Position).Magnitude <= VD.ESP_Distance then
                    createESP(obj, ESP_Colors.Generator)
                    if VD.ESP_ShowGenProgress then createGenProgressBillboard(obj)
                    else removeGenProgressBillboard(obj) end
                else removeESP(obj); removeGenProgressBillboard(obj) end
            else removeGenProgressBillboard(obj) end
        end
    else for obj in pairs(CachedGenerators) do removeESP(obj); removeGenProgressBillboard(obj) end end
    if VD.ESP_Window then
        for obj in pairs(CachedWindows) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                if pos and (pos - root.Position).Magnitude <= VD.ESP_Distance then createESP(obj, ESP_Colors.Window)
                else removeESP(obj) end
            end
        end
    else for obj in pairs(CachedWindows) do removeESP(obj) end end
    if VD.ESP_Pallet then
        for obj in pairs(CachedPallets) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                if pos and (pos - root.Position).Magnitude <= VD.ESP_Distance then createESP(obj, ESP_Colors.Pallet)
                else removeESP(obj) end
            end
        end
    else for obj in pairs(CachedPallets) do removeESP(obj) end end
    if VD.ESP_Hook then
        for obj in pairs(CachedHooks) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                if pos and (pos - root.Position).Magnitude <= VD.ESP_Distance then createESP(obj, ESP_Colors.Hook)
                else removeESP(obj) end
            end
        end
    else for obj in pairs(CachedHooks) do removeESP(obj) end end
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.1)
        if VD.ESP_Survivor or VD.ESP_Killer or VD.ESP_SCP or VD.ESP_Generator or VD.ESP_Window or VD.ESP_Pallet or VD.ESP_Hook or VD.ESP_ShowName or VD.ESP_ShowGenProgress then pcall(updateESP) end
    end
end)
RegToggle(Tabs.ESP, "ESP Killer", "Highlight killers", false, "ESP_Killer")
RegToggle(Tabs.ESP, "ESP Survivor", "Highlight survivors", false, "ESP_Survivor")
RegToggle(Tabs.ESP, "ESP SCP", "Highlight SCPs", false, "ESP_SCP")
RegToggle(Tabs.ESP, "ESP Generator", "Highlight generators", false, "ESP_Generator")
RegToggle(Tabs.ESP, "ESP Window", "Highlight windows", false, "ESP_Window")
RegToggle(Tabs.ESP, "ESP Pallet", "Highlight pallets", false, "ESP_Pallet")
RegToggle(Tabs.ESP, "ESP Hook", "Highlight hooks", false, "ESP_Hook")
RegSlider(Tabs.ESP, "ESP Radius", "Max distance", 250, 50, 1000, 10, "ESP_Distance")
RegToggle(Tabs.ESP, "ESP Name (White)", "Show player names", false, "ESP_ShowName")
RegToggle(Tabs.ESP, "Generator Progress", "Show generator progress", false, "ESP_ShowGenProgress")
RegDivider(Tabs.ESP)
RegLabel(Tabs.ESP, "ESP Colors")
RegSlider(Tabs.ESP, "Fill Transparency", "Highlight fill transparency", 70, 0, 100, 1, "ESP_FillTransparency")
RegSlider(Tabs.ESP, "Outline Transparency", "Highlight outline transparency", 20, 0, 100, 1, "ESP_OutlineTransparency")

-- ESP Status
RegDivider(Tabs.ESP)
RegLabel(Tabs.ESP, "ESP Status")
ESPStatus = (function()
    local State = { Enabled = false, Billboards = setmetatable({}, {__mode = "k"}) }
    local STATUS_COLORS = { STUNNED = Color3.fromRGB(255, 220, 0), DOWNED = Color3.fromRGB(255, 50, 50), HOOKED = Color3.fromRGB(255, 0, 100), CARRIED = Color3.fromRGB(255, 100, 200), CARRYING = Color3.fromRGB(180, 60, 255), ATTACKING = Color3.fromRGB(255, 80, 40), LUNGE = Color3.fromRGB(255, 140, 0), BLINDED = Color3.fromRGB(150, 150, 255), REPAIRING = Color3.fromRGB(0, 255, 100), HEALING = Color3.fromRGB(120, 255, 180), VAULTING = Color3.fromRGB(0, 200, 255) }
    local function GetPlayerStatus(plr)
        if not plr or not plr.Character then return nil, nil end
        local char = plr.Character
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return nil, nil end
        local hstate = hum:GetState(); if hstate == Enum.HumanoidStateType.Dead then return nil, nil end
        local isKiller = IsKiller(plr)
        local stateAttr = char:GetAttribute("State")
        local isCarrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
        local isCarried = char:GetAttribute("IsCarried") or char:GetAttribute("isCarried")
        local isStunned = char:GetAttribute("IsStunned") or char:GetAttribute("Stunned")
        local isHooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked")
        local isDowned = char:GetAttribute("Knocked") or char:GetAttribute("Downed") or char:GetAttribute("HookProgressDepleting")
        local isRepairing = char:GetAttribute("IsRepairing") or char:GetAttribute("Repairing")
        local isHealing = char:GetAttribute("IsHealing") or char:GetAttribute("Healing")
        local isBlinded = char:GetAttribute("IsBlinded") or char:GetAttribute("Blinded")
        local isVaulting = char:GetAttribute("isVaulting")
        local checkInt = char:FindFirstChild("CheckInterractable")
        if checkInt then
            if checkInt:GetAttribute("isRepairing") then isRepairing = true end
            if checkInt:GetAttribute("isHealing") then isHealing = true end
            if checkInt:GetAttribute("isVaulting") then isVaulting = true end
        end
        if hstate == Enum.HumanoidStateType.FallingDown or hstate == Enum.HumanoidStateType.Ragdoll then return "STUNNED", STATUS_COLORS.STUNNED end
        if isHooked or stateAttr == "Hooked" then return "HOOKED", STATUS_COLORS.HOOKED end
        if isCarried then return "CARRIED", STATUS_COLORS.CARRIED end
        if isDowned or stateAttr == "Downed" then return "DOWNED", STATUS_COLORS.DOWNED end
        if isStunned then return "STUNNED", STATUS_COLORS.STUNNED end
        if isCarrying then return "CARRYING", STATUS_COLORS.CARRYING end
        if isBlinded then return "BLINDED", STATUS_COLORS.BLINDED end
        if isRepairing then return "REPAIRING", STATUS_COLORS.REPAIRING end
        if isHealing then return "HEALING", STATUS_COLORS.HEALING end
        if isVaulting then return "VAULTING", STATUS_COLORS.VAULTING end
        if isKiller then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                local tracks = animator:GetPlayingAnimationTracks()
                for _, track in ipairs(tracks) do
                    local name = ""; pcall(function() name = string.lower(track.Animation and track.Animation.Name or "") end)
                    if name:find("lunge", 1, true) or name:find("charge", 1, true) then return "LUNGE", STATUS_COLORS.LUNGE end
                end
                for _, track in ipairs(tracks) do
                    local name = ""; pcall(function() name = string.lower(track.Animation and track.Animation.Name or "") end)
                    if name:find("attack", 1, true) or name:find("slash", 1, true) or name:find("stab", 1, true) or name:find("swing", 1, true) or name:find("melee", 1, true) then return "ATTACKING", STATUS_COLORS.ATTACKING end
                end
            end
        end
        return nil, nil
    end
    local function EnsureBillboard(char)
        if State.Billboards[char] and State.Billboards[char].Parent then return State.Billboards[char] end
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then return nil end
        local bb = Instance.new("BillboardGui")
        bb.Name = "MWD_ESPStatus"; bb.Size = UDim2.new(0, 200, 0, 20); bb.StudsOffset = Vector3.new(0, 4.6, 0)
        bb.AlwaysOnTop = true; bb.Adornee = head; bb.Parent = head
        local lbl = Instance.new("TextLabel")
        lbl.Name = "StatusLabel"; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
        lbl.Text = ""; lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextSize = 15; lbl.Font = Enum.Font.GothamBlack; lbl.Parent = bb
        State.Billboards[char] = bb; return bb
    end
    local function RemoveBillboard(char) if State.Billboards[char] then pcall(function() State.Billboards[char]:Destroy() end); State.Billboards[char] = nil end end
    local function Update()
        local root = getRoot(); if not root then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local char = plr.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - root.Position).Magnitude
                    local maxDist = tonumber(VD.ESP_StatusDistance) or 250
                    if dist <= maxDist then
                        local text, color = GetPlayerStatus(plr)
                        if text then
                            local show = true
                            if text == "STUNNED" and VD.ESP_StatusShowKillerStun == false then show = false end
                            if (text == "ATTACKING" or text == "LUNGE") and VD.ESP_StatusShowKillerAttack == false then show = false end
                            if text == "DOWNED" and VD.ESP_StatusShowSurvivorDown == false then show = false end
                            if text == "HOOKED" and VD.ESP_StatusShowSurvivorHook == false then show = false end
                            if (text == "CARRIED" or text == "CARRYING") and VD.ESP_StatusShowSurvivorCarry == false then show = false end
                            if text == "REPAIRING" and VD.ESP_StatusShowRepairing == false then show = false end
                            if text == "HEALING" and VD.ESP_StatusShowHealing == false then show = false end
                            if text == "BLINDED" and VD.ESP_StatusShowBlind == false then show = false end
                            if show then
                                local bb = EnsureBillboard(char)
                                if bb then
                                    local lbl = bb:FindFirstChild("StatusLabel")
                                    if lbl then lbl.Text = "[" .. text .. "]"; lbl.TextColor3 = color end
                                end
                            else RemoveBillboard(char) end
                        else RemoveBillboard(char) end
                    else RemoveBillboard(char) end
                else RemoveBillboard(char) end
            end
        end
    end
    task.spawn(function()
        while not VD.Destroyed do task.wait(0.15); if State.Enabled then pcall(Update) end end
    end)
    return {
        State = State,
        SetEnabled = function(v)
            State.Enabled = v; VD.ESP_Status = v
            if not v then
                for char, bb in pairs(State.Billboards) do if bb then pcall(function() bb:Destroy() end) end end
                State.Billboards = setmetatable({}, {__mode = "k"})
            end
        end,
    }
end)()
RegToggle(Tabs.ESP, "ESP Status (Live Status Above Players)", "Show live status above players", false, "ESP_Status", function(v)
    ESPStatus.SetEnabled(v)
    if v then notify("ESP Status", "AKTIF! Status pemain tampil di atas kepala.", 3)
    else notify("ESP Status", "Nonaktif", 2) end
end)
RegSlider(Tabs.ESP, "Status Range", "Max status distance", 250, 50, 1000, 10, "ESP_StatusDistance")
RegToggle(Tabs.ESP, "Status: Show Killer Stun", "Show killer stun status", true, "ESP_StatusShowKillerStun")
RegToggle(Tabs.ESP, "Status: Show Killer Attack/Lunge", "Show killer attack status", true, "ESP_StatusShowKillerAttack")
RegToggle(Tabs.ESP, "Status: Show Survivor Down", "Show survivor down status", true, "ESP_StatusShowSurvivorDown")
RegToggle(Tabs.ESP, "Status: Show Survivor Hooked", "Show survivor hooked status", true, "ESP_StatusShowSurvivorHook")
RegToggle(Tabs.ESP, "Status: Show Survivor Carried / Killer Carrying", "Show carry status", true, "ESP_StatusShowSurvivorCarry")
RegToggle(Tabs.ESP, "Status: Show Repairing", "Show repairing status", true, "ESP_StatusShowRepairing")
RegToggle(Tabs.ESP, "Status: Show Healing", "Show healing status", true, "ESP_StatusShowHealing")
RegToggle(Tabs.ESP, "Status: Show Blinded", "Show blinded status", true, "ESP_StatusShowBlinded")

--========================================================--
-- VISUAL TAB
--========================================================--
RegLabel(Tabs.Visual, "═══ Camera ═══")
CameraZoom = { DefaultFOV = workspace.CurrentCamera.FieldOfView }
function applyUnlimitedZoom()
    if VD.UnlimitedZoom then Player.CameraMaxZoomDistance = VD.MaxZoomDistance; Player.CameraMinZoomDistance = 0
    else Player.CameraMaxZoomDistance = 128; Player.CameraMinZoomDistance = 0.5 end
end
function applyCameraFOV()
    local cam = workspace.CurrentCamera; if not cam then return end
    if VD.FOVEnabled then cam.FieldOfView = VD.FOV
    else cam.FieldOfView = CameraZoom.DefaultFOV end
end
Player.CharacterAdded:Connect(function() task.wait(0.5); applyUnlimitedZoom(); applyCameraFOV() end)
RunService.RenderStepped:Connect(function()
    if VD.FOVEnabled then
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= VD.FOV then cam.FieldOfView = VD.FOV end
    end
end)
RegToggle(Tabs.Visual, "Unlimited Zoom Out", "Remove zoom limit", false, "UnlimitedZoom", function(v) applyUnlimitedZoom() end)
RegSlider(Tabs.Visual, "Max Zoom Distance", "Max camera distance", 1000, 100, 5000, 50, "MaxZoomDistance", function(v) if VD.UnlimitedZoom then applyUnlimitedZoom() end end)
RegToggle(Tabs.Visual, "Custom FOV", "Custom field of view", false, "FOVEnabled", function(v) applyCameraFOV() end)
RegSlider(Tabs.Visual, "Camera FOV", "Field of view", 70, 40, 120, 1, "FOV", function(v) if VD.FOVEnabled then applyCameraFOV() end end)

shiftLockWasActive = false
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera; if not cam then return end
    if VD.ThirdPerson and GetRole() == "Killer" then
        cam.CameraType = Enum.CameraType.Custom
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.new(2, 1, 8) end
    end
    if VD.ShiftLock then
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            hum.AutoRotate = false
            local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            if flat.Magnitude > 0.001 then root.CFrame = CFrame.new(root.Position, root.Position + flat.Unit) end
        end
        shiftLockWasActive = true
    elseif shiftLockWasActive then
        local hum = getHum(); if hum then hum.AutoRotate = true end
        shiftLockWasActive = false
    end
    if VD.InfinityZoom then Player.CameraMaxZoomDistance = math.huge; Player.CameraMinZoomDistance = 0 end
end)
RegToggle(Tabs.Visual, "Third Person (Killer)", "Third person camera", false, "ThirdPerson")
RegToggle(Tabs.Visual, "Shift Lock", "Enable shift lock", false, "ShiftLock")
RegToggle(Tabs.Visual, "Infinity Zoom Out", "Unlimited zoom out", false, "InfinityZoom")
RegToggle(Tabs.Visual, "No Cutscene", "Skip cutscenes", false, "NoCutscene")
RegDivider(Tabs.Visual)
RegLabel(Tabs.Visual, "Lighting")
RegToggle(Tabs.Visual, "Fullbright", "Full bright lighting", false, "Fullbright")
RegToggle(Tabs.Visual, "No Fog", "Remove fog", false, "NO_Fog")

VD_WeatherPresets = {
    ["Default"] = {},
    ["Christmas (Snow)"] = { Lighting={FogColor=Color3.fromRGB(150,180,220),FogEnd=200,ClockTime=8,OutdoorAmbient=Color3.fromRGB(100,120,150)}, Atmosphere={Density=0.5,Color=Color3.fromRGB(180,200,220),Decay=Color3.fromRGB(150,180,220),Haze=5,Glare=0} },
    ["Heavy Rain (Storm)"] = { Lighting={FogColor=Color3.fromRGB(50,50,60),FogEnd=150,OutdoorAmbient=Color3.fromRGB(40,40,50),Brightness=0.2,ClockTime=12}, CC={TintColor=Color3.fromRGB(150,150,180),Contrast=0.2,Saturation=-0.5} },
    ["Autumn (Musim Gugur)"] = { Lighting={FogColor=Color3.fromRGB(200,150,80),FogEnd=500,OutdoorAmbient=Color3.fromRGB(180,140,70),ClockTime=16.5}, CC={TintColor=Color3.fromRGB(255,220,180),Contrast=0.1,Saturation=0.2} },
    ["Cherry Blossom (Sakura)"] = { Lighting={FogColor=Color3.fromRGB(255,200,220),FogEnd=600,OutdoorAmbient=Color3.fromRGB(255,180,200),ClockTime=9}, CC={TintColor=Color3.fromRGB(255,230,240),Saturation=0.3} },
    ["Sunset (Golden Hour)"] = { Lighting={FogColor=Color3.fromRGB(255,120,50),FogEnd=1200,OutdoorAmbient=Color3.fromRGB(200,100,50),ClockTime=17.5,Brightness=1.5}, CC={TintColor=Color3.fromRGB(255,200,150),Contrast=0.2,Saturation=0.4} },
    ["Blood Moon (Spooky)"] = { Lighting={FogColor=Color3.fromRGB(150,10,10),FogEnd=500,OutdoorAmbient=Color3.fromRGB(80,0,0),ClockTime=0,Brightness=0.3}, CC={TintColor=Color3.fromRGB(255,50,50),Contrast=0.4,Saturation=0.5} },
    ["Toxic Wasteland"] = { Lighting={FogColor=Color3.fromRGB(80,150,50),FogEnd=250,OutdoorAmbient=Color3.fromRGB(50,120,40),ClockTime=12,Brightness=1}, CC={TintColor=Color3.fromRGB(150,255,150),Contrast=0.1,Saturation=0.3} },
    ["Vaporwave (Synthwave)"] = { Lighting={FogColor=Color3.fromRGB(200,50,255),FogEnd=500,OutdoorAmbient=Color3.fromRGB(150,0,200),ClockTime=20,Brightness=1}, CC={TintColor=Color3.fromRGB(255,100,255),Contrast=0.3,Saturation=0.5} },
    ["Midnight (Pitch Black)"] = { Lighting={FogColor=Color3.fromRGB(0,0,0),FogEnd=100,OutdoorAmbient=Color3.fromRGB(0,0,0),Brightness=0,ClockTime=0}, CC={TintColor=Color3.fromRGB(50,50,50),Contrast=0.5,Saturation=-0.8} }
}
function VD_ApplyWeather(themeName)
    local theme = VD_WeatherPresets[themeName] or VD_WeatherPresets["Default"]
    if getgenv().VD_WeatherCC and getgenv().VD_WeatherCC.Parent then getgenv().VD_WeatherCC:Destroy() end
    getgenv().VD_WeatherCC = nil
    if getgenv().VD_WeatherAtmosphere and getgenv().VD_WeatherAtmosphere.Parent then getgenv().VD_WeatherAtmosphere:Destroy() end
    getgenv().VD_WeatherAtmosphere = nil
    if theme.Atmosphere then
        local atm = Instance.new("Atmosphere"); atm.Name = "VD_WeatherAtmosphere"
        for k, v in pairs(theme.Atmosphere) do pcall(function() atm[k] = v end) end
        atm.Parent = Lighting; getgenv().VD_WeatherAtmosphere = atm
    end
    if theme.CC then
        local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "VD_WeatherCC"
        for k, v in pairs(theme.CC) do pcall(function() cc[k] = v end) end
        cc.Parent = Lighting; getgenv().VD_WeatherCC = cc
    end
    if theme.Lighting then for k, v in pairs(theme.Lighting) do pcall(function() Lighting[k] = v end) end end
end
task.spawn(function()
    while not VD.Destroyed do
        if VD.Fullbright then
            Lighting.Brightness = 2; Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
            Lighting.FogStart = 0; Lighting.FogEnd = 100000
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") and v.Name ~= "VD_WeatherAtmosphere" then v.Density = 0; v.Offset = 0; v.Glare = 0; v.Haze = 0 end
                if v:IsA("BlurEffect") then v.Size = 0 end
                if v:IsA("ColorCorrectionEffect") and v.Name ~= "VD_WeatherCC" then v.Enabled = false end
                if v:IsA("SunRaysEffect") then v.Enabled = false end
            end
        elseif not VD.NO_Fog then
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart or 0
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        end
        if VD.NO_Fog then Lighting.FogEnd = 100000; Lighting.FogStart = 0 end
        task.wait(0.5)
    end
end)
RegDropdown(Tabs.Visual, "Weather & Sky Theme", "Select weather theme",
    {"Default","Christmas (Snow)","Heavy Rain (Storm)","Autumn (Musim Gugur)","Cherry Blossom (Sakura)","Sunset (Golden Hour)","Blood Moon (Spooky)","Toxic Wasteland","Vaporwave (Synthwave)","Midnight (Pitch Black)"},
    "Default", false, "WeatherTheme", function(v) pcall(VD_ApplyWeather, v) end)

-- Visual Implementations
PingFPSGui, PingFPSConn = nil, nil
VD_TogglePingFPS = function(state)
    if PingFPSConn then PingFPSConn:Disconnect(); PingFPSConn = nil end
    if PingFPSGui then PingFPSGui:Destroy(); PingFPSGui = nil end
    if not state then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "MWD_PingFPS"; sg.IgnoreGuiInset = true; sg.ResetOnSpawn = false; sg.Parent = PlayerGui
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,118,0,44); f.Position = UDim2.new(0,12,0,120)
    f.BackgroundColor3 = Color3.fromRGB(16,18,24); f.BackgroundTransparency = 0.1; f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke", f); st.Color = Color3.fromRGB(96,72,160); st.Thickness = 1
    local lbl = Instance.new("TextLabel", f)
    lbl.Name = "PFLabel"; lbl.Size = UDim2.new(1,-12,1,-8); lbl.Position = UDim2.new(0,6,0,4)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(230,235,245); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "PING: --ms\nFPS: --"
    PingFPSGui = sg
    local frames, last = 0, tick()
    PingFPSConn = RunService.RenderStepped:Connect(function()
        if not VD.ShowPingFPS then return end
        frames = frames + 1
        local now = tick()
        if now - last < 0.5 then return end
        local fps = math.floor(frames / (now - last) + 0.5)
        local ping
        pcall(function()
            local stats = game:GetService("Stats")
            local srv = stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem")
            local dp = srv and srv:FindFirstChild("Data Ping")
            if dp and dp.GetValue then ping = math.floor(dp:GetValue() + 0.5) end
        end)
        frames = 0; last = now
        if lbl and lbl.Parent then lbl.Text = ("PING: %sms\nFPS: %d"):format(ping and tostring(ping) or "--", fps) end
    end)
end

HideSurvConn, HideSurvOrig = nil, {}
VD_ApplyHideSurvIcon = function()
    local pg = Player:FindFirstChild("PlayerGui"); if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:match("%-mob$") then
            local frame = gui:FindFirstChild("Frame")
            if frame then
                for i = 1, 5 do
                    local sf = frame:FindFirstChild("Survivor" .. i)
                    local il = sf and sf:FindFirstChild("ImageLabel")
                    if il and il:IsA("ImageLabel") then
                        if not HideSurvOrig[il] then HideSurvOrig[il] = { Image=il.Image, Color=il.ImageColor3, Trans=il.ImageTransparency, Offset=il.ImageRectOffset, Size=il.ImageRectSize, Scale=il.ScaleType } end
                        il.Image = ICON_URL; il.ImageColor3 = Color3.fromRGB(255,255,255); il.ImageTransparency = 0
                        il.ImageRectOffset = Vector2.new(0,0); il.ImageRectSize = Vector2.new(0,0); il.ScaleType = Enum.ScaleType.Crop
                    end
                    local tl = sf and sf:FindFirstChild("TextLabel")
                    if tl and tl:IsA("TextLabel") then
                        if not HideSurvOrig[tl] then HideSurvOrig[tl] = { Text = tl.Text, TextTransparency = tl.TextTransparency, TextStrokeTransparency = tl.TextStrokeTransparency, Visible = tl.Visible } end
                        tl.TextTransparency = 1; tl.TextStrokeTransparency = 1
                    end
                end
            end
        end
    end
end
VD_RestoreHideSurvIcon = function()
    for obj, orig in pairs(HideSurvOrig) do
        if obj and obj.Parent then
            pcall(function()
                if obj:IsA("ImageLabel") then
                    obj.Image = orig.Image; obj.ImageColor3 = orig.Color; obj.ImageTransparency = orig.Trans
                    obj.ImageRectOffset = orig.Offset; obj.ImageRectSize = orig.Size; obj.ScaleType = orig.Scale
                elseif obj:IsA("TextLabel") then
                    obj.Text = orig.Text; obj.TextTransparency = orig.TextTransparency
                    obj.TextStrokeTransparency = orig.TextStrokeTransparency; obj.Visible = orig.Visible
                end
            end)
        end
    end
    HideSurvOrig = {}
end
VD_ToggleHideSurvIcon = function(v)
    VD.HideSurvIcon = v
    if v then
        VD_ApplyHideSurvIcon()
        if not HideSurvConn then
            HideSurvConn = RunService.Heartbeat:Connect(function() if VD.HideSurvIcon then VD_ApplyHideSurvIcon() end end)
        end
    else
        if HideSurvConn then HideSurvConn:Disconnect(); HideSurvConn = nil end
        VD_RestoreHideSurvIcon()
    end
end

HookCounterConn = nil
VD_UpdateHookCounter = function(enabled)
    local pg = Player:FindFirstChild("PlayerGui"); if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:match("%-mob$") then
            local frame = gui:FindFirstChild("Frame")
            if frame then
                for i = 1, 5 do
                    local sf = frame:FindFirstChild("Survivor" .. i)
                    local il = sf and sf:FindFirstChild("ImageLabel")
                    local tl = sf and sf:FindFirstChild("TextLabel")
                    if il and tl then
                        local lbl = il:FindFirstChild("MWD_CustomHookCounter")
                        if enabled then
                            local pName = tl.Text
                            local target
                            for _, p in ipairs(Players:GetPlayers()) do if p.Name == pName or p.DisplayName == pName then target = p; break end end
                            local cnt = 0
                            if target then cnt = target:GetAttribute("HookCount") or (target.Character and target.Character:GetAttribute("HookCount")) or 0 end
                            if not lbl then
                                lbl = Instance.new("TextLabel", il)
                                lbl.Name = "MWD_CustomHookCounter"; lbl.Size = UDim2.new(1,0,0.35,0); lbl.Position = UDim2.new(0,0,0.65,0)
                                lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.BackgroundTransparency = 0.5
                                lbl.TextStrokeTransparency = 0; lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansBold
                            end
                            lbl.Visible = true
                            if cnt >= 3 then lbl.Text = "DEAD"; lbl.TextColor3 = Color3.fromRGB(255,75,75)
                            else
                                lbl.Text = "Hooks: " .. tostring(cnt)
                                if cnt == 2 then lbl.TextColor3 = Color3.fromRGB(255,140,0)
                                elseif cnt == 1 then lbl.TextColor3 = Color3.fromRGB(255,215,0)
                                else lbl.TextColor3 = Color3.fromRGB(255,255,255) end
                            end
                        elseif lbl then lbl.Visible = false end
                    end
                end
            end
        end
    end
end
VD_ToggleHookCounter = function(v)
    VD.ShowHookCounter = v
    if v then
        VD_UpdateHookCounter(true)
        if not HookCounterConn then
            HookCounterConn = RunService.Heartbeat:Connect(function() if VD.ShowHookCounter then VD_UpdateHookCounter(true) end end)
        end
    else
        if HookCounterConn then HookCounterConn:Disconnect(); HookCounterConn = nil end
        VD_UpdateHookCounter(false)
    end
end

InfoOverlayGui, InfoOverlayFrame, InfoOverlayLabel = nil, nil, nil
function EnsureInfoOverlay()
    if InfoOverlayGui and InfoOverlayGui.Parent then return end
    InfoOverlayGui = Instance.new("ScreenGui")
    InfoOverlayGui.Name = "MWD_InfoOverlay"; InfoOverlayGui.ResetOnSpawn = false; InfoOverlayGui.IgnoreGuiInset = true
    InfoOverlayGui.Parent = PlayerGui
    InfoOverlayFrame = Instance.new("Frame")
    InfoOverlayFrame.Size = UDim2.new(0, 230, 0, 0); InfoOverlayFrame.AutomaticSize = Enum.AutomaticSize.Y
    InfoOverlayFrame.Position = UDim2.new(0, 12, 0, 180)
    InfoOverlayFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24); InfoOverlayFrame.BackgroundTransparency = 0.1
    InfoOverlayFrame.BorderSizePixel = 0; InfoOverlayFrame.Parent = InfoOverlayGui
    Instance.new("UICorner", InfoOverlayFrame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", InfoOverlayFrame); stroke.Color = Color3.fromRGB(96, 72, 160); stroke.Thickness = 1
    local pad = Instance.new("UIPadding", InfoOverlayFrame)
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
    InfoOverlayLabel = Instance.new("TextLabel")
    InfoOverlayLabel.Size = UDim2.new(1, 0, 0, 0); InfoOverlayLabel.AutomaticSize = Enum.AutomaticSize.Y
    InfoOverlayLabel.BackgroundTransparency = 1; InfoOverlayLabel.Font = Enum.Font.GothamBold
    InfoOverlayLabel.TextSize = 12; InfoOverlayLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
    InfoOverlayLabel.TextXAlignment = Enum.TextXAlignment.Left; InfoOverlayLabel.TextYAlignment = Enum.TextYAlignment.Top
    InfoOverlayLabel.TextWrapped = true; InfoOverlayLabel.Text = ""; InfoOverlayLabel.Parent = InfoOverlayFrame
end
function UpdateInfoOverlay()
    local anyOn = VD.MawwwtKiller or VD.SpectatorCounter or VD.KillerPerks
    if not anyOn then if InfoOverlayFrame then InfoOverlayFrame.Visible = false end; return end
    if not InfoOverlayFrame then EnsureInfoOverlay() end
    InfoOverlayFrame.Visible = true
    local lines = {}
    if VD.MawwwtKiller then
        local list = Players:GetPlayers()
        table.sort(list, function(a, b)
            local aA = a:GetAttribute("AllowKiller") or false
            local bB = b:GetAttribute("AllowKiller") or false
            if aA ~= bB then return aA == true end
            return (a:GetAttribute("KillerChance") or 0) > (b:GetAttribute("KillerChance") or 0)
        end)
        local nk = list[1]
        local nkName = nk and (nk == Player and "YOU" or (nk.DisplayName or nk.Name)) or "Unknown"
        local nkScore = nk and (nk:GetAttribute("KillerChance") or 0) or 0
        table.insert(lines, string.format("[Killer Chance] %s (%d)", nkName, nkScore))
    end
    if VD.SpectatorCounter then
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do if p.Team and p.Team.Name == "Spectator" then count = count + 1 end end
        table.insert(lines, string.format("[Spectators] %d", count))
    end
    if VD.KillerPerks then
        local k = nil
        for _, p in ipairs(Players:GetPlayers()) do if p ~= Player and IsKiller(p) then k = p; break end end
        if k then table.insert(lines, string.format("[Killer] %s", k.DisplayName or k.Name))
        else table.insert(lines, "[Killer] None") end
    end
    InfoOverlayLabel.Text = table.concat(lines, "\n")
end
task.spawn(function()
    while not VD.Destroyed do task.wait(1); pcall(UpdateInfoOverlay) end
end)

RegToggle(Tabs.Visual, "Show Ping & FPS", "Display ping and FPS", false, "ShowPingFPS", function(v) VD.ShowPingFPS = v; VD_TogglePingFPS(v) end)
RegToggle(Tabs.Visual, "Hide Survivor Icon", "Hide survivor icon", false, "HideSurvIcon", function(v) VD_ToggleHideSurvIcon(v) end)
RegToggle(Tabs.Visual, "Show Hook Counter", "Display hook counter", false, "ShowHookCounter", function(v) VD_ToggleHookCounter(v) end)
RegToggle(Tabs.Visual, "Mawwwt Killer Display", "Show killer chance", false, "MawwwtKiller")
RegToggle(Tabs.Visual, "Spectator Counter", "Show spectator count", false, "SpectatorCounter")
RegToggle(Tabs.Visual, "Killer Perks Display", "Show killer info", false, "KillerPerks")

task.spawn(function()
    while not VD.Destroyed do
        task.wait(1.5)
        pcall(function()
            if VD.ShowPingFPS and not PingFPSGui then VD_TogglePingFPS(true) end
            if not VD.ShowPingFPS and PingFPSGui then VD_TogglePingFPS(false) end
            if VD.HideSurvIcon and not HideSurvConn then VD_ToggleHideSurvIcon(true) end
            if not VD.HideSurvIcon and HideSurvConn then VD_ToggleHideSurvIcon(false) end
            if VD.ShowHookCounter and not HookCounterConn then VD_ToggleHookCounter(true) end
            if not VD.ShowHookCounter and HookCounterConn then VD_ToggleHookCounter(false) end
        end)
    end
end)

--========================================================--
-- UTILITY TAB
--========================================================--
RegLabel(Tabs.Utility, "═══ Teleport ═══")
function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(list, p.Name) end end
    table.sort(list)
    if #list == 0 then table.insert(list, "No players") end
    return list
end
selectedTeleportPlayer = ""
teleportDropdown = nil
pcall(function()
    if Tabs.Utility then
        teleportDropdown = Tabs.Utility:Dropdown({
            Title = "Select Player", Flag = "TeleportPlayer", Values = getPlayerList(), Value = "No players",
            Multi = false,
            Callback = function(v) selectedTeleportPlayer = v end,
        })
    end
end)
RegButton(Tabs.Utility, "Refresh Player List", "Refresh player dropdown", function()
    pcall(function() if teleportDropdown and teleportDropdown.Refresh then teleportDropdown:Refresh(getPlayerList()) end end)
    notify("Teleport", "Player list refreshed", 2)
end)
RegButton(Tabs.Utility, "Teleport to Player", "Teleport to selected player", function()
    if selectedTeleportPlayer == "" or selectedTeleportPlayer == "No players" then notify("Teleport", "Select a player first", 3); return end
    local target = Players:FindFirstChild(selectedTeleportPlayer)
    local root = getRoot()
    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3); notify("Teleport", "Teleported to " .. selectedTeleportPlayer, 3) end
end)
function VD_TPToPosition(pos)
    if not pos then return false end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then return false end
    root.CFrame = CFrame.new(pos + Vector3.new(0, VD.TP_Offset, 0)); return true
end
RegButton(Tabs.Utility, "TP to Nearest Generator", "Teleport to generator", function()
    local root = getRoot(); if not root then return end
    local best, bd = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if p then local d = (p.Position - root.Position).Magnitude; if d < bd then bd = d; best = p end end
        end
    end
    if best then VD_TPToPosition(best.Position); notify("TP", "Teleported to Generator", 2) end
end)
RegButton(Tabs.Utility, "TP to Nearest Hook", "Teleport to hook", function()
    local root = getRoot(); if not root then return end
    local best, bd = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Hook" and obj:IsA("Model") then
            local p = obj:FindFirstChildWhichIsA("BasePart", true)
            if p then local d = (p.Position - root.Position).Magnitude; if d < bd then bd = d; best = p end end
        end
    end
    if best then VD_TPToPosition(best.Position); notify("TP", "Teleported to Hook", 2) end
end)

RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Gen Boost")
W = getgenv().MAWWW or {}
getgenv().MAWWW = W
if not W.GenBypass then W.GenBypass = { Enabled=false, Cache={}, CacheTimer=0, Processed={}, TriggerRange=8, HotkeyCode=Enum.KeyCode.G, UI=nil, Button=nil } end
GenBypass = W.GenBypass
function W.GB_GetAllGenerators()
    local now = tick()
    if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
    GenBypass.Cache = {}; GenBypass.CacheTimer = now
    local mf = workspace:FindFirstChild("Map"); if not mf then return GenBypass.Cache end
    pcall(function()
        for _, v in pairs(mf:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Generator" then
                local real = v:GetAttribute("RepairProgress") ~= nil or v:GetAttribute("kickcount") ~= nil or v:GetAttribute("ProgressRepair") ~= nil
                if real then table.insert(GenBypass.Cache, v) end
            end
        end
    end)
    return GenBypass.Cache
end
function W.GB_GetPoints(m)
    local pts = {}
    pcall(function() for _, o in pairs(m:GetChildren()) do if o.Name:find("GeneratorPoint") and o:IsA("BasePart") then table.insert(pts, o) end end end)
    return pts
end
function W.GB_WaitRepairing(pt, t)
    local s = tick()
    while tick() - s < (t or 1) do if pt:GetAttribute("IsRepairing") == true then return true end; task.wait(0.05) end
    return false
end
function W.GB_DoRepair(tp)
    local gm = tp.Parent
    if GenBypass.Processed[gm] then return end
    GenBypass.Processed[gm] = true
    local c = Player.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then GenBypass.Processed[gm] = nil; return end
    local re = GetRemotes() and ReplicatedStorage.Remotes:FindFirstChild("Generator") and ReplicatedStorage.Remotes.Generator:FindFirstChild("RepairEvent")
    local og = hrp.CFrame
    pcall(function()
        for _, p in pairs(W.GB_GetPoints(gm)) do
            if p ~= tp and p.Parent then
                hrp.Anchored = true; hrp.CFrame = p.CFrame; task.wait(0.15)
                pcall(function() if re then re:FireServer(p, true) end end)
                if not W.GB_WaitRepairing(p, 0.8) then
                    pcall(function() if re then re:FireServer(p, false) end end); task.wait(0.1)
                    hrp.CFrame = p.CFrame; task.wait(0.15)
                    pcall(function() if re then re:FireServer(p, true) end end)
                    W.GB_WaitRepairing(p, 0.5)
                end
                hrp.Anchored = false; task.wait(0.05)
            end
        end
    end)
    pcall(function() if hrp and hrp.Parent then hrp.Anchored = false; hrp.CFrame = og end end)
    task.wait(0.1); pcall(function() if re then re:FireServer(tp, false) end end)
end
function W.GB_GetNearestPoint()
    local c = Player.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bd = nil, math.huge
    for _, g in pairs(W.GB_GetAllGenerators()) do
        for _, p in pairs(W.GB_GetPoints(g)) do
            local d = (hrp.Position - p.Position).Magnitude
            if d < bd then bd = d; best = p end
        end
    end
    return best, bd
end
function W.GB_IsPromptVisible()
    local ok, fr = pcall(function() return PlayerGui.pcprompts.Frame.GeneratorRepair end)
    return ok and fr and fr.Visible
end
function W.GB_UpdateButton() if GenBypass.Button then GenBypass.Button.Visible = GenBypass.Enabled and isMobile end end
function W.GB_CreateButton()
    local old = PlayerGui:FindFirstChild("BypassGenUI"); if old then old:Destroy() end
    GenBypass.UI = Instance.new("ScreenGui"); GenBypass.UI.Name = "BypassGenUI"; GenBypass.UI.ResetOnSpawn = false; GenBypass.UI.IgnoreGuiInset = true; GenBypass.UI.Parent = PlayerGui
    GenBypass.Button = Instance.new("ImageButton")
    GenBypass.Button.Name = "BypassGenButton"; GenBypass.Button.Size = UDim2.new(0, 60, 0, 60); GenBypass.Button.Position = UDim2.new(0.88, 0, 0.55, 0)
    GenBypass.Button.AnchorPoint = Vector2.new(0.5, 0.5); GenBypass.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20); GenBypass.Button.Visible = false; GenBypass.Button.Parent = GenBypass.UI
    Instance.new("UICorner", GenBypass.Button).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", GenBypass.Button); st.Color = Color3.fromRGB(255, 0, 0); st.Thickness = 2; st.Transparency = 0.2; st.Parent = GenBypass.Button
    local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(1, 0, 1, 0); lb.BackgroundTransparency = 1; lb.Text = "GEN"; lb.TextColor3 = Color3.fromRGB(255, 255, 255); lb.TextScaled = true; lb.Font = Enum.Font.GothamBlack; lb.Parent = GenBypass.Button
    GenBypass.Button.MouseButton1Click:Connect(function()
        if not GenBypass.Enabled then return end
        local bp, bd = W.GB_GetNearestPoint()
        if bp and bd <= GenBypass.TriggerRange then W.GB_DoRepair(bp) end
    end)
end
W.GB_CreateButton()
Player.CharacterAdded:Connect(function() task.wait(0.5); W.GB_CreateButton(); W.GB_UpdateButton() end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or isMobile then return end
    if input.KeyCode == GenBypass.HotkeyCode and GenBypass.Enabled then
        if not W.GB_IsPromptVisible() then return end
        local bp, bd = W.GB_GetNearestPoint()
        if not bp or bd > GenBypass.TriggerRange then return end
        if GenBypass.Processed[bp.Parent] then return end
        W.GB_DoRepair(bp)
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(2)
        local c = Player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for gm in pairs(GenBypass.Processed) do
                if not gm or not gm.Parent then
                    GenBypass.Processed[gm] = nil
                else
                    local near = false
                    for _, p in pairs(W.GB_GetPoints(gm)) do
                        if p.Parent and (hrp.Position - p.Position).Magnitude <= 10 then near = true; break end
                    end
                    if not near then GenBypass.Processed[gm] = nil end
                end
            end
        end
    end
end)
function W.setGenBypass(v)
    GenBypass.Enabled = v; VD.GenBoost = v; W.GB_UpdateButton()
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.4)
        if GenBypass.Enabled and GetRole() == "Survivor" then
            if not W.GB_IsPromptVisible() then
                local bp, bd = W.GB_GetNearestPoint()
                if bp and bd and bd <= GenBypass.TriggerRange then
                    if not GenBypass.Processed[bp.Parent] then task.spawn(function() pcall(function() W.GB_DoRepair(bp) end) end) end
                end
            end
        end
    end
end)
RegToggle(Tabs.Utility, "GEN BOOST ON/OFF (Press G)", "Auto repair generator", false, "GenBoost", function(v) W.setGenBypass(v) end)
RegButton(Tabs.Utility, "Repair Nearest Gen (Manual)", "Manually repair nearest generator", function()
    local p, d = W.GB_GetNearestPoint()
    if p and d and d <= GenBypass.TriggerRange then W.GB_DoRepair(p)
    elseif p then notify("Gen Boost", string.format("Gen terlalu jauh (%.1f studs).", d), 3)
    else notify("Gen Boost", "Tidak ada generator ditemukan.", 3) end
end)
RegToggle(Tabs.Utility, "Show GenBoss Icon", "Show gen boss icon", false, "ShowGenBossIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)
RegToggle(Tabs.Utility, "Lock GenBoss Icon", "Lock icon position", false, "LockGenBossIcon", function(v)
    if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
end)

RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Anti-AFK")
RegToggle(Tabs.Utility, "Enable Anti-AFK", "Prevent AFK kick", false, "AntiAFK")
task.spawn(function()
    while not VD.Destroyed do
        task.wait(60)
        if VD.AntiAFK then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0, 0)) end) end
    end
end)

RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Quick Actions")
RegButton(Tabs.Utility, "Rejoin Server Instantly", "Rejoin current server", function()
    notify("Rejoin", "Rejoining...", 2); task.wait(0.3)
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end)
end)
RegButton(Tabs.Utility, "Reset Character", "Reset your character", function()
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.Health = 0 end); notify("Reset", "Character reset!", 2)
    else notify("Reset", "No character found", 2) end
end)

RegDivider(Tabs.Utility)
RegLabel(Tabs.Utility, "Server Hop")
MAX_HISTORY_SIZE = 200
function VD_SH_MarkVisited(jobId)
    if not jobId or jobId == "" then return end
    VD.SH_VisitedServers[jobId] = tick()
    local count = 0
    for _ in pairs(VD.SH_VisitedServers) do count = count + 1 end
    if count > MAX_HISTORY_SIZE then
        local oldestId, oldestT = nil, math.huge
        for id, t in pairs(VD.SH_VisitedServers) do if t < oldestT then oldestT = t; oldestId = id end end
        if oldestId then VD.SH_VisitedServers[oldestId] = nil end
    end
end
function VD_SH_GetServerList()
    local list = {}
    local placeId = game.PlaceId; local myJobId = game.JobId
    local visited = VD.SH_VisitedServers or {}
    local cursor = nil
    for _ = 1, 3 do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&cursor=%s", placeId, cursor or "")
        local ok, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(url, true)) end)
        if not ok or not result or not result.data then break end
        for _, s in ipairs(result.data) do
            if s.id and s.playing and s.maxPlayers then
                local skip = (s.id == myJobId)
                if not skip and VD.SH_SkipVisited and visited[s.id] then skip = true end
                if not skip and s.playing < (VD.SH_MinPlayers or 3) then skip = true end
                if not skip and s.playing >= s.maxPlayers then skip = true end
                if not skip then table.insert(list, { Id=s.id, Playing=s.playing, Max=s.maxPlayers, Ping=s.ping or 999, FillRate=s.playing / math.max(s.maxPlayers, 1) }) end
            end
        end
        if result.nextPageCursor then cursor = result.nextPageCursor else break end
    end
    for i = #list, 2, -1 do local j = math.random(1, i); list[i], list[j] = list[j], list[i] end
    return list
end
function VD_SH_PickServer()
    local list = VD_SH_GetServerList(); if #list == 0 then return nil end
    if VD.SH_RandomHop then return list[math.random(1, #list)] end
    for _, s in ipairs(list) do if s.FillRate >= 0.6 then return s end end
    return list[1]
end
function VD_SH_Hop(reason)
    if VD.SH_IsHopping then notify("Server Hop", "Sedang hop...", 2); return end
    if tick() - VD.SH_LastHopTime < (VD.SH_HopCooldown or 15) then
        local cd = math.ceil((VD.SH_HopCooldown or 15) - (tick() - VD.SH_LastHopTime))
        notify("Server Hop", "Cooldown " .. cd .. "s", 2); return
    end
    VD.SH_IsHopping = true; VD.SH_LastHopTime = tick()
    notify("Server Hop", reason or "Mencari server...", 3)
    if game.JobId and game.JobId ~= "" then VD_SH_MarkVisited(game.JobId) end
    local target = VD_SH_PickServer()
    if not target and VD.SH_AutoResetWhenAllVisited then
        local visitedCount = 0
        for _ in pairs(VD.SH_VisitedServers) do visitedCount = visitedCount + 1 end
        if visitedCount > 1 then
            VD.SH_VisitedServers = {}
            if game.JobId and game.JobId ~= "" then VD.SH_VisitedServers[game.JobId] = tick() end
            target = VD_SH_PickServer()
        end
    end
    if not target then
        pcall(function() TeleportService:Teleport(game.PlaceId, Player) end)
        task.wait(3); VD.SH_IsHopping = false; return
    end
    VD_SH_MarkVisited(target.Id)
    local modeTxt = VD.SH_RandomHop and "RANDOM" or "BEST"
    notify("Server Hop", string.format("[%s] -> [%d/%d] Ping:%d", modeTxt, target.Playing, target.Max, target.Ping), 3)
    local teleportOk = false
    for _ = 1, (VD.SH_MaxRetries or 5) do
        local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target.Id, Player) end)
        if ok then teleportOk = true; VD.SH_HopCount = VD.SH_HopCount + 1; break end
        task.wait(1)
    end
    if not teleportOk then pcall(function() TeleportService:Teleport(game.PlaceId, Player) end) end
    task.wait(5); VD.SH_IsHopping = false
end
RegToggle(Tabs.Utility, "SERVER HOP ON/OFF", "Enable server hop", false, "SH_Enabled")
RegToggle(Tabs.Utility, "Hop ke SERVER ACAK", "Random hop", true, "SH_RandomHop")
RegToggle(Tabs.Utility, "Hop setelah Match", "Hop after match", true, "SH_HopAfterMatch")
RegToggle(Tabs.Utility, "Skip Visited Server", "Skip visited servers", true, "SH_SkipVisited")
RegToggle(Tabs.Utility, "Auto Reset When All Visited", "Reset history when all visited", true, "SH_AutoResetWhenAllVisited")
RegSlider(Tabs.Utility, "Hop Cooldown (s)", "Cooldown between hops", 15, 5, 120, 1, "SH_HopCooldown")
RegSlider(Tabs.Utility, "Min Players Target", "Minimum players", 3, 1, 20, 1, "SH_MinPlayers")
RegButton(Tabs.Utility, "Hop Random Sekarang", "Manual random hop", function() VD_SH_Hop("Manual random hop") end)
RegButton(Tabs.Utility, "Reset History Server", "Reset visited servers", function()
    VD.SH_VisitedServers = {}
    if game.JobId and game.JobId ~= "" then VD.SH_VisitedServers[game.JobId] = tick() end
    notify("Server Hop", "History server di-reset!", 3)
end)
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(_, result)
        VD.SH_IsHopping = false; VD.SH_LastHopTime = 0
        notify("Server Hop", "Teleport gagal: " .. tostring(result), 3)
    end)
end)

--========================================================--
-- AUTO FARM TAB
--========================================================--
RegLabel(Tabs.AutoFarm, "═══ AUTO FARM LEVEL ═══")
function AF_ClickLobbyButton()
    local pg = Player:FindFirstChild("PlayerGui"); if not pg then return false end
    local keywords = {"Play","Ready","Start","Confirm","Join","Continue","Requeue","Vote","Yes","Begin"}
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextButton") or d:IsA("ImageButton") then
                    local txt = ""; pcall(function() txt = tostring(d.Text or "") end)
                    for _, kw in ipairs(keywords) do
                        if txt:lower():find(kw:lower(), 1, true) and d.Visible then
                            pcall(function() d:Activate() end)
                            if typeof(firesignal) == "function" then pcall(function() firesignal(d.MouseButton1Click) end) end
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
function AF_IsInMatch()
    local char = Player.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return false end
    local r = GetRole(); return r == "Killer" or r == "Survivor"
end
RegToggle(Tabs.AutoFarm, "AUTO FARM ON/OFF", "Enable auto farm", false, "AF_Enabled")
RegDropdown(Tabs.AutoFarm, "Mode", "Farm mode", {"Auto","Survivor","Killer"}, "Auto", false, "AF_Mode")
RegToggle(Tabs.AutoFarm, "Auto Ready / Join", "Auto ready/join", true, "AF_AutoReady")
RegToggle(Tabs.AutoFarm, "Auto Requeue", "Auto requeue", true, "AF_AutoRequeue")
RegToggle(Tabs.AutoFarm, "AUTO EXIT GATE INSTANT", "Instant escape", true, "AF_AutoEscapeNow")
RegToggle(Tabs.AutoFarm, "Auto Skillcheck", "Auto skillcheck", true, "AF_AutoSkill")
RegToggle(Tabs.AutoFarm, "Auto Heal Self", "Auto heal self", true, "AF_AutoHeal")
RegToggle(Tabs.AutoFarm, "Killer: Auto Attack", "Auto attack as killer", true, "AF_AutoAttack")
RegToggle(Tabs.AutoFarm, "Killer: Auto Hook", "Auto hook as killer", true, "AF_AutoHook")
RegButton(Tabs.AutoFarm, "Status Auto Farm", "Show auto farm status", function()
    local mins = math.floor((tick() - VD.AF_StartTime) / 60)
    local mode = VD.SH_RandomHop and "RANDOM" or "BEST"
    local visitedCount = 0
    for _ in pairs(VD.SH_VisitedServers) do visitedCount = visitedCount + 1 end
    notify("Auto Farm Status", string.format("%s\n%d menit | %d match | Hop: %d\nMode: %s | History: %d server", VD.AF_Status, mins, VD.AF_MatchesPlayed, VD.SH_HopCount, mode, visitedCount), 5)
end)
task.spawn(function()
    VD.AF_StartTime = tick()
    while not VD.Destroyed do
        task.wait(0.3)
        if not VD.AF_Enabled then VD.AF_Status = "Idle"
        else
            local role = GetRole(); local prevRole = VD.SH_LastRole
            if (prevRole == "Killer" or prevRole == "Survivor") and (role == "Lobby" or role == "Unknown") then
                VD.AF_MatchesPlayed = VD.AF_MatchesPlayed + 1; VD.SH_LobbyEnterTime = tick()
                notify("Auto Farm", "Match selesai! Total: " .. VD.AF_MatchesPlayed, 3)
                if VD.SH_Enabled and VD.SH_HopAfterMatch then VD_SH_Hop("Match selesai"); task.wait(5) end
            end
            VD.SH_LastRole = role
            if role == "Lobby" or role == "Unknown" then
                if VD.SH_LobbyEnterTime == 0 then VD.SH_LobbyEnterTime = tick() end
                local lobbyTime = tick() - VD.SH_LobbyEnterTime
                VD.AF_Status = string.format("Lobby - %ds / %ds", math.floor(lobbyTime), VD.SH_WaitingTimeout)
                if VD.AF_AutoReady then pcall(AF_ClickLobbyButton) end
                if VD.SH_Enabled and lobbyTime > (VD.SH_WaitingTimeout or 60) then
                    if tick() - VD.SH_LastHopTime > (VD.SH_HopCooldown or 15) then VD.SH_LobbyEnterTime = 0; VD_SH_Hop("Lobby timeout"); task.wait(5) end
                end
                task.wait(0.7)
            else
                if role == "Killer" or role == "Survivor" then VD.SH_LobbyEnterTime = 0 end
                if role == "Survivor" then
                    local char = Player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or hum.Health <= 0 then VD.AF_Status = "Mati - Menunggu respawn"; task.wait(2)
                    else
                        if VD.AF_AutoHeal and hum.Health < hum.MaxHealth * 0.9 then pcall(function() GetRemotes().Healing.HealEvent:FireServer(root, true) end) end
                        if VD.AF_AutoSkill then VD.AutoSkillcheck = true end
                        if hum.WalkSpeed < 16 and hum.WalkSpeed > 0 then hum.WalkSpeed = 16 end
                        if VD.AF_AutoEscapeNow then
                            VD.AF_Status = "Auto Exit Gate"
                            if tick() - VD.AF_LastEscapeTry > VD.AF_EscapeCooldown then VD.AF_LastEscapeTry = tick(); pcall(VD_DoEscape) end
                            task.wait(1)
                        end
                    end
                end
                if role == "Killer" then
                    local char = Player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or hum.Health <= 0 or not root then VD.AF_Status = "Menunggu spawn Killer"; task.wait(2)
                    else
                        VD.AF_Status = "Killer Mode"
                        if VD.AF_AutoAttack then VD.KillerAutoAttack = true end
                        if VD.AF_AutoHook then VD.KillerAutoHook = true end
                        local carrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
                        if carrying then
                            local bestHook, bd = nil, math.huge
                            local map = workspace:FindFirstChild("Map")
                            if map then
                                for _, o in ipairs(map:GetDescendants()) do
                                    if o:IsA("Model") and o.Name == "Hook" then
                                        local part = o:FindFirstChildWhichIsA("BasePart")
                                        if part then local d = (part.Position - root.Position).Magnitude; if d < bd then bd = d; bestHook = part end end
                                    end
                                end
                            end
                            if bestHook then
                                root.CFrame = CFrame.new(bestHook.Position + Vector3.new(0, 3, 0))
                                task.wait(0.3)
                                pcall(function()
                                    local c = GetRemotes().Carry
                                    if c then
                                        local ev = c:FindFirstChild("HookEvent"); local cm = c:FindFirstChild("HookCommit")
                                        if ev then ev:FireServer(bestHook) end
                                        if cm then cm:FireServer(bestHook) end
                                    end
                                end)
                                task.wait(1)
                            end
                        else
                            local target, td = nil, math.huge
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= Player and IsSurvivor(p) and p.Character then
                                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                                    local th = p.Character:FindFirstChildOfClass("Humanoid")
                                    if tr and th and th.Health > 0 then local d = (tr.Position - root.Position).Magnitude; if d < td then td = d; target = tr end end
                                end
                            end
                            if target then
                                if td > 20 then root.CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0)) end
                                pcall(function()
                                    local ba = GetRemotes().Attacks:FindFirstChild("BasicAttack")
                                    if ba then ba:FireServer(false) end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while not VD.Destroyed do
        task.wait(3)
        if VD.AF_Enabled and VD.AF_AutoRequeue and not VD.SH_Enabled then
            if not AF_IsInMatch() then pcall(AF_ClickLobbyButton) end
        end
    end
end)

--========================================================--
-- RADAR TAB
--========================================================--
RegLabel(Tabs.Radar, "═══ Radar ═══")
RadarGui, RadarFrame = nil, nil
RadarDots = {}
function VD_CreateRadarGUI()
    if RadarGui then pcall(function() RadarGui:Destroy() end) end
    RadarGui = Instance.new("ScreenGui"); RadarGui.Name = "MawwwHub_RadarGUI"; RadarGui.ResetOnSpawn = false; RadarGui.IgnoreGuiInset = true; RadarGui.Parent = PlayerGui
    RadarFrame = Instance.new("Frame")
    RadarFrame.Name = "RadarFrame"
    RadarFrame.Size = UDim2.new(0, VD.RADAR_Size or 150, 0, VD.RADAR_Size or 150)
    RadarFrame.Position = UDim2.new(0, 10, 0, 120)
    RadarFrame.BackgroundColor3 = Color3.fromRGB(14, 8, 22); RadarFrame.BackgroundTransparency = 1 - (VD.RADAR_Transparency or 0.2)
    RadarFrame.BorderSizePixel = 0; RadarFrame.Active = true; RadarFrame.Draggable = true; RadarFrame.Parent = RadarGui
    local corner = Instance.new("UICorner"); corner.CornerRadius = VD.RADAR_Circle and UDim.new(1,0) or UDim.new(0,8); corner.Parent = RadarFrame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(180, 60, 255); stroke.Thickness = 2; stroke.Parent = RadarFrame
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1,0,0,20); titleText.BackgroundTransparency = 1; titleText.Text = "MAWWW HUB RADAR"
    titleText.TextColor3 = Color3.fromRGB(255,255,255); titleText.Font = Enum.Font.SourceSansBold; titleText.TextSize = 12; titleText.Parent = RadarFrame
    RadarDots = {}
    for _ = 1, 30 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0,6,0,6); dot.BackgroundColor3 = Color3.fromRGB(255,65,65); dot.BorderSizePixel = 0; dot.Visible = false; dot.Parent = RadarFrame
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1,0); dc.Parent = dot
        table.insert(RadarDots, dot)
    end
    return true
end
function VD_UpdateRadar()
    if not VD.RADAR_Enabled then if RadarGui then RadarGui.Enabled = false end; return end
    if not RadarGui or not RadarFrame or not RadarGui.Parent then if not VD_CreateRadarGUI() then return end end
    RadarGui.Enabled = true; RadarFrame.Visible = true
    local camera = Workspace.CurrentCamera
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not camera or not root then return end
    RadarFrame.Size = UDim2.new(0, VD.RADAR_Size or 150, 0, VD.RADAR_Size or 150)
    RadarFrame.BackgroundTransparency = 1 - (VD.RADAR_Transparency or 0.2)
    for _, dot in ipairs(RadarDots) do dot.Visible = false end
    local halfSize = (VD.RADAR_Size or 150) / 2
    local usableHalf = halfSize - 5
    local scale = usableHalf / (VD.RADAR_Range or 250)
    local camLook = camera.CFrame.LookVector
    local pa = math.atan2(-camLook.X, -camLook.Z)
    local cA = math.cos(pa); local sA = math.sin(pa)
    local pPos = root.Position
    local function W2R(wp)
        local dx = wp.X - pPos.X; local dz = wp.Z - pPos.Z
        local d = math.sqrt(dx*dx + dz*dz)
        if d > (VD.RADAR_Range or 250) then return nil end
        local rx = dx * cA - dz * sA; local rz = dx * sA + dz * cA
        return Vector2.new(halfSize + math.clamp(rx * scale, -usableHalf+4, usableHalf-4), halfSize + math.clamp(rz * scale, -usableHalf+4, usableHalf-4))
    end
    local di = 1
    if VD.RADAR_ShowKiller or VD.RADAR_ShowSurvivor then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local pr = plr.Character:FindFirstChild("HumanoidRootPart")
                if pr then
                    local isK = IsKiller(plr)
                    local show = (isK and VD.RADAR_ShowKiller) or (not isK and VD.RADAR_ShowSurvivor)
                    if show and di <= #RadarDots then
                        local pos = W2R(pr.Position)
                        if pos then
                            local dot = RadarDots[di]; local sz = isK and 7 or 6
                            dot.Size = UDim2.new(0, sz, 0, sz)
                            dot.Position = UDim2.new(0, pos.X - sz/2, 0, pos.Y - sz/2)
                            dot.BackgroundColor3 = isK and Color3.fromRGB(255,0,0) or Color3.fromRGB(180, 60, 255)
                            dot.Visible = true; di = di + 1
                        end
                    end
                end
            end
        end
    end
end
RunService.Heartbeat:Connect(function() pcall(VD_UpdateRadar) end)
RegToggle(Tabs.Radar, "Enable Radar", "Show radar", false, "RADAR_Enabled")
RegSlider(Tabs.Radar, "Radar Size", "Radar size", 150, 100, 400, 10, "RADAR_Size")
RegSlider(Tabs.Radar, "Radar Range", "Radar range", 250, 50, 1000, 10, "RADAR_Range")
RegSlider(Tabs.Radar, "Background Transparency", "Background transparency", 20, 0, 100, 1, "RADAR_Transparency")
RegToggle(Tabs.Radar, "Circle Mode", "Circle radar", false, "RADAR_Circle")
RegToggle(Tabs.Radar, "Show Killer", "Show killers on radar", true, "RADAR_ShowKiller")
RegToggle(Tabs.Radar, "Show Survivor", "Show survivors on radar", true, "RADAR_ShowSurvivor")

--========================================================--
-- QUICK TOGGLE FLOATING UI
--========================================================--
QuickToggleUI = (function()
    local QUICK_GUI_NAME = "MawwwHub_QuickToggle"
    local DRAG_THRESHOLD = 4; local BUTTON_SIZE = 68; local LOCK_SIZE = 24; local MARGIN = 8
    local State = { Gui = nil, Buttons = {}, Locks = {}, Strokes = {}, LabelObjects = {}, Connections = {}, ButtonConnections = {}, Rebuilding = false, LastEnsure = 0 }
    local function disconnectBucket(bucket) for _, c in ipairs(bucket) do pcall(function() c:Disconnect() end) end; table.clear(bucket) end
    local function disconnectAll() disconnectBucket(State.Connections); disconnectBucket(State.ButtonConnections) end
    local function connect(signal, fn, isButtonConnection)
        local ok, conn = pcall(function() return signal:Connect(fn) end)
        if ok and conn then table.insert(isButtonConnection and State.ButtonConnections or State.Connections, conn) end
        return conn
    end
    local function getSavedPos(vdKey, fallback) local pos = VD[vdKey]; if typeof(pos) == "UDim2" then return pos end; return fallback end
    local function savePos(vdKey, pos) if typeof(pos) == "UDim2" then VD[vdKey] = pos end end
    local function ensureGui()
        if VD.Destroyed then return nil end
        local current = PlayerGui and PlayerGui:FindFirstChild(QUICK_GUI_NAME)
        if current and current:IsA("ScreenGui") then
            State.Gui = current; current.ResetOnSpawn = false; current.IgnoreGuiInset = true; current.DisplayOrder = 999; return current
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = QUICK_GUI_NAME; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999; gui.Parent = PlayerGui
        State.Gui = gui; return gui
    end
    local function applyButtonVisual(btn, stroke, enabled, label)
        if not btn or not btn.Parent then return end
        if enabled then
            btn.BackgroundColor3 = Color3.fromRGB(120, 45, 200)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            stroke.Color = Color3.fromRGB(220, 130, 255); stroke.Transparency = 0
        else
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            stroke.Color = Color3.fromRGB(120, 120, 140); stroke.Transparency = 0
        end
        if label then label.TextColor3 = btn.TextColor3 end
    end
    local function applyLockVisual(lockBtn, locked)
        if not lockBtn or not lockBtn.Parent then return end
        lockBtn.Text = locked and "🔒" or "🔓"
        lockBtn.BackgroundColor3 = locked and Color3.fromRGB(150, 45, 45) or Color3.fromRGB(45, 45, 55)
        lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    local function createLockButton(parent, vdLockKey, tooltip)
        local lock = Instance.new("TextButton")
        lock.Name = "Lock"; lock.Size = UDim2.new(0, LOCK_SIZE, 0, LOCK_SIZE)
        lock.Position = UDim2.new(1, -(LOCK_SIZE + 3), 0, 3); lock.AnchorPoint = Vector2.new(0, 0)
        lock.BackgroundColor3 = Color3.fromRGB(45, 45, 55); lock.BackgroundTransparency = 0.05
        lock.BorderSizePixel = 0; lock.AutoButtonColor = false; lock.Text = "🔓"; lock.TextSize = 13; lock.Font = Enum.Font.GothamBold; lock.ZIndex = 20; lock.Parent = parent
        Instance.new("UICorner", lock).CornerRadius = UDim.new(1, 0)
        local ls = Instance.new("UIStroke", lock); ls.Thickness = 1.5; ls.Color = Color3.fromRGB(150, 150, 165); ls.Transparency = 0.15
        lock.MouseButton1Click:Connect(function()
            VD[vdLockKey] = not (VD[vdLockKey] == true)
            applyLockVisual(lock, VD[vdLockKey] == true)
            if tooltip then notify(tooltip, VD[vdLockKey] and "LOCKED" or "UNLOCKED", 2) end
        end)
        applyLockVisual(lock, VD[vdLockKey] == true); return lock
    end
    local function createButton(spec)
        local gui = ensureGui(); if not gui then return nil end
        local old = gui:FindFirstChild(spec.name); if old then old:Destroy() end
        local btn = Instance.new("TextButton")
        btn.Name = spec.name; btn.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
        btn.Position = getSavedPos(spec.posKey, spec.defaultPos)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); btn.BorderSizePixel = 0
        btn.Text = spec.label .. "\n[" .. spec.keyLetter .. "]"; btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.AutoButtonColor = false; btn.Visible = false; btn.ZIndex = 10; btn.Parent = gui
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", btn); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(120, 120, 140); stroke.Transparency = 0
        if spec.iconId then
            local iconFrame = Instance.new("Frame")
            iconFrame.Name = "IconFrame"; iconFrame.Size = UDim2.new(1, -8, 0, 22); iconFrame.Position = UDim2.new(0, 4, 0, 4)
            iconFrame.BackgroundTransparency = 1; iconFrame.ZIndex = 12; iconFrame.Parent = btn
            local img = Instance.new("ImageLabel")
            img.Name = "IconImage"; img.Size = UDim2.new(0, 22, 0, 22); img.Position = UDim2.new(0.5, 0, 0.5, 0)
            img.AnchorPoint = Vector2.new(0.5, 0.5); img.BackgroundTransparency = 1
            img.Image = "rbxassetid://" .. tostring(spec.iconId); img.ScaleType = Enum.ScaleType.Fit; img.ZIndex = 13; img.Parent = iconFrame
        end
        local label = Instance.new("TextLabel")
        label.Name = "MainLabel"; label.Size = UDim2.new(1, -8, 1, -8); label.Position = UDim2.new(0, 4, 0, 4)
        label.BackgroundTransparency = 1; label.Text = spec.label .. "\n[" .. spec.keyLetter .. "]"
        label.TextColor3 = btn.TextColor3; label.Font = Enum.Font.GothamBold; label.TextSize = 11; label.TextWrapped = true; label.ZIndex = 11; label.Parent = btn
        local lock = createLockButton(btn, spec.lockKey, spec.lockTitle)
        local drag = { active = false, moved = false, skipClick = false, startMouse = nil, startPos = nil }
        lock.MouseButton1Down:Connect(function() drag.skipClick = true end)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if VD[spec.lockKey] == true then return end
            drag.active = true; drag.moved = false; drag.startMouse = input.Position; drag.startPos = btn.Position
        end)
        connect(UserInputService.InputChanged, function(input)
            if not drag.active then return end
            if VD[spec.lockKey] == true then drag.active = false; return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - drag.startMouse
                if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then drag.moved = true end
                btn.Position = UDim2.new(drag.startPos.X.Scale, drag.startPos.X.Offset + delta.X, drag.startPos.Y.Scale, drag.startPos.Y.Offset + delta.Y)
            end
        end, true)
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if drag.active then savePos(spec.posKey, btn.Position) end
                task.delay(0.05, function() drag.active = false; drag.moved = false end)
            end
        end, true)
        btn.MouseButton1Click:Connect(function()
            if drag.skipClick then drag.skipClick = false; return end
            if drag.moved then return end
            spec.onClick()
        end)
        btn.AncestryChanged:Connect(function(_, parent)
            if VD.Destroyed then return end
            if not parent then task.defer(function() if not VD.Destroyed then State.LastEnsure = 0 end end) end
        end)
        State.Buttons[spec.id] = btn; State.Locks[spec.id] = lock; State.Strokes[spec.id] = stroke; State.LabelObjects[spec.id] = label
        return btn
    end

    local Specs = {
        {
            id = "Moonwalk", name = "MoonwalkBtn", label = "MOON\nWALK", keyLetter = "M",
            posKey = "QuickMoonwalkPosition", lockKey = "LockMoonwalkIcon", lockTitle = "Moonwalk Lock",
            defaultPos = UDim2.new(0, 12, 0, 260), showKey = "ShowMoonwalkIcon", activeKey = "Moonwalk",
            onClick = function()
                VD.Moonwalk = not VD.Moonwalk
                if VD.Moonwalk then
                    if getgenv().MAWWW_StartMoonwalk then getgenv().MAWWW_StartMoonwalk() end
                    notify("Moonwalk", "ON", 2)
                else
                    local h = getHum(); if h then h.AutoRotate = true; h.WalkSpeed = 16 end
                    notify("Moonwalk", "OFF", 2)
                end
            end,
        },
        {
            id = "GenBoss", name = "GenBoostBtn", label = "GEN\nBOOST", keyLetter = "G",
            posKey = "QuickGenBossPosition", lockKey = "LockGenBossIcon", lockTitle = "Gen Boss Lock",
            defaultPos = UDim2.new(0, 12, 0, 340), showKey = "ShowGenBossIcon", activeKey = "GenBoost",
            onClick = function()
                if getgenv().MAWWW and getgenv().MAWWW.setGenBypass then getgenv().MAWWW.setGenBypass(not VD.GenBoost)
                else VD.GenBoost = not VD.GenBoost end
                notify("Gen Boost", VD.GenBoost and "ON — auto repair aktif" or "OFF", 2)
            end,
        },
        {
            id = "InfiniteMyers", name = "InfiniteMyersBtn", label = "INF\nMYERS", keyLetter = "I",
            iconId = ICON_ID, posKey = "QuickInfiniteMyersPosition", lockKey = "LockInfiniteMyersIcon",
            lockTitle = "Infinite Myers Lock", defaultPos = UDim2.new(0, 12, 0, 420),
            showKey = "ShowInfiniteMyersIcon", activeKey = "KillerInfGrab",
            onClick = function()
                VD.KillerInfGrab = not VD.KillerInfGrab
                if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
                notify("Infinite Myers", VD.KillerInfGrab and "ON — Infinite Grab aktif" or "OFF", 2)
            end,
        },
        {
            id = "BypassSkill", name = "BypassSkillBtn", label = "BYPASS\nSKILL", keyLetter = "B",
            posKey = "QuickBypassSkillPosition", lockKey = "LockBypassSkillIcon",
            lockTitle = "Bypass Skill Lock", defaultPos = UDim2.new(0, 12, 0, 500),
            showKey = "ShowBypassSkillIcon", activeKey = "KillerBypassSkill",
            onClick = function()
                local newVal = not VD.KillerBypassSkill
                if getgenv().MAWWW_SetAllKillerNoCooldown then
                    getgenv().MAWWW_SetAllKillerNoCooldown(newVal)
                else
                    VD.KillerBypassSkill = newVal
                end
                if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
                notify("Bypass Skill", newVal and "ON — All Killer Bypass aktif" or "OFF", 2)
            end,
        },
    }

    local function buildAll()
        if VD.Destroyed or State.Rebuilding then return end
        State.Rebuilding = true; disconnectBucket(State.ButtonConnections)
        local gui = ensureGui()
        if gui then
            State.Buttons = {}; State.Locks = {}; State.Strokes = {}; State.LabelObjects = {}
            for _, spec in ipairs(Specs) do createButton(spec) end
        end
        State.Rebuilding = false
    end
    local function refreshAll(forceBuild)
        if VD.Destroyed then return end
        local now = os.clock()
        local gui = PlayerGui and PlayerGui:FindFirstChild(QUICK_GUI_NAME)
        if forceBuild then State.LastEnsure = 0 end
        if not gui or not gui:IsA("ScreenGui")
            or not gui:FindFirstChild("MoonwalkBtn")
            or not gui:FindFirstChild("GenBoostBtn")
            or not gui:FindFirstChild("InfiniteMyersBtn")
            or not gui:FindFirstChild("BypassSkillBtn") then
            if now - State.LastEnsure > 0.1 then State.LastEnsure = now; buildAll() end
            gui = State.Gui
        else State.Gui = gui end
        if not gui then return end
        gui.Enabled = true; gui.DisplayOrder = 999
        for _, spec in ipairs(Specs) do
            local btn = State.Buttons[spec.id] or gui:FindFirstChild(spec.name)
            local lock = State.Locks[spec.id] or (btn and btn:FindFirstChild("Lock"))
            local stroke = State.Strokes[spec.id] or (btn and btn:FindFirstChildOfClass("UIStroke"))
            local label = State.LabelObjects[spec.id] or (btn and btn:FindFirstChild("MainLabel"))
            if btn and stroke then
                State.Buttons[spec.id] = btn; State.Locks[spec.id] = lock; State.Strokes[spec.id] = stroke; State.LabelObjects[spec.id] = label
                local visible = VD[spec.showKey] == true
                btn.Visible = visible
                if visible then
                    applyButtonVisual(btn, stroke, VD[spec.activeKey] == true, label)
                    if lock then applyLockVisual(lock, VD[spec.lockKey] == true) end
                end
            end
        end
    end
    buildAll(); refreshAll(true)
    connect(PlayerGui.ChildRemoved, function(child)
        if VD.Destroyed then return end
        if child.Name == QUICK_GUI_NAME then task.defer(function() if not VD.Destroyed then refreshAll(true) end end) end
    end)
    connect(Player.CharacterAdded, function() task.wait(0.35); if not VD.Destroyed then refreshAll(true) end end)
    connect(PlayerGui.DescendantRemoving, function(desc)
        if VD.Destroyed or State.Rebuilding then return end
        if desc.Name == "MoonwalkBtn" or desc.Name == "GenBoostBtn"
            or desc.Name == "InfiniteMyersBtn" or desc.Name == "BypassSkillBtn" then
            task.defer(function() if not VD.Destroyed then refreshAll(true) end end)
        end
    end)
    task.spawn(function() while not VD.Destroyed do task.wait(0.2); pcall(refreshAll, false) end end)
    getgenv().MAWWW_QuickRefresh = function() pcall(refreshAll, true) end
    return {
        Refresh = function() pcall(refreshAll, true) end,
        Destroy = function()
            disconnectAll()
            pcall(function() local g = PlayerGui and PlayerGui:FindFirstChild(QUICK_GUI_NAME); if g then g:Destroy() end end)
            State.Gui = nil; State.Buttons = {}; State.Locks = {}; State.Strokes = {}; State.LabelObjects = {}
        end,
    }
end)()

--========================================================--
-- [FINAL ADDITIONS] MISSING IMPLEMENTATIONS & REMOTE HOOKS
--========================================================--

--========================================================--
-- [1] ROBUST REMOTE PATH RESOLVER
--========================================================--
function MAWWW_GetRemotePath(path)
    if type(path) ~= "table" then return nil end
    local node = ReplicatedStorage
    for _, key in ipairs(path) do
        if not node then return nil end
        if type(key) == "table" then
            local found
            for _, name in ipairs(key) do
                local child = node:FindFirstChild(name)
                if child then found = child; break end
            end
            node = found
        else
            node = node:FindFirstChild(key)
        end
    end
    return node
end

function MAWWW_SafeFire(path, args)
    local remote = MAWWW_GetRemotePath(path)
    if not remote then return false end
    if remote:IsA("RemoteEvent") then
        return pcall(function() remote:FireServer(unpack(args or {})) end)
    elseif remote:IsA("RemoteFunction") then
        return pcall(function() remote:InvokeServer(unpack(args or {})) end)
    elseif remote:IsA("BindableEvent") then
        return pcall(function() remote:Fire(unpack(args or {})) end)
    end
    return false
end
getgenv().MAWWW_SafeFire = MAWWW_SafeFire
getgenv().MAWWW_GetRemotePath = MAWWW_GetRemotePath

--========================================================--
-- [2] NEW VD DEFAULTS
--========================================================--
local MAWWW_ExtraDefaults = {
    SURV_AntiBlind = false,
    KillerAutoSkill = false,
    KillerAutoSkillCooldown = 0.6,
    KillerAutoSkillRange = 12,
    SURV_AutoUnhook = false,
    SURV_AutoStruggle = false,
    SURV_AutoStruggleRate = 0.15,
    StatusHUD = false,
    StatusHUDPosX = 12,
    StatusHUDPosY = 380,
    AutoStalk = false,
    AutoStalkDistance = 40,
    AutoStalkRemote = true,
    -- NEW: Extra remote signal toggles
    ToF_SelfDamageAnim = false,
    Heal_AnimOff = false,
    Heal_AnimRecOn = false,
}
for k, v in pairs(MAWWW_ExtraDefaults) do
    if VD[k] == nil then VD[k] = v end
end

--========================================================--
-- [3] KILLER BYPASS WORKERS
--========================================================--
getgenv().MAWWW_BypassWorkers = getgenv().MAWWW_BypassWorkers or {}

function MAWWW_StartKillerBypassWorker(name)
    if getgenv().MAWWW_BypassWorkers[name] then return end
    if name == "Frenzy" then
        getgenv().MAWWW_BypassWorkers[name] = true
        task.spawn(function()
            while not VD.Destroyed and VD.KillerInfFrenzy do
                task.wait(0.3)
                local char = Player.Character
                if char then
                    pcall(function()
                        if char:GetAttribute("Frenzy") ~= true then
                            char:SetAttribute("Frenzy", true)
                        end
                    end)
                end
            end
            getgenv().MAWWW_BypassWorkers[name] = nil
        end)
    elseif name == "LakeMist" or name == "Pursuit" then
        if type(MAWWW_StartSlasherCooldownBypass) == "function" then
            pcall(MAWWW_StartSlasherCooldownBypass)
        end
        getgenv().MAWWW_BypassWorkers[name] = true
    elseif name == "Grab" then
        pcall(setMyersGrab, true)
        getgenv().MAWWW_BypassWorkers[name] = true
    elseif name == "Abyss" then
        if type(MAWWW_StartAbyssCooldownBypass) == "function" then
            pcall(MAWWW_StartAbyssCooldownBypass)
        end
        getgenv().MAWWW_BypassWorkers[name] = true
    elseif name == "Skill" then
        if type(BYPASS_StartHiddenCooldownBypass) == "function" then
            pcall(BYPASS_StartHiddenCooldownBypass)
        end
        getgenv().MAWWW_BypassWorkers[name] = true
    end
end

function MAWWW_StopKillerBypassWorker(name)
    getgenv().MAWWW_BypassWorkers[name] = nil
    if name == "Grab" then pcall(setMyersGrab, false) end
    if name == "Abyss" and type(MAWWW_StopAbyssCooldownBypass) == "function" then
        pcall(MAWWW_StopAbyssCooldownBypass)
    end
    if (name == "LakeMist" or name == "Pursuit") and type(MAWWW_StopSlasherCooldownBypass) == "function" then
        pcall(MAWWW_StopSlasherCooldownBypass)
    end
end
getgenv().MAWWW_StartKillerBypassWorker = MAWWW_StartKillerBypassWorker
getgenv().MAWWW_StopKillerBypassWorker  = MAWWW_StopKillerBypassWorker

local function MAWWW_AttachBypassCallbacks()
    local map = {
        KillerInfFrenzy   = function(v) if v then MAWWW_StartKillerBypassWorker("Frenzy")
                                           else MAWWW_StopKillerBypassWorker("Frenzy") end end,
        KillerInfLakeMist = function(v) if v then MAWWW_StartKillerBypassWorker("LakeMist")
                                           else MAWWW_StopKillerBypassWorker("LakeMist") end end,
        KillerInfPursuit  = function(v) if v then MAWWW_StartKillerBypassWorker("Pursuit")
                                           else MAWWW_StopKillerBypassWorker("Pursuit") end end,
        KillerInfGrab     = function(v) if v then MAWWW_StartKillerBypassWorker("Grab")
                                           else MAWWW_StopKillerBypassWorker("Grab") end end,
        KillerInfAbyss    = function(v) if v then MAWWW_StartKillerBypassWorker("Abyss")
                                           else MAWWW_StopKillerBypassWorker("Abyss") end end,
        KillerInfSkill    = function(v) if v then MAWWW_StartKillerBypassWorker("Skill")
                                           else MAWWW_StopKillerBypassWorker("Skill") end end,
        KillerBypassCD    = function(v)
            if v then
                task.spawn(function()
                    while not VD.Destroyed and VD.KillerBypassCD do
                        task.wait(0.25)
                        local char = Player.Character
                        if char then
                            pcall(function()
                                for _, a in ipairs(char:GetAttributes()) do
                                    if type(a) == "string" and a:lower():find("cooldown") then
                                        local val = char:GetAttribute(a)
                                        if type(val) == "number" and val > 0 then
                                            char:SetAttribute(a, 0)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end)
            end
        end,
    }
    for key, cb in pairs(map) do
        local obj = VD_Elements[key]
        if obj then
            if type(obj.SetCallback) == "function" then
                pcall(function() obj:SetCallback(cb) end)
            elseif type(obj.OnChanged) == "function" then
                pcall(function() obj:OnChanged(cb) end)
            end
        end
    end
end
task.defer(function()
    task.wait(1.2)
    pcall(MAWWW_AttachBypassCallbacks)
end)

--========================================================--
-- [4] EXTENDED ANTI-BLIND
--========================================================--
local function MAWWW_ApplyAntiBlind()
    local char = Player.Character
    if char then
        pcall(function()
            for _, attr in ipairs({"Blindness","Blind","IsBlinded","FlashBlind",
                                   "Flash","BlindAmount","BlindTime"}) do
                local v = char:GetAttribute(attr)
                if v ~= nil then
                    if type(v) == "number" then char:SetAttribute(attr, 0)
                    elseif type(v) == "boolean" then char:SetAttribute(attr, false) end
                end
            end
        end)
    end
    local pg = Player:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local ln = gui.Name:lower()
                if ln:find("blind") or ln:find("flash")
                   or ln:find("whiteoverlay") or ln:find("flashoverlay") then
                    gui.Enabled = false
                end
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("Frame") then
                        local n = d.Name:lower()
                        if (n:find("blind") or n:find("white") or n:find("flash"))
                           and d.BackgroundTransparency < 0.85 then
                            d.BackgroundTransparency = 1
                        end
                    end
                end
            end
        end
    end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("ColorCorrectionEffect") and v.Brightness < -0.2 then v.Brightness = 0 end
        if v:IsA("BlurEffect") and v.Size > 0 then v.Size = 0 end
    end
end

task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.15)
        if VD.KillerAntiBlind or VD.SURV_AntiBlind then
            pcall(MAWWW_ApplyAntiBlind)
        end
    end
end)

RegToggle(Tabs.Survival, "Anti Blind (Survivor)", "Ignore flashlight/blind effect (both teams)", false, "SURV_AntiBlind")

--========================================================--
-- [5] SURVIVOR AUTO-UNHOOK & AUTO-STRUGGLE
--========================================================--
local MAWWW_StruggleRemotePaths = {
    {"Carry","SelfUnHookEvent"},
    {"Carry","Struggle"},
    {"Carry","Wiggle"},
    {"Player","StruggleEvent"},
    {"Player","SelfUnHook"},
    {"PlayerActions","SelfUnHookEvent"},
}

local function MAWWW_TryStruggle()
    for _, path in ipairs(MAWWW_StruggleRemotePaths) do
        MAWWW_SafeFire(path, {})
    end
end

task.spawn(function()
    while not VD.Destroyed do
        task.wait(tonumber(VD.SURV_AutoStruggleRate) or 0.15)
        if not VD.SURV_AutoStruggle then continue end
        local char = Player.Character
        if not char then continue end
        local hooked = char:GetAttribute("IsHooked") or char:GetAttribute("Hooked") or char:GetAttribute("OnHook")
        local carried = char:GetAttribute("IsCarried") or char:GetAttribute("Carried")
        if hooked or carried then
            pcall(MAWWW_TryStruggle)
        end
    end
end)

RegToggle(Tabs.Survival, "Auto Struggle (Wiggle Remote)", "Fire struggle/wiggle remotes while hooked/carried", false, "SURV_AutoStruggle")
RegSlider(Tabs.Survival, "Struggle Rate (s)", "Interval between struggle fires", 0.15, 0.05, 1, 0.01, "SURV_AutoStruggleRate")
RegToggle(Tabs.Survival, "Auto Unhook Self", "Fire SelfUnHook remotes while carried", false, "SURV_AutoUnhook")

--========================================================--
-- [6] KILLER AUTO SKILL
--========================================================--
local MAWWW_SkillRemotePaths = {
    {"Attacks","BasicAttack"},
    {"Attacks","SkillAttack"},
    {"Attacks","SpecialAttack"},
    {"Killers","Killer","Skill"},
    {"Killers","Killer","Special"},
    {"Killers","SkillEvent"},
    {"Killers","AbilityEvent"},
}

task.spawn(function()
    while not VD.Destroyed do
        task.wait(tonumber(VD.KillerAutoSkillCooldown) or 0.6)
        if not VD.KillerAutoSkill or GetRole() ~= "Killer" then continue end
        local root = getRoot()
        if not root then continue end
        local range = tonumber(VD.KillerAutoSkillRange) or 12
        local target = nil
        local bestDist = range
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and IsSurvivor(p) and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                local th = p.Character:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health > 0 then
                    local d = (tr.Position - root.Position).Magnitude
                    if d <= bestDist then bestDist = d; target = p end
                end
            end
        end
        if target then
            for _, path in ipairs(MAWWW_SkillRemotePaths) do
                MAWWW_SafeFire(path, {false})
            end
        end
    end
end)

RegToggle(Tabs.Killer, "Auto Skill (Basic + Special)", "Fire attack/skill remotes on cooldown when survivor in range", false, "KillerAutoSkill")
RegSlider(Tabs.Killer, "Auto Skill Cooldown (s)", "Interval", 0.6, 0.15, 3, 0.05, "KillerAutoSkillCooldown")
RegSlider(Tabs.Killer, "Auto Skill Range", "Max range to trigger", 12, 5, 40, 1, "KillerAutoSkillRange")

--========================================================--
-- [7] AUTO STALK
--========================================================--
task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.35)
        if not VD.AutoStalk or GetRole() ~= "Killer" then continue end
        local root = getRoot()
        if not root then continue end
        local maxDist = tonumber(VD.AutoStalkDistance) or 40
        local closest, bestDist = nil, maxDist
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and IsSurvivor(p) and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d = (tr.Position - root.Position).Magnitude
                    if d < bestDist then bestDist = d; closest = p end
                end
            end
        end
        if closest then
            MAWWW_SafeFire({"Killers","Stalker","StartStalking"}, {closest})
            MAWWW_SafeFire({"Killers","Stalker","Stalk"}, {closest})
        end
    end
end)

RegToggle(Tabs.Killer, "Auto Stalk (Remote)", "Fire stalker remote when survivor nearby", false, "AutoStalk")
RegSlider(Tabs.Killer, "Auto Stalk Distance", "Max distance to trigger stalk", 40, 10, 120, 1, "AutoStalkDistance")

--========================================================--
-- [8] STATUS HUD OVERLAY
--========================================================--
local StatusHUDGui, StatusHUDLabel = nil, nil
local function MAWWW_CreateStatusHUD()
    if StatusHUDGui and StatusHUDGui.Parent then return end
    StatusHUDGui = Instance.new("ScreenGui")
    StatusHUDGui.Name = "MawwwHub_StatusHUD"
    StatusHUDGui.ResetOnSpawn = false
    StatusHUDGui.IgnoreGuiInset = true
    StatusHUDGui.DisplayOrder = 998
    StatusHUDGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.new(0, 220, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Position = UDim2.new(0, VD.StatusHUDPosX or 12, 0, VD.StatusHUDPosY or 380)
    frame.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = StatusHUDGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", frame)
    s.Color = Color3.fromRGB(120, 60, 200); s.Thickness = 1
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)

    StatusHUDLabel = Instance.new("TextLabel")
    StatusHUDLabel.Size = UDim2.new(1, 0, 0, 0)
    StatusHUDLabel.AutomaticSize = Enum.AutomaticSize.Y
    StatusHUDLabel.BackgroundTransparency = 1
    StatusHUDLabel.Font = Enum.Font.GothamBold
    StatusHUDLabel.TextSize = 12
    StatusHUDLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
    StatusHUDLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusHUDLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatusHUDLabel.TextWrapped = true
    StatusHUDLabel.RichText = true
    StatusHUDLabel.Text = ""
    StatusHUDLabel.Parent = frame

    local dragStart, startPos, dragging = nil, nil, false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
            VD.StatusHUDPosX = frame.Position.X.Offset
            VD.StatusHUDPosY = frame.Position.Y.Offset
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function MAWWW_UpdateStatusHUD()
    if not VD.StatusHUD then
        if StatusHUDGui then StatusHUDGui.Enabled = false end
        return
    end
    if not StatusHUDGui or not StatusHUDGui.Parent then
        MAWWW_CreateStatusHUD()
    end
    if not StatusHUDGui then return end
    StatusHUDGui.Enabled = true

    local role = GetRole()
    local hum = getHum()
    local hp = "?"
    if hum then hp = string.format("%d/%d", math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5)) end
    local ping = "?"
    pcall(function()
        local st = game:GetService("Stats")
        local net = st:FindFirstChild("Network")
        local srv = net and net:FindFirstChild("ServerStatsItem")
        local dp = srv and srv:FindFirstChild("Data Ping")
        if dp and dp.GetValue then ping = math.floor(dp:GetValue() + 0.5) end
    end)
    if not getgenv().MAWWW_FPSCounter then
        getgenv().MAWWW_FPSCounter = { Frames = 0, Last = tick(), Value = 60 }
        RunService.RenderStepped:Connect(function()
            local c = getgenv().MAWWW_FPSCounter
            c.Frames = c.Frames + 1
            local now = tick()
            if now - c.Last >= 0.5 then
                c.Value = math.floor(c.Frames / (now - c.Last) + 0.5)
                c.Frames = 0; c.Last = now
            end
        end)
    end
    local fps = getgenv().MAWWW_FPSCounter.Value

    local survivors, killers = 0, 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            if IsSurvivor(p) then survivors = survivors + 1
            elseif IsKiller(p) then killers = killers + 1 end
        end
    end

    local lines = {
        string.format('<font color="rgb(180,140,255)">[Mawww Hub]</font>'),
        string.format('Role: <font color="rgb(255,200,80)">%s</font>', role),
        string.format('HP:   <font color="rgb(120,255,140)">%s</font>', hp),
        string.format('Ping: %s  FPS: %d', ping, fps),
        string.format('Killers: %d  Survivors: %d', killers, survivors),
    }
    if StatusHUDLabel then
        StatusHUDLabel.Text = table.concat(lines, "\n")
    end
end

task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        pcall(MAWWW_UpdateStatusHUD)
    end
end)

RegToggle(Tabs.UISettings, "Status HUD Overlay", "Show info overlay (role, HP, ping, FPS, teams)", false, "StatusHUD")

--========================================================--
-- [9] ADDITIONAL HELPER REMOTES
--========================================================--
function MAWWW_PingAlive()
    MAWWW_SafeFire({"Game","Heartbeat"}, {tick()})
    MAWWW_SafeFire({"Game","Alive"}, {})
    MAWWW_SafeFire({"Player","Heartbeat"}, {tick()})
end

task.spawn(function()
    while not VD.Destroyed do
        task.wait(15)
        if VD.AntiAFK then pcall(MAWWW_PingAlive) end
    end
end)

--========================================================--
-- [11] AUTO UNHOOK (SURVIVOR) — MULTI-REMOTE FALLBACK
--========================================================--
local MAWWW_UnhookDefaults = {
    SURV_AutoUnhook = false,
    SURV_AutoUnhookRate = 0.2,
    SURV_AutoUnhookOthers = false,
    SURV_AutoUnhookOthersRange = 8,
    SURV_AutoUnhookOthersRate = 0.5,
    SURV_AutoUnhookUseScan = true,
}
for k, v in pairs(MAWWW_UnhookDefaults) do
    if VD[k] == nil then VD[k] = v end
end

local MAWWW_UnhookRemoteCandidates = {
    {"Carry", "SelfUnHookEvent"},
    {"Carry", "SelfUnHook"},
    {"Carry", "UnhookEvent"},
    {"Carry", "Unhook"},
    {"Carry", "Struggle"},
    {"Carry", "Wiggle"},
    {"Carry", "Escape"},
    {"Carry", "BreakFree"},
    {"Carry", "Rescue"},
    {"Player", "SelfUnHookEvent"},
    {"Player", "SelfUnHook"},
    {"Player", "UnhookEvent"},
    {"Player", "Unhook"},
    {"Player", "Struggle"},
    {"Player", "Wiggle"},
    {"Player", "Rescue"},
    {"PlayerActions", "SelfUnHookEvent"},
    {"PlayerActions", "SelfUnHook"},
    {"PlayerActions", "UnhookEvent"},
    {"PlayerActions", "Unhook"},
    {"PlayerActions", "Struggle"},
    {"Hook", "Unhook"},
    {"Hook", "UnhookEvent"},
    {"Hook", "Rescue"},
    {"Hook", "Struggle"},
    {"Survivor", "Unhook"},
    {"Survivor", "UnhookEvent"},
    {"Survivor", "SelfUnHook"},
    {"Game", "Unhook"},
    {"Game", "UnhookEvent"},
    {"Unhook"},
    {"UnhookEvent"},
    {"SelfUnHook"},
    {"Struggle"},
}

getgenv().MAWWW_UnhookScannedRemotes = nil
getgenv().MAWWW_UnhookScanTime = 0

function MAWWW_ScanUnhookRemotes()
    local now = tick()
    if getgenv().MAWWW_UnhookScannedRemotes and (now - getgenv().MAWWW_UnhookScanTime) < 5 then
        return getgenv().MAWWW_UnhookScannedRemotes
    end
    local found = {}
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        for _, d in ipairs(remotes:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                local n = d.Name:lower()
                if n:find("unhook") or n:find("selfunhook")
                   or n:find("rescue") or n:find("struggle")
                   or n:find("wiggle") or n:find("breakfree")
                   or n:find("escape") then
                    table.insert(found, d)
                end
            end
        end
    end
    getgenv().MAWWW_UnhookScannedRemotes = found
    getgenv().MAWWW_UnhookScanTime = now
    return found
end

function MAWWW_TryUnhook()
    local fired = false
    for _, path in ipairs(MAWWW_UnhookRemoteCandidates) do
        if MAWWW_SafeFire(path, {}) then
            fired = true
        end
    end
    if VD.SURV_AutoUnhookUseScan ~= false then
        for _, remote in ipairs(MAWWW_ScanUnhookRemotes()) do
            if remote and remote.Parent then
                if remote:IsA("RemoteEvent") then
                    pcall(function() remote:FireServer() end)
                    fired = true
                elseif remote:IsA("RemoteFunction") then
                    pcall(function() remote:InvokeServer() end)
                    fired = true
                end
            end
        end
    end
    return fired
end
getgenv().MAWWW_TryUnhook = MAWWW_TryUnhook

task.spawn(function()
    while not VD.Destroyed do
        task.wait(tonumber(VD.SURV_AutoUnhookRate) or 0.2)
        if not VD.SURV_AutoUnhook then continue end
        local char = Player.Character
        if not char then continue end
        local carried = char:GetAttribute("IsCarried")
                     or char:GetAttribute("Carried")
                     or char:GetAttribute("isCarried")
        local hooked  = char:GetAttribute("IsHooked")
                     or char:GetAttribute("Hooked")
                     or char:GetAttribute("OnHook")
                     or char:GetAttribute("IsOnHook")
        if carried or hooked then
            pcall(MAWWW_TryUnhook)
        end
    end
end)

task.spawn(function()
    while not VD.Destroyed do
        task.wait(tonumber(VD.SURV_AutoUnhookOthersRate) or 0.5)
        if not VD.SURV_AutoUnhookOthers then continue end
        if GetRole() ~= "Survivor" then continue end
        local char = Player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local bestTarget = nil
        local bestDist = tonumber(VD.SURV_AutoUnhookOthersRange) or 8
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and IsSurvivor(p) and p.Character then
                local pc = p.Character
                local pr = pc:FindFirstChild("HumanoidRootPart")
                if pr then
                    local hooked = pc:GetAttribute("IsHooked")
                                 or pc:GetAttribute("Hooked")
                                 or pc:GetAttribute("OnHook")
                                 or pc:GetAttribute("IsOnHook")
                    if hooked then
                        local d = (pr.Position - root.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestTarget = pr
                        end
                    end
                end
            end
        end

        if bestTarget then
            pcall(function()
                local dir = (bestTarget.Position - root.Position)
                if dir.Magnitude > 0.1 then
                    root.CFrame = CFrame.new(root.Position, bestTarget.Position)
                end
            end)
            pcall(MAWWW_TryUnhook)
        end
    end
end)

RegButton(Tabs.Survival, "Force Unhook Now", "Coba semua remote unhook saat ini juga", function()
    local fired = MAWWW_TryUnhook()
    if fired then
        notify("Auto Unhook", "Remote unhook berhasil difire!", 3)
    else
        notify("Auto Unhook", "Tidak ada remote unhook yang ditemukan.", 3)
    end
end)

RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "═══ Auto Unhook / Rescue ═══")

RegToggle(Tabs.Survival, "Auto Unhook Self (Multi-Remote)",
    "Fire semua remote unhook saat sedang Carried / Hooked", false, "SURV_AutoUnhook")
RegSlider(Tabs.Survival, "Auto Unhook Rate (s)",
    "Interval antara fire remote", 0.2, 0.05, 2, 0.05, "SURV_AutoUnhookRate")

RegToggle(Tabs.Survival, "Auto Unhook Teammate",
    "Otomatis rescue survivor yang ter-hook di dekatmu", false, "SURV_AutoUnhookOthers")
RegSlider(Tabs.Survival, "Teammate Unhook Range",
    "Jarak maksimal untuk rescue", 8, 3, 30, 1, "SURV_AutoUnhookOthersRange")
RegSlider(Tabs.Survival, "Teammate Unhook Rate (s)",
    "Interval rescue", 0.5, 0.1, 3, 0.1, "SURV_AutoUnhookOthersRate")

RegToggle(Tabs.Survival, "Use Remote Auto-Scan",
    "Scan semua RemoteEvent yang namanya mengandung unhook/rescue/struggle", true, "SURV_AutoUnhookUseScan")

--========================================================--
-- [12] EXTRA REMOTE SIGNAL FEATURES (NEW — Sesuai Request)
--========================================================--
local function MAWWW_GetToFFireRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local tof = items and items:FindFirstChild("Twist of Fate")
    local fire = tof and tof:FindFirstChild("Fire")
    if fire and fire:IsA("RemoteEvent") then return fire end
    return nil
end

local function MAWWW_GetHealAnimRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local healing = remotes and remotes:FindFirstChild("Healing")
    local healAnim = healing and healing:FindFirstChild("HealAnim")
    if healAnim and healAnim:IsA("RemoteEvent") then return healAnim end
    return nil
end

local function MAWWW_GetHealAnimRecRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local healing = remotes and remotes:FindFirstChild("Healing")
    local healAnimRec = healing and healing:FindFirstChild("HealAnimRec")
    if healAnimRec and healAnimRec:IsA("RemoteEvent") then return healAnimRec end
    return nil
end

task.spawn(function()
    while not VD.Destroyed do
        task.wait(0.5)
        if VD.ToF_SelfDamageAnim then
            pcall(function()
                local remote = MAWWW_GetToFFireRemote()
                if remote and typeof(firesignal) == "function" then
                    firesignal(remote.OnClientEvent, "SelfDamage")
                end
            end)
        end
        if VD.Heal_AnimOff then
            pcall(function()
                local remote = MAWWW_GetHealAnimRemote()
                if remote and typeof(firesignal) == "function" then
                    firesignal(remote.OnClientEvent, false)
                end
            end)
        end
        if VD.Heal_AnimRecOn then
            pcall(function()
                local remote = MAWWW_GetHealAnimRecRemote()
                if remote and typeof(firesignal) == "function" then
                    firesignal(remote.OnClientEvent, true)
                end
            end)
        end
    end
end)

RegDivider(Tabs.Visual)
RegLabel(Tabs.Visual, "═══ Extra Remote Signals (NEW) ═══")
RegToggle(Tabs.Visual, "TOF Fire: SelfDamage Signal",
    "Fire Twist of Fate Fire.OnClientEvent('SelfDamage') berkala", false, "ToF_SelfDamageAnim")

RegDivider(Tabs.Survival)
RegLabel(Tabs.Survival, "═══ Extra Heal Anim Signals (NEW) ═══")
RegToggle(Tabs.Survival, "Force Heal Anim Off",
    "Fire Healing.HealAnim.OnClientEvent(false)", false, "Heal_AnimOff")
RegToggle(Tabs.Survival, "Force Heal Anim Rec On",
    "Fire Healing.HealAnimRec.OnClientEvent(true)", false, "Heal_AnimRecOn")

RegButton(Tabs.Survival, "Fire SelfDamage Now (One-shot)",
    "Fire sekali Twist of Fate Fire.OnClientEvent('SelfDamage')", function()
        local ok = pcall(function()
            local remote = MAWWW_GetToFFireRemote()
            if remote and typeof(firesignal) == "function" then
                firesignal(remote.OnClientEvent, "SelfDamage")
                return true
            end
            return false
        end)
        if ok then notify("TOF Signal", "SelfDamage difire!", 2)
        else notify("TOF Signal", "Remote tidak ditemukan.", 2) end
    end)
RegButton(Tabs.Survival, "Fire HealAnim Now (One-shot: off)",
    "Fire sekali Healing.HealAnim.OnClientEvent(false)", function()
        local ok = pcall(function()
            local remote = MAWWW_GetHealAnimRemote()
            if remote and typeof(firesignal) == "function" then
                firesignal(remote.OnClientEvent, false)
                return true
            end
            return false
        end)
        if ok then notify("HealAnim", "HealAnim(false) difire!", 2)
        else notify("HealAnim", "Remote tidak ditemukan.", 2) end
    end)
RegButton(Tabs.Survival, "Fire HealAnimRec Now (One-shot: on)",
    "Fire sekali Healing.HealAnimRec.OnClientEvent(true)", function()
        local ok = pcall(function()
            local remote = MAWWW_GetHealAnimRecRemote()
            if remote and typeof(firesignal) == "function" then
                firesignal(remote.OnClientEvent, true)
                return true
            end
            return false
        end)
        if ok then notify("HealAnimRec", "HealAnimRec(true) difire!", 2)
        else notify("HealAnimRec", "Remote tidak ditemukan.", 2) end
    end)

--========================================================--
-- [10] LOG
--========================================================--
print("[Mawww Hub] Missing implementations + Unhook loaded.")
print("  - Individual killer bypass callbacks attached")
print("  - Robust remote resolver (MAWWW_SafeFire) exposed")
print("  - Auto Skill / Auto Stalk / Anti-Blind(Surv) / StatusHUD added")
print("  - Auto Struggle + Auto Unhook (Survivor) added")
print("  - Multi-remote unhook fallback: " .. tostring(#MAWWW_UnhookRemoteCandidates) .. " candidates")
print("  - Extra Remote Signals: TOF SelfDamage / HealAnim / HealAnimRec added")

--========================================================--
-- UI SETTINGS TAB
--========================================================--
RegLabel(Tabs.UISettings, "═══ Menu ═══")
RegButton(Tabs.UISettings, "Test Notification", "Test notification system", function() notify("Mawww Hub", "Notification system works!", 4) end)
RegButton(Tabs.UISettings, "Print Current State", "Print current state to console", function()
    print("========================================")
    print("MAWWW HUB V2 — CURRENT STATE (WindUI)")
    print("========================================")
end)
RegButton(Tabs.UISettings, "Reset My Character (Emergency)", "Emergency character reset", function()
    pcall(function()
        if VD.Invisible then VD.Invisible = false; Inv_Stop() end
        for p, data in pairs(InvisibleState.PartData) do
            if p and p.Parent then
                pcall(function()
                    p.Transparency = data.Transparency; p.CanCollide = data.CanCollide
                    if data.LocalTransparencyModifier ~= nil then p.LocalTransparencyModifier = data.LocalTransparencyModifier end
                end)
            end
        end
        InvisibleState.PartData = {}; InvisibleState.DecalData = {}; InvisibleState.EffectData = {}
        VD.Noclip = false
        for part, cc in pairs(originalCanCollide) do if part and part.Parent then pcall(function() part.CanCollide = cc end) end end
        originalCanCollide = {}
        local hum = getHum()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.AutoRotate = true; hum.CameraOffset = Vector3.new(0, 0, 0) end
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
        notify("Emergency Reset", "Character di-reset.", 5)
    end)
end)
RegButton(Tabs.UISettings, "Unload Script", "Unload the script", function()
    notify("Mawww Hub", "Unloading...", 2)
    VD.Destroyed = true
    if InvisibleState and InvisibleState.Active then pcall(function() Inv_Stop() end) end
    pcall(function() if ParryV2 and ParryV2.DestroyCircle then pcall(ParryV2.DestroyCircle) end end)
    pcall(function() if AutoParryModule and AutoParryModule.DestroyRing then pcall(AutoParryModule.DestroyRing) end end)
    pcall(function() if SpearVeil and SpearVeil.State and SpearVeil.State.IndicatorPart and SpearVeil.State.IndicatorPart.Parent then SpearVeil.State.IndicatorPart:Destroy() end end)
    pcall(function() if PalletRangeIndicator and PalletRangeIndicator.Part and PalletRangeIndicator.Part.Parent then DestroyPalletRangeIndicator() end end)
    pcall(function() if ToFV2 and ToFV2.ClearLaser then ToFV2.ClearLaser() end end)
    pcall(function() if TofV1New and TofV1New.Cleanup then TofV1New.Cleanup() end end)
    pcall(function() if getgenv().MAWWW_ToFClearLaser then getgenv().MAWWW_ToFClearLaser() end end)
    pcall(function() if QuickToggleUI and QuickToggleUI.Destroy then QuickToggleUI.Destroy() end end)
    pcall(function() if MyersGrabData and MyersGrabData.UI then MyersGrabData.UI:Destroy() end end)
    pcall(function() if getgenv().MAWWW and getgenv().MAWWW.GenBypass and getgenv().MAWWW.GenBypass.UI then getgenv().MAWWW.GenBypass.UI:Destroy() end end)
    pcall(function() if getgenv().MAWWW_AbyssCooldownBypassConnection then getgenv().MAWWW_AbyssCooldownBypassConnection:Disconnect() end end)
    pcall(function()
        if PingFPSGui then PingFPSGui:Destroy() end
        if PingFPSConn then PingFPSConn:Disconnect() end
        if HideSurvConn then HideSurvConn:Disconnect() end
        if HookCounterConn then HookCounterConn:Disconnect() end
    end)
    pcall(function() VeilSharedVisuals.HideAll() end)
    pcall(function()
        for _, c in pairs(VeilSharedVisuals.PlayerCircles) do
            if c.outline then c.outline:Remove() end
            if c.fill then c.fill:Remove() end
        end
        for _, bb in pairs(VeilSharedVisuals.NameLabels) do if bb then bb:Destroy() end end
    end)
    task.wait(0.3)
    pcall(function() if Window and Window.Close then Window:Close() elseif WindUI and WindUI.Close then WindUI:Close() end end)
    getgenv().MAWWW_WindUI_Window = nil
end)

RegDivider(Tabs.UISettings)
RegLabel(Tabs.UISettings, "Quick Keybinds")
function MAWWW_SafeKeybind(config)
    if not Tabs.UISettings then return nil end
    local ok, obj = pcall(function() return Tabs.UISettings:Keybind(config) end)
    if ok and obj then return obj end

    if config and config.Default ~= nil and config.Value == nil then
        local retryConfig = {}
        for k, v in pairs(config) do retryConfig[k] = v end
        retryConfig.Value = retryConfig.Default
        retryConfig.Default = nil
        local ok2, obj2 = pcall(function() return Tabs.UISettings:Keybind(retryConfig) end)
        if ok2 and obj2 then return obj2 end
        obj = obj2 or obj
    end

    warn("[Mawww Hub] Keybind failed:", config and config.Title, obj)
    return nil
end

MAWWW_SafeKeybind({
    Title = "Moonwalk Toggle", Flag = "MoonwalkKey", Default = "M",
    Callback = function(v)
        VD.Moonwalk = v
        if v then
            if getgenv().MAWWW_StartMoonwalk then getgenv().MAWWW_StartMoonwalk() end
        else
            local h = getHum(); if h then h.AutoRotate = true; h.WalkSpeed = 16 end
        end
        if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
        notify("Moonwalk", v and "ON" or "OFF", 2)
    end,
})

MAWWW_SafeKeybind({
    Title = "Gen Boost Toggle", Flag = "GenBoostKey", Default = "G",
    Callback = function(v)
        if getgenv().MAWWW and getgenv().MAWWW.setGenBypass then getgenv().MAWWW.setGenBypass(v)
        else VD.GenBoost = v end
        if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
        notify("Gen Boost", v and "ON — auto repair aktif" or "OFF", 3)
    end,
})

MAWWW_SafeKeybind({
    Title = "Infinite Myers Toggle", Flag = "InfiniteMyersKey", Default = "I",
    Callback = function(v)
        VD.KillerInfGrab = v
        if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
        notify("Infinite Myers", v and "ON — Infinite Grab aktif" or "OFF", 2)
    end,
})

MAWWW_SafeKeybind({
    Title = "Bypass Skill Toggle", Flag = "BypassSkillKey", Default = "B",
    Callback = function(v)
        if getgenv().MAWWW_SetAllKillerNoCooldown then
            getgenv().MAWWW_SetAllKillerNoCooldown(v)
        else
            VD.KillerBypassSkill = v
        end
        if getgenv().MAWWW_QuickRefresh then pcall(getgenv().MAWWW_QuickRefresh) end
        notify("Bypass Skill", v and "ON — All Killer Bypass" or "OFF", 2)
    end,
})

MAWWW_SafeKeybind({
    Title = "Myers Grab", Flag = "MyersGrabKey", Default = "H",
    Callback = function()
        if MyersGrabData and MyersGrabData.Enabled then
            doMyersGrab()
        else
            notify("Myers Grab", "Enable 'Bypass Skill (All Killers)' first.", 3)
        end
    end,
})

--========================================================--
-- WINDUI FINALIZATION / SELF-HEAL
--========================================================--
pcall(function() Window:SelectTab(1) end)
pcall(function() if type(Window.Open) == "function" then Window:Open() end end)

getgenv().MAWWW_OpenUI = function()
    if VD and VD.Destroyed then return false end
    local ok = pcall(function()
        if type(Window.Open) == "function" then Window:Open() end
        Window:SelectTab(1)
    end)
    return ok
end

pcall(function()
    if Window and Window.SelectTab then Window:SelectTab(1) end
end)

--========================================================--
-- FINAL
--========================================================--
print("============================================")
print("   MAWWW HUB V2 — VIOLENCE DISTRICT")
print("   [WINDUI + FULL FEATURES]")
print("   NEW: Bypass Skill Quick Toggle [B]")
print("   NEW: TOF V1 Auto-Aim Killer (Lookscriptkiller)")
print("   NEW: Auto Unhook Self + Teammate (Multi-Remote)")
print("   NEW: StatusHUD / Auto Skill / Auto Stalk")
print("   NEW: TOF SelfDamage Signal / HealAnim Off / HealAnimRec On")
print("   Quick Toggle: Moonwalk [M] | GenBoost [G] | Infinite Myers [I] | Bypass Skill [B]")
print("============================================")

print("============================================")
print("   MAWWW HUB V1 — VIOLENCE DISTRICT (MERGED)")
print("   [WINDUI + FULL FEATURES + Mawww Hub ADDONS]")
print("   NEW: Hide Skillcheck UI, Anti Fall Damage, First Person")
print("   NEW: Swift Vault, Pallet Reflex, Anti Knock")
print("   NEW: Invisible Not Visual, Fake Perks")
print("   NEW: Fake Generator, Aura Heal (Self/All)")
print("   NEW: Korless Morph, Copy Avatar, Spoof Stats, Streamer Hide Name")
print("   NEW: Aim Lock, Advanced Flashlight Silent Aim, Silent Aim Flask + Laser")
print("   NEW: Block All Vaults, Auto Drop All Pallets, Break All Pallets, Beat Killer")
print("   NEW: Extended Radar Filters, Killer Perks Display")
print("   NEW: Auto Unhook Self / Teammate / Force Unhook Now")
print("   NEW: Auto Struggle, Anti Blind Survivor, StatusHUD")
print("   NEW: KING SOURCE BYPASS (King's Scourge Remotes)")
print("   NEW: Extra Remote Signals (TOF SelfDamage / HealAnim / HealAnimRec)")
print("============================================")

notify("Mawww Hub V1 (VIOLENCE DISTRIK)", "UPDATE! selalu yang utama.", 6)