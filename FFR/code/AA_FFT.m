function [FOUT, AOUT, POUT, LABELS, NOUT, SNR]=AA_FFT(ERPF, FRANGE, NSEM, BINS, PLEV, TFREQS, PLOTPHASE, NOISE)
%% DESCRIPTION:
%
%   Basic function to compute an FFT based on ERP data structure for AA02
%   (and others).
%
% INPUT:
%
%   ERPF:   cell, each element is the full path to an ERP file
%   PLEV:   plot level setting (1=just group, 2=group and subject data;
%           default=1)
%   FRANGE: 2x1 or 1x2 double array, frequency range to zoom in on in
%           plots. (e.g., FRANGE=[10 80];)
%   NSEM:   integer, number of SEMs to include in error bars (default=0)
%   BINS:   integer index, BINS to include in the analysis
%   TFREQS: double array, test frequencies to return amplitude values at.
%   PLOTPHASE:  bool, flag to generate phase plots at TFREQS
%   NOISE:  1x1, 2x1, or 1x2 double array defining the noise estimation 
%           window relative to each TFREQ. the noise estiamtion is used to
%           compute the signal to noise ratio (SNR) for each TFREQ. 
%
%           If NOISE is a single number
%           (e.g., NOISE=5), then the sampling window will be symmetric
%           about the each TFREQ. Use a 1x2 or 2x1 array (e.g., NOISE = [5
%           1] to create asymmetric noise sample. If left empty, then SNR
%           will not be computed.
%
% OUTPUT:
%
%   FOUT:   double array, frequencies corresponding to AOUT
%   AOUT:   FxBxS double array of amplitude values, where F is the number
%           of frequencies specified in TFREQS (and FOUT), B is the number
%           of BINS specified in the BINS array, and S is the number of
%           subjects.
%   LABELS: cell array, bin labels from ERP.bindescr field.
%   POUT:   phase angles for target frequencies (TFREQS). Angles are in
%           radians. Use 'polar.m' to visualize.
%   NOUT:   FxN double array, frequencies used in noise estimation. 
%   SNR:    FxBxS matrix, where Z is the number of target frequencies, B is 
%           the number of BINS, and S is the number of subjects.
%
% Christopher W. Bishop
%   University of Washington
%   12/13

%% PARAMETERS
if ~exist('PLEV', 'var') || isempty(PLEV), PLEV=1; end
if ~exist('NSEM', 'var') || isempty(NSEM), NSEM=0; end % 0 by default
if ~exist('TFREQS', 'var'), TFREQS=[]; end % empty by default
if ~exist('NOISE', 'var'), NOISE=[]; end % empty by default
if length(NOISE)==1, NOISE=[NOISE NOISE]; end % create symmetric noise sample

%% OUTPUTS
FOUT=[];
AOUT=[]; 
POUT=[]; 
NOUT=[];    % Noise frequency bins used in noise estimation.
SNR=[];     % signal to noise ratio

% POST-STIM FFT STUFF
Y=[]; % Complex FFT 
A=[]; % One sided amplitude data
P=[]; % Phase data

% Use centralized loading function, AA_loaddata, to get data into proper
% format.
[~,~,LABELS,ALLERP]=AA_loaddata(ERPF); 

%% REPEAT FOR ALL SUBJECTS
for s=1:length(ALLERP)
    
    %% FILE PARTS OF INPUT FILE
%     [pathstr,name,ext]= fileparts(deblank(ERPF{s}));

    %% LOAD THE ERPFILE
%     ERP=pop_loaderp('filename', [name ext], 'filepath', pathstr); 

    ERP=ALLERP(s); 
    
    %% WHICH BINS TO ANALYZE?
    %   Analyze all bins by default
    if ~exist('BINS', 'var') || isempty(BINS)
        BINS=1:size(ERP.bindata,3); 
    end % if ~exist('BINS ...
    
    %% GET LINE SPECS
    [colorDef, styleDef]=erplab_linespec(max(BINS));
    
    %% EXTRACT PARAMETERS
%     LABELS={ERP.bindescr{BINS}}; % bin description labels
%     BLMASK=1:find(ERP.times<0,1,'last'); % base line time mask
    TMASK=find(ERP.times>=0, 1, 'first'):length(ERP.times); % post-stim mask.
        
    DATA=squeeze(ERP.bindata(:,:,:)); 
    FS=ERP.srate; 

    %% COMPUTE FFT FOR EACH DATA BIN    
    for i=1:length(BINS)
    
        % Compute post-stim data
        L=length(TMASK);
        NFFT=L;
        f = FS/2*linspace(0,1,NFFT/2+1);
        
        y=DATA(TMASK,i); 
        
        Y(:,i,s)=fft(y,NFFT)/NFFT;
        
        % Convert to one-sided amplitude spectrum and calculate phase.
        %   See doc fft for more information
        %   Also, the following PDF was helpful, especially in
        %   understanding phase of positive and negative frequencies.
        %       http://www.staff.vu.edu.au/msek/frequency%20analysis%20-%20fft.pdf        
        A(:,i,s)=2*abs(Y(1:NFFT/2+1,i,s)); % single sided amplitude spectrum (see doc fft)
        P(:,i,s)=angle(Y(1:NFFT/2+1,i,s)); % According to PDF listed above and previous knowledge, I think this is fine.
        
        %% GET TFREQS INFORMATION
        for z=1:length(TFREQS)
            
            % Find index of target frequency
            %   Look for an exact match first
            ind=find(f==TFREQS(z));
            
            % Error checking - make sure we find the precise frequency. If
            % not, throw an error.
            %
            % Changed to warning because there seems to be some rounding
            % error or something (on the order of 10^-13) at some
            % frequencies that is preventing a perfect match. So, we'll go
            % with the 
            if isempty(ind)
                tmp=abs(f-TFREQS(z));
                ind= (tmp==min(tmp));
                warning('AA02_FFT:NoMatch', [num2str(TFREQS(z)) ' not found! Closest frequency is ' num2str(f(ind)) ' Hz. \n\nProceeding with closest frequency. \n\nSee FOUT for exact frequencies.']);                 
            end % if isempty(ind)
            
            % Grab frequency, amplitude, and phase values
            FOUT(z)=f(ind); 
            AOUT(z,i,s)=A(ind,i,s);
            POUT(z,i,s)=P(ind,i,s); % return phase information
            
            % Find noise bins
            %   Only loop through this if we have a noise window
            if ~isempty(NOISE)
                nout=[find(f<=(TFREQS(z)-NOISE(1)),1,'last'):ind-1 ind+1:find(f>=(TFREQS(z)+NOISE(2)),1,'first')];
            
            
                % Compute SNR
                SNR(z,i,s)=db((AOUT(z,i,s))./mean(A(nout,i,s),1));
            
                % Store frequency bins used to estimate noise for each TFREQ
                NOUT(z,:)=f(nout); 
            
            end % if ~isempty(NOISE)
        end % for z=1 ...
    end % for i=1:size(DATA,3)
    
end % for s=1:size(SID,1)

%% PLOT ACROSS SUBJECT MEAN (Amplitude)
%   Plot as long as Plot LEVel is >0. 
if PLEV>0
    % Figure
    figure, hold on
    
    %% PLOT SEM
    %   Plotted first for ease of legend labeling. Yes, I know I'm looping
    %   through the data twice. Yes, it is inefficient. No, I don't care. 
    for i=1:length(BINS) % for each bin we are plotting
        
        tdata=squeeze(A(:,i,:)); 
        
        % Plotting SEM when NSEM=0 causes some graphical issues and very
        % slow performance. 
        if NSEM~=0
            
            % Compute +/-NSEM SEM
            U=mean(tdata,2) + std(tdata,0,2)./sqrt(size(tdata,2)).*NSEM; 
            L=mean(tdata,2) - std(tdata,0,2)./sqrt(size(tdata,2)).*NSEM; 
            ciplot(L, U, f, colorDef{BINS(i)}, 0.15); 
            
        end % if ~NSEM~=0
        
    end % for i=1:size(A,2)    
        
    for i=1:length(BINS) % for each bin we are plotting        
        tdata=mean(squeeze(A(:,i,:)),2); 
        plot(f, tdata, 'Color', colorDef{BINS(i)}, 'LineStyle', styleDef{BINS(i)}, 'linewidth', 1.5);
    end % for i=1:size(A,2)
    
    % Turn on grids
    set(gca, 'XGrid', 'on', 'YGrid', 'on');
    
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)| (uV)')
    legend(LABELS, 'Location', 'Best'); 
    title(['N=' num2str(length(ERPF)) ' | Bins: [' num2str(BINS) ']']); 

    % Set domain if user specifies it
    if exist('FRANGE', 'var') && ~isempty(FRANGE)
        xlim(FRANGE);
    end %
    
end % if PLEV>0

%% PLOT PHASE INFORMATION
%   Generate polar plots to look at phase information across subjects
%   within specified frequencies.
if ~isempty(FOUT) && PLOTPHASE && PLEV>0
    
    %% GENERATE FIGURE WITH SUBPLOTS, ONE FOR EACH SPECIFIED FREQUENCY
    %
    %   Subplots ended up being too crowded and complex, so went with
    %   something simpler for now. Maybe return to this later.   
       
    % Loop through all specified frequencies        
    for z=1:size(POUT,1)
        
        % Open a new figure
        figure
                
        for b=1:length(BINS)
            
            % Get data
            t=squeeze(POUT(z,b,:));
            
            % Make polar plot with unit radius
            %   Gives an intuitive feel for the phase variance across
            %   listeners            
            polar(t, ones(size(t)), 'o');
            hold on;
            % Get children (data points)
            h=get(gca, 'Children'); 
            set(h(1), 'MarkerEdgeColor', colorDef{BINS(b)}, 'MarkerFaceColor', colorDef{BINS(b)}, 'MarkerSize', 10);                        
                        
        end % b
        
        % Markup Figure
        %   Use FOUT instead of TFREQS because FOUT reflects the actual
        %   frequencies used. 
        title([num2str(FOUT(z)) ' Hz | Bins: [' num2str(BINS) ']']);
        legend(LABELS, 'Location', 'northeastoutside'); 
        
    end % i=1:length(TFREQS)
    
end % ~isempty(TFREQS) && PLOTPHASE

%% PLOT MEAN SNR AS A FUNCTION OF TARGET FREQUENCY
%   Plot mean SNR and standard error of the mean (SEM) for each target
%   frequency. Include SNRs for all target frequencies in a single plot.
%   Different trace for each BIN.
%
%   Recall that SNR is a ZxBxS matrix, where Z is the number of target
%   frequencies, B is the number of BINS, and S is the number of subjects
if ~isempty(FOUT) && PLEV>0 && ~isempty(SNR)
    
    % Open figure
    figure, hold on
    
    %% CALCULATE SEM
    %   Plotted first for ease of legend labeling. Yes, I know I'm looping
    %   through the data twice. Yes, it is inefficient. No, I don't care. 
    U=std(SNR,0,3)./sqrt(size(SNR,3)).*NSEM;
    
    %% CALCULATE MEAN
    %barweb(barvalues, errors, width, groupnames, bw_title, bw_xlabel, bw_ylabel, bw_colormap, gridstatus, bw_legend, error_sides, legend_type)
    tdata=mean(SNR,3); 
    barweb(tdata, U, [], TFREQS, [], [], [], color2colormap({colorDef{BINS}}), 'xy');  
    
    xlabel('Frequency (Hz)')
    ylabel('SNR (dB)')
    legend(LABELS, 'Location', 'northeast'); 
    title(['N=' num2str(length(ERPF)) ' | Bins: [' num2str(BINS) ']']);     
    
end % ~isempty(FOUT) & PLEV>0