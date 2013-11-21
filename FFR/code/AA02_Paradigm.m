function RP=AA02_Paradigm(DATATYPE, CIRCUIT)
%% DESCRIPTION:
%
%   Paradigm for Project AA Experiment 02. ALL inputs are optional, except
%   for the subject ID.
%
% INPUT:
%
%   DATATYPE:   integer, 0 (no AM) or 1 (20 Hz AM)
%   CIRCUIT:    string, full path to RCX file to load into TDT. Defaults to
%               relative path ../RP_Files/RCX_FILE, which assumes you're
%               currently in the code directory of the project. If this
%               isn't true, you're in the wrong directory anyway ;). 
%
% OUTPUT:
%
%   RP:         handle to RP object. 
%
% Christopher W. Bishop
%   University of Washington 
%   11/13

%% MATLAB INITIALIZATION
% Default variables
if ~exist('DATATYPE', 'var'), DATATYPE=[]; end

% Number of trials per block. Matching this to Experiment AA01 as closely
% as possible.
NTRLS=500; 

% Randomization
rng('shuffle', 'twister');

% ISI (sec)
%   Uniformly sampled ISI (offset to onset). This will only be approximate
%   since I plan to use the pause() function in MATLAB to control this.
ISI=[0.500 0.800]; %

%% TDT STARTUP
% Sampling Rate
%   100 kHz Sampling rate
%   Note: Audible frequency distortions if recording and presenting to
%   multiple channels simultaneously. If this occurs, decrease sampling
%   rate (e.g., FSLEVEL=3, or ~50 kHz).
FSLEVEL=4; % 100 kHz; Any faster than this causes distortions when trying to play/record simultaneously.

%   Circuit default
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT)
    CIRCUIT=fullfile('..', 'RP_Files', 'AA02.rcx'); 
end % 

% ESTABLISH CONNECTION WITH RP 2.1
RP = actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRP2('USB', 1);

% CLEAR Control Object File (COF)
RP.ClearCOF; % First clear the COF

% LOAD COF AND SET SAMPLING RATE
RP.LoadCOFsf(CIRCUIT, FSLEVEL); 

% GET SAMPLING RATE
FS = RP.GetSFreq; 

% STOP ONGOING PROCESSING
RP.Halt;     

%% STIMULUS, CODE SELECTION
if DATATYPE==0
    % NO AM STIMULUS
    wl=0.015;
    tone1 = sin_gen(1000, 1, FS, 0);
    tone2 = sin_gen(985, 1, FS, 0);
    w = hanning(ceil(wl*FS*2)); % double the duration of the hanning window.
    w = w(1:ceil(wl*FS)); % cut hanning window in half, just the initial ramp
    W = [w; ones((size(tone1,1) - size(w,1)*2),1); flipud(w)]; % on/off ramps and full amplitude between.
    DATA = [tone1.*W; tone2.*W].*.9; % normalize max amplitude to 0.9 to match normalized amplitude from make_AM_FDL_... used to make 20 Hz AM stims.    
    DATA=DATA'; % flip for TDT. It gets grumpy otherwise.
    TCODES=[4 16];
elseif DATATYPE==1
    DATA=make_AM_FDL_tones_2freq_4FFR(FS, 1000, 985, false, false, 20, 2, false);
    TCODES=[2 8];
else
    error('Invalid data type selected');
end % if 

%% SET TDT TAG VALUES
% Buffer size
if ~RP.SetTagVal('WavSize', length(DATA)), error('Parameter not set!'); end
% Trigger at start of sound
if ~RP.SetTagVal('TrigBeg', TCODES(1)), error('Parameter not set!'); end 
% Trigger approximately at midpoint of shift
if ~RP.SetTagVal('TrigMid', TCODES(2)), error('Parameter not set!'); end 
% Send data to TDT
if ~RP.WriteTagV('Snd', 0, DATA), error('Data not sent to TDT!'); end

%% START THE CIRCUIT
RP.Run;

%% PLAY SOUNDS
%   Present sounds via software trigger, then wait an appropriate length of
%   time.
for i=1:NTRLS
    RP.SoftTrg(1);
    % Wait for data to playback, then add in the ISI. This will only give
    % APPROXIMATELY the correct ISI window, but it's not hugely important.
    % That's why CWB isn't taking the time to do this a more robust way. 
    pause( length(DATA)/FS + ISI(1) + (ISI(2)-ISI(1))*rand(1));
end % i=1:100


% if ~TIMING_TEST
%     RP.SoftTrg(1); 
% elseif TIMING_TEST
%     
%     % Acquire first 10 ms
%     bufpts=ceil(0.01*FS);
%     RECDATA=nan(2,bufpts,2); 
%     
%     % 
%     for i=1:20
%         RP.SoftTrg(1);
%         
%         % Wait until buffer fills with sound    
%         while(RP.GetTagVal('index')<bufpts), end
%     
%         % Pull data out of buffer
%         RECDATA(:,:,i)=RP.ReadTagVEX('dataout', 0, bufpts,'I16','F64',2);       
%         RP.SoftTrg(2);
%         pause(1); 
%     end % i=1:...
% end % if ~TIMING_TEST