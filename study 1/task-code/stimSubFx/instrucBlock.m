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

% instruc screen 1
Screen('TextSize',wid,rects.txtsize_msg);
if params.payoffLo==1, lowValPlural = ''; else lowValPlural = 's'; end % format messages flexibly
msg = {};
msg{1} = 'You will see a token on the screen. Tokens can be sold for money.';
msg{2} = sprintf('Each token is worth %d cent%s at first. After some time, it "matures" and is worth %d cents.',...
    params.payoffLo,lowValPlural,params.payoffHi);
msg{3} = 'Now try a practice round. Wait for the token to mature, then press the spacebar to sell it.';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

% demo trial 1 -- practice waiting
[~,~,display] = showTrials(params,rects,display,trialData);

% instruc screen 2
Screen('TextSize',wid,rects.txtsize_msg);
msg = {};
msg{1} = 'OK, let''s do it again. Wait for the token to mature, then sell it.';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

% demo trial 2 -- practice waiting
[~,~,display] = showTrials(params,rects,display,trialData);

% instruc screen 3
Screen('TextSize',wid,rects.txtsize_msg);
msg = {};
msg{1} = 'You will have a limited amount of time to play.';
msg{2} = 'If a token is taking too long, you might want to sell it before it matures in order to move on to a new one.';
msg{3} = 'Next, practice selling the token before it matures.';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);

% demo trial 3 -- practice quitting
params.distrib = 'fixed10';
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
instruc_timeBar(wid,bkgd,rects,display_orig);

% final instruc screen
Screen('TextSize',wid,rects.txtsize_msg);
msg = {};
if nBks>1 % instrucs differ for 1 block or multiple blocks.
    txt1 = sprintf('You will play %d blocks, each lasting %d minutes.',nBks,blockMins);
else
    txt1 = sprintf('You will have %d minutes to play.',blockMins);
end
msg{1} = sprintf('%s Your goal is to earn as much money as you can in the available time. At the end of the experiment you will be paid what you earned.',txt1);
msg{2} = 'Any questions?';
txt = sprintf('%s\n\n',msg{:}); txt((end-1):end) = [];
showMsg(wid,bkgd,txt,respKey);






