function AA03_behavior(SID, BEH_TYPE, LOCAL_AUDIO, CIRCUIT)
%% DESCRIPTION:
%
%   MATLAB based port of behavioral testing used in VOT training. This is
%   done using a combination of response tracking (PsychToolbox) and high
%   fidelity sound output recordings using TDT software. Local audio can be
%   used for testing purposes, but should *not* be used for experimental
%   purposes since the timing precision of the local audio drivers will
%   differ. PsychoPortAudio() has not been tested at all by CWB as of
%   1/30/2014, so don't trust it for experimental purposes.
%
% INPUT:
%
%   SID:    string, subject ID (e.g., SID='s0133'); 
%   BEH_TYPE:       string, behavioral session type. (NOT IMPLEMENTED)
%                       Options:
%                           'behavior': XXX
%                           'exposure': XXX
%                           'training': XXX
%   LOCAL_AUDIO:    bool, present sounds via local Audio device. For
%                   debugging *ONLY*. Should not be used for psychophysical
%                   testing. (default=false)
%   CIRCUIT:    TDT circuit to use for sound playback. (default = AA03.rcx)
%
% OUTPUT:
%
%   Nothing useful CWB can think of at present ...
%
% List of desired features
%
%   - Support TDT and local audio. Local audio for testing only.
%   - Track and save stimulus order, responses, reaction time data to MAT
%   file
%   - Button presses for response selection

%% INPUT CHECK AND DEFAULTS
%   Default to TDT playback
%   Default to AA03.rcx
if ~exist('LOCAL_AUDIO', 'var') || isempty(LOCAL_AUDIO), LOCAL_AUDIO=false; end
if ~exist('CIRCUIT', 'var') || isempty(CIRCUIT), CIRCUIT=fullfile('..', 'RP_Files', 'AA03.rcx'); end

%% EXPERIMENT PARAMETERS
%   These can be modified and *should* be handled intelligently throughout
%   the rest of the code. Nothing else should need to be changed. If you
%   change a parameter and something crashed, tell CWB immediately. *Do
%   not* go digging through the code unless you're intimiately familiar
%   with MATLAB. And even then you should consult CWB.

% Trial information
%   Number of trials
%   Trial timing information
NTRIALS=10;                 % Number of trials for each VOT (e.g., 25 means 50 trials total if /ba/ and /mba/ are tested)
DELAY_AFTER_RESPONSE=2;     % Time delay before start of next trial after response key is pressed (sec)
FEEDBACK_DELAY=1;         % Feedback delay after response (sec)
FEEDBACK_DURATION=1;        % Duration of feedback (duration of color change)

% Audio information
CHANNEL=2;                  % Channel to present sound to. 1=left, 2=right, 3=stereo (not implemented)
FILES={...
    fullfile(pwd, '..', 'stims', 'MMBF6.WAV') ...   % full path to /ba/ stimulus
    fullfile(pwd, '..', 'stims', 'MMBF7.WAV')};   % full path to /mba/ stimulus
FSLEVEL=3;  % TDT sampling rate (Level 3 = ~49kHz, but poll info to be sure)

% Screen information
SCREEN_NUM=max(Screen('Screens'));     % secondary monitors used by default. 

% Response information
RESP_KEYS={'B' 'M'};    % first entry for /ba/, second for /mba/

%% SAVED DATA PARAMETERS
%   Parameters to save to mat file. 
TORDER=AA04_SESSORDER(1:length(FILES), NTRIALS);   % randomize using AA04_SESSIONORDER
KBRESP=nan(size(TORDER));                   % initialize with nans so screening for issues easy.
RESPTIME=nan(size(TORDER));                 % RESPTIME in ... some unit of time ...

%% INITIALIZE SUBJECT
%   Create subject specific mat file with date prepended.
INITIALIZE_SUBJECT;

%% INITIALIZE SOUND PLAYBACK DEVICE/DRIVER
%   If we are using TDT, initialize the device here. Otherwise, initialize
%   PsychPortAudio
if ~LOCAL_AUDIO
    % Initialize TDT
    % ESTABLISH CONNECTION WITH RP 2.1
    RP = actxcontrol('RPco.x',[5 5 26 26]);    
    RP.ConnectRP2('USB', 1);

    % CLEAR Control Object File (COF)
    RP.ClearCOF; % First clear the COF

    % LOAD COF AND SET SAMPLING RATE
    RP.LoadCOFsf(CIRCUIT, FSLEVEL); 

    % GET SAMPLING RATE
    FS = RP.GetSFreq;       
    
