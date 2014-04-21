function RP=AA_noisecheck(SESSTYPE, CIRCUIT)
%% DESCRIPTION:
%
%   Basic paradigm for Experiment AA04. The function is very barebones and
%   primarily serves as a convenient way to change parameters within the
%   corresponding RPX file. Briefly, the function will load the correct
%   data file, invert the polarity of the file if necessary, and set
%   trigger codes/timing information in the RPX file.
%
% INPUT:
%
%   SESSTYPE:   integer, value describing the session type. Values
%               correspond to properties defined below:
%                   1:  /ba/, native polarity
%                   2:  /mba/, native polarity
%                   3:  /ba/, inverted polarity
%                   4:  /mba/, inverted polarity
%                   5:  /ba/, native polarity, earphone unattached
%                   255:/ba/, native polarity, CODE TESTING ONLY!
%
%   CIRCUIT:    string, full path to circuit to load. This input is *not*
%               required and is used primarily for debugging purposes.
%               Unless your protocol explicitly instructs you to set this
%               parameter, then leave it empty.
%
% OUTPUT:
%
%   RP:     Active X controller object for RP2.1. 
%
%   Note: As of 01/30/2014, this has not been tested with the TDT system.
%
% Christopher W. Bishop
%   University of Washington
%   1/14

%% NEUROSCAN SAFEGUARD
r=[];
while ~strcmpi(r,'y')
    r=input(['Have you started the Neuroscan recording?? (y/n) then ' '''enter'': '], 's');
end % while ~strcmpi(r, 'y')
    
%% INPUT CHECKS AND DEFAULTS
%   Check input paramters and set default values for other experimental
%   parameters.

% Load default circuit
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT)
    CIRCUIT=fullfile('..', 'RP_Files', 'AA04.rcx');
end % if ~exist('CIRCUIT', 'var') ...

%% DEFAULT TRIGGER DELAYS
%   Different delays for the two sounds.
%   Empirically verified by CWB on 2/4/2014.
%   See http://www.evernote.com/shard/s353/sh/5c9cc9fc-e602-45b3-86e8-c5016d797b09/5cafb3acec6ac68b42c844e805ef7ddd
%
%   A constant offset of 5.719999999999892e-04 added to both to better
%   match trigger times. There's some small imprecision somewhere in my
%   initial measurement loop. 
% badelay=0.0637 + 0.1469124;         % /ba/ delay in sec
% mbadelay=0.0566 +  0.154012;        % /mba/ delay in sec
badelay=0.0637 + 5.719999999999892e-04;     % /ba/ trigger delay in sec
mbadelay=0.0566 + 5.719999999999892e-04;    % /mba/ trigger delay in sec

% Set correct filename (P) and Trigger CODE (TCODE)
%   Also performs input check on SESSTYPE and throws an error if the input
%   isn't one of the expected 4 values.
%
%   Also set custom Trigger DELAYs s
switch SESSTYPE
    case {1, 3}
        % load /ba/
        P=fullfile('..', 'stims', 'MMBF7.wav'); 
        
        % Set trigger code
        TCODE=1; 
        
        % Trigger delay
        %   Time locked to sound onset. Empirically verified by CWB on XXX.
        TDELAY=badelay; 
    case {2, 4}
        % load /mba/
        P=fullfile('..', 'stims', 'MMBF6.wav'); 
        
        % Set trigger code
        TCODE=2;
        
        % Trigger delay
        %   Time locked to sound onset. Empirically verified by CWB on XXX.
        TDELAY=mbadelay; % trigger delay in samples
    case {5}
        % load /ba/
        P=fullfile('..', 'stims', 'MMBF7.wav'); 
        
        % Set trigger code
        TCODE=5; 
        
        % Trigger delay
        %   Time locked to sound onset. Empirically verified by CWB on XXX.
        TDELAY=badelay;
    case {255}
        % Designed for trigger timing tests. 
        P=fullfile('..', 'stims', 'MMBF6.wav'); 
        
        % Set trigger code
        %   Set to 255 to raise all pins and make it easier to test timing.
        TCODE=255; 
        
        % Trigger delay
        %   Time locked to sound onset. Empirically verified by CWB on XXX.
        TDELAY=mbadelay; 
    otherwise
        error('AA04:InvalidSESSTYPE', ...
            ['''' num2str(SESSTYPE) ''' is not a valid input [1,2,3,4,5,255].']);
end % switch SESSTYPE

% Load data and sampling rate from file
[DATA, dfs]=wavread(P); 

% Polarity inversion
switch SESSTYPE
    case {3, 4}        
        disp('Inverting polarity!'); 
        
        % Invert polarity
        DATA=DATA.*-1; 
        
        % Change TCODE
        %   Add 2 to reflect inverted polarity.
        TCODE=TCODE+2; 
    otherwise
        disp('Native polarity used!');
end % switch SESSTYPE (polarity inversion)

% Experiment parameters(e.g., SOA, FS, NTRIALS, TCODE, TTIME)
SOA=0 + length(DATA)./dfs;      % Stimulus Onset Asynchrony (SOA) in seconds. Later converted to samples.
                                    % This is equivalent to a 1.993 s ISI.
                                    % This can be modified to use a
                                    % uniformly sampled jitter window if
                                    % necessary. 
NTRIALS=100000;      % Number of TRIALS for this session.
FSLEVEL=3;      % TDT FSLEVEL corresponding to ~50 kHz sampling rate. High sampling rate to prevent digitizator noise
% TDELAY=TDELAY+ 0.146928;    % CWB Notes a constant trigger offset using AA04.rcx. This corrects for it.
                            % CWB slightly confused why the triggers are so
                            % delayed, but can't figure it out at the
                            % moment.
TRIGDUR=0.02;   % TRIGger DURation (sec)

% Pad stimulus to correct SOA
if length(DATA)/dfs>SOA
    % If stimulus is longer than SOA, then throw an error. We can't support
    % SOAs that are too short.
    error('AA04:ShortSOA', ...
        'The SOA is too short for this stimulus!');
end % if length(DATA)/dfs
    
% ESTABLISH CONNECTION WITH RP 2.1
RP = actxcontrol('RPco.x',[5 5 26 26]);
% RP=actxcontrol('RPCo.x',[0 0 0 0]);
RP.ConnectRP2('USB', 1);

% CLEAR Control Object File (COF)
RP.ClearCOF; % First clear the COF

% LOAD COF AND SET SAMPLING RATE
RP.LoadCOFsf(CIRCUIT, FSLEVEL); 

% GET SAMPLING RATE
FS = RP.GetSFreq; 

% SAMPLING RATE CHECK
%   Compare file sample rate against TDT sampling rate. If they don't match
%   perfectly, throw a shoe to prevent any errors.
%   
%   300114 CWB: Changed to warning coupled with resampling procedure.
%   Prevents CWB from having to keep multiple file versions around. The
%   resampling procedure does not take long.
if FS ~= dfs 
    % Save duration of sound in native format
    ldata=length(DATA)/dfs; 
    
    warning('AA04:MismatchedSamplingRate', ...
        ['Sampling rates differ between TDT hardware (' num2str(FS) ') and ' P ' (' num2str(dfs) '). Resampling']);
    % Resample DATA to sampling rate on TDT system
%     DATA=resample(DATA, FS, dfs);

    % TDT often has a fractional sampling rate, so we need to interpolate
    % the sound instead of resample. Resample requires whole integer
    % values, which we simply don't have the luxury of.
    DATA=interp1(1:length(DATA), DATA, 1:dfs/FS:length(DATA), 'linear');
    
    % A catch just in case interpolation biffs something.
    %   Interpolation will typically be off by 1 sample, so the duration
    %   errors should be very small provided the sampling rate is high
    %   enough. 
    rdata=length(DATA)/FS;
    if ldata ~= rdata
        warning('AA04:DurationMismatch', ...
            ['Duration of resampled data differs from expected by ' num2str(rdata-ldata) '.\n' ...
            'Or, equivalently, ' num2str((rdata-ldata)*FS) ' sample error']);            
    end % ldata~=length(DATA)/FS
end % if FS~=dfs
    
% Otherwise, zero pad the stimulus to the desired SOA
zpad=round(SOA*FS - length(DATA)); % to within a sample
DATA=[DATA zeros(1,zpad)];

% STOP ONGOING PROCESSING
RP.Halt;     

%% BUFFER SIZE CHECK
%   CWB was dumb and accidentally set the buffer size to 100,000 samples,
%   which is too short for a >2 s sound file. Consequently, the beginning
%   of the file was being overwritten by zeros at the end of the file. This
%   error check is in place to protect CWB in the future from his complete
%   inability to multiply ~50,000 * 2.25. Win.
if length(DATA) > RP.GetTagVal('WavSize')
    error('AA04:BufferTooSmall', ...
    ['The buffer is too small! Increase to a minimum of ' num2str(length(DATA)) '!']);
end % if length(DATA) > RP.GetTagVal

%% SET TDT TAG VALUES
%   Several of these must be converted to samples first. 
if ~RP.SetTagVal('WavSize', length(DATA)), error('Parameter not set!'); end
if ~RP.WriteTagV('Snd', 0, DATA), error('Data not sent to TDT!'); end
if ~RP.SetTagVal('TrigDelay', round(TDELAY*FS)), error('Parameter not set!'); end % TRIGger DELAY in SAMPLES
% if ~RP.SetTagVal('TrigDelay', round(250)), error('Parameter not set!'); end % TRIGger DELAY in msec
if ~RP.SetTagVal('TrigDur', round(TRIGDUR*FS)), error('Parameter not set!'); end       % TRIGger DURation in samples
if ~RP.SetTagVal('TrigCode', TCODE), error('Parameter not set!'); end               % Trigger CODE
if ~RP.SetTagVal('NTRIALS', NTRIALS), error('Parameter not set!'); end              % Number of TRIALS

%% START THE CIRCUIT
RP.Run;

%% SOFTWARE TRIGGER
%   Starts sound playback with the NTRIALS * length(DATA) samples played.
RP.SoftTrg(1);

%% TRACK COUNTER AND ESTIMATED TIME TO COMPLETION
%   Could also see if we can set ENABLE input value to NTRIALS *
%   LENGTH(DATA). 

% make an 'edit' uicontrol to show the sweeps
tdisplay = uicontrol('style','edit','string', sprintf('Trial Number\nTime to Completion'),'units','normalized','position',[.2 .6 .6 .3], 'Max', 3, 'Min', 1);
h=gcf; 
% get counter value
COUNTER=RP.GetTagVal('Counter'); 

while COUNTER<=NTRIALS-1 % SimpCount starts at 0, so remove one here
    COUNTER=RP.GetTagVal('Counter'); 
    
    % Round estimated remaining time to tenths place
    set(tdisplay,'string',sprintf(['Trial Number: %d (of %d).\n' ...
    'Estimated Time to Completion: %.1d s'],COUNTER, NTRIALS, round(length(DATA)./FS*(NTRIALS-COUNTER)*10)/10));
    pause(length(DATA)/FS/4); % Sample 4 times a sweep. 
%     disp(['Trial: ' num2str(COUNTER+1)]); 
end % while COUNTER<=NTRIALS-1

%% CLOSE COUNTER BOX
close(h); 

%% TELL USER IT'S OVER!
display('AA04_Paradigm complete. Stop the Neuroscan recording.');