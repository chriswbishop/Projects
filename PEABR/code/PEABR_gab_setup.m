function jobs=PEABR_gab_setup(SID, EXPID)
%% DESCRIPTION:
%
%   GAB setup file for Precedence Effect Auditory Brainstem Response
%   (PEABR) study.  
%
% INPUT:
%   
%   SID:    vertically concatenated subject IDs (e.g. SID=strvcat('s2611',
%           's2615')).
%   EXPID:  string, experiment ID (e.g. EXPID='Exp07'); 
%
% OUTPUT:
%
%   jobs:   jobs structure. 
%

studyDir=['/home/cwbishop/projects/PEABR/' EXPID '/'];

jobs={};

for s=1:size(SID)
    sid=deblank(SID(s,:));
    subDir=fullfile(studyDir,sid);
    
    %% UNPACK (unpack)
    %
    %   This job moves data from a zipped tarball (.tgz) file into the
    %   specified directories.  Files with specific extensions are moved to
    %   specific folders.  For instance, *.bdf files will be moved to the
    %   'eeg' directory for that subject, while *.log files will be moved
    %   to the 'behavior' directory, etc.  
    UNPACK=gab_emptyjob;
    UNPACK.jobName='UNPACK';
    UNPACK.jobDir=fullfile(subDir, 'jobs');
    UNPACK.task{end+1}=struct(...
        'func',@gab_task_unpack,...
        'args',struct(...
            'source',fullfile(studyDir,'sandbox',[sid '.tgz']),...
            'destination',{{fullfile(subDir, 'eeg'), fullfile(subDir,'behavior')}},...
            'filter',{{['*' sid '*.bdf'], ['*' sid '*.log']}}, ...
            'directories', {{fullfile(subDir, 'eeg'), fullfile(subDir,'behavior')}}));
    
