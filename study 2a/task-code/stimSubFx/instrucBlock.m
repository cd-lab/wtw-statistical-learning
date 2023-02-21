% Instructions block for phase 2 of the wtwTaskImp() task

function [] = instrucBlock(params,rects,display,blockMins,nBks)
% presents instructions screens for qTask

% unpack some parameters
wid = params.wid;
bkgd = params.bkgd;
display_orig = display; % save the unmodified display struct
display.hatch = false;

% set the key(s) that the experimenter will press to advance instrucs
respKey = 'q';

% set params for practice trials
params.trialLimit = 1; % always do just one trial at a time
trialData = struct([]);
params.datarow = 0;
params.datafid = params.pracfid;
params.bkIdx = 0;
params.distrib = 'fixed10';

% instruc screen 
Screen('TextSize',wid,rects.txtsize_msg);
if params.payoffLo==1, lowValPlural = ''; else lowValPlural = 's'; end % format messages flexibly
msg = {};
msg{1} = sprintf('In the next block, the task is similar to the previous one, except now you can sell the token before it matures. You will receive %d cent%s and move on to a new token.',...
    params.payoffLo, lowValPlural);
msg{2} = 'You might want to do this if a token is taking too long, since you have a limited total amount of time to play.';
msg{3} = 'In the following practice trial, try selling the token before it matures.';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

% demo trial 3 -- practice quitting
params.distrib = 'fixed60';
[~,~,display] = showTrials(params,rects,display,trialData);

% instruc screen 4
Screen('TextSize',wid,rects.txtsize_msg);
msg = {};
msg{1} = 'OK, let''s do it again. Practice selling the token before it matures.';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

% demo trial 4 -- practice quitting
[~,~,display] = showTrials(params,rects,display,trialData);

% description of the progress bar
% instruc_timeBar(wid,bkgd,rects,display_orig);

% final instruc screen
Screen('TextSize',wid,rects.txtsize_msg);
msg = {};
msg{1} = sprintf('You will have %d minutes to play, and you can get as many new tokens as time permits.',blockMins);
msg{2} = 'Your goal is to earn as much money as you can in the available time. At the end of the experiment you will be paid the total amount you have earned.';
msg{3} = 'Any questions?';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

