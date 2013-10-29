function jobs=PEABR_Exp02C_gab_setup(SID, EXPID)
%% DESCRIPTION:
%
%   We absolutely needed a branch point for Exp02C.  It was getting
%   too complicated to try and work Exp02C to play nice with the setup files
%   for all previous experiments.
%
% INPUT
%
% OUTPUT

studyDir=['/home/cwbishop/projects/PEABR/' EXPID '/'];

jobs={};

%% CREATE JOBS FOR EACH SUBJECT
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

    %% GPREP_Cz_LE
    GPREP_Cz_LE=gab_emptyjob;
    GPREP_Cz_LE.jobName='GPREP_Cz_LE';
    GPREP_Cz_LE.jobDir=fullfile(subDir, 'jobs');
    GPREP_Cz_LE.parent={fullfile(UNPACK.jobDir,[UNPACK.jobName '.mat'])};
    
    % Load environmental variables
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Trim and reference data BDF with BDF_CHANOPS
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_bdf_ChanOps,...
        'args', struct( ...
            'IN', fullfile(subDir, 'eeg', [sid '_PEABR.bdf']), ...
            'OUT', fullfile(subDir, 'eeg', [sid '_Cz_LE.bdf']), ...
            'CHANOPS', {{'A1 - EXG3', 'Status'}}, ...
            'OCHLAB', {{'Cz-LE', 'Status'}}));
    
    % Import trimmed/referenced BDF
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_eeg_loadbdf,...
        'args',struct(...
            'file', GPREP_Cz_LE.task{end}.args.OUT,... % use whatever output was from previous step
            'ref',[],... 
            'chans',[]));         
    
    % Save dataset
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_eeglab_saveset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', [sid '-Cz_LE.set']));

        
%% AUDITORY BRAINSTEM RESPONSE (ABR) JOB

    %% ABR ERP
    ABR_Cz_LE=gab_emptyjob;
    ABR_Cz_LE.jobName='ABR_Cz_LE';
    ABR_Cz_LE.jobDir=fullfile(subDir, 'jobs');
    ABR_Cz_LE.parent={fullfile(GPREP_Cz_LE.jobDir,[GPREP_Cz_LE.jobName '.mat'])};

    % Load environmental variables
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Load dataset
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadset,...
        'args',struct(...
            'filepath', GPREP_Cz_LE.task{end}.args.filepath, ...
            'filename', GPREP_Cz_LE.task{end}.args.filename));

    % Reassign and cleanup event codes
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@PEABR_exp02C_eventcodes,...
        'args',struct(...
            'ICI', 0.25, ...
            'N', 20, ...
            'TBOUND', 3, ...
            'INTERP', true, ...
            'EXCLUDE', [])); 
        
    % Epoch, average, etc.
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@PEABR_ERPLAB,...
        'args',struct(...
            'BINLIST', fullfile(studyDir, '..', 'code', 'BINS_EXP02C_01.txt'), ...
            'Epoch', [-5 30], ...
            'Baseline', [-5 0], ...
            'threshold', [-50 50], ...
            'artTwin', [-5 30], ...
            'typef', 'butter', ...
            'FilterFile', fullfile(studyDir, '..', 'code', 'ABR-Butterworth'), ... % only for PEABR_ABR_ERP
            'FilterBandPass', [100 2000], ...
            'FilterOrder', 4, ...
            'ERPFilename', fullfile(studyDir, sid, 'analysis', [sid '_ABR_Cz_LE']), ...
            'ERPName', [sid '_ABR_Cz_LE'], ...
            'BINOPS', fullfile(studyDir, '..', 'code', 'BINOPS_EXP02C_01.txt'),...
            'boundary', 32766,...
            'chanArray', 1, ...
            'artcrite', 1, ...
            'iswavg', 0, ...
            'stdev', 1));   
        
    % Save EEG dataset
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_eeglab_saveset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', [sid '_ABR_Cz_LE.set']));
        
    switch sid
        case {'s3160'}
            display('s3160: Have you checked EXG04 (Right earlobe reference)?');
            display('s3160: Peculiar bump around 10 msec post stimulus onset');
            display('s3160: Potential post auricular reflex, consider using earlobe instead of mastoid reference'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (4.5 msec).bdf']);

                
        case {'s3161'}
            display('s3161: Trials when earphones fell out of place excluded for ?'); 
            display('EXCLUDE THE TRIALS, DUDE!!'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (4.0 msec).bdf']);
                
            % Exclude this session because of earphone issue.
            ABR_Cz_LE.task{3}.args.EXCLUDE=10080:10751;
        case {'s3162'}
            display('s3162: Check trial numbers, I do not think I have enough to use this person for all analyses'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.5 msec).bdf']);                
        case {'s3163'}
            display(['Files merged for ' sid '?']);
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec).bdf']);
%                 
            % Trim additional data file
            TRIM=GPREP_Cz_LE.task{2};
            TRIM.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec)B.bdf']);
            TRIM.args.OUT=fullfile(subDir, 'eeg', [sid '_Cz_LE(B).bdf']);
            GPREP_Cz_LE=gab_insert_task(GPREP_Cz_LE,TRIM,3); 
                
            % Read in both files
            GPREP_Cz_LE.task{4}.args.file={GPREP_Cz_LE.task{2}.args.OUT GPREP_Cz_LE.task{3}.args.OUT};
