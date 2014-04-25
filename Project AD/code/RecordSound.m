function audiodata=RecordSound(T)
%% DESCRIPTION:
%
%   Record sound data for a length of time (T)

% Perform basic initialization of the sound driver:
InitializePsychSound;

% Open the default audio device [], with mode 2 (== Only audio capture),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of 44100 Hz and 2 sound channels for stereo capture.
% This returns a handle to the audio device:
freq = 44100;
pahandle = PsychPortAudio('Open', 6, 2, 0, freq, 2);

% Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
PsychPortAudio('GetAudioData', pahandle, 50);

PsychPortAudio('Start', pahandle, 0, 0, 1);
pause(5);

[audiodata offset overflow tCaptureStart] = PsychPortAudio('GetAudioData', pahandle);
audiodata=audiodata';
PsychPortAudio('Close');
