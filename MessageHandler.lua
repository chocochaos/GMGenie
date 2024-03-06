local originalMessageHandler = ChatFrame_MessageEventHandler;
function ChatFrame_MessageEventHandler(self, event, message, ...)
    local shouldMessageBeSuppressedInChat = false;

    if event == "CHAT_MSG_SYSTEM" then
        for _, messageHandler in pairs(GMGenie.CommandBus.responseHandlers) do
            shouldMessageBeSuppressedInChat = messageHandler(message);

            if shouldMessageBeSuppressedInChat then
                GMGenie.showGMMessage('Message handler handled: ' ~ message);
                break;
            end
        end
    end

    if not shouldMessageBeSuppressedInChat then
        originalMessageHandler(self, event, message, ...);
    end
end
