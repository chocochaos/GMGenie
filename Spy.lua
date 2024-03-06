--- @class Spy
local Spy = {
    playerInfo = {
        --- @type string
        accountName = "",
        --- @type string
        accountId = "",
        --- @type string
        race = "",
        --- @type string
        class = "",
        --- @type string
        emailAdress = "",
        --- @type string
        gmLevel = "",
        --- @type string
        guid = "",
        --- @type string
        guild = "",
        --- @type string
        ip = "",
        --- @type string
        latency = "",
        --- @type string
        level = "",
        --- @type string
        location = "",
        --- @type string
        lastLogin = "",
        --- @type string
        failedLogins = "",
        --- @type string
        money = "",
        --- @type string
        characterName = "",
        --- @type string
        phase = "",
        --- @type string
        totalPlayTime = ""
    }
};

GMGenie.Spy = Spy;

--- @param characterName string
--- @return nil
function Spy.execute(characterName)
    characterName = Spy.resolveCharacterName(characterName);

    if not characterName or string.len(characterName) < 1 then
        GMGenie.showGMMessage("Please enter a name or target a player.");
        return ;
    end

    Spy.reset();
    Spy.playerInfo.characterName = characterName;

    GMGenie.CommandBus.dispatchAndReadResponse(
        ".pin " .. characterName,
        "Spy.handlePlayerInfoResponse",
        Spy.handlePlayerInfoResponse
    );
end

--- @param characterName string
--- @return string
function Spy.resolveCharacterName(characterName)
    local characterNameIsEmpty = not characterName or string.len(characterName) < 1;

    if characterNameIsEmpty then
        local name, _ = UnitName("target");
        return name;
    end

    local characterNameIsTarget = characterName == "%t";

    if characterNameIsTarget then
        local name, _ = UnitName("target");
        return name;
    end

    return characterName;
end

--- @return nil
function Spy.reset()
    -- Set all values in the table Spy.playerInfo to nil
    for key, _ in pairs(Spy.playerInfo) do
        Spy.playerInfo[key] = "";
    end

    Spy.updateUI();
end

--- @return nil
function Spy.updateUI()
    GMGenie_Spy_InfoWindow_Info_CharInfo:SetText("Level " .. Spy.playerInfo.level .. " " .. Spy.playerInfo.race .. " " .. Spy.playerInfo.class);
    GMGenie_Spy_InfoWindow_Info_Guild:SetText(Spy.playerInfo.guild);
    GMGenie_Spy_InfoWindow_Title_Text:SetText(Spy.playerInfo.characterName);
    GMGenie_Spy_InfoWindow_Character_Name:SetText(Spy.playerInfo.characterName);
    GMGenie_Spy_InfoWindow_Character_Id:SetText(Spy.playerInfo.guid);
    GMGenie_Spy_InfoWindow_Account_Name:SetText(Spy.playerInfo.accountName);
    GMGenie_Spy_InfoWindow_Account_Id:SetText(Spy.playerInfo.accountId);
    GMGenie_Spy_InfoWindow_Email_Email:SetText(Spy.playerInfo.emailAdress);
    GMGenie_Spy_InfoWindow_IpLat_Ip:SetText(Spy.playerInfo.ip);
    if tonumber(Spy.playerInfo.latency) and tonumber(Spy.playerInfo.latency) > 1000 then
        GMGenie_Spy_InfoWindow_IpLat_Latency:SetFontObject(GenieFontRedSmall);
    else
        GMGenie_Spy_InfoWindow_IpLat_Latency:SetFontObject(GenieFontHighlightSmall);
    end
    GMGenie_Spy_InfoWindow_IpLat_Latency:SetText(Spy.playerInfo.latency);
    GMGenie_Spy_InfoWindow_LastLogin_LastLogin:SetText(Spy.playerInfo.lastLogin);
    GMGenie_Spy_InfoWindow_PlayedGM_PlayedTime:SetText(Spy.playerInfo.totalPlayTime);
    GMGenie_Spy_InfoWindow_PlayedGM_GM:SetText(Spy.playerInfo.gmLevel);
    GMGenie_Spy_InfoWindow_MoneyPhase_Money:SetText(Spy.playerInfo.money);
    GMGenie_Spy_InfoWindow_MoneyPhase_Phase:SetText(Spy.playerInfo.phase);
    GMGenie_Spy_InfoWindow_Location_Location:SetText(Spy.playerInfo.location);
    -- Scroll the fields to the left, in case it overflows.
    GMGenie_Spy_InfoWindow_Location_Location:SetCursorPosition(0);
