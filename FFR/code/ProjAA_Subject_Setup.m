function ProjAA_Subject_Setup(STUDYDIR, EXPID, SID)
%% DESCRIPTION:
%
%   Function to setup directories for a new subject. 
%
% INPUT:
%
%   STUDYDIR:   Study directory
%   EXPID:      Experiment ID
%   SID:        Subject ID
%
% Christopher Bishop
%   University of Washington
%   12/13

DNAMES={};
%% STUDY DIRECTORY
if ~exist(STUDYDIR, 'dir')
    DNAMES{end+1}=fullfile(STUDYDIR);
    
end % end

%% EXPERIMENT DIRECTORY AND SANDBOX
EXPDIR=fullfile(STUDYDIR, EXPID);
if ~exist(EXPDIR, 'dir')
    DNAMES{end+1}=EXPDIR;
    DNAMES{end+1}=fullfile(EXPDIR, 'sandbox');     
end % end

%% SUBJECT DIRECTORY
if ~exist(fullfile(STUDYDIR, EXPID, SID), 'dir')
    DNAMES{end+1}=fullfile(STUDYDIR, EXPID, SID);
end % ~exist

%% SUBJECT SUBDIRECTORIES
SUBDIR=fullfile(STUDYDIR, EXPID, SID);

DNAMES{end+1}=fullfile(SUBDIR, 'analysis');
DNAMES{end+1}=fullfile(SUBDIR, 'behavior');
DNAMES{end+1}=fullfile(SUBDIR, 'eeg');
DNAMES{end+1}=fullfile(SUBDIR, 'jobs');

%% MAKE DIRECTORIES
gab_task_mkdir(DNAMES);