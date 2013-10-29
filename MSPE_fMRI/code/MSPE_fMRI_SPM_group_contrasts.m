function [results]=MSPE_fMRI_SPM_group_contrasts(args)
%% DESCRIPTION:
%
%   Wrapper to make group level contrasts. This requires that all contrasts
%   made for each subject in the first level analysis to be identical in
%   order in the SPM structure. This is a safe assumption provided you have
%   some sensible batch system. If not, get one. 
%
% INPUT:
%
%   args.
%       SPMDIR: cell array, each element is the full path to a directory
%               containing a 1st level analysis.
%       OUTDIR: string, full path to the top level directory where all of
%               these contrasts will live.  *Note* that there will be an
%               individual directory created within this top level for each
%               contrast specified in the SPM structure.
%       TDIR:   string, directory containing templates for batching.
%       TEMPLATE:   string, name of template file to use.
%
% OUTPUT:
%
%   results:

%% WHERE ARE WE? 
orig_dir = pwd;

%% MAKE TOP LEVEL DIRECTORY IF NECESSARY
if ~exist(args.OUTDIR, 'dir'), mkdir(args.OUTDIR); end % make the directory if it's missing
cd(args.OUTDIR);

%% LOAD ALL SPM STRUCTURES
for s=1:length(args.SPMDIR)
    load(fullfile(args.SPMDIR{s}, 'SPM.mat'), 'SPM'); % be specific in case Chris in the past was an idiot (likely).
    GSPM(s)=SPM; % get GROUP SPM
    clear SPM; % get rid of it when we're done
end % 

%% SOME ERROR CHECKING ?!?! 
%   Make sure all contrast entries are the same name at least? Maybe not.

%% FOR EACH CONTRAST, MAKE A DIRECTORY, COPY IMAGES OVER, AND COMPUTE THE
%% T-TEST AS DICTATED BY THE TEMPLATE JOB.
for c=1:length(GSPM(1).xCon)
    
    % First, make the directory
    mkdir(GSPM(1).xCon(c).name);
    cd(GSPM(1).xCon(c).name);
    
    % Second, copy over contrast images to the directory
    POUT=[];
    for s=1:length(GSPM)
        [pathstr, name, ext, versn] = fileparts(GSPM(s).xCon(c).Vcon.fname);
        POUT{s,1}=fullfile(pwd, [name '-' num2str(s) ext]);
        unix(['cp "' fullfile(GSPM(s).swd, GSPM(s).xCon(c).Vcon.fname) '" "' POUT{s} '"']);
        
        %% If it's an IMG file, grab its .hdr file too
        %   I can't seem to convince SPM to write in a nifti format by
        %   default. Love it. LOVE-IT.
        if strcmp(ext, '.img')
            [pathstr, name, ext, versn]=fileparts(fullfile(GSPM(s).swd, GSPM(s).xCon(c).Vcon.fname));
            unix(['cp "' fullfile(pathstr, [name '.hdr']) '" "' fullfile(pwd, [name '-' num2str(s) '.hdr']) '"']);
        end % if strcmp ...
    end % s
    
    %% SETUP INPUTS
    batch.INPUTS{1}={pwd}; 
    batch.INPUTS{2}=POUT;
    batch.DIR=args.TDIR;
    batch.TEMPLATE=args.TEMPLATE;
    
    %% POPULATE AND DESIGN USING gab_task_SPM_matlabbatch
    gab_task_SPM_matlabbatch(batch); 
    
    %% ESTIMATE SPM
    gab_task_SPM_estimate(struct('dir', pwd)); 

    %% ADD CONTRAST (mu>0)
    gab_task_fmri_make_con(struct('spmmat', fullfile(pwd, 'SPM.mat'), 'sessrep', {{0 0}}, 'stat', 'T', 'conName', {{['>' GSPM(1).xCon(c).name] ['<' GSPM(1).xCon(c).name]}}, 'convec', {{1 -1}}));
    
    %% ADD CONTRAST (mu<0)
%     gab_task_fmri_make_con(struct('spmmat', fullfile(pwd, 'SPM.mat'), 'sessrep', 0, 'stat', 'T', 'conName', ['<' GSPM(1).xCon(c).name], 'convec', {-1}));
    
    % Finally, back to top level    
    cd(args.OUTDIR); 
end % c

%% GO BACK TO ORIGINAL DIRECTORY
cd(orig_dir); 
results='done';