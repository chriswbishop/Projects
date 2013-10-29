function PEINT_group(SID, EXPID, F)
%% DESCRIPTION:
%
%   This function creates figures at both the subject and group level.
%   
% INPUT:
%
%   SID:    string array, each row is a subject ID.
%   EXPID:  string, experiment ID (appended to subject ID)
%   F:      Flag, integer. If you want to plot the data, set F. If not,
%           set it to 0 (default).
%
% OUTPUT:
%
%   gSRATE:
%   gNRATE:
%   gRESP:
%   gSRT:   
%   rmSRATE:
%   rmNRATE:
%
%   FIGURES:
%
%       Figure 01:  
%       Figure 02:
%       Figure 03:
%       Figure 04:
%       Figure 05:
%
% Bishop, Chris Miller Lab 2010
% Slightly modified by:
% London, Sam Miller Lab 2010

close all;

%% LOAD DEFAULTS
MSPE_DEFS;

if ~exist('F', 'var') || isempty(F), F=0; end 

%% DECLARE VARIABLES

PERF = zeros(1,8);

for s=1:size(SID,1)
    sid=deblank(SID(s,:));
end
    
    % LOAD DATA
    load([sid EXPID], 'NRESP', 'COND');
    
%% PLOT NRESP

    i = 1;
    while i < length(COND)
        if NRESP(i) == 2
            PERF(COND(i)) = PERF(COND(i)) + 1;
        end
        i = i + 1;
    end

    figure, hold on
    PERF=PERF./10;
    
        barweb(PERF,zeros(1,length(PERF)));
        legend('.00', '.025', '.15', '.30')
    axis([0.5 1.5 0 1])
    ylabel('% Different')
    