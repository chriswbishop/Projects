function [DATA ALPHAR ERPs GFP TRLS CUTOFF]=MSPE_AlphaReject(P, BINS, T, FINT, FLIMIT, REJ)
%% DESCRIPTION:
%
%   Function to create a power comparison between a frequency band of
%   interest v.s. a larger (or smaller, I guess) band.
%
% INPUT:
%
%   P:      string, path to EEG file (e.g. P='../Exp07/s2630/analysis/s2630-MSPE_ERP (CLEAN; REB).set';)
%           Alternatively, P can be an EEG structure.
%   BINS:   integer array, bins as specified in EEG.EVENTINFO (from ERPLAB)
%   T:      1x2 double array, specifies time range over which to perform
%           the operations in msec (e.g. T=[-800 0]; default
%           [T=[EEG.times(1) find(EEG.times<=0,1,'last')])
%   FINT:   1x2 integer array, frequency range of interest (e.g. FINT=[8 12])
%   FLIMIT: 1x2 integer array, frequency range to use for comparison (e.g.
%           FLIMIT=[0.5 40])
%   REJ:    integer, flag set to exclude trials flagged for rejection by
%           EEGLAB (default REJ=1, reject flagged trials). See
%           MSPE_ERPLAB_getbindata for more details.
%
% OUTPUT:
%
%   DATA:   CxTxN double matrix, where C is the number of channels and T is
%           the number of time points in the EEG.data field and N is the
%           number of trials belonging to BINS.
%   ALPHAR: Nx1 double array, power ratio.
%   ERPs:   CxTxB, where C/T are defined as above and B is the number of
%           CUTOFF points used in the analysis
%   GFP:    TxB double array, global field power at various cutoffs
%   TRLS:   Bx1 integer array, number of TRLS accepted for a given CUTOFF
%   CUTOFF: Bx1 double array, ALPHAR level cutoffs. Only trials below
%           CUTOFF are included in the average (e.g. ERPs/GFP).
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% LOAD EEG FILE
global EEG; 
if ischar(P)
    [pathstr, name, ext, versn] = fileparts(P);
    EEG=pop_loadset('filename', [name ext versn], 'filepath', pathstr, 'loadmode', 'all'); 
elseif isstruct(P)
    EEG=P; 
end % if ischar(P)

%% DEFAULTS
if ~exist('REJ', 'var') || isempty(REJ), REJ=1; end % reject flagged trials by default
if ~exist('T', 'var') || isempty(T), T=[EEG.times(1) EEG.times(find(EEG.times<=0,1,'last'))]; end % use baseline by default

%% GET EPOCHED DATA
[DATA]=MSPE_ERPLAB_getbindata(EEG, BINS, REJ);

%% CALCULATE ALPHA:TOTAL POWER RATIO
FS=EEG.srate; % sampling rate

ALPHAR=ALPHA_METRIC(DATA, FS, T, FINT, FLIMIT); 

%% CREATE ERPs WITH VARYING CUTOFFS
CUTOFF=min(ALPHAR):1:max(ALPHAR)+1;
ERPs=zeros(size(EEG.data,1),size(EEG.data,2), length(CUTOFF));
GFP=nan(size(EEG.data,2),length(CUTOFF));
TRLS=zeros(length(CUTOFF),1);
SNR=zeros(length(CUTOFF),1);

for i=1:length(CUTOFF)
    
    %% WHICH TRIALS ACCEPTED?
    %   MASK is a logical mask
    MASK=ALPHAR<=CUTOFF(i);
    
    %% HOW MANY TRIALS ACCEPTED?
    TRLS(i,1)=length(find(MASK~=0));
    
    %% CALCULATE ERP BASED ON ACCEPTED TRIALS
    ERPs(:,:,i)=mean(DATA(:,:,MASK),3);
    
    %% CALCULATE GLOBAL FIELD POWER
    GFP(:,i)=std(ERPs(:,:,i),0,1);    
    
    %% CALCULATE SNR BASED ON GFP
    SNR(i,1)=rms(GFP(find(EEG.times>0,1,'first'):end,i))./rms(GFP(1:find(EEG.times<=0,1,'last'),i));
end % i=1:length(CUTOFF)

%% PLOT PERCENTAGE OF TRIALS PER CUTOFF
figure, hold on
plot(CUTOFF, TRLS./size(DATA,3),'s-', 'linewidth', 2);
xlabel('CUTOFF (dB)'); 
ylabel(['% Epochs Accepted (Total=' num2str(size(DATA,3)) ')']);
title('% Accepted vs. CUTOFF (dB)');
set(gca, 'YGrid', 'on', 'XGrid', 'on', 'XMinorTick', 'on', 'YMinorTick', 'on');

%% GET ALPHA METRIC FOR EACH CUTOFF
ERPs_ALPHA=ALPHA_METRIC(ERPs, FS, T, FINT, FLIMIT);

% Plot Alpha metric vs. Cutoff
figure, hold on;
plot(CUTOFF, ERPs_ALPHA, 'ro--', 'linewidth', 2);  
xlabel('CUTOFF (dB)'); 
ylabel('dB');
title('dB vs. CUTOFF (dB)'); 
set(gca, 'YGrid', 'on', 'XGrid', 'on', 'XMinorTick', 'on', 'YMinorTick', 'on');

%% PLOT SNR vs. CUTOFF
plot(CUTOFF, SNR, 'kd-', 'linewidth', 2); 
legend('FINT:FLIMIT', 'GFP SNR (Post vs Pre)', 'location', 'best'); 

end % function MSPE_AlphaReject

function [ALPHAR]=ALPHA_METRIC(DATA, FS, T, FINT, FLIMIT)
%% DESCRIPTION:
%
%   Function to calculate relative alpha levels.
%
% INPUT:
%
%   see MSPE_AlphaReject.m
%
% OUTPUT:
%
%   see MSPE_AlphaReject
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

    % GET EEG STRUCTURE
    global EEG;
    
    for i=1:size(DATA,3)
        TIND=find(EEG.times>=T(1),1,'first'):find(EEG.times<=T(2),1,'last'); 
    
        N=length(TIND);
        NFFT = 2^nextpow2(N);

        F = FS/2*linspace(0,1,NFFT/2);

        % FFT over (channels)
        %   Output is normalized. Shouldn't matter either way since we are
        %   using the same FFT, but makes plotting a bit more intuitive for
        %   sanity checking.
        [Y]=fft(DATA(:,TIND,i)', NFFT)/N;
                                    
        % Amplitude 
        Y=2*abs(Y(1:NFFT/2,:)); % convert to amplitude, multiplied by 2 because this is a single-sided spectrum.    
    
        % Convert to power (dB)
        Y=db(Y.^2,'power');
    
        % Average Power Over Channels
        Y=mean(Y,2);
    
        % AVERAGE OVER FREQUENCY RANGE OF INTEREST
        %   Clumsy way to handle looping. 
        if length(FINT)==2
            FINT=find(F>=FINT(1),1,'first'):find(F<=FINT(2),1,'last'); 
            FLIMIT=find(F>=FLIMIT(1),1,'first'):find(F<=FLIMIT(2),1,'last');   
        end % if 
    
        %  RATIO (dB)
        %   Should be mean and not sum because the number of frequencies in the
        %   numerator and denominator might not be the same.
        ALPHAR(i,1)=mean(Y(FINT))-mean(Y(FLIMIT));
        
    end % i=1:size(DATA,3)
end % ALPHA_METRIC