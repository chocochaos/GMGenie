local PlayerInfoReader = {
    --- @type string
    identifier = "PlayerInfoReader",
    --- @type IncompletePlayerInfo
    retrievedData = {
        accountName = nil,
        accountId = nil,
        emailAdress = nil,
        gmLevel = nil,
        ip = nil,
        latency = nil,
        lastLogin = nil,
        failedLogins = nil,
        characterName = nil,
        characterId = nil,
        race = nil,
        class = nil,
        level = nil,
        location = nil,
        money = nil,
        phase = nil,
        totalPlayTime = nil,
        guild = nil,
    },
};

GMGenie.Reader.PlayerInfo = PlayerInfoReader;

--- @param characterName string
--- @param onSuccess fun(retrievedData: PlayerInfo): nil
--- @param onError fun(message: string): nil
function PlayerInfoReader.read(characterName, onSuccess, onError)
    --- @type ReaderConfiguration
    local readerConfiguration = {
        identifier = PlayerInfoReader.identifier,
        gmCommand = '.pin ' .. characterName,
        subscribers = PlayerInfoReader.subscribers,
        resetState = PlayerInfoReader.resetState,
        getFinalRetrievedData = PlayerInfoReader.getFinalRetrievedData,
        onSuccess = onSuccess,
        onError = onError,
    };

    GMGenie.Reader.initialise(readerConfiguration);
end

function PlayerInfoReader.resetState()
    table.foreach(
        PlayerInfoReader.retrievedData,
        function(key, _)
            PlayerInfoReader.retrievedData[key] = nil;
        end
    );
end

--- @return PlayerInfo
function PlayerInfoReader.getFinalRetrievedData()
    return {
        accountName = PlayerInfoReader.retrievedData.accountName or "",
        accountId = PlayerInfoReader.retrievedData.accountId or 0,
        emailAdress = PlayerInfoReader.retrievedData.emailAdress,
        gmLevel = PlayerInfoReader.retrievedData.gmLevel or 0,
        ip = PlayerInfoReader.retrievedData.ip or "",
        latency = PlayerInfoReader.retrievedData.latency or 0,
        lastLogin = PlayerInfoReader.retrievedData.lastLogin or "",
        failedLogins = PlayerInfoReader.retrievedData.failedLogins or 0,
        characterName = PlayerInfoReader.retrievedData.characterName or "",
        characterId = PlayerInfoReader.retrievedData.characterId or 0,
        race = PlayerInfoReader.retrievedData.race or "",
        class = PlayerInfoReader.retrievedData.class or "",
        level = PlayerInfoReader.retrievedData.level or 0,
        location = PlayerInfoReader.retrievedData.location or "",
        money = PlayerInfoReader.retrievedData.money or "",
        phase = PlayerInfoReader.retrievedData.phase or 0,
        totalPlayTime = PlayerInfoReader.retrievedData.totalPlayTime or "",
        guild = PlayerInfoReader.retrievedData.guildName,

    };
end

--- @type ChatMessageSubscriber[]
PlayerInfoReader.subscribers = {
    {
        onSystemMessage = function(message)
            if string.find(message, "Character .* does not exist") then
                GMGenie.Reader.reportError(PlayerInfoReader.identifier, "Character does not exist");
                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local _offline, characterName, _unknown, characterId = string.match(
                message,
                "Player  ?(.*) %|cffffffff%|Hplayer:(.*)%|h%[(.*)%]%|h%|r %(guid: (.*)%)"
            );

            if characterName or characterId then
                PlayerInfoReader.retrievedData.characterName = characterName;
                PlayerInfoReader.retrievedData.characterId = characterId;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local phase = string.match(message, "Phase: (.*)");

            if phase then
                PlayerInfoReader.retrievedData.phase = phase;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local account, accountId, gmLevel = string.match(message, "Account: (.*) %(ID: (.*)%), GMLevel: (.*)");

            if account or accountId or gmLevel then
                PlayerInfoReader.retrievedData.accountName = account;
                PlayerInfoReader.retrievedData.accountId = accountId;
                PlayerInfoReader.retrievedData.gmLevel = gmLevel;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local login, failedLogins = string.match(message, "Last Login: (.*) %(Failed Logins: (.*)%)");

            if login or failedLogins then
                PlayerInfoReader.retrievedData.lastLogin = login;
                PlayerInfoReader.retrievedData.failedLogins = failedLogins;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local _os, latency = string.match(message, "OS: (.*) %- Latency: (.*) ms");

            if latency then
                PlayerInfoReader.retrievedData.latency = latency;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local email = string.match(message, "%- Email: (.*)");

            if email then
                PlayerInfoReader.retrievedData.emailAdress = email;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local ip, locked = string.match(message, "Last IP: (.*) %(Locked: (.*)%)");

            if ip then
                PlayerInfoReader.retrievedData.ip = ip;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local level = string.match(message, "Level: ([0-9]+)");

            if level then
                PlayerInfoReader.retrievedData.level = level;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local race, class = string.match(message, "Race: (.*), (.*)");

            if race or class then
                PlayerInfoReader.retrievedData.race = race;
                PlayerInfoReader.retrievedData.class = class;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local alive = string.match(message, "Alive %?: (.*)");

            if alive then
                -- alive is not printed for now

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local money = string.match(message, "Money: (.*)");

            if money then
                PlayerInfoReader.retrievedData.money = money;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local map, zone, area = string.match(message, "Map: (.*), Zone: (.*), Area: (.*)");

            if not map then
                map, zone = string.match(message, "Map: (.*), Zone: (.*)");
            end

            if map or zone or area then
                local fullLocation = map;
                if zone ~= nil and string.trim(string.upper(zone)) ~= '<UNKNOWN>' and map ~= zone then
                    fullLocation = zone .. ', ' .. fullLocation;
                end
                if area ~= nil and string.trim(string.upper(area)) ~= '<UNKNOWN>' and map ~= area and zone ~= area then
                    fullLocation = area .. ', ' .. fullLocation;
                end

                PlayerInfoReader.retrievedData.location = fullLocation;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local guild, guildId = string.match(message, "Guild: (.*) %(ID: (.*)%)");

            if guild or guildId then
                PlayerInfoReader.retrievedData.guildName = guild;

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local guildRank = string.match(message, "Rank: (.*)");

            if guildRank then
                -- guild rank is not printed for now

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local note = string.match(message, "Note: (.*)");

            if note then
                -- note is not printed for now

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local officerNote = string.match(message, "O. Note: (.*)");

            if officerNote then
                -- officerNote is not printed for now

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
    {
        onSystemMessage = function(message)
            local playedTime = string.match(message, "Played time: (.*)");

            if playedTime then
                PlayerInfoReader.retrievedData.totalPlayTime = playedTime;

                -- This is the last playerinfo message, report success to stop listening for new messages.
                GMGenie.Reader.reportSuccess(PlayerInfoReader.identifier);

                return {stopPropagation = true};
            end

            return {stopPropagation = false};
        end,
    },
};