else
    % Initialization from BasicSoundOutputDemo.
    %   This doesn't seem to be low-latency mode, so this should not be
    %   used for research related purposes - just for debugging. 
    InitializePsychSound;
    
    % Get PsychPortAudio Handle
    PORTAUDIO = PsychPortAudio('Open', [], [], 0, dfs, 2); 
end % ~LOCAL_AUDIO

%% PRESENT DEFAULT SCREEN
%   Screen should have a white fixation cross with instructions below it
%   reading "index finger=/ba/ middle finger=/mba/" or something to that
%   effect.
% Screen('Preference', 'SuppressAllWarnings', 1); % we don't care so much
% about visual timing, so suppress visual warnings. 
% w=Screen('OpenWindow', SCREEN_NUM);
% Screen('FillRect', w);
% Screen('TextFont',w, 'Courier New');
% Screen('TextSize',w, 50);
% Screen('TextStyle', w, 1+2);
% Screen('DrawText', w, 'Hello World!', 100, 100, [0, 0, 255, 255]);
% Screen('TextFont',w, 'Times');
% Screen('TextSize',w, 30);
% Screen('DrawText', w, 'Hit any key to exit.', 100, 300, [255, 0, 0, 255]);
% Screen('Flip',w);
% KbWait;
% Screen('CloseAll');

%% LOAD AUDIO FILES
%   Load in audio files
SNDS=[];
for i=1:length(FILES)
    % Load individual file
    [data, dfs]=wavread(FILES{i});
    
    % Check data size
    if min(size(data))~=1        
        % If this is a stereo file
        error('AA03:StereoFile', ...
            [FILES{i} ' appears to be a multichannel file. I cannot work with that at present.']);
    elseif size(data,2)>1
        % transpose data
        data=data';
    end % if size(data,2)==2
        
    % Resample data for TDT if TDT is used and sample rates do not match
    %   Only resample if TDT is used and sampling rates do not match. For
    %   typical sampling rates (e.g., 44.1 kHz), data will need to be
    %   resampled. 
    %
    %   CWB used interp1 instead of resample because interp1 deals with
    %   fractional sampling rates. Resample requires integer sampling
    %   rates, which TDT doesn't seem to use ... ever. 
    if ~LOCAL_AUDIO && (FS ~= dfs)
        data=interp1(1:length(data), data, 1:dfs/FS:length(data), 'linear');
    end % ~LOCAL_AUDIO
    
    % Initialize SND data to zeros (no sound)
    SNDS(:,1:2,i)=zeros(length(data),2); 
    
    % Load data into appropriate channels
    switch CHANNEL        
        case {1,2}
            % Monaural data, either left (1) or right (2) channel
            SNDS(:,CHANNEL,i)=data; 
        case {3}
            % Stereo file
            SNDS(:,1:2,i)=data*[1 1];
        otherwise
            error('AA03:Channel', ...
                [num2str(CHANNEL) ' is an unsupported channel option.']);
    end % switch
end % 

%% CONVERT RESPONSE KEYS FROM STRINGS TO INTEGERS
%   Initialize to nan for speed.    
resp_keys=nan(size(RESP_KEYS)); 
for k=1:length(RESP_KEYS)
    resp_keys(k)=KbName(RESP_KEYS{k});
end % for k=1:length(RESP_KEYS)   

%% SET TDT PARAMETERS AND START CIRCUIT
if ~LOCAL_AUDIO
    TCODE=255;
    TDELAY=0.0637 + 5.719999999999892e-04;
    TRIGDUR=0.02;
    if ~RP.SetTagVal('WavSize', size(SNDS,1)), error('Parameter not set!'); end
    if ~RP.SetTagVal('TrigDelay', round(TDELAY*FS)), error('Parameter not set!'); end % TRIGger DELAY in SAMPLES        
    if ~RP.SetTagVal('TrigDur', round(TRIGDUR*FS)), error('Parameter not set!'); end       % TRIGger DURation in samples
    if ~RP.SetTagVal('TrigCode', TCODE), error('Parameter not set!'); end               % Trigger CODE
    if ~RP.SetTagVal('NTRIALS', NTRIALS), error('Parameter not set!'); end              % Number of TRIALS
    RP.Run;
end % ~LOCAL_AUDIO

