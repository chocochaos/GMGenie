local ChatMessagePublisher = {
    --- @type table<string, ChatMessageSubscriber[]>
    subscribersByKey = {},
}

GMGenie.ChatMessagePublisher = ChatMessagePublisher;

--- Subscribe to chat messages, to read command responses and act on them.
--- @param subscriptionKey string Several subscribers can share a key. If one unsubscribes, all are unsubscribed.
--- @param subscriber ChatMessageSubscriber
function ChatMessagePublisher.subscribe(subscriptionKey, subscriber)
    GMGenie.printDebugMessage("Subscribed: " .. subscriptionKey);
    table.insert(ChatMessagePublisher.subscribersByKey[subscriptionKey], subscriber);
end

--- Unsubscribe from chat messages, when all required information has been gathered.
--- @param subscriptionKey string
function ChatMessagePublisher.unsubscribe(subscriptionKey)
    GMGenie.printDebugMessage("Unsubscribed: " .. subscriptionKey);
    ChatMessagePublisher.subscribersByKey[subscriptionKey] = {};
end

--- @param message string
--- @return ChatMessageSubscriberResponse
--- @internal
function ChatMessagePublisher.publishSystemMessage(message)
    for subscriptionKey, subscribers in pairs(ChatMessagePublisher.subscribersByKey) do
        for _, subscriber in ipairs(subscribers) do
            local response;
            if subscriber.onSystemMessage then
                response = subscriber.onSystemMessage(message);
            end

            if response.stopPropagation then
                return {stopPropagation = true};
            end
        end
    end

    return {stopPropagation = false};
end
