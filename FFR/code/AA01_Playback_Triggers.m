function AA01_Playback_Triggers(DATA, TRIG, CIRCUIT, FSLEVEL)
%% DESCRIPTION:
%
% INPUT:    
%
%   DATA:   double, single channel data
%   TRIG:   integer, specifying 8-bit trigger code (0-255)
%
%

%% ESTABLISH CONNECTION WITH RP2.1
RP = actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRP2('USB', 1);

%% SET SAMPLING FREQUENCY LEVEL IF DEFINED
% 0=6k
% 1=12k
% 2=25k
% 3=50k
% 4=100k
% 5=200k
% 6=400k
switch FSLEVEL
    case{0,1,2,3,4,5,6}
        disp('FSLEVEL seems reasonable');
    otherwise
        disp('Ignoring your FSLEVEL setting; setting to default (4)');
        FSLEVEL=4; 
end % switch

%% LOAD CIRCUIT AND SET SAMPLING RATE
RP.ClearCOF; % First clear the COF
RP.LoadCOFsf(CIRCUIT, FSLEVEL); 

%% GET REAL SAMPLING RATE
%   Sampling frequencies have some slop, so see what it really is.
FS = RP.GetSFreq; 

%% SET USER SPECIFIED PARAMETERS AND DEFAULTS
%   DATA
%   TRIG
%   ISI
%   TRIGDELAY

% DEFAULT SOUND OUTPUT
%   1 sec modulated carrier with frequency shift (1kHz -> 0.95 kHz at
%   midpoint)
if ~exist('DATA', 'var') || isempty(DATA)
    DATA=make_AM_FDL_tones_2freq_4FFR(FS, 1000, 950, false, false, 20, 1, false); 
end % if ~exist('DA...

%% STOP ONGOING PROCESSING
RP.Halt; 
    
%% SET TRIGGER VALUE
% RP.WriteTagV('Trig', 0, 255); 

%% FEED IN USER SPECIFIED PARAMTERS
RP.WriteTagV('Snd', 0, DATA); 

%% START THE CIRCUIT
RP.Run;

%% PLAY THE SOUND
RP.SoftTrg(1); 
% RP.SoftTrg(2); 