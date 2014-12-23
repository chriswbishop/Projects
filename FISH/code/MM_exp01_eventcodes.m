function results=PEABR_exp02C_eventcodes(args)
%% DESCRIPTION:
%
%   Reassign PEABR (Exp02C) event codes in BDFs.  Recall that all lead-lag
%   (Ape) pairs are assigned the same codes regardless of context.  So, we
%   have to determine a post-hoc way to reassign codes based on 1. context
%   and 2. user response.
%
%   Assumes EEG data is stored in a global EEG structure. 
%
% INPUT:
%
%   args.
%       ICI:    interclick interval in seconds (e.g. 0.25); This is
%               equivalent to the within train SOA. Code assumes this is
%               constant within each train for interpolation purposes. If
%               this is not the case, then you have some coding to do.
%       N:      Number of clicks within each train (e.g. 20).
%       TBOUND: 2 element double array.  This defines the tolerance
%               boundary (in samples) for the interpolation procedure.  I'd
%               suggest keeping this number low (e.g. 1).  Not a great
%               explanation, see INTERP_ETIMES below. 
%       INTERP: logical flag, whether or not to perform within train
%               interpolation
%       EXCLUDE:integer array, list of events to exclude. This proved
%               useful when I had to exclude sessions for various reasons
%               (e.g. if there was evidence that the earphones slipped,
%               resulting in a drastic change in behavior).  These event
%               codes are effectivel removed from any analysis by replacing
%               the EEG.event(i).type field with a NaN.  
%
% OUTPUT:
%
%   results:    hold over for GAB stuff
%
% Bishop, CW 2012

%% GLOBAL VARS
global EEG;

%% ENSURE ALL VALUES ARE INTEGERS
%   When merging data sets (e.g. for s3163), EEGLAB assigns all event codes
%   as strings.  Stupid, stupid EEGLAB.  If I wanted strings, I'd make them
%   strings.  Must convert everything back.
for i=1:length(EEG.event)
    
    % Check for EEGLAB's inserted 'boundary' event
%     try 
        if strcmp(EEG.event(i).type, 'boundary')
            EEG.event(i).type=32766;
        end % if 
%     catch
%     end % try catch
    
    try 
        EEG.event(i).type=str2num(EEG.event(i).type); 
    catch 
        % maybe something clever in here?
    end % try catch
end % i

%% REMOVE BULLSHIT CODES
%   For reasons beyond my comprehension, there are often some really
%   bizarre event codes that make their way into the EEG structure. I
%   strongly suspect this is an error with the import function (shocking)
%   as I visually inspected a considerable amount of data during data
%   acquisition and saw nothing alarming.  
%
%   These codes are large (>32000).  So, we know the codes we're looking
%   for. If we encounter a code that doesn't make sense, toss it.
%
%       I did some sanity checking by hand, and it seems that the "real"
%       codes are still logged accurately relative to one another even when
%       these bullshit codes are introduced.  
%
%       These codes are not present for all subjects. I don't know what
%       this is about. 
OKCODES=[1:21 51:70 101:120 201:220 32766]; % these are the codes that we
                                            % know should be in the BDF.
                                            % Anything else, we toss. 
                                            
% Dynamically allocation event fields
%   When files are merged in EEGLAB (e.g. s3163), it sorts the fieldnames. 
%   So, if our event variable is hardcoded, it won't match the structure. 
%   Thus, need to dynamically allocate event.

