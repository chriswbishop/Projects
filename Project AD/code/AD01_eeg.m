function AD01_eeg(target, masker, code)
%% DESCRIPTION:
%
%   Paradigm for presenting stimuli/sending trigger codes for Project AD,
%   Experiment 01. The experiment is designed to present speech stimuli
%   (sentences) to listeners a predetermined number of times at various
%   signal-to-noise ratios (SNRs). The hope is to later apply offline
%   analyses similar to Ding, N. and J. Z. Simon (2013). J Neurosci 33(13).
%
% INPUT:
%
%   XXX
%
% OUTPUT:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington 
%   4/14

%% INPUT CHECKS AND DEFAULTS
circuit=''; 
isi=[1 2]; % isi in sec

%% LOAD STIMULI
%   Load using AA_loaddata. Only accept wave/double/single data types. 
p.datatypes=[1 2]; % restrict to wav and single/double array
[target, tfs]=AA_loaddata(target, p); 
[masker, mfs]=AA_loaddata(masker, p); 

%% LOWPASS FILTER
%   Potentially lowpass filter stimuli (4 kHz) similar to Ding and Simon.
%       - Probably necessary for spectrotemporal estimates using auditory
%       models. See Ding and Simon (2012b) and Ding and Simon (2013)

%% INITIALIZE TDT

% % ESTABLISH CONNECTION WITH RP 2.1
% RP = actxcontrol('RPco.x',[5 5 26 26]);
% % RP=actxcontrol('RPCo.x',[0 0 0 0]);
% RP.ConnectRP2('USB', 1);
% 
% % CLEAR Control Object File (COF)
% RP.ClearCOF; % First clear the COF
% 
% % LOAD COF AND SET SAMPLING RATE
% RP.LoadCOFsf(CIRCUIT, FSLEVEL); 
% 
% % GET SAMPLING RATE
% FS = RP.GetSFreq; 

FS=44101.25; % hard code at some random, non-integer sampling rate. 

%% RESAMPLE STIMULI
%   Resample to TDT sampling rate
target=resample4TDT(target, FS, tfs); 
masker=resample4TDT(masker, FS, mfs); 

% Error check for stimulus size
%   Both target and masker need to have the same number of samples
if length(target)~=length(masker), error('Series lengths differ'); end 

%% SET SNR
%
%   Hold target level constant and vary background noise level. 
%
%   SNR set based on condition code provided by user. 
%
%   Set SNR using RMS estimation.
%
%   Potentially allow for other SNR procedures (e.g., peak, etc.). 
trms=rms(target); 
mrms=rms(masker);

% initial SNR
isnr=db(trms)-db(mrms); 

% Code dependent SNR setting
switch code
    case {1}
        % Case 1, output SNR irrelevant
        osnr=NaN;
    case {2}        
        osnr=0; 
    case {3}
        osnr=-9; 
    otherwise
        error('Unknown code'); 
end % switch

% Set SNR
if ~isnan(osnr)
    % SNR difference to apply
    dsnr=osnr-isnr; 
    
    dsnr=db2amp(dsnr); 
    
    masker=masker./dsnr; % adjust masker levels to specified SNR. Note that 
                            % we do not want to change the target waveform
                            % at all. See Ding and Simon (2013) for more
                            % details. 
end % ~isnan(osnr)

%% MIX STIMULI
%   Add target and masker together. 
switch code
    case {1}
        stim=target; 
    otherwise
        stim=target+masker;
end % switch code

%% CLIPPING CHECK
%   Double check that no clipping has occurred after summation. If so, then
%   normalize stimuli (divide by absolute maximum value).
stim = stim./max(max(abs(stim)));

%% SEND STIMULI TO TDT
%   Upload stimuli to TDT

%% MAIN CONTROL LOOP
%   Main stimulus control loop.

%% SET SOA
%   Set stimulus onset asynchrony (SOA) by setting serial buffer size in
%   TDT circuit. 
%
%   Or, set a timer/counter to initialize the stimulus at a set interval
%   (probably cleaner). Importantly, though, we want TDT to control the
%   timing as much as possible. Just have MATLAB send some values along. 
%
%   Also do quick sanity check to make sure that buffer size is large
%   enough to allow for longest SOA.

%% PRESENT STIMULI
%   Should be handled automatically by TDT hardware/circuit

%% WAIT FOR STIMULI TO COMPLETE
%   Maybe set a flag or monitor buffer position. Dunno exactly. 

%% TIMING CHECK
%   Track timing to make sure our SOA is approximately what it should be. 
%
%   Not sure how to do this cleanly yet. 
