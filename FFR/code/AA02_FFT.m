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
EXPID='AA02'; 

%% LOAD THE ERPFILE
ERP=pop_loaderp('filename', FNAME, 'filepath', fullfile(STUDYDIR, EXPID, SID, 'analysis')); 

%% EXTRACT PARAMETERS
LABELS=ERP.bindescr; % bin description labels
TMASK=find(ERP.times>=0, 1, 'first'):length(ERP.times);
DATA=squeeze(ERP.bindata(:,TMASK,:)); 
FS=ERP.srate; 

%% COMPUTE FFT FOR EACH BIN

% FFT STUFF
Y=[]; % FFT DATA
A=[]; % Amplitude data
P=[]; % Phase data

L=size(DATA,1);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = FS/2*linspace(0,1,NFFT/2+1);

for i=1:size(DATA,2)
    y=DATA(:,i); 
    Y(:,i)=fft(y,NFFT)/L;
    A(:,i)=2*abs(Y(1:NFFT/2+1,i)); 
    P(:,i)=angle(Y(1:NFFT/2+1,i)); % Need to check this.    
end % for i=1:size(DATA,3)

%% PLOT DATA
figure, hold on
plot(f, A, 'o-', 'linewidth', 2);
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
legend(LABELS); 
