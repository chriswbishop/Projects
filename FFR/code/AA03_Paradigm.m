function AA03_Paradigm(SESSTYPE, CIRCUIT)
%% DESCRIPTION:
%
%   Basic paradigm for Experiment AA03. The function is very barebones and
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
%
%   CIRCUIT:    string, full path to circuit to load. This input is *not*
%               required and is used primarily for debugging purposes.
%               Unless your protocol explicitly instructs you to set this
%               parameter, then leave it empty.
%
% OUTPUT:
%
%   None that I can think of ...
%
% Christopher W. Bishop
%   University of Washington
%   1/14

%% INPUT CHECKS AND DEFAULTS
%   Check input paramters and set default values for other experimental
%   parameters.

% Load default circuit
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT)
    CIRCUIT=fullfile('..', 'RP_Files', 'AA03.rcx');
end % if ~exist('CIRCUIT', 'var') ...

% Set correct filename (P) and Trigger CODE (TCODE)
%   Also performs input check on SESSTYPE and throws an error if the input
%   isn't one of the expected 4 values.
switch SESSTYPE
    case {1, 3}
        % load /ba/
        P=fullfile('..', 'stims', 'MMBF6.wav'); 
        
        % Set trigger code
        TCODE=1; 
    case {2, 4}
        % load /mba/
        P=fullfile('..', 'stims', 'MMBF7.wav'); 
        
        % Set trigger code
        TCODE=2; 
    otherwise
        error('AA03:InvalidSESSTYPE', ...
            ['''' num2str(SESSTYPE) ''' is not a valid input (1,2,3,4).']);
end % switch SESSTYPE

% Load data and sampling rate from file
[DATA, dfs]=wavread(P); 

% Polarity inversion
switch SESSTYPE
    case {3, 4}
        % Invert polarity
        DATA=DATA.*-1; 
        
        % Change TCODE
        TCODE=TCODE+10; 
end % switch SESSTYPE (polarity inversion)

% Experiment parameters(e.g., SOA, FS, NTRIALS, TCODE, TTIME)
SOA=1.993;      % Stimulus Onset Asynchrony (SOA) in seconds. Later converted to samples
NTRIALS=400;    % Number of TRIALS for this session.
FSLEVEL=3;      % TDT FSLEVEL corresponding to ~50 kHz sampling rate. High sampling rate to prevent digitizator noise
TDELAY=0;        % Trigger TIME relative to sound onset (sec).
TRIGDUR=0.02;   % TRIGger DURation (sec)

% Pad stimulus to correct SOA
if length(DATA)/dfs>SOA
    % If stimulus is longer than SOA, then throw an error. We can't support
    % SOAs that are too short.
    error('AA03:ShortSOA', ...
        'The SOA is too short for this stimulus!');
else 
    % Otherwise, zero pad the stimulus to the desired SOA
    zpad=round(SOA*dfs - length(DATA)); % to within a sample
    DATA=[DATA; zeros(zpad,1)];
end % if length(DATA)/dfs
    
% ESTABLISH CONNECTION WITH RP 2.1
RP = actxcontrol('RPco.x',[5 5 26 26]);
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
if FS ~= dfs, error('AA03:MismatchedSamplingRate', ...
        ['Sampling rates differ between TDT hardware (' num2str(FS) ') and ' P ' (' num2str(dfs) ').']);
end % if FS~=dfs
    
% STOP ONGOING PROCESSING
RP.Halt;     

%% SET TDT TAG VALUES
%   Several of these must be converted to samples first. 
if ~RP.SetTagVal('WavSize', length(DATA)), error('Parameter not set!'); end
if ~RP.WriteTagV('Snd', 0, DATA), error('Data not sent to TDT!'); end
if ~RP.SetTagVal('TrigDelay', round(TDELAY*FS)), error('Parameter not set!'); end
if ~RP.SetTagVal('TrigDur', round(TDUR*FS)), error('Parameter not set!'); end
if ~RP.SetTagVal('TrigCode', TCODE), error('Parameter not set!'); end
if ~RP.SetTagVal('NTRIALS', NTRIALS), error('Parameter not set!'); end

%% START THE CIRCUIT
RP.Run;

%% SOFTWARE TRIGGER
%   Starts sound playback with the NTRIALS * length(DATA) samples played.
RP.SoftTrg(1);

% ALTERNATIVE USING COUNTER FEEDBACK
%% TRACK COUNTER AND END
%   Could also see if we can set ENABLE input value to NTRIALS *
%   LENGTH(DATA). 
% get counter value
% COUNTER=RP.GetTagVal('Counter'); 
% while COUNTER<=NTRIALS-1 % SimpCount starts at 0, so remove one here
%     disp(['Trial: ' num2str(COUNTER+1)]); 
% end % while COUNTER<=NTRIALS-1
%
% RP.Halt;