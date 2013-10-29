function MSPE_trial(IN, DATA, FS)
%% DESCRIPTION:
%
%   Function to present stimuli for Multisensory Precedence Effect project.
%   Unlike most experiments, we can't use NeuroBS's Presentation to handle
%   stimulus presentation.  This particular experiment requires precise
%   control over 4 channels independently.  Presentation can present
%   stimuli from multiple channels, but the timing using the custom mixer
%   is not great.  So, here we are using MATALB.
%
% INPUT:
%   
%   IN: see MSPE_stim for details.
%
% OUTPUT:
% 
%   NONE
%
% Notes: Presenting sounds to two different devices simultaneously can be
%        very tricky. You're likely going to get some crashes along the way
%        if you make ANY modifications to the coded below.  
%
% Bishop, Chris Miller Lab 2010

%% CLEAR VARIABLES
%   If the program crashes, these must be cleared before we do anything
%   else or the system will crash.
MSPE_clear;

%% CHECK INPUTS AND SET DEFAULTS
if ~exist('FS', 'var') || isempty(FS), FS=24000; end % FS

if ~exist('DATA', 'var') || isempty(DATA)
%     DATA=[zeros(round(0.0005*FS),1); ones(round(0.0005*FS),1).*0.90; zeros(round(0.0005*FS),1)];
    DATA=[0; sin_gen(1000,0.001,FS); 0];
end % DATA

%% CREATE STIMULI
%   See MSPE_stim for details on procedure

% 5 msec square.
% DATA=[0; ones(round(0.0005*FS),1).*0.90; 0];
[ASTIM VSTIM]=MSPE_stim(IN, DATA, FS);

%% SETUP OUTPUT DEVICE OBJECTS
% Auditory output
hw=daqhwinfo('winsound');
ao=strmatch('Fireface 800 Analog (3+4)',hw.BoardNames,'exact')-1;
Ao=analogoutput('winsound', ao);
addchannel(Ao,1:2);
set(Ao,'StandardSampleRates','Off')
set(Ao,'SampleRate',FS);

% Visual output
vo=strmatch('Fireface 800 Analog (1+2)',hw.BoardNames,'exact')-1;
Vo=analogoutput('winsound', vo);
addchannel(Vo,1:2);
set(Vo,'StandardSampleRates','Off')
set(Vo,'SampleRate',FS);

% Set trigger type to manual
%   This results in the shortest latency onset between the two devices.
%   Still not 100 % sure what this delay looks like...need to figure that
%   out.
set([Ao Vo],'TriggerType','Manual')

% Put in data
putdata(Ao,ASTIM);
putdata(Vo,VSTIM);

%% PRESENT STIMULI
%   XXX Need timing tests to confirm visual and auditory onsets are
%   overlapping well enough.
start([Ao Vo]);
trigger([Ao Vo]);
pause(size(ASTIM,1)./FS);

%% CLEAR DEVICE OBJECTS
%   If this is not done, bad things will happen.
%       Note: for reasons I cannot begin to understand, calling these lines
%       here breaks things, but if you call them in another function, it
%       works fine.  So...I moved them to MSPE_clear.
% delete([Vo Ao]);
% clear Vo Ao;
MSPE_clear;