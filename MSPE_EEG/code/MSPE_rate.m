function [ASTIM FS LEDo LEDs]=MSPE_rate(ARATE, VRATE, DATA, FS, N)
%% DESCRIPTION:
%
%   Function creates stimuli for temporal ventriloquism control in MSPE.
%   Creates audiovisual stimulus information assuming setup for MSPE.
%
% INPUT:
%
%   ARATE:  Repetition rate of auditory stimulus, defined by DATA, in Hz.
%           (default=4.0 Hz)
%   VRATE:  Repetition rate of visual stimulus in Hz. (default 4.0 Hz)
%   DATA:   double array, Mx1, where M is the length of the auditory
%           stimulus. 
%   FS:     Sampling rate (default 96 kHz)
%   N:      Number of repetitions of stimuli (default 4)
%
% OUTPUT:
%
%   ASTIM:  Auditory stimulus.
%   FS:     Sampling rate
%   LEDo:   Onset times of LEDs in samples.
%   LEDs:   Cell array of string codes for LED codes (default {'255'});
%
%   ../stims/RATE.wav
%   ../stims/RATE_cue.wav
%
% Bishop, Chris Miller Lab 2010
%   Yadav, Deepak Miller Lab 2010

%% DEFAULTS
if ~exist('ARATE', 'var') || isempty(ARATE), ARATE=4.0; end
if ~exist('VRATE', 'var') || isempty(VRATE), VRATE=4.0; end
if ~exist('FS', 'var') || isempty(FS), FS=96000; end 
if ~exist('N', 'var') || isempty(N), N=4; end

if ~exist('DATA', 'var') || isempty(DATA)
    rand('twister', sum(100*clock)); 
    %   D:  duration of stimulus (sec)
    %   R:  duration of ramp (sec)
    %   S:  scaling factor (proportion)
    D=0.100;
    R=0.003;
    S=0.4;
    DATA=rand(round(D*FS),1);
    DATA=DATA-mean(DATA);
    DATA=DATA./max(abs(DATA)).*S;
    
    w=[linspace(0,1,round(R*FS))'; ones(size(DATA,1)-2*R*FS,1);flipud(linspace(0,1,round(R*FS))')];
    DATA=w.*DATA;
end % DATA

    
% ZERO PAD DATA SO RATE IS APPROPRIATE
DATA=[DATA; zeros((1/ARATE*FS)-size(DATA,1), size(DATA,2))];

DATA=[DATA DATA];
LEDo=[];
LEDs=[];
ASTIM=[];
for i=1:N
    ASTIM=[ASTIM; DATA];
    LEDo=[LEDo 0+1/VRATE*FS*(i-1)];     % Determine timing for lights
    LEDs{i}='255';   % Light up everything.
end % i

%% DELAY AUDITORY STIMS SO LIGHT AND SOUND COME ON AT SAME TIME.
%   See MSPE_stim.m for details on determining the audiovisual offset.
L=0.001650;
ASTIM=[zeros(L*FS,size(ASTIM,2)); ASTIM];

%% ADD IN CUES TO FILE
%   Cues are sent through Parallel port on PC to power LEDs.
wavwrite(ASTIM, FS, '../stims/RATE.wav');
addWavCue('../stims/', 'RATE.wav', LEDo, LEDs, 'RATE_cue.wav'); 