GMGenie.CommandBus = {
    messageHandlers = {},

    dispatch = function(command)
        -- Using the guild channel to prevent messages being broadcast publicly
        -- in case the server does not interpret the message as a command
        SendChatMessage(command, "GUILD");
    end,
    dispatchAndReadResponse = function(command, messageHandler)
        self.registerMessageHandler(messageHandler);
        self.dispatch(command);
    end,
    registerMessageHandler = function(messageHandler)
        self.messageHandlers[messageHandler] = messageHandler;
    end,
    unregisterMessageHandler = function(messageHandler)
        self.messageHandlers[messageHandler] = nil;
    end
}
