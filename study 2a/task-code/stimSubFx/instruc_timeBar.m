function [] = instruc_timeBar(wid,bkgd,rects,display)
% presents an instruction screen that describes the progress bar tracking
% time within a trial. 
%
% also describes the explicitly available timing information, if the
% subject is in a condition that provides such information. 

% this function is partly based on showMsg.m

Screen('FillRect',wid,bkgd);
breakKey = 'q';

% add the time bar to the screen
display.trialTimeBar = ceil(rects.timeBarMax*1/3); % show 1/3 of the time elapsed
refreshDisplay_timeBar(wid,bkgd,rects,display);

% add text
msg = 'The progress bar shows you how long the current token has been on the screen. ';
ypos = rects.origin(2)*3/4; % 3/8 of the way down the screen
DrawFormattedText(wid,msg,'center',ypos,255,50,[],[],1.5);

% extra instructions to explain the hatchmarks
% if display.hatch 
% %     msg = ['The bar is crosshatched to mark the points when the token can mature. ',...
% %         'The token is equally likely to mature at any of the marked times.'];
%     msg = ['The bar is crosshatched to mark the possible reward times. ',...
%         'For each token, one of the marked times is selected at random, with equal probability, as the time when the token will mature.'];
%     ypos = rects.origin(2)*5/4; % 5/8 of the way down the screen
%     DrawFormattedText(wid,msg,'center',ypos,255,50,[],[],1.5);
% end

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






