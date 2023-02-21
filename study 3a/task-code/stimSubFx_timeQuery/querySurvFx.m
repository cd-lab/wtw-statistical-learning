function [dist] = querySurvFx(dist,wid,rects,display,fixed_t)
% presents an interactive interface to elicit the survival function for a 
% time-interval distribution. 
%
% Inputs:
%   dist: current estimate of the survival function: col1 = x, col2 = S(x)
%   wid: ptb window identifier
%   rects: stimulus screen locations
%   xval (OPTIONAL): if provided, constrains the interface to collect the
%       value of S(x) at a single x value. 
%
% Notation: x and y refer to screen positions; t and S refer to the
% corresponding coordinates on the distribution plot. 


% check whether a fixed t-value is specified
fixT = false;
display.fixed_x = [];
if nargin>4
    fixT = true;
    fixed_x = (fixed_t/display.tLength) * display.xLength + display.xMin;
    fixed_x = round(fixed_x); % nearest pixel
    display.fixed_x = fixed_x;
end

% try to control cursor shape
ShowCursor('Arrow');

% accept clicks a little outside the axes
clickMargin = 30;

% resolution of the grid (bin size in s)
gridBin = 2;

% define axis labeling
display.xTickValues = 0:10:30;
display.xTickX = display.xMin + display.xLength.*display.xTickValues./display.tLength;
display.xTickYTop = ones(size(display.xTickValues)).*rects.timeBar(4)+20;
display.xTickRects = [display.xTickX-1; display.xTickYTop; display.xTickX+1; display.xTickYTop+5];

display.yTickValues = 0:25:100;
display.yTickY = display.yMax - display.yLength.*display.yTickValues./100;
display.yTickXLeft = ones(size(display.yTickValues)).*(display.xMin - 20);
display.yTickRects = [display.yTickXLeft; display.yTickY-1; display.yTickXLeft+5; display.yTickY+1];

% log onset time (will wait at least 1s before exiting)
onsetSecs = GetSecs;

done = false;
changeDisp = false;
mouseDown = false;
refreshDisplay_timeQuery(dist,wid,rects,display);

while ~done
    
    % check for a keypress
    if detectResponse('space') && (GetSecs - onsetSecs)>1
        done = true;
    end
    
    % check mouse
    [x, y, buttons] = GetMouse;
    
    % use the specified x position, if any
    if fixT
        x = fixed_x;
        % considered also constraining the cursor to one position on the x
        % axis, but didn't do it (the below doesn't work correctly). 
        % SetMouse(fixed_x,round(y));
    end
    
    % check mouseclick
    if mouseDown && ~any(buttons) % mouse has been released
        mouseDown = false;
    elseif ~mouseDown && any(buttons) && x>=(display.xMin - clickMargin) && ...
            x<=(display.xMin + display.xLength + clickMargin) && y<=(display.yMax + clickMargin) && ...
            y>=(display.yMax - display.yLength - clickMargin) % mouse has been newly clicked in or near the axes
        
        mouseDown = true;
        changeDisp = true;
        
        % convert screen position to axis position
        t = display.tLength * (x - display.xMin)/display.xLength;
        t = max(t,0); % enforce bounds
        t = min(t,display.tLength); % enforce bounds
        t = gridBin*floor(t/gridBin); % snap to grid
        S = (display.yMax - y)/display.yLength; % scaled from 0 to 1
        S = max(S,0); % enforce bounds
        S = min(S,1); % enforce bounds
        S = round(S*100)/100; % round to 2 decimal places
        
        % during 'fixed T' phase:
        % do not allow S to exceed the S(t) for earlier values of t.
        if fixT
            prev_t = dist(:,1)<t;
            prevMinS = min(dist(prev_t,2));
            S = min(S,prevMinS);
        end
        
        % update the distribution
        newPoint = [t, S];
        % remove the previous value at this t, if any
        dup = dist(:,1)==t;
        dist(dup,:) = [];
        % set S(t) for later times so they don't exceed the current S(t)
        later_higher = dist(:,1)>=t & dist(:,2)>=S; % higher S at a later t
        dist(later_higher,2) = S;
        % set S(t) for earlier times to be at least as high as current S(t)
        earlier_lower = dist(:,1)<t & dist(:,2)<S;
        dist(earlier_lower,2) = S;
        % append the new response and sort by t
        dist = [dist; newPoint]; %#ok<AGROW>
        dist = sortrows(dist,1);
        
    end
    
    % display any updates to the display on this cycle
    if changeDisp
        changeDisp = false;
        refreshDisplay_timeQuery(dist,wid,rects,display);
    end
    
    WaitSecs(.001);
    
