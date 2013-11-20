function AA01_Playback_Triggers(DATA, TRIG, CIRCUIT, FSLEVEL, TRIGDELAY, TEST)
%% DESCRIPTION:
%
% INPUT:    
%
%   DATA:   double, single channel data
%   TRIG:   integer, specifying 8-bit trigger code (0-255)
%   FSLEVEL:    FS setting for TDT; 
%                   0=6k
%                   1=12k
%                   2=25k
%                   3=50k
%                   4=100k
%                   5=200k
%                   6=400k
%   TRIGDELAY:  trigger delay relative to buffer playback (msec). Note that
%               TDT's TTLDelay component requires a minimum of 1 msec
%               delay.
%   TEST:   bool, run trigger test. If true, no sounds will play.
%           (default=false).
%
% Bishop, CW
%   University of Washington
%   11/13

%% DEFAULTS
if ~exist('TEST', 'var') || isempty(TEST)
    TEST=false;
end % ~exist

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
RP.SetTagVal('Trig', TRIG);

%% SET TRIGGER DELAY
RP.SetTagVal('TrigDelay', TRIGDELAY); 

%% FEED IN USER SPECIFIED PARAMTERS
RP.WriteTagV('Snd', 0, DATA); 

%% START THE CIRCUIT
RP.Run;

%% FOR TESTING TRIGGER OUTPUT
%   Useful for debugging. Comment out if you don't need it.
%   Initiates trigger XXXX times using Software Trigger 4
%
%   Raises pin for 20 ms

if TEST
    RP.SetTagVal('TrigDur', ceil(FS*0.020)); 
    for i=1:10000
        RP.SoftTrg(4);
        pause(0.5);
    end % 
end % if TEST

%% PLAY THE SOUND
RP.SoftTrg(1); 
% RP.SoftTrg(2); 