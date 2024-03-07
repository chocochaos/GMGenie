local defaultInGameChatEventHandler = ChatFrame_MessageEventHandler;
local function ourChatEventHandler(self, event, message, ...)
    local response = nil;
    if event == "CHAT_MSG_SYSTEM" then
        response = GMGenie.ChatMessagePublisher.publishSystemMessage(message);
    end

    if not response or not response.stopPropagation then
        defaultInGameChatEventHandler(self, event, message, ...);
    end
end

-- Hacky, but by doing it this way propagation of messages to the in-game chat can be controlled.
ChatFrame_MessageEventHandler = ourChatEventHandler;
