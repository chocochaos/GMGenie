TicketTab = "General";

-- 1d2h3m4s to number in seconds
function GMGenie.timeStrToSeconds(timeStr)
    local days = string.match(timeStr, "([0-9]*)d");
    if not days then
        days = 0;
    end
    local hours = string.match(timeStr, "([0-9]*)h");
    if not hours then
        hours = 0;
    end
    local minutes = string.match(timeStr, "([0-9]*)m");
    if not minutes then
        minutes = 0;
    end
    local seconds = string.match(timeStr, "([0-9]*)s");
    if not seconds then
        seconds = 0;
    end
    return (((((tonumber(days) * 24) + tonumber(hours)) * 60) + tonumber(minutes)) * 60) + tonumber(seconds);
end

-- Read from chat
local ORIG_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
function ChatFrame_MessageEventHandler(self, event, message, ...)
    local ActionTaken = false;

    -- development code to analize chat messages
    local excapedarg = string.gsub(message, "%|", "%%");
    GMGenie.showGMMessage("1: " .. excapedarg);

    -- check for system messages of interest
    if (event == "CHAT_MSG_SYSTEM") then
        -- Showing list of open tickets whose creator is online.
        if string.find(message, "Showing list of open tickets") then
            Chronos.scheduleByName('ticketreupdate', 0.5, GMGenie.Tickets.update);
            ActionTaken = true;
        end
        -- ticket list or reading ticket
        local ticketId, name, createStr, lastModifiedStr, rest = string.match(message, "^%|cffaaffaaTicket%|r:%|cffaaccff%s([0-9]+).%|r%s%|cff00ff00Created%sby%|r:%|cff00ccff%s(.+)%|r%s%|cff00ff00Created%|r:%|cff00ccff%s([a-zA-Z0-9%s]+)%sago%|r%s%|cff00ff00Last%schange%|r:%|cff00ccff%s([a-zA-Z0-9%s]+)%sago%|r%s(.*)$");

        if ticketId and name and createStr and lastModifiedStr then
            ticketId = tonumber(ticketId);
            local createStamp = GMGenie.timeStrToSeconds(createStr);
            local lastModifiedStamp = GMGenie.timeStrToSeconds(lastModifiedStr);
            if GMGenie.Tickets.tempList then
                GMGenie.Tickets.listTicket(ticketId, name, createStr, createStamp, lastModifiedStr, lastModifiedStamp);
            end

            local assignedTo = string.match(rest, "%|cff00ff00Assigned%sto%|r:%|cff00ccff%s([a-zA-Z]+)%|r%s");
            if assignedTo then
                GMGenie.Tickets.setAssigned(ticketId, assignedTo);
            end
            local message = string.match(rest, "%|cff00ff00Ticket%sMessage%|r:%s%[(.-)%]%|r");
            local ticketCorrect = false;
            if message then
                ticketCorrect = GMGenie.Tickets.readTicket(ticketId, message);
            else
                local message = string.match(rest, "%|cff00ff00Ticket%sMessage%|r:%s%[(.*)");
                if message then
                    ticketCorrect = GMGenie.Tickets.readTicket(ticketId, message);
                    if ticketCorrect then
                        GMGenie.Tickets.messageOpen = true;
                    end
                end
            end

            local comment = string.match(rest, "%|cff00ff00GM%sComment%|r:%s%[(.*)%]%|r");
            if comment then
                GMGenie.Tickets.comment(ticketId, comment);
            end

            if ticketCorrect or GMGenie.Tickets.tempList then
                ActionTaken = true;
            end
        elseif GMGenie.Tickets.messageOpen then
            ActionTaken = true;
            local message, rest = string.match(message, "(.-)%]%|r(.*)");
            if message then
                GMGenie.Tickets.messageOpen = false;
                GMGenie.Tickets.addLine(message);
            else
                if string.find(message, "%]%|r") then
                    rest = string.match(message, "%]%|r(.*)");
                    GMGenie.Tickets.messageOpen = false;
                else
                    GMGenie.Tickets.addLine(message);
                end
            end

            if rest then
                local comment = string.match(rest, "%|cff00ff00GM%sComment%|r:%s%[(.*)%]%|r");
                if comment and GMGenie.Tickets.currentTicket['ticketId'] then
                    GMGenie.Tickets.comment(GMGenie.Tickets.currentTicket['ticketId'], comment);
                end
            end
        else
            -- Ticket edited
            local name, ticketId = string.match(message, "^%|cff00ff00Character%|r%|cffff00ff%s([a-zA-Z]+)%s%|r%|cff00ff00edited%shis/her%sticket:%|r%|cffff00ff%s([0-9]+).%|r$");
            if name and ticketId then
                if GMGenie.Tickets.isOpen() then
                    GMGenie.Tickets.refresh();
                end
                ActionTaken = true;
            end
            -- Ticket abandoned
            local name, ticketId = string.match(message, "^%|cff00ff00Character%|r%|cffff00ff%s([a-zA-Z]+)%s%|r%|cff00ff00abandoned%sticket%sentry:%|r%|cffff00ff%s([0-9]+).%|r$");
            if name and ticketId then
                if GMGenie.Tickets.isOpen() then
                    GMGenie.Tickets.refresh();
                end
                ActionTaken = true;
            end
            -- New Ticket
            local name, ticketId = string.match(message, "^%|cff00ff00New%sticket%sfrom%|r%|cffff00ff%s([a-zA-Z]+).%|r%s%|cff00ff00Ticket%sentry:%|r%|cffff00ff%s([0-9]+).%|r$");
            if name and ticketId then
                if GMGenie.Tickets.isOpen() then
                    GMGenie.Tickets.refresh();
                end
                ActionTaken = true;
            end
        end

        -- read coords from chat
        if GMGenie.Spawns.waitingForGps == 1 then
            if string.find(message, "^You are outdoors") or string.find(message, "^no VMAP available for area info") then
                ActionTaken = true;
            end
            local map = string.match(message, "^Map:%s([0-9]+)%s");
            if map then
                GMGenie.Spawns.waitingForGps = 2;
                GMGenie.Spawns.setMap(map);
                ActionTaken = true;
            end
        end
        if GMGenie.Spawns.waitingForGps == 2 then
            local x, y, z, o = string.match(message, "^X:%s([0-9%.%-]+)%sY:%s([0-9%.%-]+)%sZ:%s([0-9%.%-]+)%sOrientation:%s([0-9%.%-]+)$");
            if x and y and z and o then
                GMGenie.Spawns.waitingForGps = 3;
                GMGenie.Spawns.move(x, y, z, o);
                ActionTaken = true;
            end
        end
        if GMGenie.Spawns.waitingForGps == 3 then
            if string.find(message, "^grid") or string.find(message, "^ ZoneX") then
                ActionTaken = true;
            end
            if string.find(message, "^GroundZ") then
                GMGenie.Spawns.waitingForGps = 0;
                ActionTaken = true;
            end
        end

        if GMGenie.Spawns.waitingForObject then
            local name, guid, id = string.match(message, "%|cffffffff%|Hgameobject:.*%|h%[(.*)%]%|h%|r%sGUID:%s(.*)%sID:%s(.*)");
            if name and guid and id then
                GMGenie.Spawns.deleteObject(name, guid, id);
                ActionTaken = true;
            elseif string.find(message, "X:%s.*%sY:%s.*%sZ:%s.*%sMapId:%s.*") or string.find(message, "Orientation:%s.*") or string.find(message, "Phasemask%s.*") then
                ActionTaken = true;
            elseif string.find(message, "SpawnTime:%sFull:.*%sRemain:.*") then
                ActionTaken = true;
                GMGenie.Spawns.waitingForObject = false;
            elseif string.find(message, "Nothing found!") then
                GMGenie.Spawns.waitingForObject = false;
            end
        end

        if GMGenie.Spawns.waitingForObjectDelete then
            if string.find(message, "Game Object %(GUID: .*%) removed") then
                ActionTaken = true;
                GMGenie.Spawns.waitingForObjectDelete = false;
            end
        end

        local charName = UnitName("player");
        if string.match(message, "%|cffffffff%|Hplayer:" .. charName .. "%|h%[" .. charName .. "%]%|h%|r%'s Fly Mode on") then
            GMGenie.Hud.flyStatus(true);
        elseif string.match(message, "%|cffffffff%|Hplayer:" .. charName .. "%|h%[" .. charName .. "%]%|h%|r%'s Fly Mode off") then
            GMGenie.Hud.flyStatus(false);
        elseif message == "Accepting Whisper: ON" or message == "Accepting Whisper: on" then
            GMGenie.Hud.whisperStatus(true);
        elseif message == "Accepting Whisper: OFF" or message == "Accepting Whisper: off" then
            GMGenie.Hud.whisperStatus(false);
        elseif message == "You are: visible" then
            GMGenie.Hud.visibilityStatus(true);
        elseif message == "You are: invisible" then
            GMGenie.Hud.visibilityStatus(false);
        end

        local characterName = string.match(message, "%|cFFFFBF00%[AntiCheat%]%:%|cFFFFFFFF %[(.*)%] %|cFF00FFFFdetected as possible cheater%.");
        if characterName then
            message = "|cFFFFBF00[AntiCheat]:|r |Hanticheat:" .. characterName .. "|h[" .. characterName .. "]|h detected as possible cheater.";
        end
    end

    -- if nothing was done, just display the message
    if not ActionTaken then
        ORIG_ChatFrame_MessageEventHandler(self, event, message, ...);
    end
end

function GMGenie.messageStartsWithPipe(message)
    local firstCharacter = string.sub(message, 1, 1);
    return firstCharacter == '|';
end
