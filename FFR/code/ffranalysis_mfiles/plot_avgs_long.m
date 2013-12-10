
function plot_avgs_long (inFileList)
%% Define Variables
p = 'F:\Tera\Proj M\';
ylim = .5;      % set y-axes limit
xlim = .20;      % set upper limit of x-axis, or the time window
% could add for loop here for multiple x-axis limits
% for xlim = [10 20 50 100 200 300] % for example

%% Figure loop
% for i = 1:30
        % Open inFileList
  in_file_list = [p,inFileList];
  fprintf('\n opening input list file %s \n ', in_file_list)
  fid = fopen(in_file_list, 'r');             % Opens a file for reading
  if fid < 0                                  % fid == -1 means "cannot open  "
	fprintf(2,['Error: File ', in_file_list, ' not found\n']);  
	return;
  end;

i = 1;    % handle index
p = 1;    % subplot index
page = 1; % page index
page_label = [inFileList(1:end-4) '_page_' num2str(page) ];

figure('Units', 'inches', 'Position', [ .5 .5 10 7 ],...
    'Name', page_label);

%% Begin Loop for each filename of the input list
  while feof(fid) == 0        % test for end of file, feof == 1 means end of file
          fline = fgetl(fid);     % "fgetl" gets a line from the file given by fid
      if isempty(fline)       % stop when an empty line is reached in inFileList
          return;
      end
    
     load( fline, ...
            'avg_data_single', ... % non-concatenated average <10402 x 1>
            'subject_id', 'age', 't',...
            'phase_results')

    %% Do the following to each file in the list of filenames
    s(i) = subplot(4,1,p);
    set(s(i),...                       % Set axes properties
        'Box'         , 'on'      , ...
        'XLim'        , [0 xlim], ...
        'YLim'        , [-ylim ylim], ...
        'TickLength'  , [.02 .02] , ...
        'LineWidth'   , 1         );

    hold on
     plot(t, avg_data_single)
    
    gca;
      %% Annotate plot with subject number, age, and phase coherence
      % Normalized positions
    y_position = 0.75;       id_position = .01;   PC_position = .41;       

    text(xlim * id_position, ylim * y_position,...
        ['S# ' num2str(subject_id) '(' num2str(age) ')']);
      % add age to plot
    text(xlim * PC_position, ylim * y_position, ...
        ['PC ' sprintf('%0.2f', phase_results.phase_coherence)]);
    if p == 1
         tb1 = annotation('textbox', 'String'         ,...
         [inFileList '  page(' num2str(page) ')' ]      ,...
        'Position',[0.43 0.95 0.3 0.05], 'Interpreter', 'None',...
        'FitHeightToText','off','LineStyle','none');
    end
    if p ==2; ylabel('Amplitude (\muV)'); end
    if p ==4; xlabel('Time (ms)')       ; end
    p = p + 1;

    if rem(i,4) == 0
        % save figure to file
      print('-dtiff','-r300', page_label)
        % get ready for next page or figure
      p = 1;   
      page = page + 1;
      page_label = [inFileList(1:end-4) '_page_' num2str(page) ];
      figure('Units', 'inches', 'Position', [ .5 .5 10 7 ],...
          'Name', page_label );
    end
     i = i + 1;

  end
% end