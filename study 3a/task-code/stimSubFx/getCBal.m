function [cbal] = getCBal(nCells)
% randomizes condition assignment (returns an integer from 1 to nCells)

if exist('cbalSeq.mat','file')
    load cbalSeq
else
    cbalSeq = [];
end
if isempty(cbalSeq)
    cbalSeq = randperm(nCells*2);
    cbalSeq = ceil(cbalSeq/2);
end
cbal = cbalSeq(1);
cbalSeq(1) = [];
save cbalSeq.mat cbalSeq

% this should balance the condition assignments every nCells*2 subjects
% it may take intervention if something happens like a false start or a
% dropped subject
