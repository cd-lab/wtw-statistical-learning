function [rects] = setRects_crosshatch(rects,distribName,display)
% identify the screen location of hatch marks indicating possible reward
% arrival times

% get the discrete distribution corresponding to distribName
[~, ~, distrib] = drawSample(distribName,[]);

% check the returned distribution
% distrib should be a 2-row matrix
assert(ismatrix(distrib) && size(distrib,1)==2,'Unexpected distribution for hatchmarks!');
% any columns with a zero in row 2 can be ignored
nullCols = distrib(2,:)==0;
distrib(:,nullCols) = [];
% all remaining values should be weighted equally
% (otherwise hatchmarks don't represent the distribution accurately)
assert(numel(unique(distrib(2,:)))==1,'Hatchmarks requested but probabilities are unequal!');
% having checked all this, only the first row is needed
% it contains equally weighted delay values
distrib = distrib(1,:);

% set the hatchmark rectangles
origin = rects.origin;
hatchX = origin(1) - 200 + floor(distrib*rects.timeBarMax./display.timeBarMaxTime);
hatchY_hi = ones(size(hatchX)) * rects.timeBar(2) - 10;
hatchY_lo = ones(size(hatchX)) * rects.timeBar(4) + 10;
rects.timeBarHatchRects = [hatchX; hatchY_hi; hatchX+1; hatchY_lo];


