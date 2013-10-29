function [ASTIM FS LEDo LEDs]=MSPE_stim(IN, DATA, FS, D, R)
%% DESCRIPTION:
%   
%   Create stimulus for Multisensory Precedence Effect (MSPE) project.
%   Based loosely on structure from McQuism project and ideas borrowed from
%   SL's PE code.
%
% INPUT:
%   IN: (6 OR 7,1) stimulus structure.  Each row specifies a specific stimulus
%       parameter. See below for a detailed treatment.
%
%       IN(1,:) (LAC)
%           Left audio channel, integer used to determine whether or not a
%           sound should be played from the left audio channel. Input is
%           binary (0=no sound; 1=sound)
%       IN(2,:) (RAC)
%           Right audio channel, integer used to determine whether or not a
%           sound should be played from the right audio channel.  Input is
%           binary (0=no sound; 1=sound)
%       IN(3,:) (ALAG)
%           Audio lag (sec), double used to determine audio lag.  Assumes a
%           RIGHT LEADING sound.  For instance, a lag of 0.002 sec will
%           result the left channel's output being delayed by ~2 msec
%           relative to the right channel. This is arbitrary, but conforms
%           to SL's study (I think). If lag is -0.002 sec, then LEFT
%           channel leads by 2 msec (right delayed).
%       IN(4,:) VCOD
%           Video port code, double.  Paradigm currently powers LEDs
%           through Parallel port.  VCOD specifies both which light flashes 
%           and the flash timing relative to the primary and secondary.
%               12:     Right light, timed with primary.
%               14:     Left light, timed with secondary.
%               22:     Right light, timed with secondary.
%               24:     Left light, timed with secondary.
%       IN(5,:) COND
%           Condition code, double.
%       IN(6,:) VOFF (Optional)
%           Visual OFFset, double. Define the visual offset relative to
%           sound onset in seconds.  Positive values are for a visual delay
%           and negative values are for a visual advance relative to sound
%           onset.  For example, VOFF=0.100 leads to a 100 msec visual
%           lagging stimulus.
%           
%           If the user wants to specify a more precise temporal offset
%           between the sound and visual onsets, use VOFF.  Notice that
%           this is only used if size(IN,1)>6.  This is in the interest of
%           reverse compatibility with previous stimulus definition
%           structures.
%
%           NOTE: addWavCue.m will NOT throw an error if the cues are not
%           added to the sound because the wavfile is too short.  So, be
%           sure to check your stimuli and zero pad accordingly.
%
%       IN(end,:) N
%           Trial numer, integer.  Not explicitly used here, but is part of
%           the structure so it's listed.  This should ALWAYS be the last
%           row value for the stimulus definition.  At the moment, this
%           will be either 6 OR 7 depending on whether or not VOFF
%           (IN(6,1)) is defined. 
%
%   DATA:
%
%       Custom stimulus input, double array.  If something other than the
%       default stimulus is desired, set DATA to an Mx1 vector describing
%       your stimulus. (default=15 msec noise burst)
%
%       Alternatively, DATA can also be the full path to a wav file.
%       Stereo sounds will be imported correctly, but immediately converted
%       to mono sounds.  If stereo sound is required, set ALAG to the ITD
%       of interest and LAC and RAC to the desired relative decibel level.
%       All ITD/ILD information in the original (stereo) wav file will be
%       lost.
%
%   FS:
%       Sampling frequency, (default=96000 Hz).
%
% OUTPUT:
%
%       ASTIM:
%           Auditory stimulus, Mx2 array of auditory stimuli.  Visual codes
%           are embedded into the WAV file using addWavcue.m by Jess
%           Kerlin.
%
%   Note:
%       Both ASTIM and VSTIM assume that the first column (Channel 01) is
%       the LEFT speaker/LED.  If this is not the case then you're going to
%       run into problems.
%
% Bishop, Chris Miller Lab 2010
%   London, Sam Miller Lab 2010

%% CHECK INPUTS AND SET DEFAULTS

% When playing directly through FireFace, must play sounds at 96 kHz. If
% you're going through the Gina and routing sound to the appropriate ports,
% then you can play at whatever sampling rate supported by the Gina and the
% FireFace will inherit it.  
%   -CB: Was having issues at 96 kHz after some later testing...seems like
%   FireFace is trying to play at 48 kHz instead...sooo...changed to 48
%   kHz. Will figure out "why" later.
%   -CB: DATA can now also be a string to a wavfile.
%   -CB: IN structure can now define a Visual OFFset (VOFF). See INPUT
%        description for details.

if ~exist('FS', 'var') || isempty(FS), FS=96000; end % FS
if ~exist('D', 'var') || isempty(FS), D=.015; end % D %%%
if ~exist('R', 'var') || isempty(FS), R=.0005; end % R %%%

if exist('DATA', 'var') && isstr(DATA) && ~isempty(DATA), [DATA FS]=wavread(DATA); end

if ~exist('DATA', 'var') || isempty(DATA)
    rand('twister', sum(100*clock)); 
    
    %   D:  duration of stimulus (sec)
    %   R:  duration of ramp (sec)
    %   S:  scaling factor (proportion)
    %%%%D=.015
    %%%%R=.0005
    S=0.50;
    DATA=rand(round(D*FS),1);
    DATA=DATA-mean(DATA);
    DATA=DATA./max(abs(DATA)).*S;
    w=[linspace(0,1,round(R*FS))'; ones(size(DATA,1)-round(2*R*FS),1);flipud(linspace(0,1,round(R*FS))')];
    DATA=w.*DATA;
