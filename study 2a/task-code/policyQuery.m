function [t] = policyQuery(id,wid,origin)
% queries the participant for their explicit belief about the 
% reward-maximizing giving-up time
%
% Inputs are optional (id = subject, wid = ptb screen, origin = center).
%   They'll be provided if this fx is called from within wtwTask.m, with a
%       screen already open.
%   If no inputs are given, this fx runs in stand-alone mode, opening (and
%       closing) its own ptb window and prompting for subject ID. 

try

    % evaluate input arguments
    switch nargin
        case 0, standalone = true;
        case 3, standalone = false;
        otherwise, error('policyQuery requires 0 or 3 input args');
    end
    
    % set path
    addpath('stimSubFx');

    % basic display parameters
    display.bkgd = 100; % set shade of gray for screen background
    display.hatch = false;
    
    % get subject ID and open screen if in standalone mode
    cbal = nan; % cbal is inapplicable to this task
    nCells = nan;
    if standalone
        [dataFileName,dataHeader] = gatherSubInfo('policyQuery',nCells,[],cbal);
        [wid,origin,dataHeader] = manageExpt('open',dataHeader,display.bkgd); % standard initial tasks
    else
        [dataFileName,dataHeader] = gatherSubInfo('policyQuery',nCells,id,cbal);
        dataHeader.sessionTime = fix(clock);
    end
    
    % stimulus screen locations
    rects = setRects(origin,wid);
    
    % fill the progress bar the same amount as in the instructions
    display.trialTimeBar = ceil(rects.timeBarMax*1/3); % show 1/3 of the time elapsed
    
    % the participant will place a line on the progress bar to mark their
    % giving-up time. 
    % define the mapping between time values and screen pixels
    % this assumes the full timeBar spans 32s, and plot max is 30s
    display.xMin = rects.timeBar(1);
    display.xLength = (rects.timeBar(3) - rects.timeBar(1))*30/32;
    display.tLength = 30;
    % vertical endpoints of the line
    display.yMin = rects.timeBar(2) - 20; % a little above the top of the time bar
    display.yMax = rects.timeBar(4) + 20; % a little below the bottom of the bar
    
    % preliminary instruction screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg{1} = 'We are interested in your opinion about the best way to make money in the second block of this task.';
    msg{2} = 'The next screen will show you the progress bar that marked each token''s elapsed time.';
    msg{3} = 'Please mark what you think is the ideal maximum waiting time. That is, when should you give up on a token that has not yet matured?';
    msg = sprintf('%s\n\n%s\n\n%s',msg{1},msg{2},msg{3});
    showMsg(wid,display.bkgd,msg,'q');
    
    % free interactive display
    % try to control cursor shape
    ShowCursor('Arrow');

    % accept clicks a little outside the axes
    clickMargin = 30;

    % define axis labeling
    display.xTickValues = 0:10:30;
    display.xTickX = display.xMin + display.xLength.*display.xTickValues./display.tLength;
    display.xTickYTop = ones(size(display.xTickValues)).*rects.timeBar(4)+20;
    display.xTickRects = [display.xTickX-1; display.xTickYTop; display.xTickX+1; display.xTickYTop+5];
    
    % initialize display
    done = false;
    changeDisp = true;
    mouseDown = false;
    t = nan; 
    onsetSecs = GetSecs; % log onset time (will wait at least 1s before exiting)
    
    while ~done

        % check for a keypress
        if detectResponse('space') && (GetSecs - onsetSecs)>1 && ~isnan(t)
            done = true;
        end

        % check mouse
        [x, y, buttons] = GetMouse;
        if mouseDown && ~any(buttons) % mouse has been released
            mouseDown = false;
        elseif ~mouseDown && any(buttons) && x>=(display.xMin - clickMargin) && ...
                x<=(display.xMin + display.xLength + clickMargin) && y<=(display.yMax + clickMargin) && ...
                y>=(display.yMin - clickMargin) % mouse has been newly clicked in or near the axes

            mouseDown = true;
            changeDisp = true;

            % convert screen position to axis position
            t = display.tLength * (x - display.xMin)/display.xLength;
            t = max(t,0); % enforce bounds
            t = min(t,display.tLength); % enforce bounds

        end

        % display any updates to the display on this cycle
        if changeDisp
            changeDisp = false;
            refreshDisplay_policyQuery(t,wid,rects,display);
        end

        WaitSecs(.001);

    end
    
    
    
    % save out the data
    outputs.dataHeader = dataHeader;
    outputs.explicit_gut = t;
    save(dataFileName,'-struct','outputs');
    
    % final screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg = 'Response recorded.';
    showMsg(wid,display.bkgd,msg,'q');
    
    % close screen if in standalone mode
    if standalone
        manageExpt('close'); 
    end
    
    % print data file information
    fprintf('\n\nTime query data file: %s\n',dataFileName);
    
catch ME
    
    % close the expt
    disp(getReport(ME));
    fclose('all');
    manageExpt('close');
    
end % try/catch loop

end % main function









%%% subfunction to refresh the display
function [] = refreshDisplay_policyQuery(t,wid,rects,display)
% draws the policyQuery interface

% clear the screen
Screen('FillRect',wid,display.bkgd);

% place the progress bar on the screen
display.trialTimeBar = ceil(rects.timeBarMax*t/32);
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

% mark the selected giving-up time, if any
if ~isnan(t)
    xPos = (t/display.tLength) * display.xLength + display.xMin;
    Screen('DrawLine',wid,[255,50,50],xPos,display.yMin,xPos,display.yMax,3);
end

% title text
txtY = display.yMin*0.4;
txtStr = 'Click the progress bar to mark when you should give up on a token that has not yet matured.';
if ~isnan(t)
    txtStr = sprintf('%s\n\nCurrent response: %d seconds',txtStr,round(t));
end
txtStr2 = 'Press the spacebar when finished.';
Screen('TextSize',wid,42);
DrawFormattedText(wid,txtStr,'center',txtY,255,60,[],[],1.25);

% instructions for moving on
txtY = display.xTickYTop(1) + 100;
DrawFormattedText(wid,txtStr2,'center',txtY,255,[],[],[],1.25);

% show the screen
Screen('Flip',wid);

end % subfunction refreshDisplay_policyQuery








