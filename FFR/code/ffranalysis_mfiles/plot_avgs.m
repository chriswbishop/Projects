
function plot_avgs (inFileList, a_title, Fc1, Fc2)
%% Define Variables
% THis file will read Project M .mat files from Meeg2ascii.m and plot the
% average waveform for all of the subjects in a filelist.
% Example: >> plot_avgs_filtered ('fileName_list_500Hz.txt','',300, 700)
%  where inFileList is a .txt file, title is a string, and 300 & 700 are
%  the cutoff frequencies of a bandpass filter.
p = 'F:\Tera\Proj M\';
ylim = .6;        % set y-axes limit
xlim = .050;      % set upper limit of x-axis, or the time window
% could add for loop here for multiple x-axis limits
% for xlim = [10 20 50 100 200 300] % for example
%% Figure loop
% figure
% figure('Name', [fileName, 'autocorr'], 'Units', 'inches', 'Position', [ .5 .5 9 6 ]);
figure('Units', 'inches', 'Position', [ .5 .5 10 7 ], ...
    'PaperOrientation', 'Portrait', 'PaperPositionMode', 'auto');
i = 1;
% for i = 1:30
        % Open inFileList
  in_file_list = [p, inFileList];
  fprintf('\n opening input list file %s \n ', in_file_list)
  fid = fopen(in_file_list, 'r');           % Open a file for reading
  if fid < 0                                % fid == -1 means "cannot open"
	fprintf(2,['Error: File ', in_file_list, ' not found\n']);  
	return;
  end;
  
num_rows = 7;
num_col = 5;

  %% Begin Loop for each filename of the input list
  while feof(fid) == 0        % test for end of file, feof == 1 means end of file
          fline = fgetl(fid);     % "fgetl" gets a line from the file given by fid
      if isempty(fline)       % stop when an empty line is reached in inFileList
          return;
      end
    
%     input_file = [p, fline, '.mat'];    
     load( fline, ...
            'avg_data_single', ... % non-concatenated average <10402 x 1>
            'subject_id', 'age', 't','fs',...
            'phase_results')

    
                  
    %% Do the following to each file in the list of filenames
    s(i) = subplot(num_rows,num_col,i);
    set(s(i),...                       % Set axes properties
        'Box'         , 'on'      , ...
        'XLim'        , [0 xlim], ...
        'YLim'        , [-ylim ylim], ...
        'TickLength'  , [.02 .02] , ...
        'LineWidth'   , 1         );
   
    hold on
    
    if nargin > 2 % filter data if cut-off freq's are specified.
         [ avg_data_filtered ] = bp_filter(avg_data_single, Fc1, Fc2, fs);
     plot(t, avg_data_filtered)
    else
     plot(t, avg_data_single)
    end
    
    if i == 3
     title(a_title);
    end

%% Annotate plot with subject number and age    
    gca;
      % Normalized positions
    y_position = 0.75;       id_position = .05;   PC_position = .6;       
      % add subject id to plot
    t1 = text(xlim * id_position, ylim * y_position, ...
        ['S# ' num2str(subject_id) '(' num2str(age) ')']);
      % add age to plot
%     text(xlim * age_position, ylim * y_position, num2str(age));
    t2 = text(xlim * PC_position, ylim * y_position, ...
        ['PC ' sprintf('%0.2f', phase_results.phase_coherence)]);
    
    set ([t1 t2], 'FontSize', 8)
    
    i = i + 1;  
    clear avg_data_single subject_id age phase_results
    
  end
%% Annotate with x and y labels, title
tb1 = annotation('textbox', 'String', 'Time (ms)',...
        'Position',[0.49 0.03 0.2 0.05]);
% tb2 = annotation('textbox', 'String', 'Amplitude (\muV)',...
%         'Rotation', 90,...
%         'Position',[0.05 0.5 0.2 0.05]);
tb3 = annotation('textbox', 'String', inFileList,...
        'Position',[0.43 0.95 0.2 0.05], 'Interpreter', 'None');
set([tb1 tb3],'FitHeightToText','off','LineStyle','none')
end

function [ avg_data_filtered ] = bp_filter(avg_data_single, Fc1, Fc2, fs)
% Zerophase filter the data. filtfilt doubles the filter order.

N = 4; % order of filter, 6dB/octave per order
[b,a] = butter(N/2, [Fc1 Fc2]/(fs/2));
avg_data_filtered = filtfilt(b, a, avg_data_single);
end