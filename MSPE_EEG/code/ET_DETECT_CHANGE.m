function EVENT_COUNT=ET_DETECT_CHANGE(SDATA, HDR, FLD)
%% DESCRIPTION:
%
%   This is an attempt to detect BLINK and SACCADE events from the SAMPLE
%   REPORT exported from the DataViewer.  Recall, the DataViewer will
%   export a BLINK_COUNT and SACCADE_COUNT variable, but these variables
%   are gross measures of BLINK and SACCADE events over the entire duration
%   of a trial.  I believe there are ways to define interest areas (or time
%   windows) within the DataViewer and redo the meta-analysis, but that
%   requires a lot more learning for Bishop.  So, this is designed to
%   detect BLINKS and SACCADES based on SORTED (see ET_SORT) and
%   potentially TRIMMED (see ET_TRIM_SDATA) data.  This is done by
%   detecting changes in a binary timecourse (e.g. RIGHT_IN_BLINK or
%   RIGHT_IN_SACCADE).
%
%   Of course, this function doesn't care what the data are, it's just
%   written with the INTENT of being used for BLINK or SACCADE events, but
%   it can work for anything else with a changing time series. 
%
% INPUT:
%
%   SDATA:  
%   HDR:
%   FLD:
%
% OUTPUT:
%
%   
%   
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS CHECK
if exist('HDR', 'var') && isnumeric(HDR)
    EIND=HDR;
else
    EIND=ET_HDRIND(HDR, FLD);  % Event INDex
end % if 

EVENT_COUNT=0; 

%% COUNT UP CHANGE EVENTS
for i=1:length(SDATA)
    REF=SDATA{i}(:,EIND);
    D=diff(REF);
    DIND=find(D~=0); 
    
    % COUNT UP EVENTS
    %   We round up to catch events when subjects are blinking at the start
    %   of the trial or at the end of a trial (no difference detected in
    %   REF). This gives us a liberal estimate of the number of blinks
    %   within the specified time range. 
    EVENT_COUNT=EVENT_COUNT + ceil(length(DIND)./2);
end % i
