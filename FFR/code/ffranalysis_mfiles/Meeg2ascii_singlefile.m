%% function Meeg2ascii_singlefile, for Proj M's FFR data analysis. 
%   This analysis will measure FFT signal-to-noise ratios and call
%   proj_m_tpt2.m for phase analysis (T-squared, phase coherence, etc.)
%
%%%%   MOVE THE ACCEPTED.DAT FILE TO F:\Tera\Proj M\ and then run this function.
%   import a .dat file that is exported from neuroscan .eeg epoch file)
%    (.dat file: 20 lines of header, tab delimited)
%   create a data matrix (timepoint * epoch) using ONLY ACCEPTED TRIALS
%   write out the data matrix in a tab delimited text file
%
%   usage example > Meeg2ascii_singlefile(195, 78, 'm195_520ms1kaccepted',1000)
%       this will read 'm195_520ms1kaccepted.dat' file
%
%   NOTE: 'importdata' function reads a .dat file, and create a struct with 'data' and 'textdata'
%   But, this function reads the data such that he epoch headers in the tab delimited .dat file include the first
%   point of the epoch. Because of this, the first point of the epoch will not be
%   copied into the output matrix. 
% 
%   Neuroscan TCL Code: In Edit, delete rejected sweeps, save as _concatenate.eeg, filter, save
%      as .dat with only file header.   Neuroscan TCL commands:
%       DELETESWEEPS {$path\\%concatenate.eeg}
%       FILTER_EX BANDPASS ZEROPHASESHIFT 500 24 2000 24 x x x N FIR { ALL } {$path\\%concatenate.eeg}
%       EXPORTEEG_EX2 {$path\\%concatenate_eeg.dat} POINTS T F F F F F F F F F F { ALL } 
%
%  by CGC 4/08.
%%
function Meeg2ascii_singlefile (subject_id, age, fileName,stim_freq)
%   Load the file
p = 'F:\Tera\Proj M\'; % 11/13/08 - changed from 'F:...' after plugging drive back in.
header_line = 14; % 14 when only file header is checked in Neuroscan Edit
in_file = [p, fileName, '.dat'];

% importdata will import ASCII file exported via Neuroscan and will be
% stored in "newData" struct, with data[double], and textdata{cell}
delimiter = ' ';
fprintf('\n opening input file %s \n ', in_file)
newData = importdata(in_file, delimiter, header_line);
% header_data = newData.data;
% input_data = newData.textdata;
input_data = newData.data;  % This is the eeg data

%%   Variables   
fs = 20000;
% a = length(input_data);        
time_pt = 0:1/fs:0.52005;      % t = 0:1/fs:0.52005 <10402 points>
c = length(time_pt);          
double_epoch = 2 * c;       % concatenated epoch length, in points
% matrix_size = size(input_data);
% epoch_n = (matrix_size - header_line)/(e_hdr + time_pt);

%%  Count the Epochs, drop one if there's an odd number of sweeps.
%   If there is an odd number of accepted sweeps, delete the last one so that
% there will be an even number for concatenating them in pairs of two.

if rem(length(input_data),(length(time_pt)*2)) ~= 0; % if not an even # of epochs...
    input_data((length(input_data)-10401):end) = []; % delete the last epoch
    disp('Deleted last epoch')
    epoch_drop = 1;             % true, logical array
else                                            % don't delete any epochs.
    epoch_drop = 0;
end
% Double-check to see if there is an integer # of sweeps
if rem(length(input_data),(length(time_pt)*2)) == 0;% 0 = integer # of epochs
        disp('Integer number of sweeps')
else
    disp('Check length(input_data) epoch time window, non-integer # of sweeps')
    return
end
    % count the number of epochs
epoch_n = length(input_data)/(length(time_pt));%  % number of original sweeps
epoch2_n = length(input_data)/(length(time_pt)*2);% # of double epochs (20402 length, concatenated)

%%  Reshape and Average the Epochs  
% since the .eeg file is being exported as a .dat file, averaging will
% need to be done in matlab.  EEG filtering will need to be done prior to 
% exporting the .eeg file.

 % Reshape for single (original) epoch average
epoch_data_single = reshape(input_data, c, epoch_n); % single epochs per column
avg_data_single = mean(epoch_data_single,2);         % single epoch average across columns

 % Reshape input_data to have 2 concatenated epochs in each column
epoch_data_double = reshape(input_data, double_epoch, epoch2_n);
avg_data_double = mean(epoch_data_double,2);         % mean for concatentated data across columns
% data = avg_data_double;                       % rename for mplot code

%%  Calculate Averaged Waveform's FFT;    Begin mplot.m  from 12/4/07
t = 0:1/fs:0.52005;         % 520 ms  == 10402 points
% t = -0.25:1/fs:0.74999;   % for 20,0000 points November 27

%%%   FFT Window   %%%%     Not necessary with coherent sampling
% L = length(data);
% twin = tukeywin(L,0.4); 
% When plotted over 0:1/fs:1;  first 1 is at 0.1991 sec, last 1 is at 0.8009 sec

NFFT = length(avg_data_double);   % number of points submitted to FFT == length(data)
Y = fft(avg_data_double,NFFT)/length(avg_data_double);              % no zero-pad
f = fs/2 * linspace(0,1,NFFT/2);              % Frequency vector for plotting

