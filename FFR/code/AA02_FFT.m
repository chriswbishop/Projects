function AA02_FFT(SID, FNAME)
%% DESCRIPTION:
%
%   Basic function to compute an FFT based on ERP data structure for AA02
%   (and others).
%
% INPUT:
%
%   SID:    string, subject ID
%   FNAME:  ERP filename 
%
% OUTPUT:
%
%   
%
% Christopher W. Bishop
%   University of Washington
%   12/13
STUDYDIR='C:\Users\cwbishop\Documents\GitHub\Projects\FFR';
F=[900 1100]; % Frequency range to plot

% PRE-STIM FFT STUFF
pY=[];
pA=[]; % One sided amplitude data
pP=[]; % Phase data
    
% POST-STIM FFT STUFF
Y=[]; % 
A=[]; % One sided amplitude data
P=[]; % Phase data

%% REPEAT FOR ALL SUBJECTS
for s=1:size(SID,1)
    
    sid=deblank(SID(s,:));
    
    %% EXPID CHECK
    %   A quick fix to wrap in data from two separate experiments and 4
    %   listeners. Not clean, will need to improve, but on a roll. 
    switch sid
        case{'CM' 'EE'}
            EXPID='AA02'; 
        case{'CB' 'KM'}
            EXPID='Exp01';
    end % switch

    %% LOAD THE ERPFILE
    ERP=pop_loaderp('filename', [sid '-' FNAME], 'filepath', fullfile(STUDYDIR, EXPID, sid, 'analysis')); 

    %% EXTRACT PARAMETERS
    LABELS=ERP.bindescr; % bin description labels
    BLMASK=1:find(ERP.times<0,1,'last'); % base line time mask
    
    TMASK=find(ERP.times>=0, 1, 'first'):length(ERP.times); % post-stim mask.
    
    %% COHERENT SAMPLING
    %
    DATA=squeeze(ERP.bindata(:,:,:)); 
    FS=ERP.srate; 

    %% COMPUTE FFT FOR EACH BIN

    
    
    for i=1:size(DATA,2)
    
        % Compute pre-stim data (useful for noise comparisons...I think)
        L=length(BLMASK);
        NFFT = 2^nextpow2(L); % Next power of 2 from length of y
        pf = FS/2*linspace(0,1,NFFT/2+1);
        
        y=DATA(BLMASK,i); 
        
        pY(:,i,s)=fft(y,NFFT)/L;
        pA(:,i,s)=2*abs(pY(1:NFFT/2+1,i,s)); 
        pP(:,i,s)=angle(pY(1:NFFT/2+1,i,s)); % Need to check this.    
        
        % Compute post-stim data
        L=length(TMASK);
        NFFT = 2^nextpow2(L); % Next power of 2 from length of y
        f = FS/2*linspace(0,1,NFFT/2+1);
        
        y=DATA(TMASK,i); 
        
        Y(:,i,s)=fft(y,NFFT)/L;
        A(:,i,s)=2*abs(Y(1:NFFT/2+1,i,s)); 
        P(:,i,s)=angle(Y(1:NFFT/2+1,i,s)); % Need to check this.  
        [S, sF, sT]=spectrogram(y); 
    end % for i=1:size(DATA,3)
    
    %% PLOT SUBJECT DATA
    figure, hold on
    % plot pre-stim data
    plot(pf, squeeze(pA(:,:,s)), '--', 'linewidth', 1);
    
    % plot post-stim data
    plot(f, squeeze(A(:,:,s)), '-', 'linewidth', 2);
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')    
    legend(LABELS); 
    title(sid); % set subject title
    xlim(F);
end % for s=1:size(SID,1)

%% PLOT SUBJECT MEAN
figure, hold on
plot(f, squeeze(mean(A,3)), '-', 'linewidth', 2);
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
legend(LABELS); 
title(['N=' num2str(size(SID,1))]); 
xlim(F);
