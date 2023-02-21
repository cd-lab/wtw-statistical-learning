function [] = refreshDisplay_timeBar(wid,bkgd,rects,display)
% draw the progress bar marking elapsed time within a trial.
% this function is called by refreshDisplay.m. 
% (this is encapsulated by itself so that the progress bar can also be
% drawn on instructions screens). 

timeColor = [200, 200, 200];
% frame for progress bar
Screen('FillRect',wid,0,rects.timeBarBorder);
Screen('FillRect',wid,bkgd,rects.timeBar);
% progress bar itself
timeBar = rects.timeBar;
timeBar(3) = timeBar(1) + display.trialTimeBar;
Screen('FillRect',wid,timeColor,timeBar);
%%%% OPTIONAL: add hash marks at possible reward times
if display.hatch
    Screen('FillRect',wid,0,rects.timeBarHatchRects);
end


