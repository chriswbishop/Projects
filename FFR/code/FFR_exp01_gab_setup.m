function jobs = FFR_exp01_gab_setup(sid)
%% DESCIRPTION
%
%   General setup file for FFR-Clinard study.
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
EXPID='Exp01';
studyDir=['C:\Users\cwbishop\Documents\GitHub\Projects\FFR\' EXPID filesep];

jobs={};
for s=1:size(sid,1)
    
    SID=deblank(sid(s,:));
    subDir=fullfile(studyDir,SID);
    
%% BUILD DEFAULT JOBS

%% PACKAGE DATA
%
%   Package data into tgz file format??

%% MOVE/COPY Files
%
%   I don't care for the *.tgz approach we used previously, so it would be
%   great to have a function that allows me to 

% ERP Analysis
%
%   Starting with a very long epoch window and ridiculously high sampling
%   rate so things translate well to the FFR data. However, I'll later need
%   to add in data downsampling and redefine the epoch time window.
%
%   I am hitting significant memory barriers on my 32-bit MATLAB version,
%   even with the modest file sizes (~100 MB on disk, up to ~330 MB in
%   EEGLAB). So, I think I'll do the following on each dataset
%   independently.
%
%       1. Filter continuous EEG data with ERPLAB (functions should work
%       across multiple datasets)
%       2. Epoch data (using EEGLAB epoching function)
%   
%   Once this is complete, I'll merge the (now significantly downsized)
%   data into a single dataset for further analysis.
%
%   If this approach doesn't work, we can couple this with memory mapping
%   (set in EEGLAB options) to reduce data size even further.
%   
    switch SID      
        case {'CB'}
            nruns=3;
        case {'KM'}
            % KM only has two files, need to truncate
            % eliminate any file with a '03' in it. This is a bit more
            % flexible in case I change something later.
            nruns=2;
    end % switch

    ERP=gab_emptyjob;
    ERP.jobName='ERP';
    ERP.jobDir=fullfile(subDir, 'jobs');
    ERP.parent={};
    
    % Load environmental variables
    ERP.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Load CNT Files
    fnames={}; % CNT filenames
    memmapnames={}; % used for memory mapping files (must enable option in EEGLAB options)
    stimtype={'AM' 'NoAM'};
    for j=1:length(stimtype)
        for i=1:nruns
            fnames{end+1}=fullfile(subDir, 'eeg', [SID '-' EXPID '-' stimtype{j} '-0' num2str(i) '.cnt']);
            memmapnames{end+1}=fullfile(subDir, 'eeg', [SID '-' EXPID '-' stimtype{j} '-0' num2str(i) '.fdt']);
        end % j=1:length...
    end % i=1:3
    
    % Read in data
    ERP.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadcnt,...
        'args',struct(...
            'files', {fnames}, ...
            'memmapfile', {memmapnames}, ...
            'loadandmerge', false));

    % Filter Datasets
    ERP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_basicfilter, ...
        'args', struct( ...
            'chanArray', 1, ...
            'params', ...
                {{'Filter', 'bandpass', ...
                'Design', 'butter', ...
                'Cutoff', [0.1 30], ...
                'Order', 4, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary'}}));  
            
    % Create Eventlists for all Datasets
        %    'Eventlist'             - name (and path) of eventlist text file to export.
        %    'BoundaryString'        - boundary string code to be converted into a numeric code.
        %    'BoundaryNumeric'           - numeric code that boundary string code is to be converted to
        %    'Warning'               - 'on'- Warn if eventlist will be overwritten. 'off'- Don't warn if eventlist will be overwritten.
        %    'AlphanumericCleaning'  - Delete alphabetic character(s) from alphanumeric event codes (if any). 'on'/'off'
    ERP.task{end+1}=struct(...
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
    ERP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_binlister, ...
        'args', struct( ...
            'params', {{'BDF', fullfile(studyDir, '..', 'code', 'BINS_EXP01.txt'), ...
               'Resetflag', 'off', ... % don't reset artifact rejection flags
               'Forbidden', [], ... % might need to add in a [6] since there's a random even at the beginning of all files
               'Ignore', [], ... % actually, this might be where the 6 should go
               'Warning', 'off', ...
               'SendEL2', 'EEG', ...
               'Report', 'on', ...
               'Saveas', 'off'}}));
    
    % Overwrite Event Type in EEG Structure
    ERP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_overwritevent, ...
        'args', struct(...
            'mainfield', 'code'));
    
    % EPOCH DATA
    % trange    - window for epoching in msec
    % blc       - window for baseline correction in msec or either a string like 'pre', 'post', or 'all'
    %            (strings with the baseline interval also works. e.g. '-300 100')
    ERP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_epochbin,...
        'args', struct(...
            'trange', [-100 300], ... % use short time range for testing. 
            'blc', 'pre')); % baseline based on pre-stimulus onset.
        
    % Merge datasets
    ERP.task{end+1}=struct(...
        'func', @gab_task_eeg_mergeset, ...
        'args', '');   
    
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
    ERP.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-ERP.set'], ...
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
    ERP.task{end+1}=struct(...
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
    ERP.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', [SID '-ERP'], ...
                'filename', [SID '-ERP.mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
    
    %% FFR JOB
    %   Nearly identical to ERP job, except with a different passband
    FFR=ERP; 
    FFR.jobName='FFR';
    
    % Change filtering parameters; all else held constant.
    FFR.task{3}=CHANGE_PARAMS(FFR.task{3}, {'Cutoff', [100 3000], 'Order', 4});
    
    % Change epoched time window
%     FFR.task{7}=CHANGE_PARAMS(FFR.task{7}, {'trange', [-100 1000]});
    FFR.task{7}.args.trange=[-100 1000];
    
    % Change saved dataset name
    FFR.task{9}=CHANGE_PARAMS(FFR.task{9}, {'filename', [SID '-FFR.set']}); 
    
    % Change saved ERP information
    FFR.task{11}=CHANGE_PARAMS(FFR.task{11}, {'erpname', [SID '-FFR'], 'filename', [SID '-FFR.mat']}); 
    
    %% STEADY STATE JOB
    %   Under development
    
    % PUT JOBS TOGETHER
    jobs{end+1}=ERP; 
%     jobs{end+1}=FFR;    
    
end % s

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