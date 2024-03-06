GMGenie.Functions = {
    isFirstCharacterPipe = function(message)
        local firstCharacter = string.sub(message, 1, 1);
        return firstCharacter == '|';
    end
};
