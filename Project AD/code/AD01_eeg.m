function [stim, FS]=AD01_eeg(code)
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
%   code:   condition and trigger code
%               1:  Alice in quiet
%               2:  Alice at 0 dB SNR (masker = speech shaped noise)
%               3:  Alice at -9 dB SNR (" ")
%               4:  MLST in quiet
%               5:  MLST at 0 dB SNR (" ")
%               6:  MLST at -9 dB SNR (" ")
%               7:  20 ms white noise burst in quiet
%               255:    For testing ONLY!
%
% OUTPUT:
%
%   stim:   single channel stimulus (target + masker)
%   fs:     sampling rate of stimulus
%
% Christopher W. Bishop
%   University of Washington 
%   4/14

% Intialize randomization seed
rng('shuffle', 'twister');

%% INPUT CHECKS AND DEFAULTS
%   Circuit for AD01
circuit=fullfile('..', 'RP_Files', 'AD01.rcx'); 

isi=[1.5 3]; % ISI in sec
                % analysis will rqeuire EEG to be bandpass filtered
                % (offline) to 1 - 9 Hz, so we need a large jitter window
                % to cancel out 1 Hz noise ... I think ... CWB needs to
                % think about this in earnest in the future. 
                %
                % ISIs will be randomized between the first and second
                % element of isi. 

fslevel=2;  %  2.441406250000000e+04
trigdur=0.02;
trigdelay=1.24; % Delay trigger by 1.24 ms. 

%% CODE DEPENDENT SETTINGS
%   - Set SNR
%   - Set Target and Noise stimulus
switch code
    case {1, 2, 3}
        target=fullfile('..', 'stims', 'Alice_track01_sc.wav');
        masker=fullfile('..', 'stims', 'Alice_spshn.wav'); 
        ntrials=20;
    case {4, 5, 6}
        target=fullfile('..', 'stims', 'MLST-SpeechTrack.wav'); 
        masker=fullfile('..', 'stims', 'MLST_spshn.wav');
        ntrials=20;
    case {7}
        target=fullfile('..', 'stims', '20 ms-NoiseBurst.wav'); 
        masker='';
        ntrials=150; 
    case {255}
        tfs=22050; 
        target=sin_gen(1000,0.1, tfs);
        r=window(@hann, 0.02*tfs); % 10 ms on/off ramp
        target(1:length(r)/2)=target(1:length(r)/2).*r(1:length(r)/2);
        target(end-length(r)/2 : end)=(target(end-length(r)/2 : end).*r(length(r)/2:length(r)));
        masker='';        
        ntrials=100; 
    otherwise
        error('Unknown condition code'); 
end % switch code

% Code dependent SNR setting
switch code
    case {1, 4, 7, 255}
        % Sound presented in quiet so SNR irrelevant
        osnr=NaN;
    case {2, 5}        
        % 0 dB SNR
        osnr=0; 
    case {3, 6}
        % -9 dB SNR
        osnr=-9; 
    otherwise
        error('Unknown code'); 
end % switch

%% LOAD STIMULI
%   Load using AA_loaddata. Only accept wave/double/single data types. 
p.datatypes=[1 2]; % restrict to wav and single/double array
if exist('tfs', 'var') && ~isempty(tfs), p.fs=tfs; end % work around for test click
[target, tfs]=AA_loaddata(target, p); 
[masker, mfs]=AA_loaddata(masker, p); 

%% INITIALIZE TDT
% ESTABLISH CONNECTION WITH RP 2.1
RP=actxcontrol('RPCo.x',[0 0 0 0]);
RP.ConnectRP2('USB', 1);

% CLEAR Control Object File (COF)
RP.ClearCOF; % First clear the COF

% LOAD COF AND SET SAMPLING RATE
RP.LoadCOFsf(circuit, fslevel); 

RP.Halt;

% Zero out Buffer
%   Prevents silly mistakes like playing left-over sound from previous
%   setup.
RP.WriteTagV('Snd', 0, zeros(1, RP.GetTagVal('WavSize'))); 

% GET SAMPLING RATE
FS = RP.GetSFreq; 

%% RESAMPLE STIMULI
%   Resample to TDT sampling rate
target=resample4TDT(target, FS, tfs);
% If masker is empty, then just write zeros (no masker). 
%   Need to set sampling rate to FS as well (not tfs). 
if isempty(masker), masker=zeros(size(target)); mfs=FS; end
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

% Standardize target
%   No longer necessary after CWB matched RMS values (see evernote)
% maxamp=1.3;
% target=target./maxamp; % maximum amplitude we'll run into with SNR of -9 for any stimulus. 
trms=rms(target); 
mrms=rms(masker);

% initial SNR
isnr=db(trms)-db(mrms); 

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
    case {1, 4, 7} % don't mix if it's in quiet
        stim=target; 
    otherwise
        stim=target+masker;
end % switch code

% Flip dimensions for TDT's sake. 
%   TDT wants a 1 x N vector. 
stim=stim'; 

%% CLIPPING CHECK
%   Double check that no clipping has occurred after summation. If so, then
%   throw an error.
%       This means the normalization routine above failed
if max(abs(stim))>1, error('Stimulus clipped'); end 

%% SET TDT TAG VALUES
%   Several of these must be converted to samples first. 
if ~RP.SetTagVal('WavSize', length(stim)), error('Parameter not set!'); end
if ~RP.WriteTagV('Snd', 0, stim), error('Data not sent to TDT!'); end
if ~RP.SetTagVal('TrigDur', round(trigdur*FS)), error('Parameter not set!'); end       % TRIGger DURation in samples
if ~RP.SetTagVal('trigdelay', trigdelay), error('Parameter not set!'); end       
if ~RP.SetTagVal('TrigCode', code), error('Parameter not set!'); end               % Trigger CODE

%% START THE CIRCUIT
RP.Run;

%% MAIN CONTROL LOOP
%   Main stimulus control loop.

% make an 'edit' uicontrol to show the sweeps
tdisplay = uicontrol('style','edit','string', sprintf('Trial Number\nTime to Completion'),'units','normalized','position',[.2 .6 .6 .3], 'Max', 3, 'Min', 1);

JIT=[];
for n=1:ntrials
    
    % Present stimulus/drop trigger
    RP.SoftTrg(1);
    tic;
    jit=rand(1)*(diff(isi))+isi(1); 
    JIT(n)=jit; 
    % Round estimated remaining time to tenths place
    set(tdisplay,'string',sprintf(['Trial Number: %d (of %d).\n' ...
    'Estimated Time to Completion: %.1d s'],n, ntrials, round((length(stim)./FS + mean(isi))*(ntrials-n)*10)/10));
    
    % Loop until stimulus is finished
    while ~RP.GetTagVal('TrialStatus'), end 
    
    % Pause for a while
    pause(jit); 
    toc
end % for n=1:ntrials