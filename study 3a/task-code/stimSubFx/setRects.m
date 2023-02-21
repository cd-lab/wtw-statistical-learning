function [rects] = setRects(origin,wid)
% sets stimulus positions

% basic x/y/x/y
rects.origin = origin;
pointRect = [origin, origin];

% set various font sizes, relative to screen height
% (this helps accommodate different display resolutions)
scrHeight = origin(2)*2;
rects.txtsize_msg = round(0.05*scrHeight);
rects.txtsize_token = round(0.07*scrHeight);
rects.txtsize_sold = round(0.12*scrHeight);

% position of the token
tokenDiam = 0.22*scrHeight;
tokenCorner = origin - [0.5*tokenDiam, 1*tokenDiam]; % centered above screen center
rects.token = [tokenCorner, tokenCorner + tokenDiam];
rects.tokenBorder = rects.token + [-2, -2, 2, 2];

% position of the "SOLD" message
Screen('TextSize',wid,rects.txtsize_sold);
boundRect = Screen('TextBounds',wid,'SOLD');
tokVCen = mean([rects.token(2),rects.token(4)]);
rects.soldY = tokVCen - 0.5*boundRect(4);

% position of time-elapsed scale
rects.timeBarMax = 400; % largest amt to be added to 3rd element of timeBar
rects.timeBar = pointRect + [-200, 40, rects.timeBarMax-200, 60];
rects.timeBarBorder = rects.timeBar + [-2, -2, 2, 2];


% vertical position of fixation cross
% rects.fixVertPos = mean([rects.token(4), rects.timeBar(2)])-12; % halfway between

% position of the button
% rects.button = pointRect + [-170, 25, 170, 75]; % just below screen center
% rects.buttonBorder = rects.button + [-3, -3, 3, 3];
% rects.buttonMsgY = origin(2)+38;

% position of point-total message
% (note: these 2 messages are not explicitly centered during each draw 
% because we do not want their position to change when the specific time 
% or point value changes.)
Screen('TextSize',wid,rects.txtsize_msg);
rects.earningsStr = 'Earned:  $%1.2f'; % format string for text to be displayed
sampleTxt = sprintf(rects.earningsStr,0);
boundRect = Screen('TextBounds',wid,sampleTxt);
rects.earningsMsgXY = origin + [-0.5*boundRect(3), 0.2*scrHeight];

% position of digital total-time-left display
Screen('TextSize',wid,rects.txtsize_msg);
rects.timeStr = 'Time left:  %02d:%02d';
sampleTxt = sprintf(rects.timeStr,0,0);
boundRect = Screen('TextBounds',wid,sampleTxt);
rects.timeMsgXY = origin + [-0.5*boundRect(3), 0.3*scrHeight];









