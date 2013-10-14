%% Post Processsing, calculate stuff for d', P(C), and Figure

%  To avoid undefined values of d', hit rates of 0 were converted to 0.5/Ns
%  and hit rates of 1 were converted to 1-0.5/Ns, where Ns was the
%  number of signal trials presented at a given ripple density (i.e. 20)
%  (cf. Macmillan and Creelman, 2005). Hit rate proportions of 1 or 0 were 
%  thus converted to 0.975 or 0.025. Similarly, false alarm rates of 0 or 1
%  were converted to 0.025 or 0.975.

  % Calculate Probability Correct, P(C), for each tested parameter
for i = 1:length(args.par_vals)
      % on which trials was this stimulus condition presented
    found = find(par_by_trial == args.par_vals(i));
    n_correct(i)=  sum(correct(found));% # of trials with correct responses
    pc(i)       = mean(correct(found));% calculate P(C)
    
      % find signal trials, numbers of hits & misses
    sig_trials = find(order(found) == 1);% found's signal trials as indexes
    num_hits(i)   = sum( correct(found(sig_trials))); % Number of hits for this stimulus
    num_misses(i) = sum(~correct(found(sig_trials)));
    hit_rate(i)   = num_hits(i) / args.n_trialsperstim;
    
      % find noise trials, numbers of False Alarms & Correct Rejections
    noise_trials = find(order(found) == 0);%found's signaltrials as indexes
    num_corr_rej(i)   = sum( correct(found(noise_trials)));
    num_falsealarm(i) = sum(~correct(found(noise_trials))); 
    FA_rate(i)        = num_falsealarm(i) / args.n_trialsperstim;
      
      % Calculate d', criterion, and inverse cum. distributions
    if     hit_rate(i) == 1;  hit_rate(i) = 1 - 0.5/args.n_trialsperstim;
    elseif hit_rate(i) == 0;  hit_rate(i) =     0.5/args.n_trialsperstim;
    end
    
    if     FA_rate(i) == 1;  FA_rate(i) = 1 - 0.5/args.n_trialsperstim;
    elseif FA_rate(i) == 0;  FA_rate(i) =     0.5/args.n_trialsperstim;
    end
       
    zFA (i) = norminv(FA_rate (i), 0, 1); % 
    zHit(i) = norminv(hit_rate(i), 0, 1);
    dprime(i) = zHit(i) - zFA(i);               % from Wickens 2001, page 24
    criterion(i) = norminv(1-FA_rate(i),0,1);   % from Wickens 2001, page 24
end

  % Do Logistic Regression (Statistics Toolbox required)
% n_correct = n_correct';   % column vectors needed for glmfit's "y" inputs
% n_hits = num_hits';  % only include signal trials in psychometric function
n_hits = num_hits';  % only include signal trials in psychometric function
n_trialsperstim = (args.n_trialsperstim) * ones(1, length(args.par_vals))';
proportion = n_hits ./ n_trialsperstim;
[logitCoef,dev,stats] = glmfit(args.par_vals,[n_hits n_trialsperstim],'binomial','logit');
logitFit = glmval(logitCoef,args.par_vals,'logit');

  % Find 91% P(C) point and corresponding stimulus value
   %%% The logistic psychometric function:
   %%%   y = 1/(1 + e^-(mx + b))...... solve for x = (log(1/y - 1) + b)/-m
y = args.psych_point;  % find this point on psychometric function
psych_slope       = stats.beta(2);
psych_yintercept  = stats.beta(1);
psych_thresh_stim = (log(1/y - 1) + psych_yintercept)/(psych_slope * -1);

%% Make figure
figure   ('Units', 'inches', 'Position', [1 1 10 7], ...
    'PaperOrientation', 'landscape', 'PaperPositionMode', 'Auto')

  % Plot P(C)
a1 = axes('Units', 'inches', 'Position', [0.5 0.5 2.5 2.5]);
  plot(args.par_vals, proportion,'bs', ...
       args.par_vals, logitFit  ,'r-');
%    xlabel('frequency (Hz)')
   xlabel('\deltaf'); 
  ylabel('Proportion Correct');
  set(a1, 'ylim', [-0.05 1.05]);
