function [results X Y]=MSPE_jitter(args)
%% DESCRIPTION:
%
%   Probably best if EEGLAB is open (path is the same as when you use the
%   GUI).
%
% INPUT:
%
%   args
%
% OUTPUT:
%
%   results:
%   X:
%   Y:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS

%% INITIALIZE RANDOM NUMBER GENERATOR
rand('twister', sum(100*clock)); 

%% INTRODUCE JITTER TO SUBJECT SPECIFIC DATA
%
%   1. Select trials.
%   2. Jitter trials
%       2a. Assume all pre-stimulus times used for baselining? Maybe not
%       smart, but man is it EASY!
%   3. Compute subject ERP
global EEG;
for z=1:size(args.P,1)
    EEG=eeg_emptyset;
    

    p=deblank(args.P(z,:));
    [PATHSTR,NAME,EXT,VERSN] = fileparts(p);
    out.path=PATHSTR;
    out.file=[NAME EXT];
    gab_task_eeg_loadset(out);   

    
    %% EXTRACT EPOCHS BASED ON BIN GROUPING
    %   I stole some code from ERPLAB to figure out which trials are rejected.
    % averager.m (80-
    F = fieldnames(EEG.reject);
    sfields1 = regexpi(F, '\w*E$', 'match');
    sfields2 = [sfields1{:}];
    fields4reject  = regexprep(sfields2,'E','');
    
    for i=1:length(EEG.EVENTLIST.eventinfo)
        bini=EEG.EVENTLIST.eventinfo(i).bini;
        
        % Flag set to 1 if included, set to 0 if rejected.
        %   Recall that rejection information is stored based on EPOCH
        %   information, not on individual eventinfo.
        bepoch=EEG.EVENTLIST.eventinfo(i).bepoch;
        try
            flag = eegartifacts(EEG.reject, fields4reject, bepoch);
        catch
            flag=0; % toss trial if we can't be sure it's OK.
        end; 
        
        %% Only use trials that have not been flagged for rejection.
        if ~isempty(find(ismember(bini, args.binArray),1)) && flag
            trls=trls+1;
            
            % Grab epoch
            x=EEG.data(:,:,bepoch);
            
            % Temporal jitter (samples)
            ds=round(EEG.srate.*(args.jitter(1)+rand(1).*diff(args.jitter)));
            
            % Find mean of prestimulus period (sargshould be 0, but ya never
            % know)
            
            if ds>0
            elseif ds<0
            else
            end % ds
            % Assign data to matrices
            X(:,:,trls,s)=x;
            
            Y(:,:,trls,s)=y; 
        end % if 
    end % i
end % z

%
%% COMPUTE GROUP (Jittered) ERP

results='done';
