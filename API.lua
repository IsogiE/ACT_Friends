
local function GetACT()
    return LibStub("AceAddon-3.0"):GetAddon("ACT", true)
end

local function IsIntegrationEnabled()
    local act = GetACT()
    return act and act.db and act.db.profile and act.db.profile.useNicknameIntegration
end

local function GetNicknamesMap()
    local act = GetACT()
    if not act or not act.db or not act.db.profile then return {} end
    return act.db.profile.nicknames or {}
end

local function FindNicknameEntry(nicknamesMap, nickname)
    if not nickname then return nil end
    nickname = nickname:lower()
    for key, data in pairs(nicknamesMap) do
        if key:lower() == nickname then
            return data
        end
    end
    return nil
end

-- Nickname API
local NicknameAPI = {
    GetNicknameByCharacter = function(_, characterName)
        if not characterName or type(characterName) ~= "string" then 
            return nil 
        end

        characterName = characterName:lower()
        local nicknamesMap = GetNicknamesMap()

        for nickname, data in pairs(nicknamesMap) do
            if data.characters then
                for _, charData in ipairs(data.characters) do
                    if charData.character and charData.character:lower() == characterName then
                        return nickname
                    end
                end
            end
        end
        return nil
    end,

    IsCharacterInNickname = function(_, characterName, nickname)
        if not characterName or not nickname or
           type(characterName) ~= "string" or type(nickname) ~= "string" then
            return false
        end

        characterName = characterName:lower()
        local entry = FindNicknameEntry(GetNicknamesMap(), nickname)
        if entry and entry.characters then
            for _, charData in ipairs(entry.characters) do
                if charData.character and charData.character:lower() == characterName then
                    return true
                end
            end
        end
        return false
    end,

    GetCharacterByNickname = function(_, nickname)
        if not nickname or type(nickname) ~= "string" then 
            return nil 
        end

        local entry = FindNicknameEntry(GetNicknamesMap(), nickname)
        if entry and entry.characters and #entry.characters > 0 then
            return entry.characters[1].character
        end
        return nil
    end,

    GetAllCharactersByNickname = function(_, nickname)
        if not nickname or type(nickname) ~= "string" then 
            return {} 
        end

        local entry = FindNicknameEntry(GetNicknamesMap(), nickname)
        if entry and entry.characters then
            local characters = {}
            for _, charData in ipairs(entry.characters) do
                table.insert(characters, charData.character)
            end
            return characters
        end
        return {}
    end,

    GetAllNicknames = function(_)
        return GetNicknamesMap()
    end
}

_G.NicknameAPI = NicknameAPI

-- LiquidAPI (Thanks Ironi teehee)
local unitIDs = {
    player      = true,
    focus       = true,
    focustarget = true,
    target      = true,
    targettarget= true,
    mouseover   = true,
    npc         = true,
    vehicle     = true,
    pet         = true,
}

for i = 1, 4 do
    unitIDs["party" .. i] = true
    unitIDs["party" .. i .. "target"] = true
end

for i = 1, 40 do
    unitIDs["raid" .. i] = true
    unitIDs["raid" .. i .. "target"] = true
end

for i = 1, 40 do
    unitIDs["nameplate" .. i] = true
    unitIDs["nameplate" .. i .. "target"] = true
end

for i = 1, 15 do
    unitIDs["boss" .. i .. "target"] = true
end

local LiquidAPI = {
    GetName = function(_, characterName, formatting, atlasSize)
        if not characterName then
            error("LiquidAPI:GetName(characterName[, formatting, atlasSize]), characterName is nil")
            return
        end

        local nickname
        characterName = characterName:lower()

        if NicknameAPI:GetCharacterByNickname(characterName) then
            nickname = characterName
        else
            if unitIDs[characterName] then
                if UnitExists(characterName) then
                    local n = UnitName(characterName)
                    if n then
                        n = n:match("^([^-]+)")
                        nickname = NicknameAPI:GetNicknameByCharacter(n) or n
                    end
                else
                    nickname = characterName
                end
            else
                nickname = NicknameAPI:GetNicknameByCharacter(characterName) or characterName
            end
        end

        if not formatting then
            return nickname
        end

        local guid = UnitGUID(characterName)
        if not guid then
            return nickname or characterName, "%s", ""
        end

        if not UnitExists(characterName) then
            return nickname, "%s", ""
        end

        local classFileName = UnitClassBase(characterName)
        local colorStr = classFileName and RAID_CLASS_COLORS[classFileName]
                           and RAID_CLASS_COLORS[classFileName].colorStr or "ffffffff"
        local colorFormat = string.format("|c%s%%s|r", colorStr)

        local role = UnitGroupRolesAssigned(characterName)
        local roleAtlas = role == "TANK"   and "Role-Tank-SM" or
                          role == "HEALER" and "Role-Healer-SM" or
                          role == "DAMAGER" and "Role-DPS-SM"
        local roleIcon = roleAtlas and CreateAtlasMarkup(roleAtlas, atlasSize or 12, atlasSize or 12) or ""

        return nickname, colorFormat, roleIcon, RAID_CLASS_COLORS[classFileName] or {}
    end,

    GetCharacterInGroup = function(_, nickname)
        if not nickname then return nil end
        local entry = FindNicknameEntry(GetNicknamesMap(), nickname)
        if entry and entry.characters then
            for _, charData in ipairs(entry.characters) do
                local charNameLower = charData.character:lower()
                if UnitExists(charNameLower) then
                    local guid = UnitGUID(charNameLower)
                    local classFileName = UnitClassBase(charNameLower)
                    return charData.character,
                           string.format("|c%s%%s|r", RAID_CLASS_COLORS[classFileName].colorStr),
                           guid
                end
            end
        end
        return nil
    end,

    GetCharacters = function(_, nickname)
        if not nickname then
            error("LiquidAPI:GetCharacters(nickname), nickname is nil")
            return
        end

        local entry = FindNicknameEntry(GetNicknamesMap(), nickname)
        if entry and entry.characters then
            local chars = {}
            for _, charData in ipairs(entry.characters) do
                chars[charData.character] = true
            end
            return chars
        end
        return nil
    end
}

