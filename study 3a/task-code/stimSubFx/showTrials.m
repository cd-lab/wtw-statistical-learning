function [trialData, params, display] = showTrials(params,rects,display,trialData)
% subfunction to display 1 run of trials

% unpack parameters
wid = params.wid;
bkgd = params.bkgd;
sessSecs = params.sessSecs;
datarow = params.datarow;
trialLimit = params.trialLimit;
block = params.bkIdx;
datafid = params.datafid;

% initial display settings
display.timeLeft = sessSecs;
display.tokenValue = params.payoffLo;
display.tokenState = 'low';
display.soldMsg = false;
display.tokenPresent = false;
display.trialTimeBar = 0; % pixels in the progress bar

% show the initial screen
refreshDisplay(wid,bkgd,rects,display);
changeDisp = false; % register whether anything has changed on each loop
flipTimeIsRwdTime = false; % initialize

% show trials
% each trial consists of the following 3 phases:
%   feedback, iti, waiting
trialNum = 0;
seq = [];
trialPhase = 'iti';
phaseOnset = GetSecs;
runOnset = phaseOnset;
fbackOnset = phaseOnset; % used for monitoring keypresses during feedback/iti
keyDown = true; % keypress to start the block should not carry over and be called an ITI response
itiKeypressTimes = [];
while ((GetSecs-runOnset)<sessSecs) && (trialNum<=trialLimit) % proceed continuously until time is up

    % determine how far we are into the current trial phase
    timeNow = GetSecs; % timeNow is used below instead of multiple GetSecs calls
    eventLatency = timeNow-phaseOnset;

    % if the feedback or ITI phase is underway, check for keypresses
    % keypress times will be logged in order to identify a strategy of
    % constant/random keypressing.
    if ismember(trialPhase,{'feedback','iti'})
        if ~keyDown && detectResponse(params.respChar) % key was just pressed
            itiKeypressTimes = [itiKeypressTimes, timeNow-fbackOnset]; %#ok<AGROW>
            keyDown = true;
        elseif keyDown && ~detectResponse(params.respChar) % key was just released
            keyDown = false;
        end
    end
    
    % if the ITI is ending, begin a trial
    % change phase: "iti" -> "waiting"
    if strcmp(trialPhase,'iti') && eventLatency>(display.iti)/2
        trialPhase = 'waiting';
        eventLatency = 0; % for the purpose of the progress bar
        phaseOnset = timeNow;
        % waitDuration = delayList(1); % waiting time on this trial
        % delayList(1) = []; % (cycle forward in the list)
        [waitDuration,seq] = drawSample(params.distrib,seq); % waiting time on this trial
        trialNum = trialNum+1;
        if trialNum>trialLimit, continue; end % prevent final screen update if exiting
        initialTime = timeNow-runOnset; % exact time elapsed - for later logging
        display.tokenPresent = true;
        display.tokenValue = params.payoffLo;
        display.tokenState = 'low';
        rwdTime = nan; % initialize reward onset time
        changeDisp = true;

    elseif strcmp(trialPhase,'waiting')

        % if the token has matured, update it
        if eventLatency>waitDuration && strcmp(display.tokenState,'low')
            display.tokenValue = params.payoffHi;
            display.tokenState = 'high';
            changeDisp = true;
            flipTimeIsRwdTime = true; % next screen redraw is the reward onset time
        end

        % if "sell" has been selected, end the trial
        % change phase: "waiting" -> "feedback"
        % a line is added to the data record here
        if detectResponse(params.respChar)

            keyDown = true; % prevents this keypress from being counted as an ITI response
            trialPhase = 'feedback';
            phaseOnset = timeNow;
            fbackOnset = timeNow; % used for monitoring keypresses during feedback/iti
            earnings = display.tokenValue;
            sellTime = timeNow-runOnset;
            display.totalWon = display.totalWon + earnings;
            display.soldMsg = true;
            changeDisp = true;

            % save data to matlab structure
            datarow = datarow+1; % number for the new trial
            trialData(datarow).blockNum = block;
            trialData(datarow).trialNum = trialNum;
            trialData(datarow).initialTime = initialTime;
            trialData(datarow).itiKeypresses = itiKeypressTimes;
                % holds latencies (relative to the onset of feedback) of
                % any keypress responses during the feedback/iti period
                % preceding this trial. Usually this will be an empty 
                % matrix.
            trialData(datarow).designatedWait = waitDuration;
            trialData(datarow).rwdOnsetTime = rwdTime; % will sometimes be nan
            trialData(datarow).latency = eventLatency; % "sell" response time, relative to trial onset
            trialData(datarow).outcomeTime = sellTime; % "sell" time since start of block
            trialData(datarow).payoff = earnings; % current trial payoff
            trialData(datarow).totalEarned = display.totalWon;
            
            % write data in csv format
            % columns: 1=block, 2=trialnum, 3=trial start time, 
            % 4=any keypresses in preceding iti (logical), 5=wait required,
            % 6=reward time, 7=time waited, 8=sell time, 9=trial earnings
            % 10=total earnings
            fprintf(datafid,'%d,%d,%1.3f,%d,%1.3f,%1.3f,%1.3f,%1.3f,%d,%d\n',...
                block,trialNum,initialTime,any(itiKeypressTimes),...
                waitDuration,rwdTime,eventLatency,sellTime,earnings,...
                display.totalWon);
            
            % reinitialize record of ITI keypress times
            itiKeypressTimes = [];

        end

    % if the feedback interval is over, enter the ITI
    % change phase: "feedback" -> "iti"
    elseif strcmp(trialPhase,'feedback') && eventLatency>(display.iti)/2
        trialPhase = 'iti';
        phaseOnset = timeNow;
        display.tokenPresent = false;
        display.tokenValue = [];
        display.tokenState = 'low';
        display.soldMsg = false;
        changeDisp = true;
    end

    % update the trial-specific elapsed time
    if strcmp(trialPhase,'waiting')
        trialTimeElapsed = eventLatency;
    else
        trialTimeElapsed = 0;
    end
    trialTimeBar = ceil(rects.timeBarMax*trialTimeElapsed/display.timeBarMaxTime);
    trialTimeBar = min(trialTimeBar,rects.timeBarMax); % don't fill past the end of the progress bar
    if display.trialTimeBar~=trialTimeBar
        display.trialTimeBar = trialTimeBar;
        changeDisp = true;
    end

    % digital display of time remaining
    timeLeft = ceil((runOnset+sessSecs)-timeNow);
    if display.timeLeft~=timeLeft
        display.timeLeft = timeLeft;
        changeDisp = true;
    end

    % display any updates to the display on this cycle
    if changeDisp
        changeDisp = false;
        flipTime = refreshDisplay(wid,bkgd,rects,display);
        if flipTimeIsRwdTime
            rwdTime = flipTime - phaseOnset;
            flipTimeIsRwdTime = false;
        end
    end

    WaitSecs(.001);

end

params.datarow = datarow;
    


