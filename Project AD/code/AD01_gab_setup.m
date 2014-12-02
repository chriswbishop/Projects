function jobs = AD01_gab_setup(sid, EXPID)
%% DESCIRPTION
%
%   General setup file for AA04.
%
% INPUT:
%   
%   sid:    char array, each row is a subject ID
%   EXPID:  
%
% OUTPUT:
%
%   jobs:   job structure for use with GAB
%
% Bishop, Chris Miller Lab 2010
if ~exist('EXPID', 'var') || isempty(EXPID), EXPID='AD01'; end
if ~strcmp('AD01', EXPID), error('Wrong setup file??'); end

studyDir=['D:\GitHub\Projects\Project AD\' EXPID filesep];

% Conditions used in naming
% Number of repetitions
if strcmpi(EXPID, 'AD01') 
    conds=[1 2 3 7];    
end % if strcmpi(EXPID, 'AA04')

% Determine number of subjects
if isa(sid, 'cell')
    nsub=length(sid);
elseif isa(sid, 'char')
    nsub=size(sid,1);
end % 

jobs={};
for s=1:nsub

    % Convert subject IDs if cell or character array. 
    if isa(sid, 'cell')
        SID=sid{s};
    elseif isa(sid, 'char')
        SID=deblank(sid(s,:));
    end % if isa
    subDir=fullfile(studyDir,SID);
    
    % Clear file names and memory mapping names
    %   Initialize size for speed.    
%     fnames=cell(length(conds)*reps,1);   % CNT file names
%     onames=cell(length(conds)*reps,1);  % Output names after CNT_CHANOPS
%     memmapnames=cell(length(conds)*reps,1); % Memory mapping file names
    
    % Subject specific changes 
    %   Filenames will be different because KM starts at 02 for #1
    %   condition. 
    for c=1:length(conds)
        fnames{c} = fullfile(studyDir, SID, 'eeg', sprintf([SID '-AD01-%01d.cnt'], conds(c)));
        memmapnames{c}=''; % no memory mapping
    end % c=1:length(conds)
    
    %% General PREPeration     
    GPREP = gab_emptyjob;
    GPREP.jobName='GPREP';
    GPREP.jobDir=fullfile(subDir, 'jobs');
    GPREP.parent={}; % no dependencies
    
    % Load environmental variables
    GPREP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Load all CNT files    
    GPREP.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadcnt,...
        'args',struct(...
            'files', {fnames}, ...
            'memmapfile', {memmapnames}, ...
            'loadandmerge', false, ...
            'dataformat', 'int32'));
   
    % Merge CNT files
    GPREP.task{end+1}=struct(...
        'func', @gab_task_eeg_mergeset, ...
        'args', ''); 
    
    % Add Cz Channel
    %   - Cz is our reference, so add in a new channel with nothing but
    %   zeros. That way all the referencing done later carries through as
    %   well.
    GPREP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_eegchanoperator, ...
        'args', struct(...
            'formulas', { {  'ch65=ch13-ch13 label Cz'} })); % ch13 is a random pick. Can be any channel minus itself.        
    
    % Load channel locations    
    GPREP.task{end+1}=struct(...
        'func',@gab_task_eeg_chanlocs,...
        'args',struct(...
            'file', 'C:\Users\cwbishop\Documents\MATLAB\eeglab12_0_2_5b\plugins\dipfit2.2\standard_BESA\standard-10-5-cap385.elp'));
        
    % Resample to 200 Hz (we'll never need more than 200 Hz, I don't think)
    GPREP.task{end+1}=struct(...
        'func', @gab_task_eeg_resample, ...
        'args', struct(...
            'freq', 200)); 
    
    % High pass filter 
    % Design filter task
    GPREP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_basicfilter, ...
        'args', struct( ...
            'chanArray', 1:64, ...
            'params', ...
                {{'Filter', 'highpass', ...
                'Design', 'butter', ...
                'Cutoff', [0.5], ...
                'Order', 4, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary'}}));
            
    % Save EEG set
    GPREP.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-Preproc.set'], ...
               'filepath', fullfile(subDir, 'analysis'), ... 
               'check', 'off', ... 
               'savemode', 'onefile'}}));           
    
    % Data cleaning (ICA)   
    ICA=gab_emptyjob;
    ICA.jobName='ICA';
    ICA.jobDir=fullfile(subDir, 'jobs');
    ICA.parent={fullfile(GPREP.jobDir, [GPREP.jobName '.mat'])};
     
    % Load environmental variables
    ICA.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');

    % Load preprocessed data       
    ICA.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', [SID '-Preproc.set']));
    % Run ICA
    ICA.task{end+1}=struct(...
        'func', @gab_task_eeglab_runica, ...
        'args', struct(...
        'icatype', 'runica')); % tried binica but didn't have much luck. seg fault. not sure what's up
    
    % Save data + ICs
    ICA.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-Preproc (ICA).set'], ...
               'filepath', fullfile(subDir, 'analysis'), ... 
               'check', 'off', ... 
               'savemode', 'onefile'}}));
           
    %% ERP Jobs
    %   - Generate (unfiltered) ERPs.
    %   - Rereference ERPs to Average earlobe (channel operator)
    %   - Filter ERP waveform in different ways. 
    
    % ERP
    ERP_LERE=gab_emptyjob;
    ERP_LERE.jobName='ERP_LERE';
    ERP_LERE.jobDir=fullfile(subDir, 'jobs');
    ERP_LERE.parent={fullfile(GPREP.jobDir, [GPREP.jobName '.mat']) fullfile(ICA.jobDir, [ICA.jobName '.mat'])};
    
