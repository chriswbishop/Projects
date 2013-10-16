function [tone_final] = make_AM_FDL_tones_2freq_4FFR(fs, carrier_freq1, carrier_freq2, calibrate, save_wav, mod_rate, duration, DeBug, AM_TYPE)
%% DESCRIPTION:
%
%   Generate an amplitude-modulated (AM) tone of arbitrary duration with a
%   change in carrier frequency at the midpoint. The code was originally
%   created for Project E - interaural phase differences in Clinard's JMU
%   lab. This follows the methods of Grose and Mamo (2010). 
%
%   Make AM tone (formula from Picton et al, 2003, IJA ASSR Review and
%   Dimitrijevic et al, 2001, Human ASSRs to tones Independently Modulated
%   in both Frequency and Amplitude)
%   per Grose and Mamo 2010, 3pi/2 starting phase begins and ends at zero.
%
%% INPUT:
%
%   fs: sampling rate (default 44100)
%   carrier_freq1: carrier frequency for first half of stimulus (Hz)
%                 (no default)
%   carrier freq2: carrier frequency for second half of stimulus (Hz)
%                 (no default)
%   calibrate:     bool, flag set if output calibration required (default
%                  false)
%   save_wav:   bool, flag to save the wav file or not. (default false)
%   mod_rate:   modulation rate in Hz (default 40 Hz); 
%   duration:   stimulus duration in seconds (default 4 s)
%   DeBug:      bool, flag to enter debug mode (default false)
%   AM_TYPE:    string, defines type of amplitude modulation to use.
%               Options: 
%                   'SIN':  default option, sinusoidally modulated tones.
%                   'COS2': cos^2 onset ramps leading into full amplitude
%                           tones. The hope here is that we can maximize
%                           the number of full-amplitude cycles we present
%                           in each burst of the AM signal. %% NOT YET
%                           IMPLEMENTED %%
%
%% OUTPUT:
%
%   tone_final: concatenated, AM tone with two carrier frequencies (change
%               in middle of stimulus)
%
%% EXAMPLE:
%
% [tone_final] = make_AM_FDL_tones_2freq_4FFR(20000, 1000, 990, 0, 1)
%
%  Initially written by C. Clinard ~ Sept. 2013.
%
%   131014 CWB: Minor edits and reorganization to include mod_freq,
%   duration, and debug as input variables with default values. 

%% DEFAULT INPUTS
if ~exist('mod_rate', 'var'), mod_rate=40; end % default mod rate of 40 Hz
if ~exist('DeBug', 'var'), DeBug=false; end % default DeBug to 0 (do not plot stimulus)
if ~exist('duration', 'var'), duration=4.0; end % default duration to 4 (s)
if ~exist('fs', 'var'), fs=44100; end % default to 44100 sampling rate.
if ~exist('calibrate', 'var'), calibrate=false; end 

%% 131014 CWB:
%   Commented this out because I wanted the debug functions to work with
%   whatever input I specify. They're handy functions. 
%
% if DeBug == true % This loop is for code development purposes only.
%   warning(['Entering debug mode: carrier frequencies and sampling rate ' ... 
%         'may have been overwritten.']); 
%   carrier_freq1 = 500.00000;            % carrier frequency
%   carrier_freq2 = 200.00000;            % carrier frequency
%   fs = 10000;  % 10 kHz sampling rate matches FFR sampling rate
% end

%%%%%---- Carrier and Modulation  Frequencies should be specified with Coherent Sampling
Fc1 = carrier_freq1; % Initial frequency over first half of stimulus
Fc2 = carrier_freq2; %         frequency over the 2nd half of stimulus

%% If calibrating, make tone duration long
if calibrate == true;          duration = 10.0;              end

%% Make tones
% 131016 CWB: adjusted t to remove additional sample. 
t = 0:1/fs:duration/2 - 1/fs; % time vector, make 2 tones of 2 sec duration then concatenate.

 % Make Amplitude-Modulated, fixed-phase tone; multiply tone by AM envelope
   % make First frequency AM tone
   % .9 normalizes amp;  % here define envelope;      % carrier freq here;
tone1 = (.9 * (1 + sin(2*pi*mod_rate*t +(3*pi/2))) .* sin(2*pi*Fc1*t))/2;
   % make Second frequency AM tone
tone2 = (.9 * (1 + sin(2*pi*mod_rate*t +(3*pi/2))) .* sin(2*pi*Fc2*t))/2;
tone_final = [tone1 tone2];  % concatenate tones

%% Plot stimulus if debugging: waveforms and FFTs
if DeBug == true;
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
    %% 131016CWB: Changed xlim call to zoom relative to duration rather 
    %  than hardcoded assuming a 4 s stim.
    xlim([duration/2-index/fs duration/2+index/fs]); % scale to show midpoint +/- one AM cycle
    
%     zoom xon
    
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
    filename = ['../stims/' 'ProjU' num2str(Fc1) '_' num2str(Fc2) 'Hz_' num2str(mod_rate) 'HzSAM' num2str(duration) 'sec_' num2str(fs/1000) 'kHz.wav'];
    % filename = 'ProjU_500_2_450Hz_40HzSAM_4sec_10kHzfs';
    wavwrite(tone_final, fs, filename);         % Save .wav file
end

end
