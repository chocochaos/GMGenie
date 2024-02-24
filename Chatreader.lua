--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

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
    --local excapedarg = string.gsub(arg1, "%|", "%%");
    --GMGenie.showGMMessage("1: " .. excapedarg);

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

        if GMGenie.Hud.isWaitingForPlayerInfo then
            if string.find(message, "Character .* does not exist") then
                GMGenie.Hud.isWaitingForPlayerInfo = false;
                GMGenie.Hud.gmStatus(false);
            else
                local isPlayerInfoMessage = GMGenie.messageStartsWithPipe(message);
                if isPlayerInfoMessage then
                    ActionTaken = true;

                    local isGmModeActive = string.find(message, "(GM Mode active)");
                    if isGmModeActive then
                        GMGenie.Hud.gmStatus(true);
                    end

                    local isLastMessage = string.find(message, "Played time: (.*)");
                    if isLastMessage then
                        GMGenie.Hud.waitingForPin = false;
                        if not GMGenie.Hud.hasFoundGmStatus then
                            GMGenie.Hud.gmStatus(false);
                        end
                    end
                end
            end
        end

        if GMGenie.Spy.waitingForPin or GMGenie.Macros.Discipline.IpBan.waitingForPin then
            if string.find(message, "Character .* does not exist") then
                GMGenie.Spy.waitingForPin = false;
                GMGenie.Macros.Discipline.IpBan.waitingForPin = false;
            else
                local isPlayerInfoMessage = GMGenie.messageStartsWithPipe(message);
                if GMGenie.Hud.waitingForPin and isPlayerInfoMessage then
                    ActionTaken = true;

                    local gmModeActive = string.find(message, "(GM Mode active)");
                    if gmModeActive then
                        GMGenie.Hud.gmStatus(true);
                    end

                    local isLastMessage = string.find(message, "Played time: (.*)");
                    if isLastMessage then
                        GMGenie.Hud.waitingForPin = false;
                    end
                elseif GMGenie.Spy.waitingForPin then
                    local offline, name1, _, guid = string.match(message, "Player  ?(.*) %|cffffffff%|Hplayer:(.*)%|h%[(.*)%]%|h%|r %(guid: (.*)%)");
                    -- TODO: use the below to figure out the GM status
                    local phase = string.match(message, "Phase: (.*)");
                    local account, accountId, gmLevel = string.match(message, "Account: (.*) %(ID: (.*)%), GMLevel: (.*)");
                    local login, failedLogins = string.match(message, "Last Login: (.*) %(Failed Logins: (.*)%)");
                    local os_, latency = string.match(message, "OS: (.*) %- Latency: (.*) ms");
                    local email = string.match(message, "%- Email: (.*)");
                    local ip, locked = string.match(message, "Last IP: (.*) %(Locked: (.*)%)");
                    local level = string.match(message, "Level: ([0-9]+)");
                    local race, class = string.match(message, "Race: (.*), (.*)");
                    local alive = string.match(message, "Alive %?: (.*)");
                    local money = string.match(message, "Money: (.*)");
                    local map, zone, area = string.match(message, "Map: (.*), Zone: (.*), Area: (.*)");
                    if not map then
                        map, zone = string.match(message, "Map: (.*), Zone: (.*)");
                    end
                    local guild, guildId = string.match(message, "Guild: (.*) %(ID: (.*)%)");
                    local guildRank = string.match(message, "Rank: (.*)");
                    local note = string.match(message, "Note: (.*)");
                    local officerNote = string.match(message, "O. Note: (.*)");
                    local playedTime = string.match(message, "Played time: (.*)");


                    if offline then
                        GMGenie.Spy.processPin01(offline, name1, guid, message);
                        ActionTaken = true;
                    end
                    if phase then
                        GMGenie.Spy.processPin02(phase, message);
                        ActionTaken = true;
                    end
                    if account then
                        GMGenie.Spy.processPin03(account, accountId, gmLevel, message);
                        ActionTaken = true;
                    end
                    if login then
                        GMGenie.Spy.processPin04(login, failedLogins, message);
                        ActionTaken = true;
                    end
                    if os_ then
                        GMGenie.Spy.processPin05(os_, latency, message);
                        ActionTaken = true;
                    end
                    if email then
                        GMGenie.Spy.processPin06(email, message);
                        ActionTaken = true;
                    end
                    if ip then
                        GMGenie.Spy.processPin07(ip, locked, message);
                        ActionTaken = true;
                    end
                    if level then
                        GMGenie.Spy.processPin08(level, message);
                        ActionTaken = true;
                    end
                    if race then
                        GMGenie.Spy.processPin09(race, class, message);
                        ActionTaken = true;
                    end
                    if alive then
                        GMGenie.Spy.processPin10(alive, message);
                        ActionTaken = true;
                    end
                    if money then
                        GMGenie.Spy.processPin11(money, message);
                        ActionTaken = true;
                    end
                    if map then
                        GMGenie.Spy.processPin12(map, area, zone, message);
                        ActionTaken = true;
                    end
                    if guild then
                        GMGenie.Spy.processPin13(guild, guildId, message);
                        ActionTaken = true;
                    end
                    if guildRank then
                        GMGenie.Spy.processPin14(guildRank, message);
                        ActionTaken = true;
                    end
                    if note then
                        GMGenie.Spy.processPin15(note, message);
                        ActionTaken = true;
                    end
                    if officerNote then
                        GMGenie.Spy.processPin16(officerNote, message);
                        ActionTaken = true;
                    end
                    if playedTime then
                        GMGenie.Spy.processPin17(playedTime, message);
                        ActionTaken = true;
                    end
                else
                    local ip, locked = string.match(message, "Last IP: (.*) %(Locked: (.*)%)")

                    if ip then
                        GMGenie.Macros.Discipline.IpBan.processPin(ip);
                        ActionTaken = true;
                    end
                end
            end
        end

        if GMGenie.Spy.waitingForMail then
            local read, total = string.match(message, "Mails: (.*) Read/(.*) Total");
            if read then
                GMGenie.Spy.processPin18(read, total, message);
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
    local firstCharacter = string.sub(str, 1, 1);
    return firstCharacter == '|';
end
