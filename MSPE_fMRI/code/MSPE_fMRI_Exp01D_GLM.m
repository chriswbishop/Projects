function [results]=MSPE_fMRI_Exp01D_GLM(args)
%% DESCRIPTION:
%
%   Function to build DURATION and ONSET vectors from logfiles. At the time
%   of writing, 
%
% INPUT:
%
%   args.
%       P:  path to mat-file with saved data or list of log files (each row
%           is a path to the log files)
%       CONCAT: logical flag, if set, event onsets are cumulative. That is,
%               the scanner trigger count is cumulative across the log
%               files.  This is useful when concatenating several
%               "sessions" into a single session regressor.
%       NSCAN:  integer array, number of scans for each file listed in P.%       
%       SESSMEAN:   logical flag, if set, covariates modeling session means
%                   are written to file. These can then be added in as
%                   nuisance regressors or, as I currently do it, manually
%                   to the design matrix to keep SPM from doing stupid
%                   things to it (e.g. mean centering). 
%       SMOUT:  string, full path where the SESSMEAN covariates should be
%               written.
%       STRANS: logical flag, include event regressors at session
%               transitions.  This should help do two things : 1. each up
%               variance from what are most likely large responses due to
%               scanner onset; 2. help eat up variance between sessions due
%               to differences in scanner values.  
%               
%
% OUTPUT:
%
%   results:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2012
%   cwbishop@ucdavis.edu


%% INPUT CHECK
if ~isfield(args, 'CONCAT') || isempty(args.CONCAT), args.CONCAT=0; end % don't concatenate by default.
if args.CONCAT && (~isfield(args, 'NSCAN') || isempty(args.NSCAN)), error('Must provide args.NSCAN when concatenating data'); end 
if ~isfield(args, 'SESSMEAN') || isempty(args.SESSMEAN), args.SESSMEAN=0; end % SESSION MEAN

% LOAD BEHAVIORAL DATA
try 
    load(args.P, 'COND', 'ALAG', 'COND', 'NRESP', 'PCOUNT', 'P', 'S', 'M');
catch
%     if args.CONCAT
      [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF PCOUNT PTOTAL S M]=MSPE_fMRI_read(args.P);
%     else
%         [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF PCOUNT PTOTAL S M]=MSPE_fMRI_read(args.P, args.CONCAT);     
%     end % if 
        
end % try, catch

%% FIRST BREAK UP BY CONDITION
NAMES={'Ape(L)', 'A(L)', 'D(L)', 'Ape(R)', 'A(R)', 'D(R)'};
C=[2 7 24 1 8 25];

SESS=sort(unique(S)); % sort just in case something stupid happens

%% MODEL SESSION MEANS?
%   SPM includes a grand session mean, but not individual sessions within a
%   given subject. I added this little ditty when creating a concatenated
%   GLM. These are later added to the design matrix and the grand mean
%   removed. 
SM=[];
if args.SESSMEAN
    
    for s=1:length(SESS)
        SM(:,s)=[zeros(sum(args.NSCAN(1:s-1)),1); ones(args.NSCAN(s),1); zeros(sum(args.NSCAN)-sum(args.NSCAN(1:s)),1)];
    end % s
    
    %% WRITE TO FILE
    dlmwrite(args.SMOUT, SM, 'delimiter', '\t'); 
    
end % 

%% CONCATENATE SESSIONS?
if args.CONCAT  
    % Alter PCOUNT so event onsets are cumulative.
    for s=1:length(SESS)        
        %% ALTER PCOUNT
        PCOUNT(S==SESS(s))=PCOUNT(S==SESS(s))+sum(args.NSCAN(1:s-1));
    end 
    SESS=1; % only one session
    S=ones(size(S)); % assign all events to the first session.
end % if 


%% CREATE EVENT ONSET AND DURATION VECTORS. 
for s=1:length(SESS)
    onsets={};
    durations={}; 
    names={};
    for i=1:length(C)
        
        %% BREAK UP BY RESPONSE
        onsets{1,end+1}=PCOUNT(find(COND==C(i) & S==SESS(s) & NRESP==1))-1; % subtract 1
        durations{1,length(onsets)}=zeros(size(onsets{1,end}));        
        names{1,end+1}=['Sess' num2str(SESS(s)) '-' NAMES{i} '-One'];
        
        onsets{1,end+1}=PCOUNT(find(COND==C(i) & S==SESS(s) & NRESP==2))-1; % subtract 1
        durations{1,length(onsets)}=zeros(size(onsets{1,end}));        
        names{1,end+1}=['Sess' num2str(SESS(s)) '-' NAMES{i} '-Two'];
        
        onsets{1,end+1}=PCOUNT(find(COND==C(i) & S==SESS(s) & NRESP==0))-1; % subtract 1
        durations{1,length(onsets)}=zeros(size(onsets{1,end}));        
        names{1,end+1}=['Sess' num2str(SESS(s)) '-' NAMES{i} '-Miss'];
        
    end % i   
    
    %% EXCLUDE TRIALS TYPES WITH NO OCCURRENCES
    for i=1:length(onsets)
        if isempty(onsets{i})
            ind(i)=false; % exclude
        else 
            ind(i)=true; % include
        end
    end % i
    
    onsets={onsets{1,ind}};
    durations={durations{1,ind}};
    names={names{1,ind}};
    
    %% SESSION TRANSITION COVARIATES?
    if args.STRANS && ~args.CONCAT
        onsets{end+1}=0; % start of scan
        durations{end+1}=0;
        names{end+1}=['Sess' num2str(i) '-Onset'];
    elseif args.STRANS && args.CONCAT
        %% Need to do something a bit different for concatenated sessions
        for i=1:length(args.NSCAN)
            %% For first session, we want it to start at scan 0.
%             if i==1
                onsets{end+1}=sum(args.NSCAN(1:i-1)); % we don't need to increment this since a 209 here is equivalent to the 210th scan
%             else
%             %% For all other sessions, we want it to start at the beginning
%             %% of the NEXT scan
%                 onsets{end+1}=sum(args.NSCAN(1:i-1))+1;
%             end % if i==1
            durations{end+1}=0;
            names{end+1}=['Sess' num2str(i) '-Onset'];
        end % 
    end % 
    %% Save session specific mat files
    save([args.OUT '_Sess' num2str(SESS(s)) '.mat'], 'names', 'onsets', 'durations'); 
end

%% SAVE MAT FILE FOR EACH SESSION
% SESS=unique(S);
% for i=1:length(S);
%     
% save(args.OUT, 'names', 'onsets', 'durations'); 

results='done'; 