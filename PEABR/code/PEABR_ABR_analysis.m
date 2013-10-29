function [DATA SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG, PREFIX)
%% DESCRIPTION:
%
%   Function to create first pass plots and analysis of a specified ERP
%   bin. This includes a plot of the average waveforms across subjects,
%   a plot of individual traces (useful for spotting anomalies), as well as
%   a crude estimate of the signal-to-noise (SNR) level.  
%
%   Also works with individual subjects, which is nice when someone is
%   clearly an outlier. Can then look at just that one subject's data.
%
% INPUT:
%
%   SID:    character array, each row in a subject ID
%   STR:    string, appended name of ABR mat file (e.g., "_Cz_LE")
%   BINS:   integer array, specified bins in the ERP data structure.
%   ETFLAG: bool, echo threshold flag.  If true, then the post stimulus
%           time period is justified to the subject's echo threshold. This
%           proved useful when analyzing lag-only stimuli and the like.
%           (default = false)
%   BL:     2x1 array specifying the beginning and end of the period of
%           time to use for noise estimation. (default is prestimulus
%           period)
%   STIME:  2x1 array specifying the beginning and end of the signal period
%           (default, [ 0 0.01] s post-stim onset, which is either 0 ms or the
%           echo threshold depending on whether or not ETFLAG is set).
%   PFLAG:  bool, flag to generate plots (default = true)
%
% OUTPUT:
%
%   DATA:   Bindata from ERP structure for all subjects.
%   SNR:    Signal to noise ratio for bin.
%
%   BLTT:   double array, time stamps for each point.
%

%% INPUT CHECK AND DEFAULTS
if ~exist('ETFLAG', 'var') || isempty(ETFLAG), ETFLAG=false; end
if length(ETFLAG)~=length(BINS), ETFLAG=logical(ones(length(BINS),1).*ETFLAG); end
if ~exist('BL', 'var'), BL=[]; end
if ~exist('STIME', 'var'), STIME=[0 0.01]; end
if ~exist('PFLAG', 'var') || isempty(PFLAG), PFLAG=true; end % plot figures by default
if ~exist('PREFIX', 'var') || isempty(PREFIX), PREFIX='_ABR'; end

STIME=STIME*1000; % convert to ms

%% GET ERP DATA FOR SUBJECTS
DATA=[];
SNR=nan(size(SID,1), length(BINS)); 
for s=1:size(SID,1)
    
    sid=deblank(SID(s,:));
    
    % Get echo threshold for subject. These are recorded in
    % PEABR_ECHOTHRESHOLD_LOOKUP. Returns time in seconds. 
    alag=PEABR_ECHOTHRESHOLD_LOOKUP(sid); 
    alag=alag*1000; % convert to ms
    
    % Load subject ERP structure
    load(fullfile(sid, 'analysis', [sid PREFIX STR]), 'ERP');

    % Isolate noise (NOIZE) estimation for SNR calculations later.
    
    % By default, use the prestimulus period for the noise estimation
    if isempty(BL)
        BL=[ERP.times(1) 0]; 
   
    end % if isempty(BL)
    
    if s==1 % just want to convert for first subject, others inherit this
         % Convert to an index
        BL=find(ERP.times>=BL(1), 1, 'first') : find(ERP.times<=BL(2), 1, 'last');
        BLT=ERP.times(BL); 
    end % s==1

    % Mask data if we are plotting data relative to ET
    % HM, with ETFLAG set, I need to give more thought to the
    % referencing...specifically, the find statements might need to be
    % reworked to select the time window. 
    for i=1:length(BINS)
        if ETFLAG(i)
            
            % Adjust for echo threshold
            %   This litttle ditty ensures that the data size is identical
            %   whether or not we use ETFLAG or not.
            TIND=find(ERP.times>=STIME(1), 1, 'first') : find(ERP.times<=STIME(2), 1, 'last');
            TIND=find(ERP.times>=STIME(1)+alag, 1, 'first') : find(ERP.times>=STIME(1)+alag, 1, 'first')+length(TIND)-1;
            T=ERP.times(TIND)-ERP.times(TIND(1)); % adjust times so relative to 0 ms.
        else
            % Get time index if not accounting for echo threshold
            TIND=find(ERP.times>=STIME(1), 1, 'first') : find(ERP.times<=STIME(2), 1, 'last');
            T=ERP.times(TIND); 
        end 
        
        % Put subject data (masked) into larger array
        %   Handy to do this for each bin just in case we want to plot
        %   relative to true 0 or echo threshold at the same time.
        DATA(:,:,i,s)=ERP.bindata(:,TIND,(BINS(i)));
        
        % SNR ESTIMATION
        NOIZE(:,:,i,s)=ERP.bindata(:,BL,BINS(i));
        SNR(s,i)=db(rms(squeeze(DATA(:,:,i,s)))) - db(rms(squeeze(NOIZE(:,:,i,s))));
        
    end % i=1:length(BINS)    

    % Concatenated time. Useful as a return variable for plotting.
    BLTT=[BLT T]; 
    