%     Load environmental variables
    ERP_LERE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
     
    % Load preprocessed data       
    ERP_LERE.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadset,...
        'args',struct(...
            'filepath', fullfile(subDir, 'analysis'), ...
            'filename', fullfile([SID '-Preproc (ICA)-NEB.set'])));
        
    % Rereference
    %   - We want to push all the auditory related variance up to Cz (for
    %   now), so go with an average earlobe reference for ease. 
    %   - Might be worth checking out an average reference as well. CWB
    %   isn't 100% settled on the reference yet, but we definitely don't
    %   want to use Cz as reference (that's the ref during recording)
    ERP_LERE.task{end+1}=struct( ...
        'func', @gab_task_eeglab_pop_reref, ...
        'args', struct(...
            'ref', [28 29], ... % TP9/TP10 (earlobe reference)
            'params', ...
                {{'keepref', 'on'}})); % keep the reference electrodes. They will still have some information in them.
    % Filter
    %   - We want to filter our data to look at ERPs.
    %   - Start with [0.5 20] Hz, 
    %   - Simon's reverse correlation works on [1 9] Hz filtered data.
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_basicfilter, ...
        'args', struct( ...
            'chanArray', 1:65, ...
            'params', ...
                {{'Filter', 'lowpass', ...
                'Design', 'butter', ...
                'Cutoff', 20, ...
                'Order', 6, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary'}}));
    
    % Create Eventlists for all Datasets
    %    'Eventlist'             - name (and path) of eventlist text file to export.
    %    'BoundaryString'        - boundary string code to be converted into a numeric code.
    %    'BoundaryNumeric'           - numeric code that boundary string code is to be converted to
    %    'Warning'               - 'on'- Warn if eventlist will be overwritten. 'off'- Don't warn if eventlist will be overwritten.
    %    'AlphanumericCleaning'  - Delete alphabetic character(s) from alphanumeric event codes (if any). 'on'/'off'
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_creabasiceventlist, ...
        'args', struct( ...
            'params', ...
               {{'Eventlist', '', ...
               'BoundaryString', {'boundary'}, ...
               'BoundaryNumeric', {-99}, ...
               'Warning', 'off', ...
               'AlphanumericCleaning', 'on'}}));  
     
    % Binlister
    %     'BDF'         - name of the text file containing your bin descriptions (formulas).
    %     'ImportEL'	  - (optional) name of the text file, to import, that contain the event information to process,
    %                     according to ERPLAB format (see tutorial).
    %
    %     'ExportEL' 	  - (optional) name of the text file, to export, that will contain the upgraded event information,
    %                     according to ERPLAB format (see tutorial).
    %
    %     'Resetflag'   - set (all) flags to zero before starting binlister process. 'on'=reset;  'off':keep as it is.
    %
    %     'Forbidden'	  - array of event codes (numeric). If any of these codes is among a set of codes successfully captured by a bin
    %                     this "capture" will be disable.
    %     'Ignore'      - array of event codes (numeric) to be ignored. Binlister will be blind to them.
    %
    %     'UpdateEEG'   - after binlister process you can move the upgraded event information to EEG.event field. 'on'=update, 'off'=keep as it is.
    %     'Warning'     - 'on'- warn if EVENTLIST will be overwritten. 'off' - do not warn if EVENTLIST will be overwritten.
    %     'SendEL2'     - once binlister ends its work, you can send a copy of the resulting EVENTLIST structure to:
    %                    'Text'           - send to text file
    %                    'EEG'            - send to EEG structure
    %                    'EEG&Text'       - send to EEG & text file
    %                    'Workspace'      - send to Matlab workspace,
    %                    'Workspace&Text' - send to Workspace and text file,
    %                    'Workspace&EEG'  - send to workspace and EEG,
    %                    'All'- send to all of them.
    %     'Report'      - 'on'= create report about binlister performance, 'off'= do not create a report.
    %     'Saveas'      - (optional) open GUI for saving dataset. 'on'/'off'
    ERP_LERE.task{end+1}=struct(...
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
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_overwritevent, ...
        'args', struct(...
            'mainfield', 'binlabel')); % label 'type' with human readable BIN information
        
    % EPOCH DATA
    % trange    - window for epoching in msec
    % blc       - window for baseline correction in msec or either a string like 'pre', 'post', or 'all'
    %            (strings with the baseline interval also works. e.g. '-300 100')
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_epochbin,...
        'args', struct(...
            'trange', [-100 500], ... % use short time range for testing. 
            'blc', 'pre')); % baseline based on pre-stimulus onset.   

    % Threshold artifact rejection
    %
    %        'Twindow' 	- time period (in ms) to apply this tool (start end). Example [-200 800]
    %        'Threshold'    - range of amplitude (in uV). e.g  -100 100
    %        'Channel' 	- channel(s) to search artifacts.
    %        'Flag'         - flag value between 1 to 8 to be marked when an artifact is found.(1 value)
    %        'Review'       - open a popup window for scrolling marked epochs.
    %
    % Note that the summary table that kicks out in the command window
    % after this is complete will not report correct numbers. This is a
    % consequence of the clunky loading/processing done on each data set
    % individually, then merging the datasets together. Apparently the
    % EVENTLIST field doesn't merge properly. 
    %
    % Consequently, line 220 of pop_summary_AR_eeg_detection throws out
    % bullshit numbers since it's indexing a now incorrect EVENTLIST field.
    %   acce(i)  = EEG.EVENTLIST.trialsperbin(i)-rej(i);
    %

    % Save merged dataset
    %   'filename' - [string] name of the file to save to
    %   'filepath' - [string] path of the file to save to
    %   'check'    - ['on'|'off'] perform extended syntax check. Default 'off'.
    %   'savemode' - ['resave'|'onefile'|'twofiles'] 'resave' resave the 
    %                current dataset using the filename and path stored
    %                in the dataset; 'onefile' saves the full EEG 
    %                structure in a Matlab '.set' file, 'twofiles' saves 
    %                the structure without the data in a Matlab '.set' file
    %                and the transposed data in a binary float '.dat' file.
    %                By default the option from the eeg_options.m file is 
    %                used.
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-ERP_LERE.set'], ...
               'filepath', fullfile(subDir, 'analysis'), ... 
               'check', 'off', ... 
               'savemode', 'onefile'}}));
           
    % Create average
    %        'DSindex' 	- dataset index(ices) when dataset(s) are contained within the ALLEEG structure.
    %                         For single bin-epoched dataset using EEG structure this value must be equal to 1 or
    %                         left unspecified.
    %        'Criterion'    - Inclusion/exclusion of marked epochs during artifact detection:
    % 		             'all'   - include all epochs (ignore artifact detections)
    % 		             'good'  - exclude epochs marked during artifact detection
    % 		             'bad'   - include only epochs marked with artifact rejection
    %                         NOTE: for including epochs selected by the user, specify these one as a cell array. e.g {2 8 14 21 40:89}
    %
    %        'SEM'              - include standard error of the mean. 'on'/'off'
    %        'ExcludeBoundary'  - exclude epochs having boundary events. 'on'/'off'
    %        'Saveas'           - (optional) open GUI for saving averaged ERPset. 'on'/'off'
    %        'Warning'          - enable popup window warning. 'on'/'off'
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_averager, ...
        'args', struct(...
            'params', {{'DSindex', 1, ...
                'Criterion', 'good', ...
                'SEM', 'on', ...
                'ExcludeBoundary', 'on', ...
                'Warning', 'off'}}));
            
    % Save my ERP
    % The available parameters are as follows:
    %
    %         'erpname'          - ERP name to be saved
    %         'filename'         - name of ERP to be saved
    %         'filepath'         - name of path ERP is to be saved in
    %         'gui'              - 'save', 'saveas', 'erplab' or 'none'
    %         'overwriteatmenu'  - overwite erpset at erpsetmenu (no gui). 'on'/'off'
    %         'Warning'          - 'on'/'off'
    ERP_LERE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', [SID '-ERP_LERE'], ...
                'filename', [SID '-ERP_LERE.mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
    
    % Now, generate the responses we'll use for the envelope following
    % algorithm. 
    ENV_LERE = ERP_LERE; % use ERP_LERE as a starting point.
    
    % Change job name
    ENV_LERE.jobName='ENV_LERE';
    
    % Change filtering to [1 9] Hz to match Simon's work.
    ind = gab_find_task(ENV_LERE, 'gab_task_erplab_pop_basicfilter', 1); 
    ENV_LERE.task{ind} = CHANGE_PARAMS(ENV_LERE.task{ind}, {'Filter', 'bandpass', 'Cutoff', [1 9], 'Order', 6}); % change to band pass filter and change to [1 9] Hz bandpass, 6th order butter
       
    % Replace binlister file with a SPEECH ONLY FILE (omit the bursts for
    % now since we won't be using them much)
    ind = gab_find_task(ENV_LERE, 'gab_task_erplab_pop_binlister', 1); 
    ENV_LERE.task{ind} = CHANGE_PARAMS(ENV_LERE.task{ind}, {'BDF', fullfile(studyDir, '..', 'code', ['BINS_' EXPID ' (Speech Only).txt'])}); % Change binlister description file (BDF)
    
    % Replace epoch bin with longer epoch time (52 seconds)
    ind = gab_find_task(ENV_LERE, 'gab_task_erplab_pop_epochbin', 1); 
    ENV_LERE.task{ind}.args.trange = [-100 52000]; 
    
    % Change data set name
    ind = gab_find_task(ENV_LERE, 'gab_task_eeglab_saveset', 1); 
    ENV_LERE.task{ind} = CHANGE_PARAMS(ENV_LERE.task{ind}, {'filename', [SID '-ENV_LERE.set']});
    
    % Change ERP set name
    ind = gab_find_task(ENV_LERE, 'gab_task_erplab_pop_savemyerp', 1); 
    ENV_LERE.task{ind} = CHANGE_PARAMS(ENV_LERE.task{ind}, {'erpname', [SID '-ENV_LERE'], 'filename', [SID '-ENV_LERE.mat']} );
    
    % Gather ERP filenames (in cell array) for group averaging below
    ENVF_LERE{s} = fullfile(ENV_LERE.task{end}.args.params{6}, ENV_LERE.task{end}.args.params{4});
    ERPF_LERE{s} = fullfile(ERP_LERE.task{end}.args.params{6}, ERP_LERE.task{end}.args.params{4});
    
    % Gather jobs
%     jobs{end+1}=GPREP; 
%     jobs{end+1}=ICA; 
    jobs{end+1}=ERP_LERE; 
    jobs{end+1}=ENV_LERE;
    
end % s

%% CREATE GROUP AVERAGE
%       - Load all Subject ERPs
%       - Grand average waveforms (arithmetic mean, no weighting)
%       - Save ERP

subDir=fullfile(studyDir, 'GROUP');
 
ERP_LERE_GROUP=gab_emptyjob;
ERP_LERE_GROUP.jobName='ERP_LERE_GROUP';
ERP_LERE_GROUP.jobDir=fullfile(subDir, 'jobs');
% ERP_LERE_GROUP.parent='';

% Load environmental variables and a fresh workspace
ERP_LERE_GROUP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
% Load all ERPs into base workspace 
ERP_LERE_GROUP.task{end+1}=struct(...
    'func', @gab_task_erplab_pop_loaderp, ...
    'args', struct(...
        'ERPF', {ERPF_LERE}, ...
        'params', {{...
            'overwrite', 'off', ...
            'Warning', 'off', ...
            'multiload', 'off', ...
            'UpdateMainGui', 'off'}}));

% Compute grand average
ERP_LERE_GROUP.task{end+1}=struct(...
    'func', @gab_task_erplab_pop_gaverager, ...
    'args', struct(...
        'params', {{...
            'Erpsets', 1:length(ERPF_LERE), ...
            'Weighted', 'off', ...
            'SEM',  'on', ...
            'ExcludeNullBin',   'off', ...
            'Warning',  'off'}}));

% Save ERP
ERP_LERE_GROUP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', ['GROUP-ERP_LERE (N=' num2str(length(ERPF_LERE)) ')'], ...
                'filename', ['GROUP-ERP_LERE (N=' num2str(length(ERPF_LERE)) ').mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
            
% ENV_LERE_GROUP
ENV_LERE_GROUP=gab_emptyjob;
ENV_LERE_GROUP.jobName='ENV_LERE_GROUP';
ENV_LERE_GROUP.jobDir=fullfile(subDir, 'jobs');
% ERP_LERE_GROUP.parent='';

% Load environmental variables and a fresh workspace
ENV_LERE_GROUP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
% Load all ERPs into base workspace 
ENV_LERE_GROUP.task{end+1}=struct(...
    'func', @gab_task_erplab_pop_loaderp, ...
    'args', struct(...
        'ERPF', {ENVF_LERE}, ...
        'params', {{...
            'overwrite', 'off', ...
            'Warning', 'off', ...
            'multiload', 'off', ...
            'UpdateMainGui', 'off'}}));

% Compute grand average
ENV_LERE_GROUP.task{end+1}=struct(...
    'func', @gab_task_erplab_pop_gaverager, ...
    'args', struct(...
        'params', {{...
            'Erpsets', 1:length(ENVF_LERE), ...
            'Weighted', 'off', ...
            'SEM',  'on', ...
            'ExcludeNullBin',   'off', ...
            'Warning',  'off'}}));

% Save ERP
ENV_LERE_GROUP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', ['GROUP-ENV_LERE (N=' num2str(length(ENVF_LERE)) ')'], ...
                'filename', ['GROUP-ENV_LERE (N=' num2str(length(ENVF_LERE)) ').mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
% Add to jobs structure
jobs{end+1} = ERP_LERE_GROUP; 
jobs{end+1} = ENV_LERE_GROUP; 

end % function

function task=CHANGE_PARAMS(task, params)
%% DESCRIPTION:
%
%   Change the parameters for a task if they are stored in a cell array in
%   a string paired with a value (e.g., {'Order', 4}
%
%
% INPUTS:
%
%   task:
%   params:
%
% Bishop, Christopher
%   University of Washington
%   11/2013

% Loop through changed parameters

p=1:2:length(params); % parameter name
v=2:2:length(params); % parameter values

% Find the parameter
for p=1:2:length(params) % parameter name
   
   % Match parameter name
   for i=1:2:length(task.args.params)
       if strcmp(task.args.params{i}, params{p}), break; end % if       
   end % i=1:2:length(params)
   
   % Assign parameter value
   task.args.params{i+1}=params{p+1};
   
end % p=1:2


end % CHANGE_PARAMS

function JOB=MODIFY_GPREP(JOB, JNAME, REFNAME, TNAME, varargin)
%% DESCRIPTION:
%
%   Function to modify AA04 GPREP. This proved useful when comparing
%   referencing schemes quickly. 

%% CHANGE JOBNAME
% JOB.jobName=strrep(JOB.jobName, 'CzLE', 'CzRE');

%% MODIFY CNT_CHANOPS CALL

% PUT REPLACEMENT ARGS INTO STRUCTURE
ARGS=struct(varargin{:}); 

%% CHANGE OUTPUT FILE NAMES
for i=1:length(JOB.task{end}.args.OUT)
    ARGS.OUT{i,1}=strrep(JOB.task{end}.args.OUT{i}, 'Cz-LE', REFNAME);
end % i=1:length(JOB.task ...

%% REPLACE ARGUMENTS
[JOB]=gab_replace_task_args(JOB, TNAME, ARGS, JNAME);

end % MODIFY_GPREP

function JOB=MODIFY_ERP(JOB, REFNAME, FNAMES)
%%DESCRIPTION:
%
%   Function to modify ERP jobs. This proved useful when comparing what
%   were essentially exactly the same data, but filtered or referenced
%   differently.
%
% INPUT:
%
% OUTPUT:
%
% Christopher W. Bishop
%   University of Washington
%   02/14

JNAME=strrep(JOB.jobName, 'CzLE', strrep(REFNAME, '-', '')); 
%% CHANGE INPUT FILE NAMES
for i=1:length(FNAMES)
    FNAMES{i}=strrep(FNAMES{i}, 'Cz-LE', REFNAME); 
end % i=1:length(FNAMES)
args.files=FNAMES;

% Replace in gab_task_eeglab_loadcnt
JOB=gab_replace_task_args(JOB, 'gab_task_eeglab_loadcnt', args, JNAME); 

%% CHANGE DATASET NAME
% Figure out where the appropriate task is
ind=gab_find_task(JOB, 'gab_task_eeglab_saveset', 1); 

% Pull out the parameters
p=struct(JOB.task{ind}.args.params{:}); 

% Change filename
p.filename=strrep(p.filename, 'CzLE', strrep(REFNAME, '-', '')); 

% Replace parameter in task
JOB.task{ind}=CHANGE_PARAMS(JOB.task{ind}, {'filename', p.filename}); 

%% REPLACE ERPNAME
% Grab the task index
ind=gab_find_task(JOB, 'gab_task_erplab_pop_savemyerp', 1); 

% Pull out parameters
p=struct(JOB.task{ind}.args.params{:}); 

% Change erpname
p.erpname=strrep(p.erpname, 'CzLE', strrep(REFNAME, '-', '')); 
p.filename=strrep(p.filename, 'CzLE', strrep(REFNAME, '-', '')); 

% Replace parameter list indatsk
JOB.task{ind}=CHANGE_PARAMS(JOB.task{ind}, {'erpname', p.erpname, 'filename', p.filename}); 

end % MODIFY_ERP