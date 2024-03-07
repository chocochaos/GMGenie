local Reader = {
    timeoutInSeconds = 1,
    --- @type table<string, ReaderConfiguration>
    attachedReaders = {},
};

GMGenie.Reader = Reader;

--- @param reader ReaderConfiguration
function Reader.initialise(reader)
    if Reader.isReaderAlreadyAttached(reader) then
        local errorMessage = "Cannot read using "
            .. reader.identifier
            .. " again until the previous read has finished. "
            .. "In other words: don't click so fast ;)";
        reader.onError(errorMessage);
        return;
    end

    Reader.attachReader(reader);

    GMGenie.GMCommandDispatcher.dispatch(reader.gmCommand);
end

--- @param reader ReaderConfiguration
--- @return nil
function Reader.reset(reader)
    Reader.detachReader(reader);

    reader.resetState();
end

--- @param reader ReaderConfiguration
function Reader.isReaderAlreadyAttached(reader)
    return Reader.attachedReaders[reader.identifier] ~= nil;
end

--- @param reader ReaderConfiguration
function Reader.attachReader(reader)
    GMGenie.printDebugMessage("Attaching reader: " .. reader.identifier);

    Reader.attachedReaders[reader.identifier] = reader;

    table.foreach(
        reader.subscribers,
        function(_, subscriber)
            GMGenie.ChatMessagePublisher.subscribe(
                Reader.getSubscriptionKey(reader),
                subscriber
            );
        end
    );

    Chronos.scheduleByName(
        Reader.getTimeoutScheduleKey(reader),
        Reader.timeoutInSeconds,
        function()
            Reader.onTimeout(reader.identifier);
        end
    );
end

function Reader.detachReader(reader)
    GMGenie.printDebugMessage("Detaching reader: " .. reader.identifier);

    Chronos.unscheduleByName(
        Reader.getTimeoutScheduleKey(reader)
    );

    GMGenie.ChatMessagePublisher.unsubscribe(
        Reader.getSubscriptionKey(reader)
    );

    Reader.attachedReaders[reader.identifier] = nil;
end

function Reader.getSubscriptionKey(reader)
    return "SubscriptionFor" .. reader.identifier;
end

--- @param reader ReaderConfiguration
--- @return string
function Reader.getTimeoutScheduleKey(reader)
    return "TimeoutFor" .. reader.identifier;
end

--- @param readerIdentifier string
--- @return nil
function Reader.onTimeout(readerIdentifier)
    local errorMessage = "Reading " .. readerIdentifier .. " timed out after " .. Reader.timeoutInSeconds .. " seconds.";
    Reader.reportError(readerIdentifier, errorMessage);
end

--- @param readerIdentifier string
--- @param errorMessage string
--- @return nil
function Reader.reportError(readerIdentifier, errorMessage)
    GMGenie.printDebugMessage("Reader error: " .. errorMessage .. " for " .. readerIdentifier);

    local reader = Reader.attachedReaders[readerIdentifier];
    if not reader then
        GMGenie.printErrorMessage("ReaderStateManager.reportError: Reader not found for identifier " .. readerIdentifier);

        return;
    end

    Reader.reset(reader);

    reader.onError(errorMessage);
end

--- @param readerIdentifier string
--- @return nil
function Reader.reportSuccess(readerIdentifier)
    GMGenie.printDebugMessage("Reader success for " .. readerIdentifier);

    local reader = Reader.attachedReaders[readerIdentifier];
    if not reader then
        GMGenie.printErrorMessage("ReaderStateManager.reportError: Reader not found for identifier " .. readerIdentifier);

        return;
    end

    -- First reset, then trigger onSuccess, to prevent concurrency issues with chained reads.
    local retrievedData = reader.getFinalRetrievedData();
    Reader.reset(reader);

    reader.onSuccess(retrievedData);
end
