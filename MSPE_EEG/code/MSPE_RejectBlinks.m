function [EEGIN REJ]=MSPE_RejectBlinks(EEGIN, EEGREJ)
%% DESCRIPTION:
%
%   Function compares the rejection criteria for two EEG datasets and
%   resets rejection flags to exclude all trials rejected in either EEG
%   dataset.
%
% INPUT:
%
%   EEGIN:
%   EEGREJ:
%
% OUTPUT:
%
%   EEGOUT
%

F = fieldnames(EEGREJ.reject);
sfields1 = regexpi(F, '\w*E$', 'match');
sfields2 = [sfields1{:}];
fields4reject  = regexprep(sfields2,'E','');
REJ=[];
for i=1:length(EEGIN.EVENTLIST.eventinfo) % shouldn't matter which we use, since both should have the same length

    bepoch=EEGIN.EVENTLIST.eventinfo(i).bepoch;
    % If in doubt, toss out the trial
    try
        flag = eegartifacts(EEGREJ.reject, fields4reject, bepoch);
    catch 
        flag=0;
    end; 
    
    % Recall that flag~=0 if it should be included
    if ~flag && bepoch ~=0
        %%
        EEGIN.reject.rejmanualE(:,bepoch)=EEGREJ.reject.rejmanualE(:,bepoch);
        EEGIN.reject.rejmanual(:,bepoch)=EEGREJ.reject.rejmanual(:,bepoch);
        REJ(end+1)=bepoch;
    end % 
end % i=1:length...