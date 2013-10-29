function [EB NEB]=MSPE_EEG_SPLCheck(args)
%% DESCRIPTION:
%
%   Analysis script for MSPE (Experiment 06).  Our goal, as detailed in
%   greater detail in my OneNote notebook, was to determine how reflexive
%   eyeblinks (referred to in the notes as a partial eye blink or startle
%   reflex) relate to sound pressure level (SPL).  We delivered stimuli in
%   the APE (lead-lag, or precedent-echo) condition at SPL(A) values
%   ranging from 50-76 dB.  We wanted to determine two things:
%       1. How do auditory evoked potentials (AEPs) vary with SPL?
%       2. How does the startle reflex vary with SPL?
%
%   Ultimately, we're hoping to find a level where we can get robust AEPs
%   while minimizing the startle reflex.
%
% INPUT:
%   args
%       SID:
%       studyDir:
%       latency:    latencies to measure mean amplitude at.
%       binArray:
%       chanArray:
%       bindescr:
%
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
if ~exist('args', 'var'), args=struct; end
if ~isfield(args, 'SID') || isempty(args.SID), args.SID=strvcat('CB', 'SL', 'KH', 's2612', 's2613', 's2614'); end
if ~isfield(args, 'studyDir') || isempty(args.studyDir), args.studyDir='/home/cwbishop/projects/MSPE/Experiment06/'; end
if ~isfield(args, 'latency') || isempty(args.latency), args.latency=[[40 60]; [75 115]; [150 190]]; end
if ~isfield(args, 'binArray') || isempty(args.binArray), args.binArray=1:6; end
if ~isfield(args, 'chanArray') || isempty(args.chanArray), args.chanArray={[1 34] [11 47 46 12 48 49 56 32 19]}; end % cell array for MSPE_EEG_amplitude
if ~isfield(args, 'txtfile') || isempty(args.txtfile), args.txtfile=fullfile(args.studyDir, 'SPLCHECK.txt'); end
if ~isfield(args, 'bindescr') || isempty(args.bindescr), args.bindescr={'P1', 'N1', 'P2'}; end % args.bindescr
%% BUILD ERP FILES FOR "EYEBLINK" DATA
args.filename=[]; 
for s=1:size(args.SID,1)
    sid=deblank(args.SID(s,:)); 
    args.filename=strvcat(args.filename, fullfile(args.studyDir, sid, 'analysis', [sid '_ERP (ICA)+EB (100 msec BL).mat']));
end % s

[results EB]=MSPE_EEG_amplitude(args); 

%% BUILD ERP FILES FOR "No EyeBlink" DATA
args.filename=[]; 
for s=1:size(args.SID,1)
    sid=deblank(args.SID(s,:));
    args.filename=strvcat(args.filename, fullfile(args.studyDir, sid, 'analysis', [sid '_ERP (ICA)-NEB (100 msec BL).mat']));
end % s

[results NEB]=MSPE_EEG_amplitude(args); 

%% GROUP ANALYSIS AND PLOTS
SPL=[50 55 60 65 70 76]';

%% NO EYEBLINK DATA
% ANALYSES BASED ON ASSUMED DEFAULTS
%

% CODE FOR ABSOLUTE AMPLITUDE MEASURES (absolute values to keep signs
% consistent).
for i=1:size(NEB,4)
    figure, hold on
    X=squeeze(NEB(:,:,:,i)); % select second set of electrodes
    errorbar(SPL*ones(1,size(X,3)), abs(squeeze(mean(X,2))), squeeze(std(X,0,2))./size(X,1), 's-');
    xlabel('SPL (singe burst, dB(A))');
    ylabel('Absolute Mean Amplitude (uV)'); 
    title(['NEB [' num2str(args.chanArray{i}) ']' ]); 
    legend([cell2mat(args.bindescr') repmat('(', length(args.bindescr),1) num2str(args.latency) repmat(')', length(args.bindescr),1)]);
end % i

% CODE FOR PERCENTAGE AMPLITUDE CHANGE
%   Change relative to mean amplitude across time window and conditions.
for i=1:size(NEB,4)
    figure, hold on
    X=squeeze(NEB(:,:,:,i)); % select second set of electrodes
%     Y=X./(ones(size(X,1),1)*squeeze(mean(X,1)));
    Y=abs(X./(repmat(mean(X,1),[size(X,1) 1 1])));
    errorbar(SPL*ones(1,size(Y,3)), abs(squeeze(mean(Y,2))), squeeze(std(Y,0,2))./size(Y,1), 's-');
    xlabel('SPL (singe burst, dB(A))');
    ylabel('Change Relative to Mean Amplitude (ratio)'); 
    title(['NEB [' num2str(args.chanArray{i}) ']']);
    legend([cell2mat(args.bindescr') repmat('(', length(args.bindescr),1) num2str(args.latency) repmat(')', length(args.bindescr),1)]);
end % i

%% EYEBLINK DATA
%   
%   The goal of this section is to determine the SPL dependent change in
%   the startle reflex that we have been recording.  This manifests here
%   as a partial eyeblink dohicky (better described in the MSPE_EEG
%   OneNote). 
%
%   Here's an outline of the processing steps.
%   
%   1. normalize
for i=1:size(EB,4)
    figure, hold on
    X=squeeze(EB(:,:,:,i)); % select second set of electrodes
    errorbar(SPL*ones(1,size(X,3)), abs(squeeze(mean(X,2))), squeeze(std(X,0,2))./size(X,1), 's-');
    xlabel('SPL (singe burst, dB(A))');
    ylabel('Absolute Mean Amplitude (uV)'); 
    title(['EB [' num2str(args.chanArray{i}) ']' ]); 
    legend([repmat('(', length(args.bindescr),1) num2str(args.latency) repmat(')', length(args.bindescr),1)]);
end % i

for i=1:size(EB,4)
    figure, hold on
    X=squeeze(EB(:,:,:,i)); % select second set of electrodes
%     Y=X./(ones(size(X,1),1)*squeeze(mean(X,1)));
    Y=X./(repmat(mean(X,1),[size(X,1) 1 1]));
    errorbar(SPL*ones(1,size(Y,3)), abs(squeeze(mean(Y,2))), squeeze(std(Y,0,2))./size(Y,1), 's-');
    xlabel('SPL (singe burst, dB(A))');
    ylabel('Change Relative to Mean Amplitude (ratio)'); 
    title(['EB [' num2str(args.chanArray{i}) ']']);
    legend([repmat('(', length(args.bindescr),1) num2str(args.latency) repmat(')', length(args.bindescr),1)]);
end % i