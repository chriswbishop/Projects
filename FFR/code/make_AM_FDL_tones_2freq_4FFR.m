function [tone_final] = make_AM_FDL_tones_2freq_4FFR(fs, carrier_freq1, carrier_freq2, calibrate, save_wav)
% This code will make amplitude-modulated tones of 4 second duration with
% a change in frequency at the 2 second midpoint. These stimuli will
% tentatively be used in a Frequency Discrimination Psychophysical Training
% Task.
%
% This code was originally created for Project E - interaural phase differences
% in Clinard's JMU lab. This follows the methods of Grose and
% Mamo, 2010.
%
  % Make AM tone (formula from Picton et al, 2003, IJA ASSR Review and
  % Dimitrijevic et al, 2001, Human ASSRs to tones Independently Modulated
  % in both Frequency and Amplitude)
  % per Grose and Mamo 2010, 3pi/2 starting phase begins and ends at zero.
%
%   where fs is the sampling frequency, 
%   carrier_freq1 and carrier_freq2 are the first and second carrier freqs.
%   calibrate == 0 makes of of duration (defined below), == 1 makes
%   duration of 10 seconds for easier calibration on Sound Level Meter.
%   save_wav == 0 does NOT save a .wav file, == 1 saves a .wav file
%
% Useage example:
% [tone_final] = make_AM_FDL_tones_2freq_4FFR(20000, 1000, 990, 0, 1)
%
%  Initially written by C. Clinard ~ Sept. 2013.
%% Check for Debug and Define Variables
DeBug = 0; % 1 == plot stimulus, 0 == don't plot stimulus

if DeBug == 1 % This loop is for code development purposes only.
  carrier_freq1 = 500.00000;            % carrier frequency
  carrier_freq2 = 450.00000;            % carrier frequency
  fs = 10000;  % 10 kHz sampling rate matches FFR sampling rate
end

  %%%%%---- Carrier and Modulation  Frequencies should be specified with Coherent Sampling
Fc1 = carrier_freq1; % Initial frequency over first half of stimulus
Fc2 = carrier_freq2; %         frequency over the 2nd half of stimulus
mod_rate = 40; % amplitude modulation rate. 1/40 Hz = 0.025 second period
duration = 4.0;  % Entire stimulus duration, in seconds.

%% If calibrating, make tone duration long
if calibrate == 1;          duration = 10.0;              end

%% Make tones
t = 0:1/fs:duration/2; % time vector, make 2 tones of 2 sec duration then concatenate.

 % Make Amplitude-Modulated, fixed-phase tone; multiply tone by AM envelope
   % make First frequency AM tone
   % .9 normalizes amp;  % here define envelope;      % carrier freq here;
tone1 = (.9 * (1 + sin(2*pi*mod_rate*t +(3*pi/2))) .* sin(2*pi*Fc1*t))/2;
   % make Second frequency AM tone
tone2 = (.9 * (1 + sin(2*pi*mod_rate*t +(3*pi/2))) .* sin(2*pi*Fc2*t))/2;
tone_final = [tone1 tone2];  % concatenate tones

%% Plot stimulus if debugging: waveforms and FFTs
if DeBug == 1;
    % Plot the stimulus  -----------------------------------------------
    figure
     % Plot stimulus waveform
    % subplot(2,1,1)
    subplot(3,1,1)
    plot([t t+duration/2], tone_final);
     %     title(['frequency modulation of depth ' num2str(mf) '; ' num2str(mf*Fc1) '  Hz deviation']);
    title('Whole Stimulus')
    ylabel('Amplitude');
    xlabel('time (sec)')
    
     % plot onset of stimulus
    index = round((1/mod_rate)*fs);  % get index for null points
    % subplot(2,2,3)
    % subplot(3,2,3)
    subplot(3,3,4)
    plot(t(1:index), tone_final(1:index)) % plot first AM cycle, 
    title('Stimulus Onset')
    xlim([0 1/mod_rate])
    
    subplot(3,3,5)
    plot([t t+duration/2], tone_final);
    title('Midpoint of stimulus')
%     plot(t(index:index*2), stim2chan(2,index:index*2), 'r')
%     xlim([2-index/fs 2+(index*2)/fs])
    xlim([2-index/fs 2+index/fs]); % scale to show midpoint +/- one AM cycle

    zoom xon
    
         % plot offset of stimulus
    % subplot(2,2,3)
    % subplot(3,2,3)
    % subplot(3,3,4)
    subplot(3,3,6)
    plot([t t+duration/2], tone_final,'r');
    %plot(t(end-index:end)+duration/2, tone_final(end-index:end)) % plot first AM cycle, 
    title('Stimulus Offset')
    xlim([duration-index/fs duration])
    
    
    subplot(3,2,5:6)
    title('FFT')
     NFFT = length(tone1);
     f = fs/2 * linspace(0, 1, NFFT/2); 
     Y_tone1 = fft(tone1, NFFT);    
     Y_tone2 = fft(tone2, NFFT);
     plot(f, abs(Y_tone1(1:length(f)))) 
     hold on
     plot(f, abs(Y_tone2(1:length(f))), 'r');
    xlim([0 2000]); xlabel ('Frequency (Hz)')
    zoom xon
end

if save_wav == 1       %%% Create filename and Save a .wav file

        % e.g., 'ProjU_500_450Hz_40HzSAM_4sec_10kHz.wav'
    filename = ['ProjU' num2str(Fc1) '_' num2str(Fc2) 'Hz_' num2str(mod_rate) 'HzSAM' num2str(duration) 'sec_' num2str(fs/1000) 'kHz'];
    % filename = 'ProjU_500_2_450Hz_40HzSAM_4sec_10kHzfs';
    wavwrite(tone_final, fs, filename);         % Save .wav file
end

end
