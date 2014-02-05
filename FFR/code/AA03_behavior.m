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
if ~exist('BEH_TYPE', 'var') || isempty(BEH_TYPE), BEH_TYPE='behavior'; end % set to no feedback task by default. Safest. 

%% INITIALIZE RANDOMIZATION SEED
%   Without this, trial order will be the same when MATLAB is started.
rng('shuffle', 'twister')

%% EXPERIMENT PARAMETERS
%   These can be modified and *should* be handled intelligently throughout
%   the rest of the code. Nothing else should need to be changed. If you
%   change a parameter and something crashed, tell CWB immediately. *Do
%   not* go digging through the code unless you're intimiately familiar
%   with MATLAB. And even then you should consult CWB.

% Condition specific information
%   Trial timing information
%   Feedback information
switch lower(BEH_TYPE)
    case {'behavior'}
                
    case {'training'}
        
        % Trial timing information
        DEL_RESP2FEED=1;    % Delay between response and feedback (sec)
        DUR_FEED=0.3;       % Feedback duration (sec)
        DEL_FEED2TRL=2;     % Delay after feedback to beginning of next trial (sec)
        
        % Default screen information
        %   Information for button presses. 
        
        % Response information
        RESP_KEYS={'B' 'M'};    % first entry for /ba/, second for /mba/
    case {'exposure'}
end % switch lower(BEH_TYPE)

% Universal key information
QUIT_KEY='Q';

% Universal trial information        
NTRIALS=10;     % Number of trials of each stimulus type. 
                % Ex. NTRIALS = 10, then 20 trials are played with two
                % stimuli. Trial order is randomized.

% Audio information (UNIVERSAL)
CHANNEL=2;                  % Channel to present sound to. 1=left, 2=right, 3=stereo (not implemented)
FILES={...
    fullfile(pwd, '..', 'stims', 'MMBF6.WAV') ...   % full path to /ba/ stimulus
    fullfile(pwd, '..', 'stims', 'MMBF7.WAV')};   % full path to /mba/ stimulus
FSLEVEL=3;  % TDT sampling rate (Level 3 = ~49kHz, but poll info to be sure)

% Screen information (UNIVERSAL)
SCREEN_NUM=max(Screen('Screens'));     % secondary monitors used by default.

%% SAVED DATA PARAMETERS
%   Parameters to save to mat file. 
TORDER=AA04_SESSORDER(1:length(FILES), NTRIALS);   % randomize using AA04_SESSIONORDER
KBRESP=nan(size(TORDER));                   % initialize with nans so screening for issues easy.
RESPTIME=nan(size(TORDER));                 % RESPTIME in ... some unit of time ...

%% INITIALIZE SUBJECT
%   Create subject specific mat file with date prepended.
%   Returns the name of the location to save data to (mat file). 
MFILE=INITIALIZE_SUBJECT(SID, BEH_TYPE);

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
    
    %% START CIRCUIT
    RP.Run;
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
[SCREEN_HANDLE]=Screen('OpenWindow', SCREEN_NUM);
Screen('Preference', 'SuppressAllWarnings', 1); % suppress screen warnings
RES=Screen('Resolution', SCREEN_NUM);    % screen resolution structure. Used for positioning text on screen.
POST_SCREEN(RES, SCREEN_HANDLE, [RESP_KEYS{1} '=/ba/ ' RESP_KEYS{2} '=/mba/'], [255 255 255]);

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
        data=resample4TDT(data, FS, dfs); 
%         data=interp1(1:length(data), data, 1:dfs/FS:length(data), 'linear');
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
end % i=length(FILES)

%% CONVERT RESPONSE KEYS FROM STRINGS TO INTEGERS
%   Initialize to nan for speed. 
 
resp_keys=nan(length(RESP_KEYS)+1,1); 
for k=1:length(RESP_KEYS)
    resp_keys(k)=KbName(RESP_KEYS{k});
end % for k=1:length(RESP_KEYS)  

%% APPEND QUIT_KEY
resp_keys(end)=KbName(QUIT_KEY); 

%% SET TDT PARAMETERS AND START CIRCUIT
if ~LOCAL_AUDIO
    TCODE=255;
    TDELAY=1;
    TRIGDUR=0.02;
    if ~RP.SetTagVal('WavSize', size(SNDS,1)), error('Parameter not set!'); end
    if ~RP.SetTagVal('TrigDelay', round(TDELAY*FS)), error('Parameter not set!'); end % TRIGger DELAY in SAMPLES        
    if ~RP.SetTagVal('TrigDur', round(TRIGDUR*FS)), error('Parameter not set!'); end       % TRIGger DURation in samples
    if ~RP.SetTagVal('TrigCode', TCODE), error('Parameter not set!'); end               % Trigger CODE
    
