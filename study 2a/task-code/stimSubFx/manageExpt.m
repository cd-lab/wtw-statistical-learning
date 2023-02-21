function [wid,origin,dataHeader] = manageExpt(task,varargin)
% for opening and closing ptb experiments
% Inputs:
%   task is the string 'open' or 'close'
%   varargin may contain (1) header data, and (2) screen background color

% variable inputs
if ~isempty(varargin)
    dataHeader = varargin{1};
end
if length(varargin)>1
    bkgd = varargin{2};
else
    bkgd = 75; % standard gray
end
        
switch task
    case 'open'
        
        % seed random numbers
        randSeed = sum(100*clock);
        RandStream.setGlobalStream(RandStream('mt19937ar','Seed',randSeed)); %reset the random number generator
        
        % initial data entries
        dataHeader.randSeed = randSeed;
        dataHeader.sessionTime = fix(clock);
        
        % priority settings, etc
        ShowCursor(0);
        ListenChar(2);
        if IsOSX, Priority(7); else Priority(1); end
        
        % which monitor to use?  1 for secondary, 0 for primary
        mon = 0; 
        
        % open primary sreen
        [wid,wRect] = Screen('OpenWindow',mon,bkgd,[],[],[],[],[],kPsychNeedFastBackingStore);
        % [wid,wRect] = Screen('OpenWindow',mon,bkgd);
        
        % get center coordinates
        xcen = floor(wRect(3)/2);
        ycen = floor(wRect(4)/2);
        origin = [xcen,ycen];
        
        % standard screen parameters
        Screen(wid,'TextSize',24);
        Screen('TextFont',wid,'Helvetica');
        
    case 'close'
        
        % close out the experiment
        Screen('CloseAll'); % close screen
        ShowCursor; % display mouse cursor again
        ListenChar(0); % allow keystrokes to Matlab
        Priority(0); % return Matlab's priority level to normal
        fclose('all'); % close any text files open for writing
        
        % deal w/ output args
        dataHeader = NaN;
        origin = NaN;
        
    otherwise
        error('Invalid argument to manageExpt.m');
end