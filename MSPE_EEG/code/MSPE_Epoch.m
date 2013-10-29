function results=MSPE_Epoch(args)
%% DESCRIPTION
%
% INPUT:
%
%   args
%       .type:          cell array, each member of the array is a string
%                       name of the event type to parcel out of the data.
%                       (e.g. args.type={'321'})
%       .EpochWindow:   1x2 double array, the time window about each event
%                       to epoch the data.  First element is the shortest
%                       time (often negative to look for prestimulus
%                       baseline) and the second is the larger of the two.
%                       *Note*: time must be in seconds (e.g. [-0.5 0.8])
%       .Baseline:      1x2 double array, the time window used to baseline
%                       the data. Same conventions as EpochWindow (e.g.
%                       [-.5 0];
%       .thresh:        double, threshold (microvolts) to use for artifact
%                       rejection. (e.g. 80)
%       .OFFSET:        double, if all events must be shifted in time by a
%                       fixed amount, then set OFFSET to a non-zero value.
%                       For example, to move the event onset time 100 msec
%                       later, OFFSET=0.100. *Note* that OFFSET must be in
%                       seconds.
%
% OUTPUT:
%
%   results:    string, per GAB conventions, this is returned as 'done'
%               regardless of the result.
%
% Bishop, Chris Miller lab 2010 

global EEG ALLEEG
if ~exist('ALLEEG', 'var')
    global ALLEEG;
    ALLEEG=[];
end % check for ALLEEG
% ALLEEG=eeg_store(ALLEEG, EEG);

%% 100506CWB:
%   We don't want this to set any defaults.
% %% CHECK INPUTS
% if ~isfield(args, 'type') || isempty(args.type)
%     args.type={'311' '312' '321' '322' '331' '332' '341' '342' '351' '352'};
% end % type
% 
% if ~isfield(args, 'EpochWindow') || isempty(args.EpochWindow)
%     args.EpochWindow=[-0.5 1.0];
% end % EpochWindow
% 
% if ~isfield(args, 'Baseline') || isempty(args.Baseline)
%     args.Baseline=[args.EpochWindow(1) 0];
% end % Baseline
% 
% if ~isfield(args, 'thresh') || isempty(args.thresh)
%     args.thresh=[100];
% end % Baseline
% 
% if ~isfield(args, 'OFFSET') || isempty(args.OFFSET)
%     args.OFFSET=0;
% end % Baseline

%% CHANGE EVENT TIMES
%   100505CWB: Added functionality below.
%
%   During early piloting, subjects often had different auditory speech
%   onset times.  If set, this OFFSETs the event latency by the amount set
%   in args.OFFSET. Event latencies are reset in EEG structure after
%   epoching is finished.
%
%   Note that OFFSET should be specified in seconds.
for i=1:length(EEG.event)
    EEG.event(i).latency=EEG.event(i).latency+(args.OFFSET*EEG.srate);
end % for i

%% EPOCH BY CONDITION/PERCEPT
for z=1:length(args.scheme)
    switch args.scheme(z)
        case {'i'}
            for i=1:length(args.type)
    
                %% 100426CWB: Had to add in try/catch statement. If no events,
                %% pop_epoch crashes. Implemented after s2102.
                try 
                    OUT=pop_epoch(EEG(1), {args.type{i}}, args.EpochWindow);
                    % 100422CWB: Added in additional check for more than 1 trial.
                    % pop_thresh tries to disgard outliers. With only 1 trial, it breaks.
                    if ~isempty(OUT.event) && length(OUT.event)>1       
                        OUT.urevent=[]; %% Is this correct??
                        OUT=pop_rmbase(OUT, args.Baseline);
                        OUT=pop_eegthresh(OUT, 1, 1:64, args.thresh*-1, args.thresh, args.EpochWindow(1), args.EpochWindow(2), 0, 1);
                        OUT.comments=args.type{i};
                        OUT.setname=[args.SID '-' args.type{i}];
                        [ALLEEG]=eeg_store(ALLEEG, OUT);          
                    end % if 
                catch
                    display(['No ' args.type{i} ' events!']);                
                end     % try/catch                    
                clear OUT
            end % i=1:length(args.type)
        case {'a'}
            %% EPOCH ALL STIMULI
            try 
                OUT=pop_epoch(EEG(1), args.type, args.EpochWindow);
                
                if ~isempty(OUT.event) && length(OUT.event)>1
                    OUT=pop_rmbase(OUT, args.Baseline);
                    OUT=pop_eegthresh(OUT, 1, 1:64, args.thresh*-1, args.thresh, args.Baseline(1), args.EpochWindow(2), 0, 1);
                
                     comment=[args.SID '-'];
                     % Build up name string
                     for q=1:length(args.type)
                         if q==length(args.type)
                             comment=[comment args.type{q}];
                         else 
                             comment=[comment args.type{q} '_'];
                         end % if
                     end % for q
                     if ~isfield(args, 'name') || isempty(args.name)
                         name=comment;
                     else 
                         name=args.name;
                     end
                    OUT.setname=name;
                    OUT.comments=strvcat(comment, '\n', OUT.comments);
                    [ALLEEG]=eeg_store(ALLEEG, OUT);
                end % if 
            catch
                display(['No events!']);
            end % try
        otherwise 
            error('Incorrect Epoching Scheme');
    end % switch

end % z

%% RESET EEG LATENCY EVENTS
%   Not sure if this is the best thing to do...
for i=1:length(EEG.event)
    EEG.event(i).latency=EEG.event(i).latency-round(args.OFFSET*EEG.srate);
end % for i...
results='done';