end

end % main function 


%%% subfunction to refresh the display
function [] = refreshDisplay_timeQuery(dist,wid,rects,display)
% draws the timeQuery interface

% clear the screen
Screen('FillRect',wid,display.bkgd);

% draw the survival distribution
plotRects = nan(4,size(dist,1)-1);
for i = 1:(size(dist,1)-1)
    % define each rectangle in the stair plot
    plotRects(1,i) = (dist(i,1)/display.tLength) * display.xLength + display.xMin; % left
    plotRects(2,i) = display.yMax - dist(i,2) * display.yLength; % top
    plotRects(3,i) = (dist(i+1,1)/display.tLength) * display.xLength + display.xMin; % right
    plotRects(4,i) = display.yMax; % bottom
end
Screen('FillRect',wid,200,plotRects);

% mark the fixed-x time if any
if ~isempty(display.fixed_x)
    yHi = display.yMax + 10;
    yLo = display.yMax - display.yLength - 10;
    Screen('DrawLine',wid,255,display.fixed_x,yHi,display.fixed_x,yLo,3);
end

% place the progress bar on the screen
refreshDisplay_timeBar(wid,display.bkgd,rects,display)

% label the x axis
Screen('FillRect',wid,255,display.xTickRects);
Screen('TextSize',wid,18);
for i = 1:length(display.xTickValues)
    Screen('DrawText',wid,sprintf('%d',display.xTickValues(i)),...
        display.xTickX(i)-6,display.xTickRects(4,i)+5,255);    
end
Screen('TextSize',wid,24);
DrawFormattedText(wid,'Time (seconds)','center',display.xTickRects(4,i)+32,255);

% label the y axis
Screen('FillRect',wid,255,display.yTickRects);
Screen('TextSize',wid,18);
for i = 1:length(display.yTickValues)
    Screen('DrawText',wid,sprintf('% 4d',display.yTickValues(i)),...
        display.yTickRects(1,i)-40,display.yTickY(i)-10);
end
Screen('TextSize',wid,24);
DrawFormattedText(wid,sprintf('Number of tokens\nthat take longer'),...
    display.yTickRects(1,1)-250,mean(display.yTickY)-20,255);

% title text
txtY = (display.yMax - display.yLength)*0.4;
if ~isempty(display.fixed_x)
    fixed_t = round(display.tLength * (display.fixed_x - display.xMin)/display.xLength);
    txtStr = sprintf('Out of 100 tokens, how many would take longer than %d seconds?',fixed_t);
    % also state the subject's current response if any
    thisIdx = round(dist(:,1))==fixed_t;
    if any(thisIdx)
        % there should only be one response for the current time
        assert(sum(thisIdx)==1,'Multiple rows of dist match fixed_t.');
        txtStr = sprintf('%s\nYour current response: %d',txtStr,round(dist(thisIdx,2)*100));
    end
    txtStr2 = sprintf('Click to adjust the graph.\nPress the spacebar to enter your response.');
else
    txtStr = sprintf('Now you can adjust the graph freely.\nOut of 100 tokens, how many would exceed each time value?');
    txtStr2 = 'Press the spacebar when finished.';
end
Screen('TextSize',wid,36);
DrawFormattedText(wid,txtStr,'center',txtY,255,[],[],[],1.25);

% instructions for moving on
txtY = display.xTickYTop(1) + 100;
DrawFormattedText(wid,txtStr2,'center',txtY,255,[],[],[],1.25);

% show the screen
Screen('Flip',wid);

end % subfunction refreshDisplay_timeQuery








