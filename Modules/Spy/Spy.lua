local Spy = {
    --- @type CharacterInfo|nil
    characterInfo = nil,
    --- @type AccountInfo|nil
    account = nil,
    --- @type GuildInfo|nil
    guild = nil,
};

GMGenie.Spy = Spy;

--- @param characterName string
--- @return nil
function Spy.execute(characterName)
    characterName = Spy.resolveCharacterName(characterName);

    if not characterName or string.len(characterName) < 1 then
        GMGenie.printErrorMessage("Please enter a name or target a player.");
        return ;
    end

    Spy.reset();

    GMGenie.Reader.PlayerInfo.read(
        characterName,
        Spy.onPlayerInfoSuccess,
        Spy.onPlayerInfoError
    );
end

function Spy.reset()
    Spy.characterInfo = nil;
    Spy.account = nil;
    Spy.guild = nil;
    Spy.updateDataInUI();
end

--- @param playerInfo PlayerInfo
--- @return nil
function Spy.onPlayerInfoSuccess(playerInfo)
    --- @type CharacterInfo
    Spy.character = {
        characterName = playerInfo.characterName,
        characterId = playerInfo.characterId,
        race = playerInfo.race,
        class = playerInfo.class,
        level = playerInfo.level,
        location = playerInfo.location,
        money = playerInfo.money,
        phase = playerInfo.phase,
        totalPlayTime = playerInfo.totalPlayTime,
    };
    --- @type AccountInfo
    Spy.account = {
        accountName = playerInfo.accountName,
        accountId = playerInfo.accountId,
        emailAdress = playerInfo.emailAdress,
        gmLevel = playerInfo.gmLevel,
        ip = playerInfo.ip,
        latency = playerInfo.latency,
        lastLogin = playerInfo.lastLogin,
        failedLogins = playerInfo.failedLogins,
    };
    --- @type GuildInfo
    Spy.guild = {
        guildName = playerInfo.guildName,
    };

    Spy.updateDataInUI();
    Spy.openWindow();
end

--- @param errorMessage string
--- @return nil
function Spy.onPlayerInfoError(errorMessage)
    GMGenie.printErrorMessage(errorMessage);
    Spy.reset();
    Spy.closeWindow();
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

function Spy.openWindow()
    GMGenie.Spy_InfoWindow:Show();
end

function Spy.closeWindow()
    GMGenie.Spy_InfoWindow:Hide();
end

--- @return nil
function Spy.updateDataInUI()
    GMGenie_Spy_InfoWindow_Info_CharInfo:SetText(
        "Level " .. (Spy.character.level or 0)
        .. " " .. (Spy.character.race or "")
        .. " " .. (Spy.character.class or "")
    );
    GMGenie_Spy_InfoWindow_Info_Guild:SetText(
        tostring(Spy.guild.guildName or nil)
    );
    GMGenie_Spy_InfoWindow_Title_Text:SetText(
        tostring(Spy.character.characterName or nil)
    );
    GMGenie_Spy_InfoWindow_Character_Name:SetText(
        tostring(Spy.character.characterName or nil)
    );
    GMGenie_Spy_InfoWindow_Character_Id:SetText(
        tostring(Spy.character.characterId or nil)
    );
    GMGenie_Spy_InfoWindow_Account_Name:SetText(
        tostring(Spy.account.accountName or nil)
    );
    GMGenie_Spy_InfoWindow_Account_Id:SetText(
        tostring(Spy.account.accountId or nil)
    );
    GMGenie_Spy_InfoWindow_Email_Email:SetText(
        tostring(Spy.account.emailAdress or nil)
    );
    GMGenie_Spy_InfoWindow_IpLat_Ip:SetText(
        tostring(Spy.account.ip or nil)
    );
    local latency = tonumber(Spy.account.latency or 0);
    if latency and latency > 1000 then
        GMGenie_Spy_InfoWindow_IpLat_Latency:SetFontObject(GenieFontRedSmall);
    else
        GMGenie_Spy_InfoWindow_IpLat_Latency:SetFontObject(GenieFontHighlightSmall);
    end
    GMGenie_Spy_InfoWindow_IpLat_Latency:SetText(
        tostring(Spy.account.latency or nil)
    );
    GMGenie_Spy_InfoWindow_LastLogin_LastLogin:SetText(
        tostring(Spy.account.lastLogin or nil)
);
    GMGenie_Spy_InfoWindow_PlayedGM_PlayedTime:SetText(
        tostring(Spy.character.totalPlayTime or nil)
    );
    GMGenie_Spy_InfoWindow_PlayedGM_GM:SetText(
        tostring(Spy.account.gmLevel or nil)
    );
    GMGenie_Spy_InfoWindow_MoneyPhase_Money:SetText(
        tostring(Spy.character.money or nil)
    );
    GMGenie_Spy_InfoWindow_MoneyPhase_Phase:SetText(
        tostring(Spy.character.phase or nil)
    );
    GMGenie_Spy_InfoWindow_Location_Location:SetText(
        tostring(Spy.character.location or nil)
    );
    -- Scroll the location field to the left, in case it overflows.
    GMGenie_Spy_InfoWindow_Location_Location:SetCursorPosition(0);

    Spy.openWindow();
end

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
    ChatFrame_SendTell(Spy.character.characterName);
end

function Spy.summon()
    GMGenie.Macros.summon(Spy.character.characterName);
end

function Spy.appear()
    GMGenie.Macros.appear(Spy.character.characterName);
end

function Spy.revive()
    GMGenie.Macros.revive(Spy.character.characterName);
end

function Spy.freeze()
    GMGenie.Macros.freeze(Spy.character.characterName);
end

function Spy.unfreeze()
    GMGenie.Macros.unfreeze(Spy.character.characterName);
end

function Spy.rename()
    GMGenie.Macros.rename(Spy.character.characterName);
end

function Spy.antiCheatPlayer()
    GMGenie.Macros.antiCheatPlayer(Spy.character.characterName);
end

function Spy.customize()
    GMGenie.Macros.customize(Spy.character.characterName);
end

function Spy.changefaction()
    GMGenie.Macros.changefaction(Spy.character.characterName);
end

function Spy.changerace()
    GMGenie.Macros.changerace(Spy.character.characterName);
end

function Spy.banInfo()
    CloseDropDownMenus()
    SendChatMessage(".baninfo account " .. Spy.account.accountName, "GUILD");
    SendChatMessage(".baninfo character " .. Spy.character.characterName, "GUILD");
    SendChatMessage(".baninfo ip " .. Spy.account.ip, "GUILD");
end

function Spy.lookupPlayer()
    CloseDropDownMenus()
    SendChatMessage(".lookup player account " .. Spy.account.accountName, "GUILD");
    SendChatMessage(".lookup player email " .. Spy.account.emailAdress, "GUILD");
    SendChatMessage(".lookup player ip " .. Spy.account.ip, "GUILD");
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
