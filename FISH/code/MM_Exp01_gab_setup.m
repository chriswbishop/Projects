function jobs=MM_Exp01_gab_setup(SID, EXPID)
%% DESCRIPTION:
%
%   We absolutely needed a branch point for Exp02C.  It was getting
%   too complicated to try and work Exp02C to play nice with the setup files
%   for all previous experiments.
%
% INPUT
%
% OUTPUT

studyDir=['/home/cwbishop/projects/MooreMiller/' EXPID '/'];

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
    GPREP_Cz_LE.parent={}; % remove parent dependencies for now
    
    % Load environmental variables
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Trim and reference data BDF with BDF_CHANOPS
    GPREP_Cz_LE.task{end+1}=struct(...
        'func',@gab_task_bdf_ChanOps,...
        'args', struct( ...
            'IN', fullfile(subDir, 'eeg', [sid '_01_clicks.bdf']), ...
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
    %   140118 CWB: Removed this because I do not know the stimulation
    %   rate. Not until I load the file, at least
%     ABR_Cz_LE.task{end+1}=struct(...
%         'func',@PEABR_exp02C_eventcodes,...
%         'args',struct(...
%             'ICI', 0.25, ...
%             'N', 20, ...
%             'TBOUND', 3, ...
%             'INTERP', true, ...
%             'EXCLUDE', [])); 
        
    % Epoch, average, etc.
    ABR_Cz_LE.task{end+1}=struct(...
        'func',@MM_ERPLAB,...
        'args',struct(...
            'BINLIST', fullfile(studyDir, '..', 'code', 'BINS_EXP01_CB.txt'), ...
            'Epoch', [-5 30], ...
            'Baseline', [-5 0], ...
            'threshold', [-50 50], ...
            'artTwin', [-5 30], ...
            'typef', 'butter', ...
            'FilterBandPass', [100 2000], ...
            'FilterOrder', 4, ...
            'ERPFilename', fullfile(studyDir, sid, 'analysis', [sid '_ABR_Cz_LE']), ...
            'ERPName', [sid '_ABR_Cz_LE'], ...
            ... %             'BINOPS', fullfile(studyDir, '..', 'code', 'BINS_EXP01_clicks_CB.txt'),...
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
    
    %%% CREATE ADDITIONAL JOBS
    %   This approach will break for GPREP if several files are merged.
    %   Need a different approach for these subjects (s3163 and s3199).
    
    % CLICK JOBS
    CLICK_GPREP_6CH_LERE=MODIFY_GPREP(GPREP_Cz_LE, '_CLICK_6CH_LERE', '6CH-LERE', '((A1+A2+A3+A4+A5+A6)./6) - ((EXG3+EXG4 )./2)', sid, subDir);    
    CLICK_6CH_LERE=MODIFY_ABR(ABR_Cz_LE, '_CLICK_6CH_LERE', sid, subDir);
    
    % CHIRP JOBS
    
    % Modify general preparation file
    %   1. change some naming around
    %   2. change name of bdf used
    CHIRP_GPREP_6CH_LERE=MODIFY_GPREP(GPREP_Cz_LE, '_CHIRP_6CH_LERE', '6CH-LERE', '((A1+A2+A3+A4+A5+A6)./6) - ((EXG3+EXG4 )./2)', sid, subDir);    
    CHIRP_GPREP_6CH_LERE.task{2}.args.IN=strrep(CLICK_GPREP_6CH_LERE.task{2}.args.IN, '_01_click', '_02_chirp');
    
    % Modify ABR job
    CHIRP_6CH_LERE=MODIFY_ABR(ABR_Cz_LE, '_CHIRP_6CH_LERE', sid, subDir);
    
    % MLR JOBS
    %   BDM, this line can be edited to look at middle latency responses if
    %   that's something you are interested in.
%     MLR_6CH_LERE=ABR2MLR(ABR_6CH_LERE, '_CLICK_6CH_LERE', sid, subDir, [15 2000], [-5 60]); 
    
%% JOBS
    jobs{end+1}=CLICK_GPREP_6CH_LERE;      
    jobs{end+1}=CLICK_6CH_LERE;
    jobs{end+1}=CHIRP_GPREP_6CH_LERE; 
    jobs{end+1}=CHIRP_6CH_LERE; 

    % clear jobs
    clear UNPACK;
    clear CLICK_GPREP_6CH_LERE CHIRP_GPREP_6CH_LERE
    clear CLICK_6CH_LERE CHIRP_6CH_LERE
    
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
    TASK='MM_ERPLAB';
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
