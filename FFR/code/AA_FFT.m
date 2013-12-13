function [FOUT, AOUT, POUT, LABELS]=AA_FFT(ERPF, FRANGE, NSEM, BINS, PLEV, TFREQS, PLOTPHASE)
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
%   NSEM:   integer, number of SEMs to include in error bars (default=0)
%   BINS:   integer index, BINS to include in the analysis
%   TFREQS: double array, test frequencies to return amplitude values at.
%   PLOTPHASE:  bool, flag to generate phase plots at TFREQS
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
%
% Christopher W. Bishop
%   University of Washington
%   12/13

%% PARAMETERS
if ~exist('PLEV', 'var') || isempty(PLEV), PLEV=1; end
if ~exist('NSEM', 'var') || isempty(NSEM), NSEM=0; end % 0 by default
if ~exist('TFREQS', 'var'), TFREQS=[]; end % empty by default

%% OUTPUTS
FOUT=[];
AOUT=[]; 
POUT=[];

% PRE-STIM FFT STUFF
pY=[];
pA=[]; % One sided amplitude data
pP=[]; % Phase data
    
% POST-STIM FFT STUFF
Y=[]; % Complex FFT 
A=[]; % One sided amplitude data
P=[]; % Phase data

%% REPEAT FOR ALL SUBJECTS
for s=1:length(ERPF)
    
    %% FILE PARTS OF INPUT FILE
    [pathstr,name,ext]= fileparts(deblank(ERPF{s}));

    %% LOAD THE ERPFILE
    ERP=pop_loaderp('filename', [name ext], 'filepath', pathstr); 

    %% WHICH BINS TO ANALYZE?
    %   Analyze all bins by default
    if ~exist('BINS', 'var') || isempty(BINS)
        BINS=1:size(ERP.bindata,3); 
    end % if ~exist('BINS ...
    
    %% GET LINE SPECS
    [colorDef, styleDef]=erplab_linespec(max(BINS));
    
    %% EXTRACT PARAMETERS
    LABELS={ERP.bindescr{BINS}}; % bin description labels
    BLMASK=1:find(ERP.times<0,1,'last'); % base line time mask
    TMASK=find(ERP.times>=0, 1, 'first'):length(ERP.times); % post-stim mask.
        
    DATA=squeeze(ERP.bindata(:,:,:)); 
    FS=ERP.srate; 

    %% COMPUTE FFT FOR EACH DATA BIN    
    for i=1:length(BINS)
    
%         % Compute pre-stim data (useful for noise sanity check...I think)
%         L=length(BLMASK);
%         NFFT = L; % Not doing next power of 2 in an attempt to get coherent sampling
%         pf = FS/2*linspace(0,1,NFFT/2+1);
%         
%         y=DATA(BLMASK,BINS(i)); 
%         
%         pY(:,i,s)=fft(y,NFFT)/NFFT; % Normalize FFT output
%         pA(:,i,s)=2*abs(pY(1:NFFT/2+1,i,s)); 
%         pP(:,i,s)=angle(pY(1:NFFT/2+1,i,s)); % Need to check this.    
%         
        % Compute post-stim data
        L=length(TMASK);
        NFFT=L;
%         NFFT = 2^nextpow2(L); % Next power of 2 from length of y
        f = FS/2*linspace(0,1,NFFT/2+1);
        
        y=DATA(TMASK,i); 
        
        Y(:,i,s)=fft(y,NFFT)/NFFT;
        A(:,i,s)=2*abs(Y(1:NFFT/2+1,i,s)); 
        P(:,i,s)=angle(Y(1:NFFT/2+1,i,s)); % Need to check this.  
        
        %% GET TFREQS INFORMATION
        for z=1:length(TFREQS)
            
            % Find index of target frequency
            ind=find(f==TFREQS(z));
            
            % Error checking - make sure we find the precise frequency. If
            % not, throw an error.
            if isempty(TFREQS)
                error([num2str(TFREQS(z)) ' not found!']); 
            else
                % Grab amplitude value
                FOUT(z)=f(ind); 
                AOUT(z,i,s)=A(ind,i,s);
                POUT(z,i,s)=P(ind,i,s); % return phase information
            end % if isempty(TFREQS)
            
        end % for z=1 ...
    end % for i=1:size(DATA,3)
    
    %% PLOT SUBJECT DATA
    %   Only plot if user specifies this level of detail
    %   If you'd like to plot individual subject data, call this function
    %   with a single ERPF field populated. That way all the plotting ends
    %   up being the same no matter how many subjects are used. 
%     if PLEV==2
%         figure, hold on
%         % plot pre-stim data
%     %     plot(pf, squeeze(pA(:,:,s)), '--', 'linewidth', 1);
%     
%         % plot post-stim data
%         plot(f, squeeze(A(:,:,s)), '-', 'linewidth', 2);
%         title('Single-Sided Amplitude Spectrum of y(t)')
%         xlabel('Frequency (Hz)')
%         ylabel('|Y(f)| (uV)')    
%         legend(LABELS, 'Location', 'Best'); 
%         title([ERP.erpname ' | Bins: [' num2str(BINS) ']']); % set ERPNAME as title
%     
%         % Set domain if user specifies it
%         if exist('FRANGE', 'var')
%             xlim(FRANGE);
%         end %
%     end % if PLEV==2
    
    
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
    
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)| (uV)')
    legend(LABELS, 'Location', 'Best'); 
    title(['N=' num2str(length(ERPF)) ' | Bins: [' num2str(BINS) ']']); 

    % Set domain if user specifies it
    if exist('FRANGE', 'var')
        xlim(FRANGE);
    end %
    
end % if PLEV>0

%% PLOT PHASE INFORMATION
%   Generate polar plots to look at phase information across subjects
%   within specified frequencies.
if ~isempty(TFREQS) && PLOTPHASE && PLEV>0
    
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
        title([num2str(TFREQS(z)) ' Hz | Bins: [' num2str(BINS) ']']);
        legend(LABELS, 'Location', 'northeastoutside'); 
        
    end % i=1:length(TFREQS)
    
end % ~isempty(TFREQS) && PLOTPHASE