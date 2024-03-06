--- @class CommandBus
local CommandBus = {
    --- @type table<any, function>
    responseHandlers = {}
}

function CommandBus.dispatch(command)
    -- Using the guild channel to prevent messages being broadcast publicly
    -- in case the server does not interpret the message as a command
    SendChatMessage(command, "GUILD");
end

-- Dispatches a command and reads its response, then passes that response to a callback function.
--
-- @param command string The command to be dispatched.
-- @param callback fun(message: string):void The callback function that processes the command's response. It accepts a single string parameter.
function CommandBus.dispatchAndReadResponse(command, responseHandler)
    CommandBus.registerMessageHandler(responseHandler);
    CommandBus.dispatch(command);
end

function CommandBus.registerMessageHandler(responseHandler)
    CommandBus.responseHandlers[responseHandler] = responseHandler;
end

function CommandBus.unregisterMessageHandler(responseHandler)
    CommandBus.responseHandlers[responseHandler] = nil;
end

GMGenie.CommandBus = CommandBus
