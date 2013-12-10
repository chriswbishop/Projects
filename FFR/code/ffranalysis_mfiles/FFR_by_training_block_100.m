function FFR_by_training_block_100 ( fileName )
% This m-file will calculate phase coherence on blocks of 60 trials, from
% Project M's data.  This analysis is to be used as preliminary data to see
% if PC may be calculated over blocks of 60 single trials or 30
% concatenated files
%
% To run as a batch file, use with masterbatch.m
%
%% Load data and define Variables
load(fileName, ...
    'epoch_data_single', 'epoch_n', ... 
    'subject_id', 'age', 'stim_freq', 'bin', 'f', 't', 'fs')

block_length = 100;             % might be 60 trials for training
% block_max = 16;                 % 1000/60 = 16.66667; 500/30 = 16.666667
block_max = 5;                  % 1000/2 = 500; 500/100 = 5
block_index = 1;

NFFT = length(t)*2;
f = fs/2 * linspace(0,1,NFFT/2);            % Frequency vector for plotting

% Concatenate consecutive sweeps and get FFT data
[sx, sy, epochs_concat] = get_fft_data(epoch_data_single, epoch_n, bin, NFFT);

ax = max(abs(sy))* 1.3;         % pad axes by 30% of max absolute value for debugging
output = 1;             % for tpt2

% plot_indexX = 1;
% plot_indexY = 1;
plot_width = 1.5;
figure('Name',[fileName '/\/\ FFR x TrainingBlock'] , 'Units', 'inches', 'Position', [ 1 1 10 6]);

%% calculations by training block length
indexes = [1 block_length];
    
for k = 1:block_max
    
      % Partition sweeps by block
%     if k == 1
%         sx_loop = sx(k:block_index+block_length-1);
%         sy_loop = sy(k:block_index+block_length-1);
%     else
%         sx_loop = sx((k-1)*block_length+1:block_index+block_length-1);
%         sy_loop = sy((k-1)*block_length+1:block_index+block_length-1);
%     end
        sx_loop = sx(indexes(1):indexes(2));
        sy_loop = sy(indexes(1):indexes(2));
    
      % Calculate amplitude for subset of sweeps
    epochs4amp = epochs_concat(indexes(1):indexes(2));
    [amp, bin_nx, bin_snrdb, p_val_fft, Y ] = get_amp (epochs4amp, bin, NFFT);

    indexes = indexes + block_length;
    %          subplot(plot_indexX, plot_indexY,i)
    a(k) = axes('Units', 'inches', 'Position', [k*plot_width*1.1 3.5 plot_width plot_width]);
    
      % plot FFR area
    bar(f, 2*abs(Y(1:NFFT/2)));                     % frequency on x-axis
     hold on
    stem(f(bin), amp, 'r','LineWidth', 1)             % highlight FFR bin
     hold off
    title('FFT');
    
   if k ==1;         ylabel('Amplitude (\muV)'); end
      % Calculate phase-based metrics
    [s1, s2, s3, phase_results, k, b] = tpt2_by_training_block(sx_loop, sy_loop, '' , ax, output, k, plot_width);
    
      % Annotate with results CHECK PVALUE OF MAGNITUDE SQUARED COHERENCE
    tb(k) = annotation('textbox', 'String',{ ['FFR Amp = ' (sprintf('%0.5f', amp)) ' \muV'], ...
        ['Noise \pm 5 Hz = ' (sprintf('%0.5f', bin_nx)) ' \muV'], ...
        ['SNR = ' (sprintf('%0.2f',bin_snrdb)) ' dB' ], ...
         (sprintf('p-value = %1.4f', p_val_fft)), ...
        '- - Phase Analysis - - ', ...
        sprintf('PC = %.4f, p = %.4f',phase_results.phase_coherence,phase_results.phase_coherence_pval),...
        sprintf('MSC = %.4f, p = %.4f',phase_results.msc,phase_results.ellipse_t2_pval) },...
        'Units', 'inches',...
        'Position',[k*plot_width*1.1 .9 plot_width plot_width/4], ...
        'FontSize', 8);

    if k ==1    % Set Axes Titles, e.g. sweeps 1 - 100
        title([ 'sweeps ' num2str(k) '-' num2str(100*k)]);
        ylabel('Amplitude (\muV)')
    else
        title([ 'sweeps ' num2str((100*(k-1))+1) '-' num2str(100*(k-1)+100)]);
    end
    
    % adjust block and subplot indices
