function [SDATA, AMP, HDR]=MSPE_ET_analysis(SID)
%% DESCRIPTION:
%
%   Reads in and analyzes eye-tracking (ET) data.
%
% INPUT:
%
% OUTPUT:
%
% Bishop, Christopher W. 
%   UC Davis
%   Miller Lab 2011

%% SACCADE DATA
P=['../EyeTracking/' SID '_SACCADE.xls']; 
[SDATA HDR]=ET_read(P);

%% ANALYSIS:
%   Need to determine mean saccade amplitude for each condition/percept.
% conds=unique(SDATA(:,4)); 
% resp=unique(SDATA(:,5));
conds=[2 4 7 24];
resp=[1 2];
exAMP=[];
for c=1:length(conds)
    for r=1:length(resp)
        try 
            AMP(conds(c), resp(r))=mean(SDATA(SDATA(:,4)==conds(c) & SDATA(:,5)==resp(r) & SDATA(:,2)<800, 1));
        catch     
            %% need to put something in here, it hangs on missed trials.
        end % try  
    end % r
end % c
