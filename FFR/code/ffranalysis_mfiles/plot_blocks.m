function plot_blocks(xls_filename, y_variable, plot_by_age)
% X axis: block, Y -axis variable
%
% Generate plots of PC x block for all subjects, uses data generated from
% FFR_by_training_block_60single.m that calculates PC over blocks some
% number of sweeps (e.g. over blocks of 60 sweeps).
%
% example: >> plot_blocks('TESTXLS.xls', 'pc')
%
%% Define variables
PC_max = 1.0;
path = 'F:\Tera\Proj M';
%% Get data from Excel spreadsheet
  % Assign column letter 
% if  strcmp (x_variable, 'age') == 1;    x_column = 'B';
% elseif    strcmp(x_variable, 'amp') == 1; x_column = 'D';
% elseif    strcmp(x_variable, 'msc') == 1; x_column = 'J';
% elseif    strcmp(x_variable, 'pc') == 1; x_column = 'K'; else
% end

if  strcmp (y_variable, 'age') == 1;    y_column = 'B';
elseif    strcmp(y_variable, 'amp') == 1; y_column = 'D';
elseif    strcmp(y_variable, 'msc') == 1; y_column = 'J';
elseif    strcmp(y_variable, 'pc') == 1; y_column = 'K'; else
end

  % Assign row number
  % determine the dimensions of the spreadsheet, assuming all sheets are
  % the same dimensions
[num, txt]= xlsread(xls_filename, 'Block1'); 
[m,n] = size(num); % dimensions of existing data in worksheet
last_row = m + 1; % add one column for first row being text labels

  % Spreadsheet index
        %   % for x_variable
        %   row_index = ['A' num2str(row_num)]; 
  
    % for y_variable
y_index = [y_column num2str(2) ':' y_column num2str(last_row)];
age_index = ['B' num2str(2) ':' 'B' num2str(last_row)];

% for block_index = 1:6  % get the data 
for block_index = 1:4  % get the data 
    sheet_name = ['Block' num2str(block_index)];
    data. block(block_index).pc = xlsread(xls_filename, sheet_name, y_index);
    data. block(block_index).age = xlsread(xls_filename, sheet_name, age_index);
end

  % for each subject,put their PC from each block into a row variable
for subj = 1:m      
    for q = 1:6      
%     for q = 1:4      
        xy4regr(subj, q) = (data.block(q).pc(subj)); % one subject per row
    end
end 

for k = 1:6  % Calculate average for each block
% for k = 1:4  % Calculate average for each block
    avgs(k) = mean(data.block(k).pc);
end

%% Plot data from blocks
% figname = [xls_filename(1:end-4) '--FFRx360 trials-single epochs-by age'];
figname = [xls_filename(1:end-4) '--FFRx360 trials-single epochs-by age-4R01'];
figure('Name', figname , 'NumberTitle', 'off', ...
       'Units', 'inches', 'Position', [ 1 .5 8 8]);

for i = 1:6 % age x PC for each block
% for i = 1:4 % age x PC for each block
    a(i) = subplot(3,3, i + 3);
    plot(data.block(i).age, data.block(i).pc, 'o')
    hold on
     % do age x PC regression for each block
    [stats_results, linearFit] = linear_regression (data.block(i).age, data.block(i).pc);
    plot(data. block(1).age,linearFit,'k-');
    
    xlabel('age'); ylabel('PC');
    xlim([15 85]); ylim([0 PC_max]); 
    title(['block ' num2str(i)])
          %Position text annotation: regression formula, r^2, p-value
    xpos = get(gca, 'XLim'); ypos = get(gca,'YLim');
    txt1 = text(xpos(2)*.95 , ypos(2)*.85, ...
    {['y = ' (sprintf('%0.4f', stats_results.beta(2))) 'x + ' (sprintf('%0.4f', stats_results.beta(1))) ], ...
     ['R^2 = ' (sprintf('%0.2f', stats_results.rsquare))]      , ...
     ['p = ' (sprintf('%0.3f', stats_results.fstat.pval)) ]}   , ...
         'LineStyle'      ,   'none' , ...
         'FontName'       ,   'Arial', ...
         'FontSize'       ,   8      , ...
         'HorizontalAlignment', 'Right');
end

% Plot pc x block with individual data and mean for each block
b = subplot(3,3,3);
hold on
for k = 1:6
% for k = 1:4
%     plot(k, data.block(k).pc, 'bo')
%     plot(1:6, xy4regr, 'o', 'LineStyle', '-')
    plot(1:4, xy4regr, 'o', 'LineStyle', '-')
    xlabel('block'); ylabel('PC');
    xlim([0.5 6.5]); ylim([0 PC_max]);
    title('PC x block')
end
  % Plot mean data for each block
plot(1:6, avgs, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 2)
% plot(1:4, avgs, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 2)
plot(1:4, avgs, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 2)
hold off

%% Plot regression slope over block across subject  - Does the amount of PC
% change over 6 blocks change with age?
   
    % get regression slope for each subject's PC over block number
    % keep subjects in rows like the xy4regr variable 
for subj = 1:m
[stats_results, linearFit] = linear_regression ( 1:6, xy4regr(subj, :));
slopes.stats(subj) = stats_results;
end

  % make a variable of each subject's slopes
for subj = 1:m      
        slopes_variable(subj,:) = (slopes.stats(subj).beta(2)); % one subject per row
end 

  % Now, do linear regression on the slopes of all subjects (x = age, y = slope)
[stats_results, linearFit] = linear_regression (data. block(1).age, slopes_variable);


c = subplot(3,3,2);
plot(data. block(1).age, slopes_variable, 'o')
hold on
plot(data. block(1).age,linearFit,'k-');

    xlabel('age'); ylabel('Regression Slope');
    xlim([15 85]); ylim([-inf 0.3])
    title('slopes x age')
    
      %Position text annotation: regression formula, r^2, p-value
    xpos = get(gca, 'XLim'); ypos = get(gca,'YLim');
    txt2 = text(xpos(2)*.95 , ypos(2)*.7, ...
    {['y = ' (sprintf('%0.4f', stats_results.beta(2))) 'x + ' (sprintf('%0.4f', stats_results.beta(1))) ], ...
     ['R^2 = ' (sprintf('%0.2f', stats_results.rsquare))]      , ...
     ['p = ' (sprintf('%0.3f', stats_results.fstat.pval)) ]}   , ...
         'LineStyle'      ,   'none', ...
         'FontName'       ,   'Arial',...
         'HorizontalAlignment', 'Right');
    
     set([a b c], 'TickLength', [.02 .02], 'Box', 'on');

     saveas(gcf,[ path '\Adaptation\' figname],'fig')
     
     if nargin > 2
         plot_adaptationXage (data, xy4regr, xls_filename, figname)  
     end

end