%% GENERAL PREPROCESSING JOB

    %% GPREP
    GPREP=gab_emptyjob;
    GPREP.jobName='GPREP';
    GPREP.jobDir=fullfile(subDir, 'jobs');
    GPREP.parent={fullfile(UNPACK.jobDir,[UNPACK.jobName '.mat'])};
    GPREP.QOPTS='-l mem_free=12G';
    
    % Load environmental variables
    GPREP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Trim data file
    GPREP.task{end+1}=struct(...
        'func',@gab_task_bdf_trim,...
        'args', struct( ...
            'IN', fullfile(subDir, 'eeg', [sid '_PEABR.bdf']), ...
            'OUT', fullfile(subDir, 'eeg', [sid '_PEABR_trim.bdf']), ...
            'CHANNELS', strvcat('A5', 'EXG5', 'EXG6', 'Status')));
    
    % Import BDF
    GPREP.task{end+1}=struct(...
        'func',@gab_task_eeg_loadbdf,...
        'args',struct(...
            'file',fullfile(subDir, 'eeg', [sid '_PEABR_trim.bdf']),...
            'ref',[],... 
            'chans',[]));         
    
    % Save dataset
    GPREP.task{end+1}=struct(...
        'func',@gab_task_eeglab_saveset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', [sid '-Preproc.set']));

%% AUDITORY BRAINSTEM RESPONSE (ABR) JOB

    %% ABR ERP, with interpolated event codes
    ABR_ERP=gab_emptyjob;
    ABR_ERP.jobName='ABR_ERP';
    ABR_ERP.jobDir=fullfile(subDir, 'jobs');
    ABR_ERP.parent={fullfile(GPREP.jobDir,[GPREP.jobName '.mat'])};
    ABR_ERP.QOPTS='-l mem_free=12G';
    % Load environmental variables
    ABR_ERP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Load dataset
    ABR_ERP.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadset,...
        'args',struct(...
            'filepath', GPREP.task{end}.args.filepath, ...
            'filename', GPREP.task{end}.args.filename));
      
    % Rereference    
    ABR_ERP.task{end+1}=struct(...
        'func',@gab_task_erplab_eegchanoperator,...
        'args', struct(...
            'formulas', fullfile(studyDir, '..', 'code', 'CHANOPS01.txt') ));
        
    % Epoch, average, etc.
    ABR_ERP.task{end+1}=struct(...
        'func',@PEABR_ERPLAB,...
        'args',struct(...
            'BINLIST', fullfile(studyDir, '..', 'code', 'BIN01.txt'), ...
            'Epoch', [-5 30], ...
            'Baseline', [-5 0], ...
            'threshold', [-50 50], ...
            'artTwin', [-5 30], ... % -100 to 100 msec check for eyeblinks. 
            'typef', 'butter', ...
            'FilterFile', fullfile(studyDir, '..', 'code', 'ABR-Butterworth'), ... % only for PEABR_ABR_ERP
            'FilterBandPass', [100 2000], ... % no additional filtering
            'FilterOrder', 4, ...
            'ERPFilename', fullfile(studyDir, sid, 'analysis', [sid '_ABR_ERP']), ...
            'ERPName', [sid '_ABR_ERP'], ...
            'BINOPS', fullfile(studyDir, '..', 'code', 'BINOPS01.txt'),...
            'boundary', 32766,...
            'chanArray', 1:3, ...
            'artcrite', 1, ...
            'iswavg', 0, ...
            'stdev', 1));   
        
    % Save EEG dataset
    ABR_ERP.task{end+1}=struct(...
        'func',@gab_task_eeglab_saveset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', [sid '-PEABR_ABRERP.set']));

% %% MIDDLE LATENCY RESPONSE (MLR) JOB
% 
%     %% ML ERP   
%     ML_ERP=gab_emptyjob;
%     ML_ERP.jobName='ML_ERP';
%     ML_ERP.jobDir=fullfile(subDir, 'jobs');
%     ML_ERP.parent={fullfile(GPREP.jobDir,[GPREP.jobName '.mat'])};
%     
%     % Load environmental variables
%     ML_ERP.task{end+1}=struct(...
%         'func',@gab_task_envvars,...
%         'args','');
%     
%     % Load dataset
%     ML_ERP.task{end+1}=struct(...
%         'func',@gab_task_eeglab_loadset,...
%         'args',struct(...
%             'filepath', GPREP.task{end}.args.filepath, ...
%             'filename', GPREP.task{end}.args.filename));
%         
% %     % High pass filter
% %     ML_ERP.task{end+1}=struct(...
% %         'func',@gab_task_erplab_basicfilter,...
% %         'args',struct(...
% %             'channels', 1:3, ...
% %             'locutoff', 70, ...
% %             'hicutoff', 0, ...
% %             'filterorder', 2, ...
% %             'typef', 'butter', ...
% %             'remove_dc', 1, ...
% %             'boundary', 32766)); % biosemi default boundary event is 32766    
%     % Rereference    
%     ML_ERP.task{end+1}=struct(...
%         'func',@gab_task_erplab_eegchanoperator,...
%         'args', struct(...
%             'formulas', fullfile(studyDir, '..', 'code', 'CHANOPS01.txt') ));
%         
%     % Epoch, average, etc.
%     ML_ERP.task{end+1}=struct(...
%         'func',@PEABR_ERPLAB,...
%         'args',struct(...
%             'BINLIST', fullfile(studyDir, '..', 'code', 'BIN01.txt'), ...
%             'Epoch', [-5 80], ...
%             'Baseline', [-5 0], ...
%             'threshold', [-50 50], ...
%             'artTwin', [-5 80], ... % -100 to 100 msec check for eyeblinks. 
%             'typef', 'butter', ...
%             'FilterFile', fullfile(studyDir, '..', 'code', 'ABR-Butterworth'), ... % only for PEABR_ABR_ERP
%             'FilterBandPass', [15 2000], ... % no additional filtering
%             'FilterOrder', 4, ...
%             'ERPFilename', fullfile(studyDir, sid, 'analysis', [sid '_ML_ERP']), ...
%             'ERPName', [sid '_ML_ERP'], ...
%             'BINOPS', fullfile(studyDir, '..', 'code', 'BINOPS01.txt'),...
%             'boundary', 32766,...
%             'chanArray', 1:3, ...
%             'artcrite', 1, ...
%             'iswavg', 0, ...
%             'stdev', 1));   
%         
%     % Save EEG dataset
%     ML_ERP.task{end+1}=struct(...
%         'func',@gab_task_eeglab_saveset,...
%         'args',struct(...
%             'filepath', fullfile(subDir, 'analysis'), ...
%             'filename', [sid '-PEABR_MLERP.set']));
        
    if strcmp(EXPID, 'Exp01')==1
        switch sid
            case {'CB'}
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp01.bdf']);
        end % switch
    elseif strcmp(EXPID, 'Exp02B')==1
        GPREP.task{2}.args.CHANNELS=strvcat('A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'EXG1', 'EXG2', 'EXG3', 'EXG4', 'Status');                
        GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '-PEABR_EXP02B.bdf']);
        
        %% NEED TO SAVE AS A MAT FILE BECAUSE pop_saveset tries to save
        %% things in a mat file format that cannot support large files. 
        GPREP.task{4}=struct(...
            'func',@gab_task_savemat,...
            'args', struct(...
                'vars', {{'EEG'}}, ...
                'path', fullfile(subDir, 'analysis'), ...
                'file', [sid '-Preproc.mat'])); 
        
        %% NEED TO LOAD MATFILE INSTEAD OF READING SET
        ABR_ERP.task{2}=struct(...
           'func', @gab_task_load, ...
           'args', struct( ...
                'mats', {{fullfile(GPREP.task{4}.args.path, GPREP.task{4}.args.file)}}));
        
        %% NEED TO CHANGE BINLISTER, BINOPS, AND CHANOPS
        ABR_ERP.task{3}.args.formulas=fullfile(studyDir, '..', 'code', 'CHANOPS_EXP02B_AVGMASTOID.txt');
        ABR_ERP.task{4}.args.BINOPS=fullfile(studyDir, '..', 'code', 'BINOPS_EXP02B.txt');
        ABR_ERP.task{4}.args.BINLIST=fullfile(studyDir, '..', 'code', 'BINS_EXP02B.txt');
        ABR_ERP.task{4}.args.ERPFilename=fullfile(studyDir, sid, 'analysis', [sid '_ABR_ERP_AVGM']);
        ABR_ERP.task{4}.args.ERPName=[sid '_ABRERP_AVGM'];     
        ABR_ERP.task{4}.args.chanArray=1:10; % Filter all 10 channels
        ABR_ERP.task{5}=struct(...
            'func',@gab_task_savemat,...
            'args', struct(...
                'vars', {{'EEG'}}, ...
                'path', fullfile(subDir, 'analysis'), ...
                'file', [sid '-PEABR_ABRERP_AVGM.mat'])); 
        % AVERAGE MASTOID ERP
        ABR_ERP_AVGM=ABR_ERP;
        
        
        switch sid
            case {'CB'}
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '-PEABR_EXP02B-02.bdf']);
        end % switch
        
    elseif strcmp(EXPID, 'Exp02C')==1
        
        %% EXPERIMENT 02C SPECIFIC CHANGES
        % Need to add a few jobs. Here's a complete job list for Experiment
        % 02C
        % 
        %   UNPACK:         unpack data from a TGZ file.  
        %   GPREP_Cz_LE:    Prepare and trim file using just Cz as a
        %                   measurement electrode and the left earlobe (LE)
        %                   as a reference.
        %   GPREP_Cz_RE:    " ", but use right earlobe as reference
        %   GPREP_Cz_LERE:  " ", but use average of left/right earlobe as
        %                   reference
        %   GPREP_Cz_LM:    " ", but use left mastoid as reference
        %   GPREP_Cz_RM:    " ", but use right mastoid as a reference
        %   GPREP_Cz_LMRM:  " ", but use average of left/right mastoid as 
        %                   reference 
        %
        %   GPREP_6CH_LE:   " ", but using average of 6 channels as a
        %                   measurement electrode.
        %   GPREP_6CH_RE:   " "
        %   GPREP_6CH_LERE: " ", but use average of left/right earlobe as
        %                   reference
        %   GPREP_6CH_LM:   " "
        %   GPREP_6CH_RM:   " "
        %   GPREP_6CH_LMRM: " ", but use average of left/right mastoid as
        %                   reference       
        %
        %   ABR_Cz_LE:      Job to create auditory brainstem response based
        %                   on Cz_LE data.
        %   ABR_Cz_RE:      " ", but using Cz_RE data
        %   ABR_Cz_LERE:    " ", but using Cz_LERE data
        %   ABR_Cz_LM:      " ", but using Cz_LM data
        %   ABR_Cz_RM:      " ", but using Cz_RM data
        %   ABR_Cz_LMRM:    " ", but using Cz_LMRM data
        %
        %   ABR_6CH_LE:     " ", but using 6CH_LE data
        %   ABR_6CH_RE:     " ", but using 6CH_RE data
        %   ABR_6CH_LM:     " ", but using 6CH_LM data
        %   ABR_6CH_RM:     " ", but using 6CH-RM data
        %  
        %   MLR XXX
        
        %% GENERAL PREPARATION TEMPLATE
        % Use bdf_ChanOps to do trimming.
        %   -Change function handle
        %   -Remove unnecessary fields
        %   -Add in channel operations
        %   -Add in channel labels
        GPREP.task{2}.func=@gab_task_bdf_ChanOps;
        GPREP.task{2}.args.OUT=fullfile(subDir, 'eeg', [sid '-PEABR_Cz.bdf']);
        GPREP.task{2}.args=rmfield(GPREP.task{2}.args, 'CHANNELS'); 
        GPREP.task{2}.args.CHANOPS={'A1', 'EXG1', 'Status'};
        GPREP.task{2}.args.OCHLAB=GPREP.task{2}.args.CHANOPS;        
        GPREP.task{3}.args.file=GPREP.task{2}.args.OUT; % use output from previous task
        
        % NEED TO SAVE AS A MAT FILE BECAUSE pop_saveset tries to save
        % things in a mat file format that cannot support large files. 
        GPREP.task{end}=struct(...
            'func',@gab_task_savemat,...
            'args', struct(...
                'vars', {{'EEG'}}, ...
                'path', fullfile(subDir, 'analysis'), ...
                'file', [sid '-Preproc-A1.mat'])); 
        
       
        
        %% NEED TO LOAD MATFILE INSTEAD OF READING SET
        ABR_ERP.task{2}=struct(...
           'func', @gab_task_load, ...
           'args', struct( ...
                'mats', {{fullfile(GPREP.task{end}.args.path, GPREP.task{end}.args.file)}}));
        
        %% NEED TO CHANGE BINLISTER, BINOPS, AND CHANOPS
        ABR_ERP.task{3}.args.formulas=fullfile(studyDir, '..', 'code', 'CHANOPS_EXP02C_CHAN2.txt'); % 
        ABR_ERP.task{4}.args.BINOPS=fullfile(studyDir, '..', 'code', 'BINOPS_EXP02C_01.txt');
        ABR_ERP.task{4}.args.BINLIST=fullfile(studyDir, '..', 'code', 'BINS_EXP02C_01.txt');
        ABR_ERP.task{4}.args.ERPFilename=fullfile(studyDir, sid, 'analysis', [sid '_ABR_ERP_CHAN2']);
        ABR_ERP.task{4}.args.ERPName=[sid '_ABRERP_CHAN2'];     
        ABR_ERP.task{4}.args.chanArray=1:length(GPREP.task{2}.args.CHANOPS)-1; % Filter all channels, except STATUS
        ABR_ERP.task{5}=struct(...
            'func',@gab_task_savemat,...
            'args', struct(...
                'vars', {{'EEG'}}, ...
                'path', fullfile(subDir, 'analysis'), ...
                'file', [sid '-PEABR_ABRERP_CHAN2.mat'])); 
        % AVERAGE MASTOID ERP
