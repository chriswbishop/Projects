function jobs=FISH_Exp02_gab_setup(SID, EXPID)
%% DESCRIPTION:
%
%   We absolutely needed a branch point for Exp02C.  It was getting
%   too complicated to try and work Exp02C to play nice with the setup files
%   for all previous experiments.
%
% INPUT
%
% OUTPUT

studyDir=['D:\GitHub\Projects\FISH\' EXPID filesep];

jobs={};

%% CREATE JOBS FOR EACH SUBJECT
for s=1:size(SID)
    sid=deblank(SID(s,:));
    subDir=fullfile(studyDir,sid);
    
    % Create the job
    %% ABR ERP
    REV_CORR=gab_emptyjob;
    REV_CORR.jobName='REV_CORR';
    REV_CORR.jobDir=fullfile(subDir, 'jobs');
    REV_CORR.parent={''};
    
    % Load environmental variables
    REV_CORR.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Load the data set
    %   Datasets are exported from BVA
    % Load dataset
    REV_CORR.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadset,...
        'args',struct(...
            'filepath', fullfile(studyDir, sid, 'eeg' ), ...
            'filename', [sid '_03_sentences_LLR_MatlabTransform.set']));
       
    % Resample to 200 Hz
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_eeg_resample, ...
        'args', struct(...
            'freq', 200)); 
        
    % Bandpass filter the data (1 - 9 Hz)
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_basicfilter, ...
        'args', struct( ...
            'chanArray', 1:7, ...
            'params', ...
                {{'Filter', 'bandpass', ...
                'Design', 'butter', ...
                'Cutoff', [1 9], ...
                'Order', 6, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary'}}));
            
    % Create Event List
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_creabasiceventlist, ...
        'args', struct( ...
            'params', ...
               {{'Eventlist', '', ...
               'BoundaryString', {'boundary'}, ...
               'BoundaryNumeric', {-99}, ...
               'Warning', 'off', ...
               'AlphanumericCleaning', 'on'}}));  

           
    % Binlister
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_binlister, ...
        'args', struct( ...
            'params', {{'BDF', fullfile(studyDir, '..', 'code', ['BINS_' EXPID '.txt']), ...
               'Resetflag', 'off', ... % don't reset artifact rejection flags
               'Forbidden', [], ... % might need to add in a [6] since there's a random even at the beginning of all files
               'Ignore', [], ... % actually, this might be where the 6 should go
               'Warning', 'off', ...
               'SendEL2', 'EEG', ... 
               'Report', 'on', ...
               'Saveas', 'off'}}));
           
    % Overwrite Event Type in EEG Structure
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_overwritevent, ...
        'args', struct(...
            'mainfield', 'binlabel')); % label 'type' with human readable BIN information
        
    % Epoch    
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_epochbin,...
        'args', struct(...
            'trange', [-100 122*1000], ... % Epoch to full length of speech track
            'blc', 'pre')); % baseline based on pre-stimulus onset.   
        
    % Save set    
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-REV_CORR.set'], ...
               'filepath', fullfile(subDir, 'analysis'), ... 
               'check', 'off', ... 
               'savemode', 'onefile'}}));
    
    % Create ERPs
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_averager, ...
        'args', struct(...
            'params', {{'DSindex', 1, ...
                'Criterion', 'good', ...
                'SEM', 'on', ...
                'ExcludeBoundary', 'on', ...
                'Warning', 'off'}}));
    % Save ERP        
    REV_CORR.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', [SID '-REV_CORR'], ...
                'filename', [SID '-REV_CORR.mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
    
    
    %% JOBS
    jobs{end+1}=REV_CORR;      
        
end % s


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
