function [dataFileName,dataHeader] = gatherSubInfo(tag,nCells,id,cbal)
% GATHERSUBINFO requests the subject's ID code.
% Creates a unique filename for saving the data.  
% Returns some relevant info in dataHeader.
%
% Inputs:
%  tag (string): the experiment name to be used in the data file
%  nCells (integer): number of unique counterbalance conditions
%  id (string, optional): may force a value for subject ID
%  cbal (integer, optional): may force a value for cbal

suppressMsg = false;
if nargin<3 || isempty(id)
    id = [];
    while isempty(id)
        id = input('Subject ID:  ','s');
    end
else
    % if an id was provided, assume this fx was called with a screen
    % already open, and suppress the final confirmation message. 
    suppressMsg = true;
end

if nargin<4 || isempty(cbal)
    cbal = [];
    cbalResp = false;
    while ~cbalResp
        cbal = input(sprintf('Counterbalance condition (1-%d; OPTIONAL):  ',nCells));
        if isempty(cbal) || ismember(cbal,1:nCells)
            cbalResp = true; 
        end
    end
    if isempty(cbal), cbal = getCBal(nCells); end
end

session = 1;
nameVetted = false;
while ~nameVetted
    dataFileName = fullfile('data',sprintf('%s_%s_%d',tag,id,session));
    if exist(sprintf('%s.mat',dataFileName),'file')==2
        session = session+1;
    elseif exist(sprintf('%s.txt',dataFileName),'file')==2
        session = session+1;
    else
        nameVetted = true;
    end
end

dataHeader.id = id;
dataHeader.dfname = dataFileName;
dataHeader.cbal = cbal;

if ~suppressMsg
    input(['Data will be saved in ',dataFileName,' (ENTER to continue)']);
end