%         ABR_ERP_AVGM=ABR_ERP;
        % Reassign event codes
        REASSIGN_INTERP=struct(...
            'func',@PEABR_exp02C_eventcodes,...
            'args',struct(...
                'ICI', 0.25, ...
                'N', 20, ...
                'TBOUND', 3, ...
                'INTERP', true));
        REASSIGN=struct(...
            'func',@PEABR_exp02C_eventcodes,...
            'args',struct(...
                'ICI', [], ...
                'N', [], ...
                'TBOUND', [], ...
                'INTERP', false));
        
        ABR_ERP_INTERP=ABR_ERP;
        ABR_ERP_INTERP.jobName='ABR_ERP_INTERP'; % different job name
        ABR_ERP_INTERP.task{4}.args.ERPFilename=fullfile(studyDir, sid, 'analysis', [sid '_ABR_ERP_INTERP_CHAN2']);
        ABR_ERP_INTERP.task{4}.args.ERPName=[sid '_ABRERP_INTERP_CHAN2'];     
        ABR_ERP_INTERP.task{4}.args.chanArray=1:length(GPREP.task{2}.args.CHANOPS)-1; % Filter all channels, except STATUS
        ABR_ERP_INTERP.task{5}=struct(...
            'func',@gab_task_savemat,...
            'args', struct(...
                'vars', {{'EEG'}}, ...
                'path', fullfile(subDir, 'analysis'), ...
                'file', [sid '-PEABR_ABRERP_INTERP_CHAN2.mat'])); 
        
        % Assign new event codes either with or without event time
        % interpolation. 
        ABR_ERP=INSERT_TASK(ABR_ERP, REASSIGN, 3); 
        ABR_ERP_INTERP=INSERT_TASK(ABR_ERP_INTERP, REASSIGN_INTERP, 3);
        
        
