local GMCommandDispatcher = {};

GMGenie.GMCommandDispatcher = GMCommandDispatcher;

--- Dispatch a GM command.
--- @param command string
function GMCommandDispatcher.dispatch(command)
    GMGenie.printDebugMessage("Dispatching GM command: " .. command);

    -- Using the guild channel to prevent messages being broadcast publicly
    -- in case the server does not interpret the message as a command
    SendChatMessage(command, "GUILD");
end