%     block_index = block_index+block_length; 
    block_index = block_index+block_length; 
    %         if rem(i,4) == 0;
    %             plot_indexX = 1;
    %         else
    %             plot_indexX = plot_indexX +1;
    %         end

    %         if rem(i,4) == 0;       plot_indexY = plot_indexY+1;      end
end

  % set axes properties
set(a(2:end), 'YTickLabel', '');
 
  ymax = get(a(:), 'YLim');
  for q = 1:length(ymax); ymax2(q) = ymax{q}(2); end 
  ymax2 = max(ymax2);
set(a(:),'TickLength', [0.02 0.02], 'Box', 'On',...
    'XLim', [stim_freq-100 stim_freq+100], ...
    'YLim', [0 ymax2]);

%% Annotate with subject/condition info
tb(k+1) = annotation('textbox','String',...
    {['Subject# ' num2str(subject_id) '           Age: ' num2str(age)],...
    ['Condition: ' fileName],...
    ['Stimulus Frequency = ' num2str(stim_freq) ' Hz']},...
    'Position',[0.02 0.9 0.425 0.05], 'Interpreter','none');

% add phase results from .mat file
load(fileName, 's1', 's2', 's3', 'amp', 'bin_nx', 'bin_snrdb', 'p_val_fft')
tb(k+2) = annotation('textbox', 'String'                    , ...
    {'Results from full data set:'                          , ...
    ['Amp = ' (sprintf('%0.5f', amp)) ' \muV']              , ...
    ['Noise \pm 5 Hz = ' (sprintf('%0.5f', bin_nx)) ' \muV'], ...
    ['SNR = ' (sprintf('%0.2f',bin_snrdb)) ' dB' ]          , ...
    (sprintf('p-value = %1.4f', p_val_fft))}                , ...
    'Units', 'inches'                                       , ...
    'Position', [4.5 5.85 2 0.05],    'FontSize', 8);                                   
    
% tb(k+3) = annotation('textbox', 'String'                    , ...
%     {'- - Phase Analysis - - '                               , ...
%     sprintf('PC = %.4f, p = %.4f',phase_results.phase_coherence,phase_results.phase_coherence_pval),...
%     sprintf('MSC = %.4f, p = %.4f',phase_results.msc,phase_results.ellipse_t2_pval)},...
%     'FontSize', 8                                           , ...
%     'Position', [5 5.85 2 0.05]);

tb(k+3) = annotation('textbox', 'String'                    , ...
    {'- - Phase Analysis - - ', s1, s2, s3}                 , ...
    'FontSize', 8                                           , ...
    'Units', 'inches'                                       , ...
    'Position', [6.75 5.85 3 .05]);
    
set(tb(:), 'FitHeightToText','off','LineStyle','none')
end

function [sx, sy, epochs_concat] = get_fft_data(epoch_data_single, epoch_n, bin, NFFT)
% Concatenate consecutive sweeps and get FFT data

k = 1:2:epoch_n;
epochs_concat = zeros(20804,500);
for i = 1:epoch_n/2
epochs_concat(:,i) = vertcat(epoch_data_single(:, k(i)), epoch_data_single(:,k(i)+1));
end

  % Calculate FFT for each column of concatenated sweeps
h = waitbar(0,'FFTs being calcuated ...');
y = zeros(length(epochs_concat), epoch_n/2);
for i = 1:epoch_n/2;  % Calculate FFT for each column of concatenated sweeps
    y(:,i) = fft(epochs_concat(:,i),NFFT)/NFFT;
    waitbar(i/(epoch_n/2))
end
close(h) 

  % Get real and imaginary FFR data for each sweep:
complex = y(bin,1:epoch_n/2)';   % FFR data in complex form
sx = real(complex);   
sy = imag(complex); 
end

function [amp, bin_nx, bin_snrdb, p_val_fft, Y] = get_amp(epochs_concat, bin, NFFT)
Y = fft(epochs_concat,NFFT)/NFFT;

  % Calculate amplitude (in microvolts), noise, and SNRs
amp = 2 * abs(Y(bin));                  % amplitude at FFR's FFT bin
bin_low  = 2 * abs(Y(bin-5:bin-1))';    % the 2*abs keeps it in microvolts
bin_high = 2 * abs(Y(bin+1:bin+5))';
bin_nx = mean(vertcat(bin_low,bin_high)); % mean noise +/- 5 Hz
bin_snr = amp/bin_nx;                   % SNR re: plus and minus 5 Hz
bin_snrdb = 10 * log10(bin_snr);        % SNR in decibels
p_val_fft = 1 - fcdf(bin_snr,2,20);         % p-value for f-test

% ADD PLUS-MINUS NOISE ESTIMATE HERE
end