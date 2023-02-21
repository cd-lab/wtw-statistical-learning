function [] = showMsg(wid,bkgd,msg,breakKey)
% show text centered on the screen
% if breakKey is provided, wait till that key is pressed
% otherwise wait till any key is pressed

Screen('FillRect',wid,bkgd);
DrawFormattedText(wid,msg,'center','center',255,50,[],[],1.5);
Screen('Flip',wid);

WaitSecs(1); % minimum delay

resp = false;
while ~resp
    
    % check the keyboard
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown
        if nargin<4, resp = true;
        else
            k = KbName(keyCode);
            if iscell(k), k = k{1}; end
            if any(ismember(breakKey,k)), resp = true; end
        end
    end
    
    % check the mouse (as long as no specific key is required)
    [x,y,buttons] = GetMouse;
    if nargin<4 && any(buttons)
        resp = true;
    end
    
    WaitSecs(.001);
    
end
            
            