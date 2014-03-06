function jobs = AA04_gab_setup(sid, EXPID)
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
if ~exist('EXPID', 'var') || isempty(EXPID), EXPID='AA04'; end
if ~strcmp('AA04', EXPID), error('Wrong setup file??'); end

studyDir=['C:\Users\cwbishop\Documents\GitHub\Projects\FFR\' EXPID filesep];

% Conditions used in naming
% Number of repetitions
if strcmpi(EXPID, 'AA04') 
    conds=[1 3 5];
    reps=3;
end % if strcmpi(EXPID, 'AA04')

% Determine number of subjects
if isa(sid, 'cell')
    nsub=length(sid);
elseif isa(sid, 'char')
    nsub=size(sid,2);
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
    fnames=cell(length(conds)*reps,1);   % CNT file names
    onames=cell(length(conds)*reps,1);  % Output names after CNT_CHANOPS
    memmapnames=cell(length(conds)*reps,1); % Memory mapping file names
    
    % Subject specific changes 
    %   Filenames will be different because KM starts at 02 for #1
    %   condition. 
    for c=1:length(conds)
        for r=1:reps            
            
            % For KM, start naming scheme for condition 1 at 02. 
            if strcmpi(SID, 'KM') && conds(c)==1
                tfname=fullfile(studyDir, SID, 'eeg', sprintf([SID '-AA04-%01d-%02d.cnt'], conds(c), r+1));
            else
                tfname=fullfile(studyDir, SID, 'eeg', sprintf([SID '-AA04-%01d-%02d.cnt'], conds(c), r));
            end % switch                   
            
            % Append to file names
            fnames{(c-1)*reps + r}=tfname;
            onames{(c-1)*reps + r}=[tfname(1:end-4) '_Cz-LE' tfname(end-3:end)];
            %   No memory mapping (memmapnames are empty)
            memmapnames{(c-1)*reps + r}='';
            
        end % for r=1:reps
    end % c=1:length(conds)
    
    %% General PREParation for Cz referenced to left earlobe.     
    GPREP_CzLE=gab_emptyjob;
    GPREP_CzLE.jobName='GPREP_CzLE';
    GPREP_CzLE.jobDir=fullfile(subDir, 'jobs');
    GPREP_CzLE.parent={}; % no dependencies
    
    % Load environmental variables
    GPREP_CzLE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Run CNT_CHANOPS    
    GPREP_CzLE.task{end+1}=struct(...
        'func',@gab_task_CNT_CHANOPS,...
        'args',struct(...
            'IN', {fnames}, ...
            'OUT', {onames}, ...
            'CHANOPS', {{'TP9.*-1'}}, ...
            'OCHLAB', {{'Cz-LE'}}, ...
            'BLOCKSIZE', 30, ...
            'DATAFORMAT', 'int32', ...
            'PRECISION', 'single'));
    
    %% ERP Job for CzLE
    RAW_CzLE=gab_emptyjob;
    RAW_CzLE.jobName='RAW_CzLE';
    RAW_CzLE.jobDir=fullfile(subDir, 'jobs');
    RAW_CzLE.parent={fullfile(GPREP_CzLE.jobDir, [GPREP_CzLE.jobName '.mat'])};
    
    % Load environmental variables
    RAW_CzLE.task{end+1}=struct(...
        'func',@gab_task_envvars,...
        'args','');
    
    % Read in rewritten data
    RAW_CzLE.task{end+1}=struct(...
        'func',@gab_task_eeglab_loadcnt,...
        'args',struct(...
            'files', {onames}, ...
            'memmapfile', {memmapnames}, ...
            'loadandmerge', false, ...
            'dataformat', 'int32'));     
    
    % Create Eventlists for all Datasets
    %    'Eventlist'             - name (and path) of eventlist text file to export.
    %    'BoundaryString'        - boundary string code to be converted into a numeric code.
    %    'BoundaryNumeric'           - numeric code that boundary string code is to be converted to
    %    'Warning'               - 'on'- Warn if eventlist will be overwritten. 'off'- Don't warn if eventlist will be overwritten.
    %    'AlphanumericCleaning'  - Delete alphabetic character(s) from alphanumeric event codes (if any). 'on'/'off'
    RAW_CzLE.task{end+1}=struct(...
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
    RAW_CzLE.task{end+1}=struct(...
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
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_overwritevent, ...
        'args', struct(...
            'mainfield', 'binlabel')); % label 'type' with human readable BIN information
        
    % EPOCH DATA
    % trange    - window for epoching in msec
    % blc       - window for baseline correction in msec or either a string like 'pre', 'post', or 'all'
    %            (strings with the baseline interval also works. e.g. '-300 100')
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_epochbin,...
        'args', struct(...
            'trange', [-100 1000], ... % use short time range for testing. 
            'blc', 'pre')); % baseline based on pre-stimulus onset.   
        
    % Merge datasets
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_eeg_mergeset, ...
        'args', '');         

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
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_artextval,...
        'args', struct(...
            'params', {{...
                'Twindow', RAW_CzLE.task{end-1}.args.trange, ... % use the whole time range
                'Threshold', [-80 80], ... % 50 microvolt rejection criterion
                'Channel', 1, ... % onle a single channel
                'Flag', 1, ... % mark with a 1 for threshold rejection
                'Review', 'off'}}));            
    
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
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_eeglab_saveset, ...
        'args', struct(...
            'params', {{'filename', [SID '-RAW_CzLE.set'], ...
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
    RAW_CzLE.task{end+1}=struct(...
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
    RAW_CzLE.task{end+1}=struct(...
        'func', @gab_task_erplab_pop_savemyerp, ...
        'args', struct(...
            'params', {{'erpname', [SID '-RAW_CzLE'], ...
                'filename', [SID '-RAW_CzLE.mat'], ...
                'filepath', fullfile(subDir, 'analysis'), ...
                'gui', 'none', ...
                'Warning', 'off'}}));
    

%     

    % Design filter task
    FILTTASK=struct(...
        'func', @gab_task_erplab_pop_basicfilter, ...
        'args', struct( ...
            'chanArray', 1, ...
            'params', ...
                {{'Filter', 'bandpass', ...
                'Design', 'butter', ...
                'Cutoff', [70 2000], ...
                'Order', 4, ...
                'RemoveDC', 'on', ...
                'Boundary', 'boundary'}}));
            
    %% cABR
    %   Basically the same as RAW, but with a tighter time window, shorter
    %   baseline, and without any file rewrites at the beginning. Also data
    %   will be filtered from 70-2000 Hz according to ...
    %   
    %   Anderson, S., et al. (2013). Hear Res 300: 18-32.
    cABR_CzLE=RAW_CzLE;
    cABR_CzLE.jobName='cABR_CzLE';    
%     cABR_CzLE.parent=fullfile(cABR_CzLE.jobDir, [RAW_CzLE.jobName '.mat']); 
    cABR_CzLE.parent='';
    cABR_CzLE.task{6}.args.trange=[-40 400];
    cABR_CzLE.task{8}=CHANGE_PARAMS(cABR_CzLE.task{8}, {'Twindow', cABR_CzLE.task{6}.args.trange, 'Threshold', [-30 30]});
    cABR_CzLE.task{9}=CHANGE_PARAMS(cABR_CzLE.task{9}, {'filename', [SID '-cABR_CzLE.set']});
    cABR_CzLE.task{11}=CHANGE_PARAMS(cABR_CzLE.task{11}, {'erpname', [SID '-cABR_CzLE'], 'filename', [SID '-cABR_CzLE.mat']}); 
    
    % Remove CNT_CHANOPS and add in filtering task
%     cABR_CzLE=gab_remove_task(cABR_CzLE, 2); % no longer need to remove
%     this since we are not reading/writing data within each ERP job
%     anymore. 
    cABR_CzLE=gab_insert_task(cABR_CzLE, FILTTASK, 3);     
        
    %% CREATE ADDITIONAL GPREP JOBS
    
    % CzRE
    GPREP_CzRE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'CzRE'), 'Cz-RE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'TP10.*-1'}}, ...
        'OCHLAB', {{'Cz-RE'}});
    
    % CzLERE
    %   Cz referenced to average earlobe
    GPREP_CzLERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'CzLERE'), 'Cz-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'-1.*((TP9+TP10)/2)'}}, ... % Cz relative to average earlobe reference. Recall that Cz was the original ref. 
        'OCHLAB', {{'Cz-LERE'}});
    
    % 7CHLE
    %   7 channel average relative to left earlobe
    GPREP_7CHLE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', '7CHLE'), '7CH-LE', 'gab_task_CNT_CHANOPS', ...
        ...'CHANOPS', {{'(TP9.*-1 + (FC1-TP9) + (FC2-TP9) + (C1-TP9) + (C2-TP9) + (CP1-TP9) + (CP2-TP9))/7'}}, ... % TP9*-1 is Cz referenced to left earlobe
        'CHANOPS', {{'(FC1+FC2+C1+C2+CP1+CP2)/7 - TP9'}}, ... % dividing 6 channels by 7, then subtracting the reference essentially adds the original reference (Cz) into the average. 
        'OCHLAB', {{'7CH-LE'}}); 
    
    % 7CHRE
    %   7 channel average relative to right earlobe
    GPREP_7CHRE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', '7CHRE'), '7CH-RE', 'gab_task_CNT_CHANOPS', ...
        ...'CHANOPS', {{'(TP10.*-1 + (FC1-TP10) + (FC2-TP10) + (C1-TP10) + (C2-TP10) + (CP1-TP10) + (CP2-TP10))/7'}}, ... % TP9*-1 is Cz referenced to left earlobe
        'CHANOPS', {{'(FC1+FC2+C1+C2+CP1+CP2)/7 - TP10'}}, ...
        'OCHLAB', {{'7CH-RE'}});
    
    % 7CHLERE
    %   7 channel average relative to average earlobe
    GPREP_7CHLERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', '7CHLERE'), '7CH-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'(FC1+FC2+C1+C2+CP1+CP2)/7 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'7CH-LERE'}});
    
    % FC1LERE
    GPREP_FC1LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'FC1LERE'), 'FC1-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'FC1 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'FC1-LERE'}});
    
    % FC2LERE
    GPREP_FC2LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'FC2LERE'), 'FC2-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'FC2 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'FC2-LERE'}});
    
    % C1LERE
    GPREP_C1LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'C1LERE'), 'C1-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'C1 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'C1-LERE'}});
    
    % C2LERE
    GPREP_C2LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'C2LERE'), 'C2-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'C2 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'C2-LERE'}});
    
    % CP1LERE
    GPREP_CP1LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'CP1LERE'), 'CP1-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'CP1 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'CP1-LERE'}});
    
    % CP2LERE
    GPREP_CP2LERE=MODIFY_GPREP(GPREP_CzLE, strrep(GPREP_CzLE.jobName, 'CzLE', 'CP2LERE'), 'CP2-LERE', 'gab_task_CNT_CHANOPS', ...
        'CHANOPS', {{'CP2 - ((TP9+TP10)/2)'}}, ... % essentially a 7 channel average.  
        'OCHLAB', {{'CP2-LERE'}});
    
    %% CREATE ADDITIONAL ERP JOBS
    %   cABRs and RAW plots. Only a few RAW ERPs done for now.
    % Cz
    cABR_CzRE=MODIFY_ERP(cABR_CzLE, 'Cz-RE', onames); 
    cABR_CzLERE=MODIFY_ERP(cABR_CzLE, 'Cz-LERE', onames); 
    
    %% 7CH
    
    % cABRs
    cABR_7CHLE=MODIFY_ERP(cABR_CzLE, '7CH-LE', onames); 
    cABR_7CHRE=MODIFY_ERP(cABR_CzLE, '7CH-RE', onames); 
    cABR_7CHLERE=MODIFY_ERP(cABR_CzLE, '7CH-LERE', onames); 
    
    % Unfiltered data
    RAW_7CHLERE=MODIFY_ERP(RAW_CzLE, '7CH-LERE', onames); 
    
    % Other single channel averages vs average earlobe
    % FC1
    cABR_FC1LERE=MODIFY_ERP(cABR_CzLE, 'FC1-LERE', onames); 
    % FC2
    cABR_FC2LERE=MODIFY_ERP(cABR_CzLE, 'FC2-LERE', onames); 
    % C1
    cABR_C1LERE=MODIFY_ERP(cABR_CzLE, 'C1-LERE', onames);     
    % C2
    cABR_C2LERE=MODIFY_ERP(cABR_CzLE, 'C2-LERE', onames); 
    % CP1
    cABR_CP1LERE=MODIFY_ERP(cABR_CzLE, 'CP1-LERE', onames); 
    % CP2
    cABR_CP2LERE=MODIFY_ERP(cABR_CzLE, 'CP2-LERE', onames); 
    
    % PUT JOBS TOGETHER
    
    % GPREP JOBS
    jobs{end+1}=GPREP_CzLE;
    jobs{end+1}=GPREP_CzRE; 
    jobs{end+1}=GPREP_CzLERE;
    jobs{end+1}=GPREP_7CHLE;
    jobs{end+1}=GPREP_7CHRE;
    jobs{end+1}=GPREP_7CHLERE;
    jobs{end+1}=GPREP_FC1LERE;
    jobs{end+1}=GPREP_FC2LERE;
    jobs{end+1}=GPREP_C1LERE;
    jobs{end+1}=GPREP_C2LERE;
    jobs{end+1}=GPREP_CP1LERE;
    jobs{end+1}=GPREP_CP2LERE;
    
    % ERP JOBS
    jobs{end+1}=RAW_CzLE; 
    jobs{end+1}=cABR_CzLE; 
    jobs{end+1}=cABR_CzRE;
    jobs{end+1}=cABR_CzLERE;
    jobs{end+1}=cABR_7CHLE;
    jobs{end+1}=cABR_7CHRE;
    jobs{end+1}=cABR_7CHLERE;
    jobs{end+1}=cABR_FC1LERE;
    jobs{end+1}=cABR_FC2LERE;
    jobs{end+1}=cABR_C1LERE;
    jobs{end+1}=cABR_C2LERE;
    jobs{end+1}=cABR_CP1LERE;
    jobs{end+1}=cABR_CP2LERE;
    jobs{end+1}=RAW_7CHLERE;
    
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