end % for s=1:size(SID,1)

%% CREATE PLOTS FOR EACH BIN
if PFLAG
    h=figure;
    hold on; % overlay figure
    for i=1:length(BINS)
        
        %% AVERAGE PLOT
    	h1=figure;
        hold on
    
        % Plot group average signal
        Y=squeeze(DATA(:,:,i,:));
    
        if size(SID,1)>1
            M=mean(Y,2);
            E=std(Y,0,2)./sqrt(size(Y,2));
            N=size(Y,2);
        else
            M=Y; E=zeros(size(M)); 
            N=1; 
        end % 
    
        % Error bars
    	ciplot(M-E, M+E, T, 'k', 0.2);
        plot(T, M, 'k', 'linewidth', 2);
	
        clr={'k' ,'r', 'b', 'g'};
        
        figure(h);
        % Error bars
%     	ciplot(M-E, M+E, T, 'k', 0.2);
        plot(T, M, clr{i}, 'linewidth', 2);
        
        % Plot baseline
        Y=squeeze(NOIZE(:,:,i,:));
    
        if size(SID,1)>1
         	M=mean(Y,2);
            E=std(Y,0,2)./sqrt(size(Y,2));
        else
            M=Y; E=zeros(size(M)); 
        end % 
    
        figure(h1);
        ciplot(M-E, M+E, BLT, 'b', 0.2); 
        plot(BLT, M, 'b', 'linewidth', 2); 
        
        figure(h);
%         ciplot(M-E, M+E, BLT, , 0.2); 
%         plot(BLT, M, 'b', 'linewidth', 2); 
        
        figure(h1);
        % MARK UP
        %   Title changes slightly for single versus multiple subjects
        if size(SID,1)>1
            title([ERP.bindescr{BINS(i)} ' N=(' num2str(size(Y,2)) ')']);
        else
            title([SID ';' ERP.bindescr{BINS(i)}]);
        end % if size(SID,1)
        xlabel('Time (msec)')
    	ylabel('microVolt');   
        legend({['ABR' STR ' (SEM)'], ['ABR' STR], 'Baseline (SEM)', 'Baseline'}, 'location', 'best', 'interpreter', 'none');
    	set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', 'XGrid', 'on');
        xlim([BLT(1) T(end)])
        ylim([-1 1]); % hard code y lim to facilitate comparisons 

        %% INDIVIDUAL PLOTS
        %   Plot both the signal (solid lines) and the baseline (dashed lines)
        %   for each subject.
        figure, hold on
        plot(T, squeeze(DATA(:,:,i,:)), 'linewidth', 2); 
        plot(BLT, squeeze(NOIZE(:,:,i,:)), '--');
    
        % Mark up
        title([ERP.bindescr{BINS(i)}]);
        xlabel('Time (msec)')
    	ylabel('microVolt');
        xlim([BLT(1) T(end)])
        ylim([-1 1]); % hard code y lim to facilitate comparisons.
        legend(SID, 'location', 'best');
    	set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', 'XGrid', 'on');
    end %
    
    % Markup overlay
    figure(h);
    if size(SID,1)>1
        title(['Overlay' ' N=(' num2str(size(Y,2)) ')']);
    else
        title([SID ';' 'Overlay']);
    end % if size(SID,1)
    xlabel('Time (msec)')
	ylabel('microVolt');   
    legend({ERP.bindescr{BINS}}, 'location', 'best', 'interpreter', 'none');
	set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', 'XGrid', 'on');
    xlim([BLT(1) T(end)])
    ylim([-1 1]); % hard code y lim to facilitate comparisons 
end % if PFLAG