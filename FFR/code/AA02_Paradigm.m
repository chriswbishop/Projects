function AA02_Paradigm(CIRCUIT)
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
%
% OUTPUT:
%
%   XXX
%
% Christopher W. Bishop
%   University of Washington 
%   11/13

%% DEFAULTS

% TDT Sampling Rate (~100 kHz)
FSLEVEL=4; % 100kHz

%   Circuit default
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT)
    CIRCUIT=fullfile('..', 'RP_Files', 'AA02.rcx'); 
end % 

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
DATA=make_AM_FDL_tones_2freq_4FFR(FS, 1000, 950, false, false, 20, 1, false);
% DATA=[ones(ceil(FS*0.0005),1); zeros(ceil(FS*1),1)]; 
% DATA=[DATA; DATA; DATA; DATA];

%% SET BUFFER LENGTH
RP.SetTagVal('WavSize', length(DATA));

%% STOP ONGOING PROCESSING
RP.Halt; 
    
%% SET TRIGGER VALUE
RP.SetTagVal('Trig', 255); % 255 for testing

%% SET TRIGGER DELAY
RP.SetTagVal('TrigDelay', 0); % 1 sec delay for testing

%% FEED IN USER SPECIFIED PARAMTERS
RP.WriteTagV('Snd', 0, DATA); 

%% START THE CIRCUIT
RP.Run;

%% PLAY SOUND
RP.SoftTrg(1); 