_G.LiquidAPI = LiquidAPI

-- WeakAuras (again thanks Ironi)
if WeakAuras then
    WeakAuras.GetName = function(n)
        if not n then return end
        return NicknameAPI:GetNicknameByCharacter(n) or n
    end

    WeakAuras.UnitName = function(unit)
        if not unit then return end
        local n, s = UnitName(unit)
        if not n then return end
        return NicknameAPI:GetNicknameByCharacter(n) or n, s
    end

    if WeakAuras.GetUnitName then
        WeakAuras.GetUnitName = function(unit, showServer)
            if not unit then return end
            local unitName = GetUnitName(unit, showServer)
            if not unitName then return end
            if not UnitIsPlayer(unit) then return unitName end
            
            local nickname = NicknameAPI:GetNicknameByCharacter(unitName)
            if not nickname then return unitName end
            
            if showServer then
                local n, s = strsplit("-", unitName)
                return s and string.format("%s-%s", nickname, s) or nickname
            end
            
            return nickname
        end
    end

    WeakAuras.UnitFullName = function(unit)
        if not unit then return end
        local n, s = UnitFullName(unit)
        if not n then return end
        if UnitIsPlayer(unit) then
            return NicknameAPI:GetNicknameByCharacter(n) or n, s
        end
        return n, s
    end
end

-- ElvUI
local elvInitialized = false
local function SetupElvUITags()
    if elvInitialized then return end
    if not ElvUF or not ElvUF.Tags then return end
    elvInitialized = true
    ElvUF.Tags.Events['nickname']        = 'UNIT_NAME_UPDATE'
    ElvUF.Tags.Events['nickname:Short']  = 'UNIT_NAME_UPDATE'
    ElvUF.Tags.Events['nickname:Medium'] = 'UNIT_NAME_UPDATE'

    local function makeGetter(max)
        return function(unit)
            local name = UnitName(unit)
            if not name then return "" end
            if not IsIntegrationEnabled() then
                return max and string.sub(name,1,max) or name
            end
            local nick = NicknameAPI:GetNicknameByCharacter(name) or name
            return max and string.sub(nick,1,max) or nick
        end
    end

    ElvUF.Tags.Methods['nickname']           = makeGetter(nil)
    ElvUF.Tags.Methods['nickname:veryshort'] = makeGetter(5)
    ElvUF.Tags.Methods['nickname:short']     = makeGetter(8)
    ElvUF.Tags.Methods['nickname:medium']    = makeGetter(10)
end

-- Grid2
local grid2Initialized = false
local function InitializeGrid2()
    if grid2Initialized or not Grid2 then return end
    grid2Initialized = true
    local Name = Grid2.statusPrototype:new("name")
    Name.IsActive = Grid2.statusLibrary.IsActive
    function Name:UNIT_NAME_UPDATE(_, unit) self:UpdateIndicators(unit) end
    function Name:OnEnable()   self:RegisterEvent("UNIT_NAME_UPDATE") end
    function Name:OnDisable()  self:UnregisterEvent("UNIT_NAME_UPDATE") end
    function Name:GetText(unit)
        local name = UnitName(unit)
        if not IsIntegrationEnabled() then return name end
        return name and NicknameAPI:GetNicknameByCharacter(name) or name
    end
    local function Create(baseKey, dbx) Grid2:RegisterStatus(Name,{"text"},baseKey,dbx); return Name end
    Grid2.setupFunc["name"] = Create
    Grid2:DbSetStatusDefaultValue("name",{ type="name" })
end