end % DATA

if size(DATA,2)>1, DATA=DATA(:,1); end % Assume mono
%% DELAY SOUND TO ALIGN WITH LED.
% Lag (L) was determined empirically by CB using an oscilloscope.  When
% sending port codes, the port code is typically received ~1.625 msec after
% sound onset.  So, we delay the sound by 1.625 msec to align light and
% sound onset.  All sounds are delayed by 1.625 msec.
%   Delay is actually a little more using embedded cues (see addWavCue).
%   More like a 1.650 msec lag.
%   L:  time to delay sound to synchronize it with LED (sec).
%
% NOTE: With Gina 1+2 Digital out, the sound is actually delayed relative
% to the port code (LEDs) by ~1 msec. So, padding the sound makes the
% problem worse.  
% L=0.001650;
L=0;
DATA=[zeros(round(L*FS),size(DATA,2)); DATA]; 

%% DECLARE VARIABLES
%   ASTIM:  Mx2 double array, auditory stimulus. ASTIM(:,1)=left channel,
%   ASTIM(:,2)=right channel.
ASTIM=[];

%% CREATE AUDITORY STIMULUS
%   Assumes that Channel 01 is the LEFT channel.  This should be the
%   default setting in most other code.
if IN(3)>0 % Right leading
    ASTIM(:,1)=[zeros(round(abs(IN(3))*FS), 1); DATA];
    ASTIM(:,2)=[DATA; zeros(round(abs(IN(3))*FS),1)];
elseif IN(3)<0 % Left leading
    ASTIM(:,1)=[DATA; zeros(round(abs(IN(3))*FS),1)];
    ASTIM(:,2)=[zeros(round(abs(IN(3))*FS), 1); DATA];
elseif IN(3)==0 % simultaneous
    ASTIM=[DATA DATA];    
end % if 

% Exclude channels if necessary.
ASTIM(:,1)=ASTIM(:,1).*IN(1);
ASTIM(:,2)=ASTIM(:,2).*IN(2);

%% DETERMINE TIMING OF PRIMARY AND SECONDARY
%   Needs to be specified in number of samples for addWavCue. See addWavCue
%   for more information. 
pt=0; st=length(zeros(round(abs(IN(3))*FS), 1));

%% DETERMINE TIMING/SIDE OF FLASH
%   CB modified VCOD to contain information about timing relative to
%   primary or secondary sounds.  This information is used here to
%   determine when the port code to light the LED should be lit.  Granted,
%   within this particular paradigm, a difference in timing onset within
%   the expected lags of echo suppresssion (on the order of milliseconds),
%   won't be perceptually asynchronous. It might matter later, so it's
%   fixed here.
str=num2str(IN(4)); 
try 
    % In interest of reverse compatibility with VCOD limited to 2 and 4,
    % this bit of code tries looks for the new (2-digit) code first. If it
    % doesn't work, then the old format is assumed in the catch statement.
    %
    % 100827CB: Altered to accept codes of any aribtrary length.  However,
    % if the VCOD is > 2 digits, the first digit MUST be the relative
    % timing code.  Otherwise, things are going to self-destruct. 
    LEDt=str2double(str(1));
    LEDs=str(2:end);
catch
    LEDt=1;
    LEDs=str;
    warning([str ' does not contain timing information. LED timed with primary.']);
end %

% LEDt==1, LED timed with primary
% LEDt==2, LED timed with secondary
% LEDt==0, a single digit code was used and it spit back LEDt=0 as a
% result.  This is a quick fix to the problem.
if LEDt==1 || LEDt==0
    LEDo=pt;
elseif LEDt==2
    LEDo=st;
end % if 


%% ADD ADDITIONAL TIMING INFORMATION
%   For later experiments, we found that we needed a more flexible
%   framework to change the timing of the LED onset relative to sound
%   onset.  To do this, I added an additional (optional) input to the
%   stimulus structure (IN).  See INPUT description above for more details.
%   In the interest of reverse compatibility, this section of code is only
%   executed if IN exceeds 6 rows.
if size(IN,1)>6, LEDo=LEDo+(IN(6,1)*FS); end % size(IN,1)

%% ADD IN CUES TO FILE
%   Cues are sent through Parallel port on PC to power LEDs.
%
%   As noted above, when using the Gina 1+2 digital sound output, the sound
%   is delayed relative to LED light up. So, we need to delay LED Port
%   codes by an appropriate amount (defined by L).
%   
%   -CB: Threw in an error check to make sure the codes are within the time
%        range of the stimulus. addWavCue doesn't do this for some reason
%        and I ain't touchin' that thing.
L=0.001; % padding, in msec.
wavwrite(ASTIM, FS, '../stims/ASTIM.wav');
if LEDo+L*FS>size(ASTIM,1), error('STIMULUS NOT LONG ENOUGH!'); end % if
addWavCue('../stims/', 'ASTIM.wav', LEDo+L*FS, {LEDs}, 'ASTIM_cue.wav'); 