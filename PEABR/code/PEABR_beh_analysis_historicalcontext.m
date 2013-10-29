function OUT=PEABR_beh_analysis_historicalcontext(SID, STR, TL, P)
%% DESCRIPTION:
%
%   Function designed to look at historical context in behavioral
%   responses.  This uses an ERP structure whose responses have already
%   been sorted into various contexts (e.g., lag-ape, lead-ape, etc.).  The
%   hope here is to see how a listener's overall percept is affected by
%   local history.
%
% INPUT:
%
%
%
% OUTPUT:
%
%

%% INPUT CHECKS
if ~exist('TL', 'var') || isempty(TL), TL=20; end
if ~exist('P', 'var') || isempty(P), P=3; end
if ~exist('BFLAG', 'var') || isempty(BFLAG), BFLAG=false; end

%% OUTPUT VARIABLES
CONTEXT={};
PERC_COUNT={};
OKCODES=[510 511 520 521]; % Only want to look at these codes;
okcodes_str='find(';

for i=1:length(OKCODES)
    if i~=length(OKCODES)
        okcodes_str=[okcodes_str 'ECODE==' num2str(OKCODES(i)) ' | '];
    else
        okcodes_str=[okcodes_str 'ECODE==' num2str(OKCODES(i)) ');'];
    end % i~=length(OKCODES)
end % 

%% LOOP THROUGH EACH SUBJECT
for s=1:size(SID,1)
    CONTEXT{s}=[];
    PERC_COUNT{s}=[];
    
    sid=deblank(SID(s,:)); 
    
    % Load the ERP data
    load(fullfile(sid, 'analysis', [sid STR '.mat']), 'ERP'); 
    
    %% EXTRACT EVENTS, ECODE, ETIME
    EVENT=struct2cell(ERP.EVENTLIST.eventinfo);
    
    % Code matching either done on original event codes or on the bins of a
    % trial. 
    if ~BFLAG
        ECODE=cell2mat(squeeze(EVENT(strmatch('code', fieldnames(ERP.EVENTLIST.eventinfo), 'exact'),:,:)));
    else
        ECODE=cell2mat(squeeze(EVENT(strmatch('bini', fieldnames(ERP.EVENTLIST.eventinfo), 'exact'),:,:)));
    end % ~BFLAG
    
    % MASK ECODES, JUST LOOK AT OKCODES
    MASK=eval(okcodes_str);
    ECODE=ECODE(MASK); 
    
    % FIND LEAD-APE AND LAG-APE TRAINS
    IND=1;
    while IND<length(ECODE)
        
        % If this is a potential lead-ape train
        if ismember(ECODE(IND), [510; 511])
            codes=[510; 511];
            tmp=zeros(1,2);
            % if this is a potential lead-ape train
            for n=1:TL
                [tf loc]=ismember(ECODE(IND+n-1), codes);
                if ~tf, error('Something weird happened and this code is not what we think it should be'); end
                
                if codes(loc)==511
                    tmp=tmp+1; % increment both                    
                elseif codes(loc)==510;
                    tmp(2)=tmp(2)+1; % just increment the total
                end % if codes(loc)==511
            end % n
            CONTEXT{s}(end+1)=1;
            PERC_COUNT{s}(length(CONTEXT{s}))=tmp(1)./tmp(2).*100;
            IND=IND+TL;
            
        elseif ismember(ECODE(IND), [520; 521])
            codes=[520; 521];
            tmp=zeros(1,2);
            % if this is a potential lead-ape train
            for n=1:TL
                [tf loc]=ismember(ECODE(IND+n-1), codes);
                if ~tf, error('Something weird happened and this code is not what we think it should be'); end
                
                if codes(loc)==521
                    tmp=tmp+1; % increment both                    
                elseif codes(loc)==520;
                    tmp(2)=tmp(2)+1; % just increment the total
                end % if codes(loc)==511
            end % n
            CONTEXT{s}(end+1)=2;
            PERC_COUNT{s}(length(CONTEXT{s}))=tmp(1)./tmp(2).*100;
            IND=IND+TL;
        else 
            % if nothing matches, then move on to the next event
            IND=IND+1; 
        end % if ismember(ECOD....      

    end % whilte IND<length(ECODE)
    
end % s=1:size(SID,1)

%% NOW, GET WHAT WE'RE ACTUALLY AFTER
OUT=zeros(size(SID,1), P+1,2);
for s=1:size(SID,1)
    
    context=CONTEXT{s};
    perc_count=PERC_COUNT{s};
    for i=P+1:length(context)
        % Only look at lead-ape trains
        %   I think this is the right thing to do ...
        if context(i)==1 
            IND=i-(P):i-1;
            tmp=context(IND);
            tmp=length(find(context(IND)==1))+1; 
            OUT(s,tmp,1)=OUT(s,tmp,1)+perc_count(i);
            OUT(s,tmp,2)=OUT(s,tmp,2)+1;
        end % if context(i) ==1
    end % 
end % 

% GET AVERAGE
OUT=OUT(:,:,1)./OUT(:,:,2); 