% event=struct('type', [], 'latency', [], 'duration', []', 'urevent', []);
names=fieldnames(EEG.event);
for i=1:length(names)
    event.(names{i})=[];
end % i=1:length(names)

% Only include codes that are listed in OKCODES
%   We check EEG.event(i).type to see if it's one of the accepted event
%   code types. If it is, include the event. If it is not, exclude it.
%   EEG.event is set to event after this loop
flag=1;
for i=1:length(EEG.event)
    if ismember(EEG.event(i).type, OKCODES)
        if flag
            event(1)=EEG.event(i);            
            flag=0;
        else 
            event(length(event)+1)=EEG.event(i);            
        end 
    end 
end % 

% Overwrite events in EEG structure. 
EEG.event=event; 
clear event;

%% GET EVENTS AND EVENT CODES
EVENT=struct2cell(EEG.event);

%% MATCH FIELDS
%   EEGLAB, in its infinite wisdom, also resorts the EEG.event fields after
%   merging a file. So, need to be more explicit in matching this.
ECODE=cell2mat(squeeze(EVENT(strmatch('type', fieldnames(EEG.event)),:,:)));
ETIME=cell2mat(squeeze(EVENT(strmatch('latency', fieldnames(EEG.event)),:,:)));

%% ASSIGN NaNs to output codes.
EOUT=nan(size(ECODE)); % rewritten event codes

%% IDENTIFY LAG-ONLY TRIALS
%   Rather than simply checking for a 201, we check for the full sequence.
%   This will prevent specific errors (e.g. subject presses 201 intead of
%   20 for a response) from screwing up things later on.
%       I just did 3 because that should be way specific enough.
%           Actually, we need all 20 in case we exit early or something. We
%           only want to include COMPLETE trains. 
%       
%           Checking for all 20 actually helped us by excluding trains with
%           errors in the event code records in the BDF. For instance, if a
%           218 was not dropped in a string of 201-220, then we won't
%           identify it as a valid train and exclude it from analysis.
str='LAG=find(';
C=201:220;
for i=1:length(C)
    str=[str ['[ECODE(' num2str(i) ':end)'' ' num2str(nan(1,(i-1))) ']==' num2str(C(i))]];
    if i==length(C)
        str=[str ');'];
    else 
        str=[str ' & '];
    end % if i==length(C)
end % for i
eval(str); 
% LAG=find(ECODE==201 & [ECODE(2:end); NaN]==202 & [ECODE(3:end); NaN; NaN]==203);

%% IDENTIFY LEAD ONLY
str='LEAD=find(';
C=101:120;
for i=1:length(C)
    str=[str ['[ECODE(' num2str(i) ':end)'' ' num2str(nan(1,(i-1))) ']==' num2str(C(i))]];
    if i==length(C)
        str=[str ');'];
    else 
        str=[str ' & '];
    end % if i==length(C)
end % for i
eval(str); 
% LEAD=find(ECODE==101 & [ECODE(2:end); NaN]==102 & [ECODE(3:end); NaN; NaN]==103);

%% IDENTIFY LEAD-LAG TRAINS
str='APE=find(';
C=51:70;
for i=1:length(C)
    str=[str ['[ECODE(' num2str(i) ':end)'' ' num2str(nan(1,(i-1))) ']==' num2str(C(i))]];
    if i==length(C)
        str=[str ');'];
    else 
        str=[str ' & '];
    end % if i==length(C)
end % for i
eval(str); 
% APE=find(ECODE==51 & [ECODE(2:end); NaN]==52 & [ECODE(3:end); NaN; NaN]==53);
LEAD=LEAD'; LAG=LAG'; APE=APE'; 

%% FIND RESPONSES
%   Only count responses within specified range
%       Recall that responses are incremented by 1 in the BDF
RESP=find(ECODE>=1 & ECODE<=21);

%% FIND BOUNDARY EVENTS
BOUNDARY=find(ECODE==32766);

%% CLASSIFY CONTEXT OF APE TRAINS
%   Change event codes based on context.
%
%   Note:   There is a potential bug here.  If a LEAD or LAG train is
%   excluded above (e.g. if a code is missing from the train), then the APE
%   train will be misclassified (I think).  Need to address this. 
%       -This issue has been addressed and tested with s3180.
%       
%CONTEXT=NaN(size(APE)); 
for i=1:length(APE)
    lead_lag=sort([LEAD; LAG]);
    
    % This identifies the previous LEAD or LAG train prior to the current
    % APE train.
    prevtrain=(find(ETIME(lead_lag)<ETIME(APE(i)),1,'last'));
    
    % This is an additional precaution. If, for some reason, a Lead or Lag
    % train is not flagged above (e.g. if a code is missing from the train,
    % which happens occassionally), then we need to toss the corresponding
    % APE train as well.  So, we see if there are any APE trains with a
    % time closer than the presumed "previous" trial.  
    FLAG=0;
    if i==1 % if it's the first one, then we're good. 
        FLAG=1; % include
    elseif i~=1 && (min(ETIME(APE(i))-ETIME(APE(1:i-1))) >(ETIME(APE(i)) - ETIME(lead_lag(prevtrain))))
        FLAG=1; % include
    end % train order check 
    
    % Using this index, we detect if we have LEAD or LAG train. 
    if ~isempty(find(LEAD==lead_lag(prevtrain))) && isempty(find(LAG==lead_lag(prevtrain))) && FLAG
        ECODE(APE(i):APE(i)+19)=51; % Assign base codes for full sequence.
    elseif ~isempty(find(LAG==lead_lag(prevtrain))) && isempty(find(LEAD==lead_lag(prevtrain))) && FLAG
        ECODE(APE(i):APE(i)+19)=52; %
    else 
        ECODE(APE(i):APE(i)+19)=NaN; % Assign NaNs to exclude trial from analysis.
    end % if   
    
end % i

%% BIN BASED ON RESPONSES
ind=sort([APE; LEAD; LAG]); % put everything together.

% Go through responses and assign to preceding trial.
%   This way is better than trying to match each stimulus train to a
%   response because it doesn't assume that each train HAS a response (e.g.
%   if subjects mistype and enter a "nothing".  
%
%   Also, this will handle multiple response entries for the same event
%   better (should that occur, which it SHOULDN'T).
%       -With a bug fix (see below) this is no longer true. This condition
%       (multiple response codes registered in the BDF for the same train)
%       should never occur, really, so I opted to let this potential
%       flexibility fall by the wayside. 
%
%   There is, however, a potential bug here.  If a train is not included
%   because a code is missing (rare, but it happens), then we will
%   essentially have a Trial (T) and Response (R) order like this : T R _
%   R. The _ is the rejected trial. In such a case, the second response
%   will be remapped onto the incorrect trial.  That could be problematic. 
for i=1:length(RESP)
    
    % Preceding trial. 
    resp=ECODE(RESP(i)); 
    prevtrain=(find(ETIME(ind)<ETIME(RESP(i)),1,'last')); % previous trial
    tmp=ind(prevtrain); 
    
    FLAG=0;    
    if i==1
        FLAG=1; % include
    elseif (i~=1 && (min(ETIME(RESP(i))-ETIME(RESP(1:i-1))) >(ETIME(RESP(i)) - ETIME(tmp))))
        FLAG=1;
    end % check for missing trains.
    
    % subtract 2 from response. 
    %   1 because we increment in the BDF. 1 more because we want a total
    %   of 20.
    %       Only set codes if the train and response can be unambiguously
    %       mapped. 
    if FLAG
        EOUT(tmp:tmp+resp-2)=ECODE(tmp:tmp+resp-2)*10+1; % multiply by 10, add 1. 
        EOUT(tmp+resp-2+1:tmp+19)=ECODE(tmp+resp-2+1:tmp+19)*10+0; % multiply by 10, add 0;
    end % FLAG
    
end % i

%% ASSIGN RESPONSE CODES
%   Convert these to the actual response counts (subtract 1)
EOUT(RESP)=ECODE(RESP)-1; 

%% ASSIGN BOUNDARY EVENTS!!
%   Missed this when going through the first time. No boundary events
%   found, so filters are applied over the whole data range.  Not sure it
%   matters much practically since edge effects will be there regardless
%   and gone within a few seconds, but worth looking into.
EOUT(BOUNDARY)=32766; 

% [EOUT]=TRAIN_TOLERANCE(args.TBOUND, LEAD, ECODE, ETIME, EOUT);
if args.INTERP
    [ETIME EOUT NREJAPE]=INTERP_ETIME(APE, EOUT, ETIME, args.ICI, EEG.srate, args.TBOUND, args.N); 
    [ETIME EOUT NREJLEAD]=INTERP_ETIME(LEAD, EOUT, ETIME, args.ICI, EEG.srate, args.TBOUND, args.N);
    [ETIME EOUT NREJLAG]=INTERP_ETIME(LAG, EOUT, ETIME, args.ICI, EEG.srate, args.TBOUND, args.N);
end % args.INTERP

%% MANUALLY REMOVE EVENT CODES
%
%   In the event that certain events must be removed (e.g. in case the
%   earphones slipped, etc.), the user can specify the args.EXCLUDE field.
if isfield(args, 'EXCLUDE') && ~isempty(args.EXCLUDE)
    EOUT(args.EXCLUDE)=NaN;
end % if isfield( ... 

%% REASSIGN EOUT TO EEG STRUCTURE
%   Only assign changes to EEG.event. Leave EEG.urevent alone for cross
%   checking later on.
for i=1:length(EEG.event)
    EEG.event(i).type=EOUT(i); 
    EEG.event(i).latency=ETIME(i); % these times are likely modified due to interpolation. 
                                    % Leave urevent alone for comparison
                                    % later. 
end %
results='done';

end % PEABR_exp02C_eventcodes.m

function [ETIME EOUT NREJ]=INTERP_ETIME(ONS, EOUT, ETIME, ICI, FS, TBOUND, N)
%% DESCRIPTION:
%
%   Function performs a linear interpolation of event codes in time.  This
%   proved useful for PEABR when events were presented in trains with known
%   inter click intervals (ICI).  Much to our dismay, as I poked around I
%   realized that for some subjects (e.g. s3180) have a rather large
%   percentage of event codes that are set at irregular intervals.  More
%   poking around revealed that this was due to sporadic errors in port
%   code output from the Presentation PC that tended to be bad for some
%   subjects. However, errors for any given click seemed to be independent
%   of other timing errors, so we can use the "good codes" to interpolate
%   the bad ones.  
%
% INPUT:
%
%   ONS:    Integer array, an index to the start of each click train we
%           want to interpolate.
%   EOUT:   The event output codes.
%   ETIME:  Event code times
%   ICI:    Double, interclick interval in seconds (e.g. 0.25 for a 4 Hz
%           presentation rate.
%   N:      The number of clicks in a train.
%
% OUTPUT:
%
%   ETIME:  Modified event times.
%
% Bishop, CW 2012.
NREJ=0;
for i=1:length(ONS)
    
    % REJECTION FLAG:
    %   Determines if current train will be rejected. 
    REJ=false;
    % Get event times for all clicks in train
    CLICK_ET=ETIME(ONS(i):ONS(i)+(N-1)); % Get event times for all clicks in train
    
    % Which clicks will we use for the regression?
    %   We'll make this pretty conservative. We'll only include clicks that
    %   are perfectly spaced ICI sec from the click before and after it.
    %   Consequently, we'll ignore the first and last click in the train.
    INC=[];
    for j=2:N-1
        tmp=CLICK_ET(j-1:j+1);
        if isempty(find(diff(tmp)./FS~=ICI,1)), INC(end+1,1)=j; end
    end % j
    
    % One additional check. Make sure there's no remainder (modulus). if
    % there is, that suggests there might be a string of samples that are
    % spaced by ICI from eachother, but not a multiple of ICI from other
    % samples.  An additional DIFF step should identify and exclude such
    % cases.
    %
    %   Actually, there's not much we can do here, nor is there a great way
    %   to tell which "segment" (that is, sequences of clicks that are
    %   spaced at ICI sec with eachother, but not members of other
    %   sequences) is actually correct. So, just make sure there aren't any
    %   huge errors (give it some room for slop) and move on.
    %
    %   So, what to do? Well, we can check for egregious differences and
    %   toss the train, I guess...I dunno. 
    
    % If we exceed the Tolerance BOUND (TBOUND), toss the train. 
    %   We essentially sum up all the changes between sequences and make
    %   sure they don't exceed TBOUND. 
    tmp=ICI*FS-rem(abs(sum((rem(diff(CLICK_ET(INC)), ICI*FS)))), ICI*FS);
    if tmp~=ICI*FS && tmp>TBOUND
        REJ=1; %EOUT(ONS(i):ONS(i)+(N-1))=NaN;  
    end % if 
%     INC=INC(~logical(abs(mod(diff(CLICK_ET(INC))>TBOUND), ICI.*FS)));
    
    % Linear Regression
    %   Need to have enough points to fit a line
    if length(INC)>=2 
        p=polyfit(INC, CLICK_ET(INC), 1);
            
        % Reassign all event times for this click train
        ETIME(ONS(i):ONS(i)+(N-1))=round(p(1).*[1:N]+p(2)); 
    else 
        % if we don't have enough data points, toss the train.
        REJ=1; %EOUT(ONS(i):ONS(i)+(N-1))=NaN;
    end % if length(INC)
    
    % Reject train?
    if REJ
        NREJ=NREJ+1;
        EOUT(ONS(i):ONS(i)+(N-1))=NaN;
    end 
end % i


end % INTERPOLATE_ETIME
% function [EOUT]=TRAIN_TOLERANCE(TBOUND, ONSETS, ECODE, ETIME, EOUT)
% %% THIS FUNCTION HAS NOT BEEN TESTED OR DEBUGGED
% 
% %% DESCRIPTION:
% %
% %   This function identifies members of a train of click stimuli that fall
% %   outside a specified tolerance limit (e.g. 0.5 msec).
% %
% % INPUT: 
% %   
% %   TBOUND: 2 element double array specifying tolerance limits in seconds.
% %   ONSETS: Event onsets for start of click trains.
% %   ECODE:  Event codes
% %   ETIME:  Event times
% %   EOUT:   Reassigned event codes
% %
% % OUTPUT:
% %
% %   EOUT:   Modified event codes with trials exceding tolerance limits
% %           removed.
% 
% % D=[];
% % for i=1:length(ONSETS)
% %     for j=1:20 % 20 clicks
% %         
% %         
% %         if j==1 || j==20 % first or last click have different rules
% %         else
% %             D=diff(ETIME(ONSETS(i)+(j-2) : ETIME(ONSETS(i)+j)));            
% %         end % 
% %         
% %         % If we are within confidence limits for one neighbor, keep it. If
% %         % not, toss it. The logic here is that a single mistimed event will
% %         % result in the rejection of 3 trials (the code before, the
% %         % mistimed code itself, and the code after). 
% %         if (D(1)<TBOUND(1) && D(1)>TBOUND(2)) && (D(2)<TBOUND(1) && D(2)>TBOUND(2))
% %             EOUT(ONSETS(i)+(j-1)) = NaN;
% %         end 
% %     end %
% % end % i
% 
% end % TRAIN_TOLERANCE