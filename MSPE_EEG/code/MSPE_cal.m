function [L R V DATA FS]=MSPE_cal(DATA, FS, N)
%% DESCRIPTION:
%   
%   Function to record/calibrate stims for MSPE.  Prior to running this
%   script, the following hardware must be setup.
%   
%   1.  Both active speakers must be connected to outputs 3/4 of the
%       FireFace. Left=3, Right=4.
%   2.  The SHURE microphone must be positioned where the subject where the
%       subject's head is likely to be.  Do not apply a spatial filter
%       (select the circle), no filter (flat line), 0 dB gain.  
%   3.  Connect SHURE microphone input into INPUT 9 on the front of the
%       FireFace.  We must use 9 so we have an adjustable gain for
%       recording.  Calibrate gain so you get a robust signal.
%   4.  Run MSPE_cal.m
%
%
% INPUT:
%
%   DATA:   double array (Mx1), where M=number of samples.  Specifies the 
%           calibration stimulus.  (default=1 sample click)
%   FS:     integer, specifies sampling rate. (default=24 kHz) Default has
%           to be 24 kHz because MATLAB thinks the FireFace can only
%           record/play at 48 kHz. Setting FS to anything higher than 24
%           kHz will break it, so I don't recommend specifying this
%           variable.
%   N:      integer, number of repeated presentations of the stimulus
%           (default=10)
%
% OUTPUT:
%
%   L:  NxT*FS, recording of left speaker. Each row is a single recording.
%   R:  " " for right speaker
%   V:  Variance in trigger times (not terribly useful)
%   Figure 01:  Plots of individual recordings from each channel/repetition
%   Figure 02:  Average recordings from both channels.
%   Figure 03:  Speaker amplitude assessment.  Plots mean +/- STD of
%               speaker RMS (dB).  A two-sample t-test is performed to
%               quantify any differences.
%
%   NOTE:   The two-sample t-test used to quantify interspeaker differences
%           in amplitude is almost overly sensitive because of the low
%           intraspeaker variance.  So, even if the null hypothesis
%           (speakers are the same volume) is rejected, it might not
%           matter. It's up to you, but I'm willing to accept a a dB or two
%           variance.  Moving the microphone around can add about 1-2 dB of
%           variance, but this variation is not taken into account in the
%           statistics.  Probably should be, but I don't want to take the
%           time to do it. Go nuts! An F-test is probably more appropriate.
%
% Bishop, Chris Miller Lab 2010

%% Clear variables
close all;
MSPE_clear;
clear Ai Ao

%% SET DEFAULTS
if ~exist('DATA', 'var') || isempty(DATA)
%     load('WHITENOISE_3sec');
%     DATA=WHITENOISE;
    DATA=[zeros(1,1); ones(1,1);zeros(1,1)].*0.90;
end % if 

if ~exist('N', 'var') || isempty(N), N=10; end
if ~exist('FS', 'var') || isempty(FS), FS=96000; end
hw=winsoundhwinfo; %daqhwinfo('winsound'); %daqhwinfo stupidly assumes same input and output device order, winsoundhwinfo.m can be found on matlab central

%% SETUP INPUT DEVICE
ai=strmatch('Fireface 800 Analog (9+10)',hw.InputBoardNames,'exact')-1;
Ai=analoginput('winsound', ai); 
addchannel(Ai, 1);
set(Ai, 'StandardSampleRates', 'Off');
set(Ai, 'SampleRate', FS);
set(Ai,'SamplesPerTrigger',length(DATA)+0.1*get(Ai, 'SampleRate'));


%% SETUP OUTPUT DEVICE OBJECT
% ao=strmatch('Fireface 800 Analog (3+4)',hw.OutputBoardNames,'exact')-1;
% ao=strmatch('Fireface 800 Analog (5+6)',hw.OutputBoardNames,'exact')-1;
ao=0; % use whatever the default output is.
% ao=0;
Ao=analogoutput('winsound', ao);
addchannel(Ao,1:2);
set(Ao,'StandardSampleRates','Off')
set(Ao,'SampleRate',FS);
% set(Ao, 'BitsPerSample', 16);
set([Ai Ao],'TriggerType','Manual')

% Required for lowest possible latency during recording.
set(Ai,'ManualTriggerHwOn','Trigger');
 
%% CALIBRATE LEFT SPEAKER
out=[DATA zeros(size(DATA))];
L=[]; V=[];
for i=1:N
    putdata(Ao,out);
    
    % For reasons I can't understand, the order in which the devices are
    % started MATTERs here. Starting Ai before Ao will result in an error
    % during the second iteration.
    start([Ao Ai]);
    trigger([Ai Ao]);
    L=[L getdata(Ai)];
    V=[V; get(Ao,'InitialTriggerTime')-get(Ai,'InitialTriggerTime')];
end % i

%% CALIBRATE RIGHT SPEAKER
out=[zeros(size(DATA)) DATA];
R=[];
for i=1:N
    putdata(Ao,out);
    % For reasons I can't understand, the order in which the devices are
    % started MATTERs here. Starting Ai before Ao will result in an error
    % during the second iteration.
    start([Ao Ai]);
    trigger([Ai Ao]);
    R=[R getdata(Ai)];
    V=[V; get(Ao,'InitialTriggerTime')-get(Ai,'InitialTriggerTime')];
end % i

MSPE_clear;

%% ANALYZE/PLOT RESULTS
figure, hold on
x=0:1/FS:length(L)./FS-1./FS;
subplot(2,1,1);
plot(x, L);
axis([0 length(L)./FS-1./FS -1*max(max(abs([L R]))) max(max(abs([L R])))]);
title(['Left (N=' num2str(size(L,2)) ')']);
subplot(2,1,2);
plot(x, R);
axis([0 length(L)./FS-1./FS -1*max(max(abs([L R]))) max(max(abs([L R])))]);
title(['Right (N=' num2str(size(R,2)) ')'])
xlabel('Time (sec)');
ylabel('Amplitude');

figure, hold on
plot(x, [mean(L,2) mean(R,2)]);
title('Mean Left vs. Mean Right');
legend('Left', 'Right')
xlabel('Time (sec)');
ylabel('Amplitude');

% Two-sample t-test to see if speakers are consistently different in mean
% output
figure, hold on
title('Speaker Amplitude Variance');
xlabel('Speaker');
ylabel('Amplitude (dB)');
errorbar([1 2], [mean(db(rms(L))) mean(db(rms(R)))], [std(db(rms(L))) std(db(rms(R)))], 'ks');%%
[h,p]=ttest2(db(rms(L)), db(rms(R)));%%
if ~isnan(h) && h
    warning('Speakers are significantly different!');
else 
    display('Speakers seem to be about equal loudness');
end % h

% Speaker transfer function for average recording.
figure, hold on
f=linspace(0,FS,size(L,1));
plot(f, [db(abs(fft(mean(L,2)))) db(abs(fft(mean(R,2))))]);
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)'); 
title('Speaker Transfer Functions');
legend('Left', 'Right');