%% BEGIN EXPERIMENT
for i=1:length(TORDER)
    
    % Get timing at beginning of trial
    %   Use GetSecs (PsychToolbox) because it claims to have better
    %   precision.    
    if ~LOCAL_AUDIO
       
        
        % SET TDT TAGS
        
        if ~RP.WriteTagV('Snd', 0, SNDS(:,CHANNEL,TORDER(i))'), error('Data not sent to TDT!'); end
       
%         if ~RP.SetTagVal('WavSize', size(SNDS,1)), error('Parameter not set!'); end
%         if ~RP.SetTagVal('TrigCode', 255), error('Parameter not set!'); end % for debugging
%         if ~RP.SetTagVal('TrigDur', round(0.02*FS)), error('Parameter not set!'); end % for debugging
%         if ~RP.SetTagVal('TrigDelay', round(0.1*FS)), error('Parameter not set!'); end % TRIGger DELAY in SAMPLES
        
        
        % Unset parameters
        %   TrigDelay, TrigDur, TrigCode
        
        % Fill TDT Serial Buffer
        %   Note that the channel sound is presented to must be set in the
        %   RCX file. 
%         if ~RP.WriteTagV('Snd', 0, SNDS(:,CHANNEL,TORDER(i))'), error('Data not sent to TDT!'); end        
    else
        % Presnt locally using PsychPortAudio drivers
        % Fill the audio playback buffer with the audio data 'wavedata':
        PsychPortAudio('FillBuffer', PORTAUDIO, SNDS(:,:,TORDER(i))');
    end % ~LOCAL_AUDIO
    
    % Trial starts after sound is loaded into correct buffer.
    start_time=GetSecs;
    
    if ~LOCAL_AUDIO
        % Begin TDT playback
        RP.SoftTrg(1);        
    else
        % Start audio playback for 'repetitions' repetitions of the sound data,
        % start it immediately (0) and wait for the playback to start, return onset
        % timestamp.
        %
        % CWB has no idea what the last input is - PsychPortAudio's help
        % file looks like it was written by advanced primates. 
        PsychPortAudio('Start', PORTAUDIO, 1, 0, 1);        
    end % if ~LOCAL_AUDIO
    
    
    
    % Use custom function to wait for specific key presses.
    %   second input turns character display (i.e., typing will not appear
    %   in command window). If you want to see what you or a subject are/is
    %   typing, set to "true".
    [rtime, key_num]=KbWait4Key(resp_keys, true);     
       
    % Record responses in larger array.
    RESP(i)=key_num; 
    
    % Record response time (sec)
    RESPTIME(i)=rtime-start_time; 
    
    % Provide feedback 
    %   Check response against filenames
    [routcome]=RESP_CHECK(TORDER(i), resp_keys, RESP(i)); 
    
    % Insert your custom feedback routine here. First guess is that a
    % simple color change of the fixation cross would be fine. 
    COLORCHANGE;
    
    % Save data
    %   use save command
    
end % for i=1:length(TORDER)

end % AA03_behavior

function INITIALIZE_SUBJECT()
%% DESCRIPTION:
%
%   Function to initialize files and the like for this subject. 
%
% INPUT:
%
% OUTPUT:
%
% Christopher W. Bishop
%   University of Washington
%   1/14

% Determine name of mat file
% Check to see if mat file exists
%   If it does, throw a shoe or append a counter. Not sure yet. 
% Do other stuff I can't think of right now. 
end % INITIALIZE_SUBJECT

function [OUTCOME]=RESP_CHECK(STIM, RESP_KEYS, RESP)
%% DESCRIPTION:
%
%   Function to check accuracy of most recent response. Returns a binary
%   outcome if the response is correct (true) or incorrect (false). Very
%   simple checking done here, but CWB wanted to modularize it to allow for
%   more sophisticated checking system and time management in the future.
%   If it's needed, that is. 
%
% INPUT:
%
%   STIM:   integer, stimulus number presented.
%   RESP_KEYS:  integer array, response key numbers as returned by KbName.
%   RESP:   listener response.
%
% OUTPUT:
%   
%   OUTCOME:    bool, true if response is correct, false if incorrect.
%   incorrect.
%
% Christopher W. Bishop
%   University of Washington
%   1/14

if RESP==RESP_KEYS(STIM)
    OUTCOME=true;
else 
    OUTCOME=false;
end % RESP==RESP_KEYS(STIM)
end % RESP_CHECK

function COLORCHANGE
%% DESCRIPTION:
%
%   Function to provide listener feedback by changing the color of a cross
%   on the screen. 
%
% INPUT:
%
% OUTPUT:
%
% Christopher W. Bishop
%   University of Washington
%   1/14
end % function