%         ABR_ERP_INTERP=INSERT_TASK(ABR_ERP_INTERP, REASSIGN_INTERP, 3); 
        %% ALSO NEED TO DO CLASSIFICATION JOB
        %   DUMMY JOB FOR RIGHT NOW
%         ABR_ERP.task{end+1}=struct(...
%             'func',@PEABR_classify,...
%             'args', struct(...
%                 'BINS', {{[44] [45]}}, ...                
%                 'T', [[0 1]; [1 2]; [2 3]; [3 4]; [4 5]; [5 6]; [6 7]; [7 8]; [8 9]; [9 10]; [10 11]; [11 12]; [12 13]; [13 14]; [14 15]; [15 16]; [16 17]; [17 18]; [18 19]; [19 20]], ...
%                 'REPS', 200, ...
%                 'CHANNELS', 1, ...
%                 'CHUNK', 1, ...
%                 'SCALE', 0, ...
%                 'REJ', 1)); 
            
        switch sid
            case {'s3160'}
                display('s3160: Have you checked EXG04 (Right earlobe reference)?');
                display('s3160: Peculiar bump around 10 msec post stimulus onset');
                display('s3160: Potential post auricular reflex, consider using earlobe instead of mastoid reference'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (4.5 msec).bdf']);
%                 ABR_ERP.task{4}.args.FilterBandPass=[200 2000]; % trying a slightly different filter because of low frequency bump that's confusing.
                
            case {'s3161'}
                display('s3161: Trials when earphones fell out of place excluded for ?'); 
                display('EXCLUDE THE TRIALS, DUDE!!'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (4.0 msec).bdf']);
                
               % Exclude this session because of earphone issue.
               ABR_ERP.task{3}.args.EXCLUDE=10080:10751;
               ABR_ERP_INTERP.task{3}.args.EXCLUDE=10080:10751;
            case {'s3162'}
                display('s3162: Check trial numbers, I do not think I have enough to use this person for all analyses'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.5 msec).bdf']);                
            case {'s3163'}
                display(['Files merged for ' sid '?']);
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec).bdf']);
                
                % Trim additional data file
                TRIM=GPREP.task{2};
                TRIM.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec)B.bdf']);
                TRIM.args.OUT=fullfile(subDir, 'eeg', [sid '_PEABR_A1(B).bdf']);
                GPREP=INSERT_TASK(GPREP,TRIM,3); 
                
                % Read in both files
                GPREP.task{4}.args.file={GPREP.task{2}.args.OUT GPREP.task{3}.args.OUT};
                
                % MERGE FILES
                MERGE=struct(...
                    'func', @gab_task_eeg_mergeset, ...
                    'args', '');
                GPREP=INSERT_TASK(GPREP, MERGE, 5);                

            case {'s3167'}
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (5.1 msec).bdf']);
            case {'s3173'}
                display('s3173: Inspect EXG2. Notes indicate high noise levels during recording');
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (1.7 msec).bdf']);
            case {'s3174'}
                display('s3174: Check EXG04 before using (high offsets during recording)'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEAB_Exp02C (2.0 msec).bdf']);
            case {'s3175'}
                display('s3175: Did you edit out bad session in EEG file?');
                display('s3175: Check left mastoid.'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (1.5 msec).bdf']);
%                 GPREP.task{2}.args.CHANNELS(2,1:4)='EXG3'; % use left earlobe instead of mastoid
                GPREP.task{2}.args.CHANOPS{2}='EXG3'; % use left earlobe reference instead of mastoid
                
                % Exclude this session because of earphone issue.
                ABR_ERP.task{3}.args.EXCLUDE=4040:4711;
                ABR_ERP_INTERP.task{3}.args.EXCLUDE=4040:4711; 
            case {'s3179'}
                display('s3179: Slow wave ABR. Need different filter settings?'); 
                display('s3179: Potential post auricular reflex, consider using earlobe reference'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.35 msec).bdf']);
            case {'s3180'}
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec).bdf']);
            case {'s3184'}                
                display('s3184: Do not use right mastoid');
                display('s3184: Subject has reports of fading in, double check analysis scripts');
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.75 msec).bdf']);
            case {'s3185'}
                display('s3185: Exclude sessions with earphone slippage'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (5.771 msec).bdf']);
                
                % Exclude sessions with earphone slippage. 
                ABR_ERP.task{3}.args.EXCLUDE=[2021:2692 3367:4079];
                ABR_ERP_INTERP.task{3}.args.EXCLUDE=[2021:2692 3367:4079];
            case {'s3188'}
                display('s3188:Left mastoid noisy, use left earlobe. Confirm this'); 
                display('s3188: Sporadic reports of fading in, typically in Lead-Ape condition'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.8 msec).bdf']);
                
                % Use left earlobe reference instead of left mastoid. 
                GPREP.task{2}.args.CHANOPS{2}='EXG3';
                GPREP.task{2}.args.OCHLAB{2}='EXG3'; 
            case {'s3189'}
                display('s3189: Left mastoid looks noisy at times, try using left earlobe ref instead??');                 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.74 msec).bdf']);
            case {'s3190'}
                display('s3190: with left mastoid reference, see large ... PAMR?'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.55 msec).bdf']);
            case {'s3193'}
                display('s3193: Remove events with right earphone slippage'); 
                display('s3193: Also abserved a large positivity around 12 msec, could be big Pa?'); 
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (7.285 msec).bdf']);                
            case {'s3194'}
                GPREP.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.125 msec).bdf']);
        end % switch
        
        %% GPREP2
        %   This averages over all channels at the vertex (6 channels)
        %
        %   Need to do something slightly different with s3163 since we 
        %   have to merge files. 
        GPREP2=GPREP;
        GPREP2.jobName='GPREP2';
        if strcmp('s3163', sid)==1
            GPREP2.task{2}.args.OUT=fullfile(subDir, 'eeg', [sid '-PEABR_Vertex.bdf']);
            GPREP2.task{2}.args.CHANOPS={'(A1+A2+A3+A4+A5+A6)./6', GPREP.task{2}.args.CHANOPS{2}, 'Status'}; 
            GPREP2.task{2}.args.OCHLAB={'Vertex', 'Reference', 'Status'};
            GPREP2.task{3}=GPREP2.task{2};
            GPREP2.task{3}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec)B.bdf']); 
            GPREP2.task{3}.args.OUT=fullfile(subDir, 'eeg', [sid '-PEABR_Vertex(B).bdf']);
            GPREP2.task{4}.args.file={GPREP2.task{2}.args.OUT GPREP2.task{3}.args.OUT};
            GPREP2.task{end}.args.file=[sid '-Preproc-Vertex.mat']; 
        else           
            GPREP2.task{2}.args.OUT=fullfile(subDir, 'eeg', [sid '-PEABR_Vertex.bdf']); 
            GPREP2.task{2}.args.CHANOPS={'(A1+A2+A3+A4+A5+A6)./6', GPREP.task{2}.args.CHANOPS{2}, 'Status'}; 
            GPREP2.task{2}.args.OCHLAB={'Vertex', 'Reference', 'Status'}; 
            GPREP2.task{3}.args.file=GPREP2.task{2}.args.OUT; % use previous file
            GPREP2.task{end}.args.file=[sid '-Preproc-Vertex.mat']; 
        end % if strcmp
        %% ABR_ERP_Vertex
        %   Same as ABR_ERP, but averaged over all vertex electrodes
        %
        %   -Change loaded data file
        ABR_ERP_Vertex=ABR_ERP;
        ABR_ERP_Vertex.jobName='ABR_ERP_Vertex';   
        ABR_ERP_Vertex.parent={fullfile(GPREP2.jobDir,[GPREP2.jobName '.mat'])};
        ABR_ERP_Vertex.task{2}.args.mats={fullfile(GPREP2.task{end}.args.path, GPREP2.task{end}.args.file)};
        ABR_ERP_Vertex.task{5}.args.ERPFilename=fullfile(subDir, 'analysis', [sid '_ABR_ERP_Vertex_CHAN2']);
        ABR_ERP_Vertex.task{5}.args.ERPName=[sid '_ABRERP_Vertex_CHAN2']; 
        ABR_ERP_Vertex.task{6}.args.file=[sid '-PEABR_ABRERP_Vertex_CHAN2.mat']; 
        
        %% ABR_ERP_INTERP_Vertex
        %   Same as ABR_ERP_INTERP, but signal averaged over all vertex
        %   electrodes
        ABR_ERP_INTERP_Vertex=ABR_ERP_INTERP; 
        ABR_ERP_INTERP_Vertex.jobName='ABR_ERP_INTERP_Vertex'; 
        ABR_ERP_INTERP_Vertex.parent={fullfile(GPREP2.jobDir,[GPREP2.jobName '.mat'])};
        ABR_ERP_INTERP_Vertex.task{2}.args.mats={fullfile(GPREP2.task{end}.args.path, GPREP2.task{end}.args.file)};
        ABR_ERP_INTERP_Vertex.task{5}.args.ERPFilename=fullfile(subDir, 'analysis', [sid '_ABR_ERP_INTERP_Vertex_CHAN2']);
        ABR_ERP_INTERP_Vertex.task{5}.args.ERPName=[sid '_ABRERP_INTERP_Vertex_CHAN2']; 
        ABR_ERP_INTERP_Vertex.task{6}.args.file=[sid '-PEABR_ABRERP_INTERP_Vertex_CHAN2.mat']; 
    end %if
    
    jobs{end+1}=UNPACK; 
    jobs{end+1}=GPREP;
    jobs{end+1}=GPREP2; 
    jobs{end+1}=ABR_ERP;
%     jobs{end+1}=ABR_ERP_INTERP;
%     jobs{end+1}=ABR_ERP_Vertex;
%     jobs{end+1}=ABR_ERP_INTERP_Vertex;
%     jobs{end+1}=ML_ERP;
end % s

end % function

function job=INSERT_TASK(job, task, ind)
%% DESCRIPTION
%
% INPUT:
%
%   job
%   task
%   ind
%
% OUTPUT:
%
%   job
%
% Bishop, Christopher W.
%   UC Davis 
%   Miller Lab 2011 
%   cwbishop@ucdavis.edu

    %% COPY HEADER INFO
    tjob=gab_emptyjob;
    tjob.jobName=job.jobName;
    tjob.jobDir=job.jobDir;
    tjob.parent=job.parent;
    
    
    if isfield(job, 'QOPTS')
        tjob.QOPTS=job.QOPTS;
    end % 
    
    %% INSERT TASK
    for i=1:length(job.task)        
        if i==ind
            tjob.task{end+1}=task;
            tjob.task{end+1}=job.task{i};
        else
            tjob.task{end+1}=job.task{i};
        end % if
    end % i   
    
    %% COPY MODIFIED JOB
    job=tjob;
end % INSERT_TASK