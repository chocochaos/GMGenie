--- @class CommandBus
local CommandBus = {
    --- @type table<any, function>
    responseHandlers = {}
}

GMGenie.CommandBus = CommandBus;

--- @param command string
function CommandBus.dispatch(command)
    -- Using the guild channel to prevent messages being broadcast publicly
    -- in case the server does not interpret the message as a command
    SendChatMessage(command, "GUILD");
end

--- Dispatches a command and reads its response, then passes that response to a callback function.
--- @param command string The command to be dispatched.
--- @param identifier string
--- @param responseHandler fun(message: string):boolean The callback function that processes the command's response. It accepts a single string parameter.
function CommandBus.dispatchAndReadResponse(command, identifier, responseHandler)
    CommandBus.registerMessageHandler(identifier, responseHandler);
    CommandBus.dispatch(command);
end

--- @param identifier string
--- @param responseHandler fun(message: string):boolean
function CommandBus.registerMessageHandler(identifier, responseHandler)
    CommandBus.responseHandlers[identifier] = responseHandler;
end

--- @param identifier string
function CommandBus.unregisterMessageHandler(identifier)
    CommandBus.responseHandlers[identifier] = nil;
end
