function [] = wtwTaskImp()
% presents the WTW experiment
%   -look-and-feel is similar to the MR study (maturing tokens)

try
    
    % skipping sync tests
    Screen('Preference', 'SkipSyncTests', 1);
    
    %%% modifiable parameters
    % timing
    sessMins = 15; % block duration in minutes (normally 15)
    display.iti = 1; % intertrial interval in s
    timeBarMaxTime = 32; % length of within-trial time meter
    % payoff contingencies
    params.payoffHi = 10; % cents
    params.payoffLo = 0; % cents
    % special parameters for the "study" block of wtw_implicit
    bkResponseDeadline = [1, 1]; % RT deadline in s
        % one element per block
        % nan means no deadline
    bkProhibitQuitting = [10, nan]; % penalty for anticipatory responses
        % one element per block
        % nan means quitting is permitted as normal
        
    % response key (only one required)
    params.respChar = {'space'};
    % token colors
    % this order is also fixed. If order of timing conditions is switched,
    % order of colors should be left the same. 
    blockTokenColor = {'green', 'green'};
    
    %%% special display prefs if on windows OS
    if IsWin
        % modify text display settings
        % set font to helvetica (default is courier new)
        Screen('Preference', 'DefaultFontName', 'Helvetica');
        % set style to normal (=0) (default is bold [=1])
        Screen('Preference', 'DefaultFontStyle', 0);
    end
    
    % set path
    addpath('stimSubFx');
    % path(path,'delayDistributions');
    
    % name datafile
    nCells = 4; % number of counterbalance conditions
    [dataFileName,dataHeader] = gatherSubInfo('wtw_discrete_implicit',nCells);
    dataHeader.sessionDurationInMin = sessMins;
    params.datafid = fopen([dataFileName,'.txt'],'w');
    params.pracfid = fopen([dataFileName,'_prac.txt'],'w');
    
    % set parameters based on the counterbalance condition
    switch dataHeader.cbal
        case 1
            timingDistribs = {'scale_1_20', 'scale_1_20'};
            display.hatch = false; 
        case 2
            timingDistribs = {'scale_1_20', 'scale_1.5_30'};
            display.hatch = false;
        case 3
            timingDistribs = {'scale_1.5_30', 'scale_1_20'};
            display.hatch = false;
        case 4
            timingDistribs = {'scale_1.5_30','scale_1.5_30'};
            display.hatch = false;
    end

    % open the screen
    bkgd = 100; % set shade of gray for screen background
    [wid,origin,dataHeader] = manageExpt('open',dataHeader,bkgd); % standard initial tasks
    
    % set screen locations for stimuli and buttons
    rects = setRects(origin,wid);
    
    % initialize display
    HideCursor;
    params.wid = wid;
    params.bkgd = bkgd;
    display.totalWon = 0; % initial value
    params.sessSecs = sessMins * 60;
    display.timeBarMaxTime = timeBarMaxTime; % the amount of time, in s, represented by the full time bar
    
    % colors to be used
    % tokColors.prac = [0, 0, 0];
    tokColors.green = 50+[0, 100, 0];
    tokColors.purple = 50+[80, 0, 100];
    tokColors.red = 50+[100, 0, 0];
    
    % initialize data logging structures
    dataHeader.distribs = timingDistribs; % log the sequence of distributions
    trialData = struct([]);
    params.datarow = 0;
    
    % instructions and practice - parameters match the first block
    nBks = length(timingDistribs); % number of blocks to present
    display.tokenColor = tokColors.(blockTokenColor{1}); % token matches 1st block
    params.responseDeadline = bkResponseDeadline(1); % matches first block
    params.prohibitQuitting = bkProhibitQuitting(1); % matches first block
    % set crosshatching rects for first block if needed
    if display.hatch
        rects = setRects_crosshatch(rects,params.distrib,display);
    end
    
    % show the instructions
    instrucBlockTraining(params,rects,display,sessMins,nBks);
    
    % present individual blocks
    for bkIdx = 1:nBks
    
        % set block-specific parameters
        params.bkIdx = bkIdx;
        params.distrib = timingDistribs{bkIdx};
        display.tokenColor = tokColors.(blockTokenColor{bkIdx});
        params.responseDeadline = bkResponseDeadline(bkIdx);
        params.prohibitQuitting = bkProhibitQuitting(bkIdx);
        
        % set rects for progress bar crosshatching if needed
        if display.hatch
            rects = setRects_crosshatch(rects,params.distrib,display);
        end
        
        % show the trials
        params.trialLimit = inf;
        [trialData, params, display] = showTrials(params,rects,display,trialData);
        
        % save data
        save(dataFileName,'dataHeader','trialData');
        
        % intermediate instructions screen
        % (shown after the non-final block[s])
        if bkIdx<nBks
            
            Screen('TextSize',wid,rects.txtsize_msg);
            msg = sprintf('Block %d complete.\nPlease notify the experimenter that you have reached this point.',...
                bkIdx);
            showMsg(wid,bkgd,msg,'q');
            
            % present new instructions
            % set parameters to match upcoming block
            display.tokenColor = tokColors.(blockTokenColor{bkIdx+1});
            params.responseDeadline = bkResponseDeadline(bkIdx+1); 
            params.prohibitQuitting = bkProhibitQuitting(bkIdx+1);
            instrucBlock(params,rects,display,sessMins,nBks);
            
%             Screen('TextSize',wid,rects.txtsize_msg);
%             msg = sprintf('Block %d complete.\nNow the timing of the task will change.\n\nGet ready to begin block %d.',...
%                 bkIdx,bkIdx+1);
%             showMsg(wid,bkgd,msg,'q');
        end
        
    end % loop over blocks
    
    % initial completion screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg = sprintf('Block %d complete.\nTotal earned: $%2.2f.',...
        nBks,display.totalWon/100);
    msg = sprintf('%s\n\nPlease let the experimenter know you have reached this point.',msg);
    showMsg(wid,bkgd,msg,'q');
    
    %%% policy query task
    explicit_gut = policyQuery(dataHeader.id,wid,origin);
    dataHeader.explicit_gut = explicit_gut; % include results in main data header
    save(dataFileName,'dataHeader','trialData'); % save data
    
    %%% time query task
    explicit_dist = timeQuery(dataHeader.id,wid,origin);
    dataHeader.explicit_dist = explicit_dist; % include results in main data header
    save(dataFileName,'dataHeader','trialData'); % save data
    
    % show the final screen
    Screen('TextSize',wid,rects.txtsize_msg);
    msg = sprintf('Complete!\nTotal earned: $%2.2f.',...
        display.totalWon/100);
    showMsg(wid,bkgd,msg,'q');
    
    % close the expt
    manageExpt('close'); % note: this closes any text files open for writing
    
    % print some information
    fprintf('\n\nParticipant: %s\n',dataHeader.dfname);
    fprintf('Winnings: $%2.2f\n\n',display.totalWon/100);
    
catch ME
    
    % close the expt
    disp(getReport(ME));
    fclose('all');
    manageExpt('close');
    
end % try/catch loop

    

    


