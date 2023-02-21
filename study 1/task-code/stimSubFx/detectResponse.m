function [resp, secs] = detectResponse(respChar)
% output: 'resp' is a logical indicating whether keyboard input matches
% the allowed response characters. 
% input: respChar is a cell array of strings with allowable characters

resp = false; % default output
[keyIsDown, secs, keyCode] = KbCheck(-1);
if ~keyIsDown, return; end % no keys depressed

% if respChar is empty, any keypress is allowable
if isempty(respChar), resp = true; return; end

% if keys were pressed, verify which keys
keyName = KbName(keyCode);
resp = any(ismember(keyName,respChar));
% one key pressed:
% if keyName is a string, resp will be true if the string exactly
% matches any string in the respChar cell array.
% multiple keys pressed:
% if keyname is a cell array, resp will be true if any string in
% keyName exactly matches a string in respChar

end
    
