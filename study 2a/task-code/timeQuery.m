function [dist] = timeQuery(id,wid,origin)
% queries the participant about the time-interval distribution they just
% experienced, and saves the data. 
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
        otherwise, error('timeQuery requires 0 or 3 input args');
    end
    
    % set path
    addpath('stimSubFx');
    addpath('stimSubFx_timeQuery');

    % basic display parameters
    display.bkgd = 100; % set shade of gray for screen background
    display.hatch = false;
    
    % get subject ID and open screen if in standalone mode
    cbal = nan; % cbal is inapplicable to this task
    nCells = nan;
    if standalone
        [dataFileName,dataHeader] = gatherSubInfo('timeQuery',nCells,[],cbal);
        [wid,origin,dataHeader] = manageExpt('open',dataHeader,display.bkgd); % standard initial tasks
    else
        [dataFileName,dataHeader] = gatherSubInfo('timeQuery',nCells,id,cbal);
        dataHeader.sessionTime = fix(clock);
    end
    
    % stimulus screen locations
    rects = setRects(origin,wid);
    
    % define the mapping between plot values and screen pixels
    % this assumes the full timeBar spans 32s, and plot max is 30s
    % note: yMax, the highest y coord, is the bottom of the plot
    display.xMin = rects.timeBar(1);
    display.xLength = (rects.timeBar(3) - rects.timeBar(1))*30/32;
    display.yMax = rects.timeBar(2) - 20; % a little above the top of the time bar
    display.yLength = display.xLength*3/4; % keep a constant aspect ratio
    display.tLength = 30;
    
    % initialize the survival function (col1 = x, col2 = S(x))
    dist = [0, 1; 30, 0];
    
    % preliminary instruction screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg{1} = 'We are interested in your memory of how long tokens took to mature in the second task block you performed.';
    msg{2} = 'Imagine you got 100 new tokens and waited for every one of them to mature.';
    msg{3} = 'The next screen asks you to judge how many tokens would take various lengths of time.';
    msg = sprintf('%s\n\n%s\n\n%s',msg{1},msg{2},msg{3});
    showMsg(wid,display.bkgd,msg,'q');
    
    % loop over specific values to query
    ShowCursor;
    for t = 2:2:28
        % skip if S(t) was set to zero at an earlier t
        if any(dist(:,1)<t & dist(:,2)==0), continue; end
        % otherwise present this query
        display.trialTimeBar = ceil(rects.timeBarMax*t/32);
        dist = querySurvFx(dist,wid,rects,display,t);
    end
    
    % preserve a version of the distribution at this point
    dist_preliminary = dist;
    
    % free interactive display
    dist = querySurvFx(dist,wid,rects,display);

    % save out the data
    outputs.dataHeader = dataHeader;
    outputs.dist_preliminary = dist_preliminary;
    outputs.dist = dist; %#ok<STRNU>
    save(dataFileName,'-struct','outputs');
    
    % final screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg = 'Time judgment task complete.';
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

