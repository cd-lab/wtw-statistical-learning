%%%%% DRAWSAMPLE %%%%%
% subfunction to draw a delay duration
function [delay,seq,dist] = drawSample(distrib,seq)
% generates a sample from next quantile of the designated distribution
% timing parameters are specified within this function

% identify the distribution
switch distrib
    case 'shortTail'
        dist = [ 0,  5, 10, 15, 20, 25, 30, 35, 40      % row 1: times in seconds
                 0,  1,  1,  1,  1,  1,  1,  1,  1 ];   % row 2: relative frequencies

    case 'longTail'
        dist = [ 0,  5, 10, 15, 20, 90      % row 1: times in seconds
                 0,  1,  1,  1,  1,  4 ];   % row 2: relative frequencies

    case 'practice'
        dist = [ 10, 10
                  1,  1 ];
              
    case 'fixed10'
        dist = [10; 1];
        
    case 'fixed60'
        dist = [60; 1];

    case 'beta20'
        % discrete distribution based on percentiles of a beta dist
        quantiles = 0:0.1:1;
        betaParam = 0.4;
        dist = 20*betainv(quantiles,betaParam,betaParam);
        dist(2,:) = ones(size(dist));

    case 'unif20'
        % discrete uniform distribution
        % uses the same setup as beta20 above to match range
        quantiles = 0:0.1:1;
        betaParam = 1;
        dist = 20*betainv(quantiles,betaParam,betaParam);
        dist(2,:) = ones(size(dist));
        
    case 'scale_1.5_30' % a heavy-tailed distribution (10 points)
        
        base = 1.5;
        maxtime = 30;
        pt_lag = base.^(0:9); % each point's lag from the previous point
        dist = cumsum(pt_lag);
        dist = maxtime*dist./dist(end); % normalize largest time to the max
        dist(2,:) = ones(size(dist));
        
    case 'scale_1_20' % corresponds to a discrete uniform distribution
        
        base = 1;
        maxtime = 20;
        pt_lag = base.^(0:9); % each point's lag from the previous point
        dist = cumsum(pt_lag);
        dist = maxtime*dist./dist(end); % normalize largest time to the max
        dist(2,:) = ones(size(dist));

end

% the number of unique sequence elements
if strcmp(distrib,'practice')
    % for practice, simply do items 1 and 2 in order
    if isempty(seq)
        seq = 1;
    else
        seq = [1, 2];
    end
    nextItem = seq(end);
else % for any of the real distributions
    % find the index of the next sequence element
    nUnique = sum(dist(2,:)); % number of elements to randomize
    [nextItem, seq] = seqAppend(seq,nUnique);
        % 2nd arg is the number of unique sequence elements
end

% map the selected randomization element (stored in nextItem) to a
% delay value, allowing for distributions in which delay values have
% unequal probabilities.
idxCol = cumsum(dist(2,:));
sampIdx = find(nextItem<=idxCol,1,'first');
delay = dist(1,sampIdx);