% Specify FFT bins by frequency; for 20402 (concatenated) data
if       stim_freq == 1000;   bin = 1041;
  elseif stim_freq == 999;    bin = 1040;
  elseif stim_freq == 998;    bin = 1039;
  elseif stim_freq == 975;    bin = 1015;
  elseif stim_freq == 423;    bin = 441;
  elseif stim_freq == 905;    bin = 941;
  elseif stim_freq == 900;    bin = 937;
  elseif stim_freq == 925;    bin = 963;
  elseif stim_freq == 890;    bin = 927;
  elseif stim_freq == 800;    bin = 833;
  elseif stim_freq == 980;    bin = 1019;
  elseif stim_freq == 500;    bin = 521;
  elseif stim_freq == 499;    bin = 520;
  elseif stim_freq == 498;    bin = 519;
  elseif stim_freq == 463;    bin = 483;
  elseif stim_freq == 50;     bin = 53;
  elseif stim_freq == 100;    bin = 105;      
  elseif stim_freq == 150;    bin = 157;            
  elseif stim_freq == 200;    bin = 209;            
  elseif stim_freq == 250;    bin = 261;
else
    disp('a FFT bin number is not specified for this stim_freq')
    bin = input('\n Please enter the FFT bin number that contains the FFR:', 's');
end

%% Calculate amplitude (in microvolts), noise, and SNRs
amp = 2 * abs(Y(bin));                  % amplitude at FFR's FFT bin
bin_low  = 2 * abs(Y(bin-5:bin-1))';    % the 2*abs keeps it in microvolts
bin_high = 2 * abs(Y(bin+1:bin+5))';
bin_nx = mean(cat(2,bin_low,bin_high)); % mean noise +/- 5 Hz
bin_snr = amp/bin_nx;                   % SNR re: plus and minus 5 Hz
bin_snrdb = 10 * log10(bin_snr);        % SNR in decibels
p_val_fft = 1 - fcdf(bin_snr,2,20);         % p-value for f-test

%%  Prep for Phase analysis and sent to proj_m_tpt2.m
NFFT = length(epoch_data_double);    % number of points submitted to FFT 
% Calculate FFT for each column of concatenated sweeps
h = waitbar(0,'FFTs being calculated ...');
y = zeros(length(epoch_data_double), epoch2_n);
for i = 1:epoch2_n;  % Calculate FFT for each column of concatenated sweeps
    y(:,i) = fft(epoch_data_double(:,i),NFFT)/NFFT;
    waitbar(i/epoch2_n)
end
close(h) 
% Get real and imaginary FFR data for each sweep:
complex = y(bin,1:epoch2_n)';   % FFR data in complex form
sx = real(complex);   
sy = imag(complex); 

figure('Name',fileName);
% send to proj_m_tpt2.m
xtitle = '    '; % leave spaces here for title alignment
output = 1; 
ax = 4;
[s1, s2, s3, phase_results] = proj_m_tpt2(sx, sy, xtitle, ax, output);
hold on

%%   Save variables to file   %%%
% out_file = [p, fileName, '.txt'];
out_file = [p, fileName];
fprintf('\n writing output file %s \n\n ', out_file)
% save(out_file, 'avg_data_double','-ASCII','-tabs'); % saves averaged wave  
save(fileName);                           % save all variables as .mat file

%%   plot FFT data   %%
% plot whole FFT
% h1 = subplot(2,2,1);
h1 = subplot(3,3,4);
% h1 = axes('position', [.13 .7 .35 .2]); 
stem(f, 2*abs(Y(1:NFFT/2))); 
hold on 
stem(f(bin), amp, 'r','LineWidth', 1)               % highlight FFR bin
hold off
xlim([0 5000]);                           title('FFT')
zoom xon;    xlabel('Frequency (Hz)');    ylabel('Amplitude (\muV)');

% plot FFR area
% h2 = subplot(2,2,2);
h2 = subplot(3,3,5);
% h2 = axes('position', [.57 .7 .35 .2]); 
stem(f, 2*abs(Y(1:NFFT/2)));                        % frequency on x-axis
hold on
stem(f(bin), amp, 'r','LineWidth', 1)               % highlight FFR bin
hold off
xlim([stim_freq-100 stim_freq+100]); % alternately, xlim([900 1100])in Hz.
zoom xon;    xlabel('Frequency (Hz)');    ylabel('Amplitude (\muV)')
title('FFT');

% plot time-domain waveform
% h3 = subplot(3,1,3); % change to subplot(3,3,7:8), 
h3 = subplot(3,2,2); 
plot(t, avg_data_single);       % plot the single-epoch average waveform
xlim([-0.01 0.55]); 
xlabel('Time (sec)'); ylabel('Amplitude (\muV)')

%% Annotate figure with textboxes and calculations
tb1 = annotation('textbox','String',...
    {['Subject# ' num2str(subject_id) '           Age: ' num2str(age)],...
    ['Condition: ' fileName],...
    ['Stimulus Frequency = ' num2str(stim_freq) ' Hz']},...
        'Position',[0.02 0.9 0.425 0.05], 'Interpreter','none');
    
tb2 = annotation('textbox','String', ...
    {'FFT Analysis:' ,...
    ['FFR Amp = ' (sprintf('%0.5f', amp)) ' \muV'], ...
    ['Noise \pm 5 Hz = ' (sprintf('%0.5f', bin_nx)) ' \muV'], ...
    ['SNR = ' (sprintf('%0.2f',bin_snrdb)) ' dB' ], ...
    [(sprintf('p-value = %1.6f', p_val_fft))]}, ...
        'Position',[0.65 0.55 0.35 0.05]);
    
tb3 = annotation('textbox', 'String',{'Phase Analysis: ', s1, s2, s3},...
        'Position',[0.4 0.1 0.55 0.2]);
    
set([tb1 tb2 tb3],'FitHeightToText','off','LineStyle','none')

%% Save Figure
saveas(gcf,fileName,'fig')

end