%   ylim([-0.05 1.05])
  title('P(C) x \deltaf')
    hold on
   % show lines from 91% to X axis
  xlimits = get(gca, 'xlim');  ylimits = get(gca, 'ylim');
  plot([xlimits(1)        psych_thresh_stim], [y y         ], 'k', ...
       [psych_thresh_stim psych_thresh_stim], [y ylimits(1)], 'k')
    
 % Plot d'
a2 = axes('Units', 'inches', 'Position', [3.5 0.5 2.5 2.5]);
  plot(args.par_vals, dprime,'bs-')
  xlabel('\deltaf'); ylabel('d''');
  set(a2, 'ylim', [0 4]);
%   ylim([-3 4])
  title('d'' x \deltaf')

 % Annotate figure with Subject info, Hit Rate, etc.
tb1 = annotation('textbox','String',...
    {['Subject# ' num2str(args.subject_id{:}) '           Age: ' num2str(args.age{:})],...
    ['Condition/filename: ' filename],...
    ['Stimulus Frequency = ' num2str(frequency) ' Hz']},...
        'Position',[0.02 0.95 0.425 0.05], 'Interpreter','none', ...
        'LineStyle','none');
  
tb2 = annotation('textbox','String',...
{['Signal-to-Noise Ratio  '       (sprintf('%0.1f    ',args.par_vals)) 'dB SPL'], ... 
 ['Hit Rate ............. ' (sprintf('%0.2f   ' ,hit_rate))          ], ...
 ['False Alarm Rate '       (sprintf('%0.2f   ' ,FA_rate))           ], ...
 ''                                                                   , ...
 ['d''  ....................  '      (sprintf('%0.2f   ' , dprime  ))], ... 
 ['criterion ............. '      (sprintf('%0.2f   ' , criterion  ))], ... 
 ['# Hits ............... ' (sprintf('%0.0f        ',num_hits      ))], ...
 ['# Misses ........... '   (sprintf('%0.0f        ',num_misses    ))], ...
 ['# Correct Reject. '      (sprintf('%0.0f        ',num_corr_rej  ))], ...
 ['# False Alarms .. '      (sprintf('%0.0f        ',num_falsealarm))], ...
 ''                                                                   , ...
 ['Stimulus Frequency = '   num2str(frequency) ' Hz'            ], ...
 ['91% Correct at ' num2str(psych_thresh_stim) ' \deltaf'       ]}, ...
                   'FitBoxToText', 'on', ...
                   'Position',[0.02 0.5 0.5 0.35], 'Interpreter','none');

               
  % Plot probability density functions for each condition
    range = -4:0.1:7; x_pos  = 7; y_pos  = 7; width = 2.5; height = 0.4;
for i = 1:length(args.par_vals)
    dist_noise = pdf('Normal', range ,        0 , 1); %prob. dens. function
    dist_sig   = pdf('Normal', range , dprime(i), 1);
    p(i) = axes('Units', 'inches', ...
        'Position', [x_pos y_pos-i*.6 width height]);
      plot(range, dist_noise, 'k-', 'linestyle', '-' )% plot noise
        hold on
      plot(range, dist_sig  , 'b-', 'linestyle', '--')% plot signal
        ylim = get(gca,'YLim');
      plot(0*[1,1]           ,ylim           ,'k:', ... % plot criterion
           dprime(i)*[1,1]   ,ylim           ,'k:', ...
           criterion(i)*[1,1],[0,ylim(2)*1.1],'k-');
      ylabel([num2str(args.par_vals(i)) '\deltaf'], 'Rotation', 0.0)
end
set(p(:), 'xlim', [range(1) range(end)], ... % set axes parameters
    'xtick'     ,  range(1):range(end) , ...
    'xticklabel', {'-4', '', '-2', '', '0', '', '2', '', '4', '', '6', ''})

figname = [args.path, 'ProjA_', filename,'_date',num2str(datestr(now,30))];
saveas(gcf, figname, 'fig'); % save the figure .fig

%% Save final results file as .mat
clear grey SUBJECT_RESPONSE k stopnow a str_correct  i 
clear x_pos xlimits y y_pos ylim ylimits temp_filename NEXT max_noise
clear noise tone noise_rms tone_rms width height dB_snr_now dB_snr_target
results = [args.path 'ProjA_' filename 'Results_' num2str(datestr(now,30))]; % save final results .mat
save(results)