end

----------------------------------------
--- START PLAYERINFO RESPONSE HANDLING
----------------------------------------

--- @param message string
--- @return boolean
function Spy.handlePlayerInfoResponse(message)
    GMGenie.showGMMessage("Spy - handling message: " .. message);
    if string.find(message, "Character .* does not exist") then
        GMGenie.showGMMessage("Spy: character not found");
        GMGenie.CommandBus.unregisterMessageHandler("Spy.handlePlayerInfoResponse");
        return false;
    end

    local isPlayerInfoMessage = GMGenie.messageStartsWithBrokenBar(message);
    if not isPlayerInfoMessage then
        GMGenie.showGMMessage("Spy: this is not a playerinfo message");
        return false;
    end

    for _, lineHandler in pairs(Spy.PlayerInfoLineHandlers) do
        local lineWasParsed = lineHandler(message);

        if lineWasParsed then
            GMGenie.showGMMessage("Spy: line was parsed");
            Spy.updateUI();
            return true;
        end
    end

    return false;
end

--- @type table<number, fun(message: string):boolean>
Spy.PlayerInfoLineHandlers = {
    function(message)
        local _offline, characterName, _unknown, guid = string.match(
            message,
            "Player  ?(.*) %|cffffffff%|Hplayer:(.*)%|h%[(.*)%]%|h%|r %(guid: (.*)%)"
        );

        if characterName or guid then
            Spy.playerInfo.characterName = characterName;
            Spy.playerInfo.guid = guid;

            return true;
        end

        return false;
    end,
    function(message)
        local phase = string.match(message, "Phase: (.*)");

        if phase then
            Spy.playerInfo.phase = phase;

            return true;
        end

        return false;
    end,
    function(message)
        local account, accountId, gmLevel = string.match(message, "Account: (.*) %(ID: (.*)%), GMLevel: (.*)");

        if account or accountId or gmLevel then
            Spy.playerInfo.accountName = account;
            Spy.playerInfo.accountId = accountId;
            Spy.playerInfo.gmLevel = gmLevel;

            return true;
        end

        return false;
    end,
    function(message)
        local login, failedLogins = string.match(message, "Last Login: (.*) %(Failed Logins: (.*)%)");

        if login or failedLogins then
            Spy.playerInfo.lastLogin = login;
            Spy.playerInfo.failedLogins = failedLogins;

            return true;
        end

        return false;
    end,
    function(message)
        local _os, latency = string.match(message, "OS: (.*) %- Latency: (.*) ms");

        if latency then
            Spy.playerInfo.latency = latency;

            return true;
        end

        return false;
    end,
    function(message)
        local email = string.match(message, "%- Email: (.*)");

        if email then
            Spy.playerInfo.emailAdress = email;

            return true;
        end

        return false;
    end,
    function(message)
        local ip, locked = string.match(message, "Last IP: (.*) %(Locked: (.*)%)");

        if ip then
            Spy.playerInfo.ip = ip;

            return true;
        end

        return false;
    end,
    function(message)
        local level = string.match(message, "Level: ([0-9]+)");

        if level then
            Spy.playerInfo.level = level;

            return true;
        end

        return false;
    end,
    function(message)
        local race, class = string.match(message, "Race: (.*), (.*)");

        if race or class then
            Spy.playerInfo.race = race;
            Spy.playerInfo.class = class;

            return true;
        end

        return false;
    end,
    function(message)
        local alive = string.match(message, "Alive %?: (.*)");

        if alive then
            -- alive is not printed for now

            return true;
        end

        return false;
    end,
    function(message)
        local money = string.match(message, "Money: (.*)");

        if money then
            Spy.playerInfo.money = money;

            return true;
        end

        return false;
    end,
    function(message)
        local map, zone, area = string.match(message, "Map: (.*), Zone: (.*), Area: (.*)");

        if not map then
            map, zone = string.match(message, "Map: (.*), Zone: (.*)");
        end

        if map or zone or area then
            local fullLocation = map;
            if zone ~= nil and string.upper(zone) ~= '<UNKNOWN>' and map ~= zone then
                fullLocation = zone .. ', ' .. fullLocation;
            end
            if area ~= nil and map ~= area and zone ~= area then
                fullLocation = area .. ', ' .. fullLocation;
            end

            Spy.playerInfo.location = fullLocation;

            return true;
        end

        return false;
    end,
    function(message)
        local guild, guildId = string.match(message, "Guild: (.*) %(ID: (.*)%)");

        if guild or guildId then
            Spy.playerInfo.guild = guild;

            return true;
        end

        return false;
    end,
    function(message)
        local guildRank = string.match(message, "Rank: (.*)");

        if guildRank then
            -- guild rank is not printed for now

            return true;
        end

        return false;
    end,
    function(message)
        local note = string.match(message, "Note: (.*)");

        if note then
            -- note is not printed for now

            return true;
        end

        return false;
    end,
    function(message)
        local officerNote = string.match(message, "O. Note: (.*)");

        if officerNote then
            -- officerNote is not printed for now

            return true;
        end

        return false;
    end,
    function(message)
        local playedTime = string.match(message, "Played time: (.*)");

        if playedTime then
            Spy.playerInfo.totalPlayTime = playedTime;

            -- This is the last playerInfo message, so we can unregister the handler here.
            GMGenie.CommandBus.unregisterMessageHandler("Spy.handlePlayerInfoResponse");

            return true;
        end

        return false;
    end
}