-- Cell
local function UpdateCellNicknames()
    if not C_AddOns.IsAddOnLoaded("Cell") or not CellDB or not CellDB.nicknames then return end

    if not IsIntegrationEnabled() then
        for i = #CellDB.nicknames.list, 1, -1 do
            local entry = CellDB.nicknames.list[i]
            local character, nickname = entry:match("^([^:]+):(.+)$")
            if character and FindNicknameEntry(GetNicknamesMap(), nickname) then
                table.remove(CellDB.nicknames.list, i)
                if Cell then Cell:Fire("UpdateNicknames", "list-update", character, nil) end
            end
        end
        return
    end

    local nicknameData = GetNicknamesMap()
    local currentEntries = {}
    
    for i, entry in ipairs(CellDB.nicknames.list) do
        local character, nickname = entry:match("^([^:]+):(.+)$")
        if character then
            currentEntries[character] = {index = i, nickname = nickname}
        end
    end

    for nickname, data in pairs(nicknameData) do
        if data.characters then
            for _, charData in ipairs(data.characters) do
                if charData.character then
                    local current = currentEntries[charData.character]
                    local newEntry = string.format("%s:%s", charData.character, nickname)
                    if current then
                        if current.nickname ~= nickname then
                            CellDB.nicknames.list[current.index] = newEntry
                            if Cell then Cell:Fire("UpdateNicknames", "list-update", charData.character, nickname) end
                        end
                        currentEntries[charData.character] = nil
                    else
                        table.insert(CellDB.nicknames.list, newEntry)
                        if Cell then Cell:Fire("UpdateNicknames", "list-update", charData.character, nickname) end
                    end
                end
            end
        end
    end

    for character, data in pairs(currentEntries) do
        table.remove(CellDB.nicknames.list, data.index)
        if Cell then Cell:Fire("UpdateNicknames", "list-update", character, nil) end
    end

    CellDB.nicknames.custom = true
end

-- MRT
local mrtInitialized = false
local function InitializeMRT()
    if mrtInitialized or not C_AddOns.IsAddOnLoaded("MRT") or not GMRT or not GMRT.F then return end
    GMRT.F:RegisterCallback("RaidCooldowns_Bar_TextName", function(_, _, gsubData)
        if not IsIntegrationEnabled() then return end
        if gsubData and gsubData.name then
            gsubData.name = NicknameAPI:GetNicknameByCharacter(gsubData.name) or gsubData.name
        end
    end)
    mrtInitialized = true
end

-- Default Frames
local function UpdateDefaultFrames()
    local hookedFrames = {}
    local function HookFrameName(frame)
        if hookedFrames[frame] or not frame.name then return end
        frame.name.OriginalSetText = frame.name.SetText
        hooksecurefunc(frame.name,"SetText",function(self,text)
            if not IsIntegrationEnabled() then return end
            local baseName = text and text:match("^([^-]+)") or ""
            local nickname = NicknameAPI:GetNicknameByCharacter(baseName)
            if nickname then self:OriginalSetText(nickname) end
        end)
        hookedFrames[frame] = true
    end
    local function UpdateFrameName(frame)
        if not frame or not frame.unit then return end
        HookFrameName(frame)
        if frame.name:GetText() then frame.name:SetText(frame.name:GetText()) end
    end
    local function UpdateAllFrames()
        for i=1,8 do local f=_G["CompactPartyFrameMember"..i]; if f and f:IsVisible() then UpdateFrameName(f) end end
        for i=1,40 do
            local f=_G["CompactRaidFrame"..i]; if f and f:IsVisible() then UpdateFrameName(f) end
            for j=1,5 do local g=_G["CompactRaidGroup"..i.."Member"..j]; if g and g:IsVisible() then UpdateFrameName(g) end end
        end
    end
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    eventFrame:SetScript("OnEvent",function(self,event,unit)
        if event=="UNIT_NAME_UPDATE" then
            for i=1,40 do local f=_G["CompactRaidFrame"..i]; if f and f.unit==unit then UpdateFrameName(f); break end end
        else
            C_Timer.After(0.5,UpdateAllFrames)
        end
    end)
    C_Timer.After(1,UpdateAllFrames)
end

-- Load shit
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("ADDON_LOADED")

local function addonInitDispatcher(addonName)
    if addonName=="ElvUI" then C_Timer.After(0,SetupElvUITags) end
    if addonName=="Grid2" then InitializeGrid2() end
    if addonName=="MRT" then InitializeMRT() end
end

initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateCellNicknames()
        UpdateDefaultFrames()
        if C_AddOns.IsAddOnLoaded("ElvUI") then SetupElvUITags() end
        if C_AddOns.IsAddOnLoaded("Grid2") then InitializeGrid2() end
        if C_AddOns.IsAddOnLoaded("MRT") then InitializeMRT() end

    elseif event == "ADDON_LOADED" then
        addonInitDispatcher(arg1)
    end
end)

if C_AddOns.IsAddOnLoaded("ElvUI") then SetupElvUITags() end
if C_AddOns.IsAddOnLoaded("Grid2") then InitializeGrid2() end
if C_AddOns.IsAddOnLoaded("MRT") then InitializeMRT() end