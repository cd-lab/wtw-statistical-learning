function [nextItem, newSeq] = seqAppend(seq,nUnique)
% function for generating a sequence of elements, one at a time, balancing
% the frequency of first-order transitions (i.e., balancing two-element
% subsequences). 
% 
% Inputs:
%   - seq: the sequence so far, to be considered in generating the next
%   element
%   - nUnique: number of unique elements. Elements are integers 1:nUnique
%
% Outputs:
%   - nextItem: integer (drawn from 1:nUnique) of the item added
%   - newSeq: sequence with the new item appended. newSeq will be passed to
%   this function the next time around, may be stored across task blocks,
%   etc.
%
% For testing the output of this function, see here:
% ~/Documents/project_code/mr_qTask/pilot_expt_B/design/seqBalance.m
%
% by JTM, 3/28/2011

avail = 1:nUnique; % potential elements

% only balance 1st-order transitions (length 2)
% this introduces a weak temporal autocorrelation structure
% (autocorrelation from balancing 0th-order transitions is much larger)
subLength = 2; % length of subsequence to balance (hardcoded)
candidates = avail;
nCand = length(candidates);
cost = zeros(1,nCand);
if length(seq)>=subLength % provided this subsequence length exists
    for i = 1:nCand % evaluate each current candidate
        provisSeq = [seq, candidates(i)]; % the full sequence that candidate i would create
        newSubseq = provisSeq((end-subLength+1):end); % the relevant subsequence
        cost(i) = length(strfind(seq,newSubseq)); % number of subsequence repetitions
    end
    % only keep candidates with the fewest subsequence repetitions
    candidates = candidates(cost==min(cost));
end

% choose randomly among the candidates
nextItem = candidates(randi(length(candidates)));

% append it
newSeq = [seq, nextItem];
    
    
    
    