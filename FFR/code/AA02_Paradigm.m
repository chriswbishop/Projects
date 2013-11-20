function [RP, RECDATA]=AA02_Paradigm(TIMING_TEST, CIRCUIT)
%% DESCRIPTION:
%
%   Paradigm for Project AA Experiment 02. ALL inputs are optional, except
%   for the subject ID.
%
% INPUT:
%
%   CIRCUIT:    string, full path to RCX file to load into TDT. Defaults to
%               relative path ../RP_Files/RCX_FILE, which assumes you're
%               currently in the code directory of the project. If this
%               isn't true, you're in the wrong directory anyway ;). 
%   TIMING_TEST:    bool, set to true if you'd like to conduct a timing
%                   test. (default=false)
%
% OUTPUT:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington 
%   11/13

%% DEFAULTS

% TDT Sampling Rate (~50 kHz)
FSLEVEL=3; % 50 kHz; Any faster than this causes distortions when trying to play/record simultaneously.

%   Circuit default
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT)
    CIRCUIT=fullfile('..', 'RP_Files', 'AA02.rcx'); 
end % 

% Timing Test?
if ~exist('TIMING_TEST', 'var') || isempty(TIMING_TEST)
    TIMING_TEST=FALSE;
end % ~exist('TIMING...

%% ESTABLISH CONNECTION WITH RP 2.1
RP = actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRP2('USB', 1);

%% CLEAR Control Object File (COF)
RP.ClearCOF; % First clear the COF

%% LOAD COF AND SET SAMPLING RATE
RP.LoadCOFsf(CIRCUIT, FSLEVEL); 

%% GET SAMPLING RATE
FS = RP.GetSFreq; 

%% MAKE STIMULI
%   This is a place holder for now. Will need to make the correct stimuli
%   later. 
DATA=sin_gen(1000,1,FS,0)';
% DATA=make_AM_FDL_tones_2freq_4FFR(FS, 1000, 1000, false, false, 20, 1, false);
% DATA=[zeros(ceil(FS*0.05),1); ones(ceil(FS*0.0005),1); zeros(ceil(FS*0.05),1)]; 
% DATA=[DATA; DATA; DATA; DATA];

%% SET BUFFER LENGTH
RP.SetTagVal('WavSize', length(DATA));

%% STOP ONGOING PROCESSING
RP.Halt; 
    
%% SET TRIGGER VALUE
RP.SetTagVal('Trig', 255); % 255 for testing

%% SET TRIGGER DELAY
RP.SetTagVal('TrigDelay', 0); % trigger delay

%% FEED IN USER SPECIFIED PARAMTERS
RP.WriteTagV('Snd', 0, DATA); 

%% START THE CIRCUIT
RP.Run;

%% PLAY SOUND
if ~TIMING_TEST
    RP.SoftTrg(1); 
elseif TIMING_TEST
    
    % Acquire first 10 ms
    bufpts=ceil(0.01*FS);
    RECDATA=nan(2,bufpts,2); 
    
    % 
    for i=1:20
        RP.SoftTrg(1);
        
        % Wait until buffer fills with sound    
        while(RP.GetTagVal('index')<bufpts), end
    
        % Pull data out of buffer
        RECDATA(:,:,i)=RP.ReadTagVEX('dataout', 0, bufpts,'I16','F64',2);       
        RP.SoftTrg(2);
        pause(1); 
    end % i=1:...
end % if ~TIMING_TEST