function [audiodata]=PlayRecord(X)
%% DESCRIPTION:
%
%   proof of concept to allow simultaneous recordings/sound playback.

% Open the default audio device [], with mode 2 (== Only audio capture),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of 44100 Hz and 2 sound channels for stereo capture.
% This returns a handle to the audio device:
InitializePsychSound;
freq = 44100;
r = PsychPortAudio('Open', [], 2, 0, freq, 1);

% Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
PsychPortAudio('GetAudioData', r, 50);

PsychPortAudio('Start', r, 0, 0, 1);

% Now, play the sound

nchans=8;
% [X, FS]=AA_loaddata(X); 
% X=X*ones(1, nchans); 

% Sine wave test 
%   Make sure that the output frmo all channels is truly independent
%   (should be)
freqs=[250 400 800 1000 2000 4000 6000 8000];
for i=1:length(freqs)
    X(:,i)=sin_gen(freqs(i), 10, freq); 
end % i=1:length(freqs)
[X, FS]=AA_loaddata(X, 'fs', freq); 
X=resample(X, 44100, FS); 
% [Y, FS]=AA_loaddata(Y);

p = PsychPortAudio('Open', 20, [], 0, 44100, size(X,2)); 

PsychPortAudio('FillBuffer', p, X');
PsychPortAudio('Start', p, 100, 0, 1, [], 1);

pause(5); 

[audiodata offset overflow tCaptureStart] = PsychPortAudio('GetAudioData', r);
