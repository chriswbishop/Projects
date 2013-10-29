function MSPE_EEG_ET_analysis(SID, LD, SAMPLE_DATA_DV)
%% DESCRIPTION:
%
%   Eye Tracking Analysis code for MultiSensory Precedence Effect
%   ElectroEncephaloGraphy study.  
%
% INPUT:
%
%   SID:
%   DVINT:
%
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
MSPE_DEFS; 
SMP_TWIN=DEF_SMP_TWIN;
if ~exist('SAMPLE_DATA_DV', 'var') || isempty(SAMPLE_DATA_DV), SAMPLE_DATA_DV=[1 2]; end
% if ~exist('TRIAL_DATA_DV', 'var') || isempty(SAMPLE_DATA_DV), SAMPLE_DATA_DV=[1 2]; end
TRIAL_DATA_DV=1:5;

% if ~exist('DV', 'var') || isempty(DV), DV=1; end 
if ~exist('DVINT', 'var') || isempty(DVINT), DVINT=NaN; end 
if ~exist('LD', 'var') || isempty(LD), LD=0; end % start from scratch by default.

for s=1:size(SID,1)
    
    sid=deblank(SID(s,:)); 
    display(sid);
    
    %% SAMPLE REPORT (SMP)
    %   Read it in
    %       But only if user doesn't want to load in old stuff.
    
    % Only read in the data if we have to.
    if LD
        try
            display(['Attempting to load ' sid '_SMP']); 
            load([sid '_ET'], 'SMP_DATA', 'SMP_HDR', 'SMP_EX', ...
                'TRL_DATA', 'TRL_HDR', 'TRL_EX');
            SMP_DATA; % hacks a hairball if it ain't there.
            TRL_DATA;             
        catch 
            display('That shit didn''''t work!'); 
            [SMP_DATA SMP_HDR SMP_EX]=ET_read(fullfile('..', 'EyeTracking', [sid '_SMP.txt']), SAMPLE_DATA_DV, DVINT); 
            [TRL_DATA TRL_HDR TRL_EX]=ET_read(fullfile('..', 'EyeTracking', [sid '_TRL.txt']), TRIAL_DATA_DV, 0); 
        end % try
    else
        [SMP_DATA SMP_HDR SMP_EX]=ET_read(fullfile('..', 'EyeTracking', [sid '_SMP.txt']), SAMPLE_DATA_DV, DVINT);
        [TRL_DATA TRL_HDR TRL_EX]=ET_read(fullfile('..', 'EyeTracking', [sid '_TRL.txt']), TRIAL_DATA_DV, 0); 
    end % ~OW
    
    % BREAK IT UP INTO TRIALS
    SMP_SDATA=ET_SORT(SMP_DATA, SMP_HDR, 'TRIAL_INDEX');  
        
    % DIGEST INTO EASIER TO USE VARIABLES       
    %   SMP_TWIN loaded from MSPE_DEFS
    [RIGHT_GAZE_X RIGHT_GAZE_Y RIGHT_IN_BLINK RIGHT_IN_SACCADE SMP_SDATA SMP_TIME SMP_BLINK_COUNT SMP_SACCADE_COUNT]=MSPE_SMP(SMP_SDATA, SMP_HDR, SMP_TWIN); 
        
    % SAVE DATA
    save([sid '_ET'], 'SMP_DATA', 'SMP_HDR', 'SMP_EX', 'SMP_SDATA', 'RIGHT_GAZE_X', 'RIGHT_GAZE_Y', 'SMP_TWIN', 'SMP_TIME', ...
        'RIGHT_IN_BLINK', 'RIGHT_IN_SACCADE', 'SMP_BLINK_COUNT', 'SMP_SACCADE_COUNT');    
    
    %% TRIAL REPORT
    % Break it up into trials
    %   INDEX instead of TRIAL_INDEX since it's a TRIAL report (makes
    %   sense). 
    TRL_SDATA=ET_SORT(TRL_DATA, TRL_HDR, 'INDEX'); 
    
    % digest into easier things to deal with.
    [AVERAGE_SACCADE_AMPLITUDE SACCADE_COUNT BLINK_COUNT FIXATION_COUNT]=MSPE_TRL(TRL_SDATA, TRL_HDR); 
    
    % save data
    save([sid '_ET'], 'TRL_DATA', 'TRL_HDR', 'TRL_EX', 'TRL_SDATA','AVERAGE_SACCADE_AMPLITUDE', 'SACCADE_COUNT', 'BLINK_COUNT', 'FIXATION_COUNT', '-append'); 
    
end % s=1:size(SID,1)
    
end % MSPE_EEG_ET_analysis

function [RIGHT_GAZE_X RIGHT_GAZE_Y RIGHT_IN_BLINK RIGHT_IN_SACCADE SDATA SMP_TIME SMP_BLINK_COUNT SMP_SACCADE_COUNT]=MSPE_SMP(SDATA, HDR, TWIN)
%% DESCRIPTION
%
%   Create desired variables with data samples. 
%
% INPUT:
%
%   SDATA:
%   HDR:
%
% OUTPUT
%
%   RIGHT_GAZE_X:
%   RIGHT_GAZE_Y:
%   RIGHT_IN_BLINK:
%   RIGHT_IN_SACCADE:
%   SMP_RIGHT_BLINK_COUNT: hasn't been implemented yet, but blink count
%   based on sample data (detecting change)
%   SMP_RIGHT_SACCADE_COUNT: hasn't been implemented yet, but saccade count
%   based on sample data (detecting change)
%   SDATA:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
MSPE_DEFS;
RESP=nNRESP; % from MSPE_DEFS
RIND=RESP+1; % since responses start with 0 (misses), need to move up 1. 
clear nNRESP; 

%% GET DATA INDICES THAT WE'LL NEED
%   Use ET_HDRIND instead of hardcoding the column numbers so it's much
%   more flexible and less prone to errors now and later (when we
%   inevitably change the format of the exported data from the
%   DataViewer). 
XIND=ET_HDRIND(HDR, 'RIGHT_GAZE_X');
YIND=ET_HDRIND(HDR, 'RIGHT_GAZE_Y'); 
TIND=ET_HDRIND(HDR, 'TIMESTAMP'); 
INBLK=ET_HDRIND(HDR, 'RIGHT_IN_BLINK'); 
INSAC=ET_HDRIND(HDR, 'RIGHT_IN_SACCADE'); 

%% SET TIME 0 TO BEGINNING OF TRIAL
for i=1:length(SDATA)                        
    SDATA{i}(:,TIND)=SDATA{i}(:,TIND)-SDATA{i}(1,TIND);
end % i

%% DIGEST INTO MORE MANAGABLE MATRICES
for c=1:length(rCOND)
    for r=1:length(RESP)
        % GRAB DATA
        [SINDEX SSDATA]=ET_SORT_SDATA(SDATA, HDR, 'CONDITION', c, 'NRESP', RESP(r));
        
        % Only go through the trouble if there's any data to worry about. 
        if ~isempty(SSDATA)
            
            % TRIM DATA
            %   Get a chunk of time range.  Keep in mind that this trims
            %   ALL data entries based on missing independent data.  
            [TSSDATA]=ET_TRIM_SDATA(SSDATA, HDR, 'TIMESTAMP', TWIN);
            
            % WHAT IS SAMPLE TIME NOW?
            SMP_TIME=TSSDATA{1}(:,TIND);            
        
            % Declare return and temporary variables
            if ~exist('RIGHT_GAZE_X', 'var'), RIGHT_GAZE_X=nan(size(TSSDATA{1},1), length(rCOND),max(RIND)); end
            if ~exist('RIGHT_GAZE_Y', 'var'), RIGHT_GAZE_Y=nan(size(TSSDATA{1},1), length(rCOND),max(RIND)); end
            if ~exist('RIGHT_IN_BLINK', 'var'), RIGHT_IN_BLINK=nan(size(TSSDATA{1},1), length(rCOND),max(RIND)); end
            if ~exist('RIGHT_IN_SACCADE', 'var'), RIGHT_IN_SACCADE=nan(size(TSSDATA{1},1), length(rCOND),max(RIND)); end
            
            % These are necessarily trial averages, so the first dimension
            % (time) is discarded. 
            if ~exist('SMP_BLINK_COUNT', 'var'), SMP_BLINK_COUNT=nan(1, length(rCOND),max(RIND)); end
            if ~exist('SMP_SACCADE_COUNT', 'var'), SMP_SACCADE_COUNT=nan(1, length(rCOND),max(RIND)); end
            
            % Temporary variables used to store each trial data information.
            right_gaze_x=[];%nan(size(TSSDATA{1},1), length(rCOND),length(RESP)+1, length(TSSDATA)); end
            right_gaze_y=[];%nan(size(TSSDATA{1},1), length(rCOND),length(RESP)+1, length(TSSDATA)); end
            right_in_blink=[]; 
            right_in_saccade=[]; 
            smp_blink_count=[];
            smp_saccade_count=[];
            
            % Parse Data in TSSDATA
            %   TSSDATA has lots of information in it, so go through it and
            %   put all of it into its corresponding matrix. 
            for i=1:length(TSSDATA)
                right_gaze_x(:,c,RIND(r),i)=TSSDATA{i}(:,XIND);
                right_gaze_y(:,c,RIND(r),i)=TSSDATA{i}(:,YIND);
                right_in_blink(:,c,RIND(r),i)=TSSDATA{i}(:,INBLK); 
                right_in_saccade(:,c,RIND(r),i)=TSSDATA{i}(:,INSAC);  %#ok<*AGROW>
                smp_blink_count(:,c,RIND(r),i)=ET_DETECT_CHANGE(TSSDATA(i), INBLK);
                smp_saccade_count(:,c,RIND(r),i)=ET_DETECT_CHANGE(TSSDATA(i), INSAC);
            end % i
            
            % Average Data over trials
            right_gaze_x=nanmean(right_gaze_x,4);
            right_gaze_y=nanmean(right_gaze_y,4);
            right_in_blink=nanmean(right_in_blink,4); 
            right_in_saccade=nanmean(right_in_saccade,4); 
            smp_blink_count=nanmean(smp_blink_count,4);
            smp_saccade_count=nanmean(smp_saccade_count,4); 
            
            % Assign to return variables. 
            RIGHT_GAZE_X(:,c,RIND(r))=right_gaze_x(:,c,RIND(r)); 
            RIGHT_GAZE_Y(:,c,RIND(r))=right_gaze_y(:,c,RIND(r)); 
            
            % Average over RIGHT_IN_BLINK
            %   Originally I planned to SUM the data, but this could lead
            %   to another (uninteresting) source of variance between
            %   subjects since the number of TRIALS per condition/percept
            %   is going to vary considerably across subjects.  Averaging
            %   allows us to account for these differences.
            RIGHT_IN_BLINK(:,c,RIND(r))=right_in_blink(:,c,RIND(r)); 
            RIGHT_IN_SACCADE(:,c,RIND(r))=right_in_saccade(:,c,RIND(r));             
            SMP_BLINK_COUNT(:,c,RIND(r))=smp_blink_count(:,c,RIND(r)); 
            SMP_SACCADE_COUNT(:,c,RIND(r))=smp_saccade_count(:,c,RIND(r)); 
            
        end % if isempty(SDATA)                
    end % r
end % c

end % MSPE_SMP

function [AVERAGE_SACCADE_AMPLITUDE SACCADE_COUNT BLINK_COUNT FIXATION_COUNT]=MSPE_TRL(SDATA, HDR)
%% DESCRIPTION:
%
%   Breaks up information from TRL report into easier to play with
%   variables.
%
%   NOTE: The layout of this function is almost identical to MSPE_SMP. It
%   might be worth modifying this code to work with a generic case since
%   that's less likely to have peculiar bugs (e.g. CB typing in an 'i'
%   instead of a 'c').  Might be more trouble than it's worth, but think
%   about it!
%
% INPUT:
%   
%   TRL_SDATA:
%   TRL_HDR:
%
% OUTPUT:
%
%   AVERAGE_SACCADE_AMPLITUDE
%   SACCADE_COUNT
%   BLINK_COUNT
%   FIXATION_COUNT
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
MSPE_DEFS;
RESP=nNRESP; % from MSPE_DEFS
RIND=RESP+1; % since responses start with 0 (misses), need to move up 1. 
clear nNRESP; 

%% DATA INDICES
%   Grab column indices. 
ASAIND=ET_HDRIND(HDR, 'AVERAGE_SACCADE_AMPLITUDE'); 
SCIND=ET_HDRIND(HDR, 'SACCADE_COUNT');
BCIND=ET_HDRIND(HDR, 'BLINK_COUNT'); 
FCIND=ET_HDRIND(HDR, 'FIXATION_COUNT'); 

for c=1:length(rCOND)
    for r=1:length(RESP)
        % GRAB DATA
        [SINDEX SSDATA]=ET_SORT_SDATA(SDATA, HDR, 'CONDITION', c, 'NRESP', RESP(r));
        
        % Only go through the trouble if there's any data to worry about. 
        if ~isempty(SSDATA)

            % No trimming necessary...I don't think ... so just reset
            % variable and go to town. 
            TSSDATA=SSDATA; 
            % Populate return variables
            if ~exist('AVERAGE_SACCADE_AMPLITUDE', 'var'), AVERAGE_SACCADE_AMPLITUDE=nan(size(TSSDATA{1},1),length(rCOND),max(RIND)); end
            if ~exist('SACCADE_COUNT', 'var'), SACCADE_COUNT=nan(size(TSSDATA{1},1),length(rCOND),max(RIND)); end
            if ~exist('BLINK_COUNT', 'var'), BLINK_COUNT=nan(size(TSSDATA{1},1),length(rCOND),max(RIND)); end
            if ~exist('FIXATION_COUNT', 'var'), FIXATION_COUNT=nan(size(TSSDATA{1},1),length(rCOND),max(RIND)); end

            % Temporary variables used to store each trial data information.
            average_saccade_amplitude=[];%nan(size(TSSDATA{1},1),length(rCOND),max(RIND),1);
            saccade_count=[];%nan(size(TSSDATA{1},1),length(rCOND),max(RIND),1);
            blink_count=[];%nan(size(TSSDATA{1},1),length(rCOND),max(RIND),1);
            fixation_count=[];%nan(size(TSSDATA{1},1),length(rCOND),max(RIND),1);
            
            % Parse Data in TSSDATA            
            for i=1:length(TSSDATA)
                average_saccade_amplitude(:,c,RIND(r),i)=TSSDATA{i}(:,ASAIND);
                saccade_count(:,c,RIND(r),i)=TSSDATA{i}(:,SCIND);
                blink_count(:,c,RIND(r),i)=TSSDATA{i}(:,BCIND);
                fixation_count(:,c,RIND(r),i)=TSSDATA{i}(:,FCIND); 
            end % i
            
            % Average Data over trials
            average_saccade_amplitude=nanmean(average_saccade_amplitude,4);
            saccade_count=nanmean(saccade_count,4);
            blink_count=nanmean(blink_count,4);
            fixation_count=nanmean(fixation_count,4); 
            
            % Assign to return variables
            AVERAGE_SACCADE_AMPLITUDE(:,c,RIND(r))=average_saccade_amplitude(:,c,RIND(r));
            SACCADE_COUNT(:,c,RIND(r))=saccade_count(:,c,RIND(r)); 
            BLINK_COUNT(:,c,RIND(r))=blink_count(:,c,RIND(r)); 
            FIXATION_COUNT(:,c,RIND(r))=fixation_count(:,c,RIND(r)); 
            
        end % if isempty(SDATA)                
    end % r
end % c 

end % MSPE_TRL