function [RPROF W]=PEABR_response_profile(SID, STR, CODES, N, BFLAG)
%% DESCRIPTION:
%
%   Function used to create a behavioral "response profile". While
%   performing analyses for Exp02C, it seemed necessary to know the
%   percentage of suppressed responses at each position in a lead-lag
%   train.  This function is my lame attempt to do so.
%
% INPUT:
%
%   SID:    character array, in which each row is a subject ID.
%   STR:    string, string appended to the ERP mat file
%   CODES:  integer array, codes to look for and include in analysis.
%   N:      length of trains (e.g., 20).
%   BFLAG:  bool, set to true of CODES provided match bin indices
%           (eventinfo.bini field). (default = false)
%
% OUTPUT:
%
%   RPROF:  C x N x S matrix, where C is the number of CODES, N is the
%           number of members in a train, and S is the number of subjects. 
%           An element of an array reflects the overall percentage of codes
%
%   W:      W differs from RPROF in a subtle way. While RPROF reflects the
%           percentage of instances a specific code is observed relative to
%           all codes observed at a position in the train, W reflects the
%           percentage of a specific code observed at a given condition
%           relative to that single code across all positions.  Bishop is
%           tired right now, but, in this vulnerable state, I think these
%           are not necessarily equivalent. The W is what we want to
%           compute a weighted average of the neural response while the
%           RPROF is a more meaningful behavioral measure...I *think*.
%   Several figures also generated.
%

%% INPUT CHECK
if ~exist('BFLAG', 'var') || isempty(BFLAG), BFLAG=false; end % default for BFLAG

%% SET RETURN VARIABLES
RPROF=nan(length(CODES), N, size(SID,1)); % initialize array
W=nan(size(RPROF)); 
for s=1:size(SID,1)
    
    % Subject ID
    sid=deblank(SID(s,:)); 
    
    %% LOAD SUBJECT DATA
    load(fullfile(sid, 'analysis', [sid '_ABR' STR]), 'ERP'); 
    
    %% EXTRACT EVENTS, ECODE, ETIME
    EVENT=struct2cell(ERP.EVENTLIST.eventinfo);
    
    % Code matching either done on original event codes or on the bins of a
    % trial. 
    if ~BFLAG
        ECODE=cell2mat(squeeze(EVENT(strmatch('code', fieldnames(ERP.EVENTLIST.eventinfo), 'exact'),:,:)));
    else
        ECODE=cell2mat(squeeze(EVENT(strmatch('bini', fieldnames(ERP.EVENTLIST.eventinfo), 'exact'),:,:)));
    end % ~BFLAG
%     ETIME=cell2mat(squeeze(EVENT(strmatch('time', fieldnames(ERP.EVENTLIST.eventinfo), 'exact'),:,:)));
    
    %% CONSTRUCT RESPONSE PROFILE
    rprof=zeros(length(CODES), N); 
    
    IND=1;
    while IND<length(ECODE)
        
        % Find if code matches

        if ismember(ECODE(IND), CODES)
            
            % If the code is one we're looking for, do something with it
            
            for n=1:N
                [tf loc]=ismember(ECODE(IND+n-1), CODES);
                
                % Simple error catch just in case we encounter an
                % unexpected code.
                %   This helps safeguard against any instances when we do
                %   not have a full N consecutive codes.
                if ~tf, error('Something weird happened and this code is not what we think it should be'); end
                rprof(loc, n)=rprof(loc, n)+1; % increment counter
                
            end % for i
            
            % Increment IND
            %   Add N so we start looking for the next train just after
            %   this one ends.
            IND=IND+N; 
        else
            % If this code doesn't matter, just increment IND
            IND=IND+1;
        end % ~isempty ...
    end % while
    
    % Transfer to larger matrix
    %   Convert each position in the train to a percentage
    RPROF(:,:,s)=rprof./(ones(length(CODES), 1)*sum(rprof)).*100;

    % Calculate weighting matrix for each response category. Useful when
    % computing a weighted average of neural responses. 
    W(:,:,s)=rprof./(sum(rprof,2)*ones(1,N));
end % s=1:size(SID,1)