----------------------------------------
--- END PLAYERINFO RESPONSE HANDLING
----------------------------------------

function Spy.loadDropdown(_, level)
    local info = UIDropDownMenu_CreateInfo();
    info.hasArrow = false;
    info.notCheckable = true;
    info.text = 'Ban Info';
    info.func = GMGenie.Spy.banInfo;
    UIDropDownMenu_AddButton(info, level);

    local info = UIDropDownMenu_CreateInfo();
    info.hasArrow = false;
    info.notCheckable = true;
    info.text = 'Lookup Player';
    info.func = GMGenie.Spy.lookupPlayer;
    UIDropDownMenu_AddButton(info, level);
end

SLASH_SPY1 = "/spy";
SlashCmdList["SPY"] = Spy.execute;

function Spy.whisper()
    ChatFrame_SendTell(Spy.playerInfo.characterName);
end

function Spy.summon()
    GMGenie.Macros.summon(Spy.playerInfo.characterName);
end

function Spy.appear()
    GMGenie.Macros.appear(Spy.playerInfo.characterName);
end

function Spy.revive()
    GMGenie.Macros.revive(Spy.playerInfo.characterName);
end

function Spy.freeze()
    GMGenie.Macros.freeze(Spy.playerInfo.characterName);
end

function Spy.unfreeze()
    GMGenie.Macros.unfreeze(Spy.playerInfo.characterName);
end

function Spy.rename()
    GMGenie.Macros.rename(Spy.playerInfo.characterName);
end

function Spy.antiCheatPlayer()
    GMGenie.Macros.antiCheatPlayer(Spy.playerInfo.characterName);
end

function Spy.customize()
    GMGenie.Macros.customize(Spy.playerInfo.characterName);
end

function Spy.changefaction()
    GMGenie.Macros.changefaction(Spy.playerInfo.characterName);
end

function Spy.changerace()
    GMGenie.Macros.changerace(Spy.playerInfo.characterName);
end

function Spy.banInfo()
    CloseDropDownMenus()
    SendChatMessage(".baninfo account " .. Spy.playerInfo.accountName, "GUILD");
    SendChatMessage(".baninfo character " .. Spy.playerInfo.characterName, "GUILD");
    SendChatMessage(".baninfo ip " .. Spy.playerInfo.ip, "GUILD");
end

function Spy.lookupPlayer()
    CloseDropDownMenus()
    SendChatMessage(".lookup player account " .. Spy.playerInfo.accountName, "GUILD");
    SendChatMessage(".lookup player email " .. Spy.playerInfo.emailAdress, "GUILD");
    SendChatMessage(".lookup player ip " .. Spy.playerInfo.ip, "GUILD");
end

local Saved_SetItemRef = SetItemRef;
function SetItemRef(link, text, button, chatFrame)
    if (strsub(link, 1, 9) == "anticheat") then
        local _, name = strsplit(":", link);
        if (button == "LeftButton") then
            GMGenie.Spy.antiCheat(name);
        elseif (button == "RightButton") then
            FriendsFrame_ShowDropdown(name, 1);
        end
        return ;
    end
    Saved_SetItemRef(link, text, button, chatFrame);
end

function Spy.antiCheat(name)
    Spy.execute(name);
    GMGenie.Spy.antiCheatPlayer();
    GMGenie.Hud.toggleVisibility(false);
    GMGenie.Spy.appear();
end