end % ~LOCAL_AUDIO

%% INTIALIZE VARIABLES TO SAVE
TSTART=[];  % Trial start time returned from GetSecs
RESP=[];    % Response value
RESPTIME=[];    % response time (sec)
ROUTCOME=[];    % Response outcome - true if correct, false if incorrect. 

%% PAUSE AT BEGINNING
%   After screen posts and everything is setup, pause for a couple of
%   seconds.
pause(4); 

%% BEGIN EXPERIMENT
for i=1:length(TORDER)
    
    % Get timing at beginning of trial
    %   Use GetSecs (PsychToolbox) because it claims to have better
    %   precision.    
    if ~LOCAL_AUDIO      
        % Fill TDT Serial Buffer
        %   Loads sound file into serial buffer dynamically. 
        %   If timing is crucial, can also use a RAM buffer and load both
        %   sounds into RAM. Then we can do some context dependent
        %   pointer adjustments to play the correct sound in buffer. CWB
        %   uncomfortable with this approach at time he wrote this
        %   (2/5/2014).
        if ~RP.WriteTagV('Snd', 0, SNDS(:,CHANNEL,TORDER(i))'), error('Data not sent to TDT!'); end
    else
        % Presnt locally using PsychPortAudio drivers
        % Fill the audio playback buffer with the audio data 'wavedata':
        PsychPortAudio('FillBuffer', PORTAUDIO, SNDS(:,:,TORDER(i))');
    end % ~LOCAL_AUDIO
    
    % Trial starts after sound is loaded into correct buffer.
    TSTART(i)=GetSecs;
    
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
    %   Second input turns character display (i.e., typing will not appear
    %   in command window). If you want to see what you or a subject are/is
    %   typing, set to "true".
    [rtime, key_num]=KbWait4Key(resp_keys, true);     
       
    % Check if subject wants to quit
    if key_num==KbName(QUIT_KEY)
        FINISH; 
        return; 
    end % key_num==KbName(QUIT_KEY)
    
    % Record responses in larger array.
    RESP(i)=key_num; 
    
    % Record response time (sec)
    RESPTIME(i)=rtime-TSTART(i); 
    
    % Provide feedback 
    %   Check response against filenames
    [routcome]=RESP_CHECK(TORDER(i), resp_keys, RESP(i)); 
    ROUTCOME(i)=routcome; 
    clear routcome; 
    
    % Pause before feedback
    pause(DEL_RESP2FEED);
    
    % Insert your custom feedback routine here. First guess is that a
    % simple color change of the fixation cross would be fine. 
    switch lower(BEH_TYPE)
        case {'training'}
            % Post green or white cross
            %   Green cross = correct response
            %   white cross = incorrect response
            if ROUTCOME(i)
                POST_SCREEN(RES, SCREEN_HANDLE, [RESP_KEYS{1} '=/ba/ ' RESP_KEYS{2} '=/mba/'], [0 255 0]);
            else
                POST_SCREEN(RES, SCREEN_HANDLE, [RESP_KEYS{1} '=/ba/ ' RESP_KEYS{2} '=/mba/'], [255 255 255]);
            end % if routcome
            pause(DUR_FEED);
            POST_SCREEN(RES, SCREEN_HANDLE, [RESP_KEYS{1} '=/ba/ ' RESP_KEYS{2} '=/mba/'], [255 255 255]);
        case {'behavior'}
        case {'exposure'}
    end % switch
    
    % Save data
    %   use save command
    %   Verify that save is not eating up too much time (> time from
    %   response to feedback). If it DOES, then throw an error. 
     save(MFILE, 'TORDER', 'RESP', 'RESPTIME', 'TSTART', 'ROUTCOME'); 
    
    % Wait to provide feedback
    %   Might be more precise ways to control this, but this is very easy.
    %   And timing is not super precise anyway. 
    %
    %   XXX This conditional statement doesn't make any sense. A tired CWB
    %   clearly wrote it. XXX
    if (GetSecs - TSTART(i))>0
        pause(GetSecs - TSTART(i)); 
    else
        error('AA03:Feed2NextTrl', ...
            'Too little time after Feedback'); 
    end % (GetSecs - TSTART(i) ...   
    
end % for i=1:length(TORDER)

%% SHUTDOWN CLEANLY
FINISH;
end % AA03_behavior

function FINISH
%% DESCRIPTION:
%
%   Cleanup and close down for a smooth exit. Modularized so CWB can add
%   routines as he thinks of them. At time of writing, just closes screens.
%
% INPUT:
%
%   None
%
% OUTPUT:
%
%   None
%
% Christopher W. Bishop
%   University of Washington
%   2/14
Screen('CloseAll');
end % FINISH

function MFILE=INITIALIZE_SUBJECT(SID, BEH_TYPE)
%% DESCRIPTION:
%
%   Function to initialize files and the like for this subject. 
%
% INPUT:
%
%   SID:    string, subject ID
%
% OUTPUT:
%
%   Directories created to gather/save behavior.
%
% Christopher W. Bishop
%   University of Washington
%   1/14

% Determine name of mat file
% Check to see if mat file exists
%   If it does, throw a shoe or append a counter. Not sure yet. 
% Do other stuff I can't think of right now. 

% Make subject directory
if ~exist(fullfile('..', 'behavior'), 'dir')
    mkdir(fullfile('..', 'behavior')); 
end % if ~exist(fullfile ...

% Make subject directory
if ~exist(fullfile('..', 'behavior', SID), 'dir')
    mkdir(fullfile('..', 'behavior', SID));
end % subject directory

%% DOES A MAT-FILE ALREADY EXIST?
%   Suggest a mat file name and see if it exists already. If it does,
%   suggest a file name with appended counter. 
MFILE=fullfile('..', 'behavior', SID, [SID '-AA04-' BEH_TYPE '-01.mat']);
mfile=MFILE;
fnum=1; 

while exist(mfile, 'file')
    % If file exists, increment file counter
    fnum=fnum+1; 
    % Create new file name with counter appended.
    mfile=[mfile(1:end-6) sprintf('%02d', fnum) '.mat'];
end % while exist(mfile, 'file')
    
% If we had to change the file name, then warn experimenter and kick back
% updated file name.
if ~strcmp(MFILE, mfile)
    [~,oname,oext]=fileparts(MFILE);
    [~,nname,next]=fileparts(mfile);
    warning('AA03:FileExists', [oname oext ' exists!\n'...
        'Changing filename to ' nname next])
    MFILE=mfile;
end % ~strcmp(MFILE, mfile)

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



function POST_SCREEN(RES, SCREEN_HANDLE, PROMPT, CROSSCOL)
%% DESCRIPTION:
%
%   Function to present the default screen with fixation cross and the
%   "prompt" as provided by the experimenter.
%
% INPUT:
%
%   RES:        screen resolution structure
%   SCREEN_HANDLE:  handle to screen use wants to post to
%   PROMPT:     string, text to display.
%   CROSSCOL:   rgb value for cross color. 
%
% OUTPUT:
%
%   Screen
%
% Christopher W. Bishop
%   University of Washington
%   2/14

%% GET SCREEN RESOLUTION
%   Need width and height to set text correctly in various computers. 
screen_center=[round(RES.width/2) round(RES.height/2)];

% Black screen
Screen('FillRect', SCREEN_HANDLE, [0 0 0]);
Screen('TextFont',SCREEN_HANDLE, 'Arial');
Screen('TextSize',SCREEN_HANDLE, 50);

% Draw a cross at center of screen
Screen('DrawText', SCREEN_HANDLE, '+', screen_center(1), screen_center(2), CROSSCOL);
Screen('DrawText', SCREEN_HANDLE, PROMPT, round(screen_center(1)*3.85/5), screen_center(2)-100, [255 255 255]);
Screen('Flip',SCREEN_HANDLE);

% Get text bounds
% woff=Screen('OpenOffscreenWindow',[],[0 0 3*50*length(PROMPT) 2*PROMPT]);
% Screen(woff,'TextFont','Arial');
% Screen(woff,'TextSize',50);
% Screen(woff,'TextStyle',1); % 0=plain (default for new window), 1=bold, etc.
% bounds=TextBounds(woff,string);
% Draw prompt above cross

% Screen('TextStyle', w, 1+2);
% DrawFormattedText(w, [PROMPT '+'], 'center', 'center', [255 255 255], length(PROMPT), [], [], 5);
% Screen('DrawText', w, '[B] = /ba/, [M]= /mba/ \n+', 100, 100, [0, 0, 255, 255]);
% Screen('TextFont',w, 'Arial');
% Screen('TextSize',w, 30);
% Screen('DrawText', w, 'Hit any key to exit.', 100, 300, [255, 0, 0, 255]);

% KbWait;
% Screen('CloseAll');
end % DEFAULT_SCREEN