%                
            % MERGE FILES
            MERGE=struct(...
                'func', @gab_task_eeg_mergeset, ...
                'args', '');
            GPREP_Cz_LE=gab_insert_task(GPREP_Cz_LE, MERGE, 5);                
            
        case {'s3167'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (5.1 msec).bdf']);
        case {'s3173'}
            display('s3173: Inspect EXG2. Notes indicate high noise levels during recording');
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (1.7 msec).bdf']);
        case {'s3174'}
            display('s3174: Check EXG04 before using (high offsets during recording)'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEAB_Exp02C (2.0 msec).bdf']);
        case {'s3175'}
            display('s3175: Did you edit out bad session in EEG file?');
            display('s3175: Check left mastoid.'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (1.5 msec).bdf']);
            
            % Exclude this session because of earphone issue.
            ABR_Cz_LE.task{3}.args.EXCLUDE=4040:4711;
        case {'s3179'}
            display('s3179: Slow wave ABR. Need different filter settings?'); 
            display('s3179: Potential post auricular reflex, consider using earlobe reference'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.35 msec).bdf']);
        case {'s3180'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.0 msec).bdf']);
        case {'s3184'}                
            display('s3184: Do not use right mastoid');
            display('s3184: Subject has reports of fading in, double check analysis scripts');
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.75 msec).bdf']);
        case {'s3185'}
            display('s3185: Exclude sessions with earphone slippage'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (5.771 msec).bdf']);
               
            % Exclude sessions with earphone slippage. 
            ABR_Cz_LE.task{3}.args.EXCLUDE=[2021:2692 3367:4079];
        case {'s3188'}
            display('s3188:Left mastoid noisy, use left earlobe. Confirm this'); 
            display('s3188: Sporadic reports of fading in, typically in Lead-Ape condition'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.8 msec).bdf']);
             
        case {'s3189'}
            display('s3189: Left mastoid looks noisy at times, try using left earlobe ref instead??');                 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.74 msec).bdf']);
        case {'s3190'}
            display('s3190: with left mastoid reference, see large ... PAMR?'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.55 msec).bdf']);
        case {'s3193'}
            display('s3193: Remove events with right earphone slippage'); 
            display('s3193: Also abserved a large positivity around 12 msec, could be big Pa?'); 
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (7.285 msec).bdf']);                
        case {'s3194'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.125 msec).bdf']);
        case {'s3195'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (3.7 msec).bdf']);
        case {'s3196'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (4.533 msec).bdf']);
        case {'s3199'}
            display('s3199: BDF files merged?');      
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.1 msec).bdf']);
%                 
            % Trim additional data file
            TRIM=GPREP_Cz_LE.task{2};
            TRIM.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.1 msec)B.bdf']);
            TRIM.args.OUT=fullfile(subDir, 'eeg', [sid '_Cz_LE(B).bdf']);
            GPREP_Cz_LE=gab_insert_task(GPREP_Cz_LE,TRIM,3); 
                
            % Read in both files
            GPREP_Cz_LE.task{4}.args.file={GPREP_Cz_LE.task{2}.args.OUT GPREP_Cz_LE.task{3}.args.OUT};
%                
            % MERGE FILES
            MERGE=struct(...
                'func', @gab_task_eeg_mergeset, ...
                'args', '');
            GPREP_Cz_LE=gab_insert_task(GPREP_Cz_LE, MERGE, 5);                
            
        case{'s31100'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C (2.5 msec).bdf']);
            
        case {'s31101'}
            display('s31101: Potential cardiac artifact in EXG3?');  
        case {'s0000'}
            GPREP_Cz_LE.task{2}.args.IN=fullfile(subDir, 'eeg', [sid '_PEABR_Exp02C.bdf']);
            ABR_Cz_LE.task{3}.args.INTERP=0;
%             ABR_Cz_LE.task={ABR_Cz_LE.task{[1 2 4 5]}}; 
            
    end % switch      

    %%% CREATE ADDITIONAL JOBS
    %   This approach will break for GPREP if several files are merged.
    %   Need a different approach for these subjects (s3163 and s3199).
    
    %% GPREP_Cz_(REFERENCE)
    
    % Earlobes
    GPREP_Cz_RE=MODIFY_GPREP(GPREP_Cz_LE, '_Cz_RE', 'Cz-RE', '(A1-EXG4)', sid, subDir);  
    GPREP_Cz_LERE=MODIFY_GPREP(GPREP_Cz_LE, '_Cz_LERE', 'Cz-LERE', '(A1 - ((EXG3+EXG4)./2) )', sid, subDir);
    
    % Mastoids
    GPREP_Cz_LM=MODIFY_GPREP(GPREP_Cz_LE, '_Cz_LM', 'Cz-LM', '(A1-EXG1)', sid, subDir);  
    GPREP_Cz_RM=MODIFY_GPREP(GPREP_Cz_LE, '_Cz_RM', 'Cz-RM', '(A1-EXG2)', sid, subDir);  
    GPREP_Cz_LMRM=MODIFY_GPREP(GPREP_Cz_LE, '_Cz_LMRM', 'Cz-LMRM', '(A1 - ((EXG1+EXG2)./2) )', sid, subDir);  
    
    % 6 Channel Signal, Earlobes
    GPREP_6CH_LE=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_LE', '6CH-LE', '((A1+A2+A3+A4+A5+A6)./6) - EXG3', sid, subDir);
    GPREP_6CH_RE=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_RE', '6CH-RE', '((A1+A2+A3+A4+A5+A6)./6) - EXG4', sid, subDir);
    GPREP_6CH_LERE=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_LERE', '6CH-LERE', '((A1+A2+A3+A4+A5+A6)./6) - ((EXG3+EXG4 )./2)', sid, subDir);
    
    % 6 Channel signal, mastoids
    GPREP_6CH_LM=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_LM', '6CH-LM', '((A1+A2+A3+A4+A5+A6)./6) - EXG1', sid, subDir);
    GPREP_6CH_RM=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_RM', '6CH-RM', '((A1+A2+A3+A4+A5+A6)./6) - EXG2', sid, subDir);
    GPREP_6CH_LMRM=MODIFY_GPREP(GPREP_Cz_LE, '_6CH_LMRM', '6CH-LMRM', '((A1+A2+A3+A4+A5+A6)./6) - ((EXG1+EXG2 )./2)', sid, subDir);
    
    
    %% CREATE ADDITIONAL ABR JOBS
    ABR_Cz_RE=MODIFY_ABR(ABR_Cz_LE, '_Cz_RE', sid, subDir);
    ABR_Cz_LERE=MODIFY_ABR(ABR_Cz_LE, '_Cz_LERE', sid, subDir);
    ABR_Cz_LM=MODIFY_ABR(ABR_Cz_LE, '_Cz_LM', sid, subDir);
    ABR_Cz_RM=MODIFY_ABR(ABR_Cz_LE, '_Cz_RM', sid, subDir);
    ABR_Cz_LMRM=MODIFY_ABR(ABR_Cz_LE, '_Cz_LMRM', sid, subDir);

    ABR_6CH_LE=MODIFY_ABR(ABR_Cz_LE, '_6CH_LE', sid, subDir); 
    ABR_6CH_RE=MODIFY_ABR(ABR_Cz_LE, '_6CH_RE', sid, subDir);
    ABR_6CH_LERE=MODIFY_ABR(ABR_Cz_LE, '_6CH_LERE', sid, subDir);
    ABR_6CH_LM=MODIFY_ABR(ABR_Cz_LE, '_6CH_LM', sid, subDir);
    ABR_6CH_RM=MODIFY_ABR(ABR_Cz_LE, '_6CH_RM', sid, subDir);
    ABR_6CH_LMRM=MODIFY_ABR(ABR_Cz_LE, '_6CH_LMRM', sid, subDir);
    
    % MLR JOBS
    MLR_6CH_LERE=ABR2MLR(ABR_6CH_LERE, '_6CH_LERE', sid, subDir, [15 2000], [-5 60]); 
    
%% JOBS
%     jobs{end+1}=UNPACK;

% %     jobs{end+1}=GPREP_Cz_LE;   
% %     jobs{end+1}=GPREP_Cz_RE;
% %     jobs{end+1}=GPREP_Cz_LERE;
% %     jobs{end+1}=GPREP_Cz_LM;
% %     jobs{end+1}=GPREP_Cz_RM;
% %     jobs{end+1}=GPREP_Cz_LMRM;

%     jobs{end+1}=GPREP_6CH_LE;
%     jobs{end+1}=GPREP_6CH_RE;
%     jobs{end+1}=GPREP_6CH_LERE;
%     jobs{end+1}=GPREP_6CH_LM;
%     jobs{end+1}=GPREP_6CH_RM;
%     jobs{end+1}=GPREP_6CH_LMRM;
% 
% %     jobs{end+1}=ABR_Cz_LE;
% %     jobs{end+1}=ABR_Cz_RE;
% %     jobs{end+1}=ABR_Cz_LERE;
% %     jobs{end+1}=ABR_Cz_LM;
% %     jobs{end+1}=ABR_Cz_RM;
% %     jobs{end+1}=ABR_Cz_LMRM;
% 
%     jobs{end+1}=ABR_6CH_LE;
%     jobs{end+1}=ABR_6CH_RE;
    jobs{end+1}=ABR_6CH_LERE;
%     jobs{end+1}=ABR_6CH_LM;
%     jobs{end+1}=ABR_6CH_RM;
%     jobs{end+1}=ABR_6CH_LMRM;

    % MLR Jobs
%     jobs{end+1}=MLR_6CH_LERE; 
    
    % clear jobs
    clear UNPACK;
    clear GPREP_Cz_LE GPREP_Cz_RE GPREP_Cz_LERE
    clear GPREP_Cz_LM GPREP_Cz_RM GPREP_Cz_LMRM
    clear ABR_Cz_LE ABR_Cz_RE ABR_Cz_LERE
    clear ABR_Cz_LM ABR_Cz_RM ABR_Cz_LMRM
    clear MLR_6CH_LERE; 
    clear GPREP_6CH_LE GPREP_6CH_RE GPREP_6CH_LERE
    clear GPREP_6CH_LM GPREP_6CH_RM GPREP_6CH_LMRM
    clear ABR_6CH_LE ABR_6CH_RE ABR_6CH_LERE
    clear ABR_6CH_LM ABR_6CH_RM ABR_6CH_LMRM
    
end % s

%% GROUP JOBS
GSID='GROUP';
GroupDir=fullfile(studyDir, GSID);

G_ABR_6CH_LERE=gab_emptyjob;
G_ABR_6CH_LERE.jobName='Group ABR_LERE';
G_ABR_6CH_LERE.jobDir=fullfile(GroupDir, 'jobs');
G_ABR_6CH_LERE.parent=''; 
clear parent; 
    % Load environmental variables
    G_ABR_6CH_LERE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    G_ABR_6CH_LERE.task{end+1}=struct(...
        'func',@MSPE_GROUP_ERP, ...
        'args',struct( ...
            'sid', SID, ...
            'studyDir', studyDir, ...
            'iswavg', 0, ...
            'ERPName', ['G_ABR_6CH_LERE (N=' num2str(size(SID,1)) ')'], ...
            'ERPext', '_ABR_6CH_LERE'));
    G_ABR_6CH_LERE.task{end}.args.outDir=fullfile(studyDir, GSID, 'analysis', [GSID G_ABR_6CH_LERE.task{end}.args.ERPext '(N=' num2str(size(SID,1)) ')']);
    
%     jobs{end+1} = G_ABR_6CH_LERE;
end % PEABR_Exp02C_gab_setup

function JOB=MODIFY_GPREP(JOB, STR, CHLAB, EQ, sid, subDir)
%% DESCRIPTION:
%
%   Function to modify a general preparation (GPREP) scaffold to work with
%   different references. Some special instructions are built in for
%   subjects s3163 and s3199 who need to have files merged.
%
% INPUT:
%
%   job:    job structure
%   STR:    String to append to job names, etc.
%   CHLAB:  Channel label (e.g. 'Cz-RE')
%   EQ:     Equation for channel operations (e.g., 'A1-EXG4')
%   sid:    subject ID
%
% OUTPUT:

    % Change bdf_ChanOps
    ARGS=struct();
    JNAME=['GPREP' STR]; % change job name
    TASK='gab_task_bdf_ChanOps'; % function handle name to change
    ARGS.OUT=fullfile(subDir, 'eeg', [sid STR '.bdf']); % output for
    ARGS.CHANOPS={EQ 'Status'};
    ARGS.OCHLAB={CHLAB 'Status'};
    JOB=gab_replace_task_args(JOB, TASK, ARGS, JNAME); 

    % Change gab_task_eeg_loadbdf
    ARGS=struct();
    TASK='gab_task_eeg_loadbdf'; 
    ARGS.file=fullfile(subDir, 'eeg', [sid STR '.bdf']); 
    JOB=gab_replace_task_args(JOB, TASK, ARGS, JNAME); 
    
    % Change gab_task_eeglab_saveset
    ARGS=struct();
    TASK='gab_task_eeglab_saveset'; 
    ARGS.filename=[sid '-' STR(2:end)]; 
    JOB=gab_replace_task_args(JOB, TASK, ARGS, JNAME); 

    % Some special processing for subjects with multiple files that are
    % later merged. Both have a similar task order, so fix should be pretty
    % simple, I think .
    if ~isempty(strmatch(sid, {'s3163', 's3199'}))
        
        % Patch bdf_chanops
        ARGS=struct();
        [pathstr, name, ext, versn] = fileparts(JOB.task{2}.args.OUT);
        ARGS.OUT=fullfile(pathstr, [name '(B)', '.bdf']); 
        TASK=3;
        JOB=gab_replace_task_args(JOB, TASK, ARGS); 
        
        % Patch BDF file loading
        ARGS=struct();
        ARGS.file={JOB.task{2}.args.OUT JOB.task{3}.args.OUT};
        TASK='gab_task_eeg_loadbdf';
        JOB=gab_replace_task_args(JOB, TASK, ARGS);        
        
   end % ~isempty(strmatch ...
   
end % JOB=MODIFY_GPREP

function JOB=MODIFY_ABR(JOB, STR, sid, subDir)
%% DESCRIPTION:
%
%   Function to modify ABR jobs
%   
% INPUT:
%
%   JOB:    job structure
%   STR:    string to append to job names, etc.
%   sid:    subject ID
%
% OUTPUT:
%
%
    %% ABR_Cz_RE
    JNAME=['ABR' STR];

    % Modify parent
    [pathstr, name, ext, versn] = fileparts(JOB.parent{1});
    JOB.parent={fullfile(pathstr, [name(1:end-6) STR ext])};
    
    % Modify gab_task_eeglab_loadset
    ARGS=struct();
    ARGS.filename=[sid '-' STR(2:end) '.set'];
    TASK='gab_task_eeglab_loadset';
    JOB=gab_replace_task_args(JOB, TASK, ARGS, JNAME); 
    
    % Modify PEABR_ERPLAB
    ARGS=struct();
    ARGS.ERPFilename=fullfile(subDir, 'analysis', [sid '_ABR' STR]);
    ARGS.ERPName=[sid '_ABR' STR];
    TASK='PEABR_ERPLAB';
    JOB=gab_replace_task_args(JOB, TASK, ARGS); 
    
    % Modify gab_task_eeglab_saveset
    ARGS=struct();
    ARGS.filename=[sid '_ABR' STR '.set'];
    TASK='gab_task_eeglab_saveset';
    JOB=gab_replace_task_args(JOB, TASK, ARGS);
    
end % function JOB=MODIFY_ABR

function JOB=ABR2MLR(JOB, STR, sid, subDir, F, TWIN)
%% DESCRIPTION:
%
%   Function to convert an ABR scaffold to MLR.
%
% INPUT:
%
%   F:
%
% OUTPUT:
%
%   JOB

     %% ABR_Cz_RE
    JNAME=['MLR' STR];
    JOB.jobName=JNAME;
           
    % Modify PEABR_ERPLAB
    ARGS=struct();
    ARGS.ERPFilename=fullfile(subDir, 'analysis', [sid '_MLR' STR]);
    ARGS.ERPName=[sid '_MLR' STR];
    ARGS.FilterBandPass=F;
    ARGS.Epoch=TWIN;
    ARGS.artTwin=TWIN;
    TASK='PEABR_ERPLAB';
    JOB=gab_replace_task_args(JOB, TASK, ARGS); 
    
    % Modify gab_task_eeglab_saveset
    ARGS=struct();
    ARGS.filename=[sid '_MLR' STR '.set'];
    TASK='gab_task_eeglab_saveset';
    JOB=gab_replace_task_args(JOB, TASK, ARGS);
end % JOB=ABR2MLR
