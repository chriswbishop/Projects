function [OUT FITOBJ T TDATA]=PEABR_ABR_SNRanalysis(EEG, CHANNELS, BINS, NTRLS, N, TSNR, BL, PT, REJ, DATA)
%% DESCRIPTION:
%
%   Snippet to track SNR vs. trial number randomly sampled from an EEG
%   structure.  
%   
% INPUT:
%
%   EEG:
%   CHANNELS:
%   BINS:   
%   NTRLS:
%   N:
%   TSNR:
%   BL:
%   PT:
%   REJ:
%
% OUTPUT:
%
%   OUT:
%   FITOBJ:
%   T:
%   

%% DEFAULTS
if ~exist('REJ', 'var') || isempty(REJ), REJ=1; end % reject flagged files by default
if ischar(EEG), load(EEG, 'EEG'); end % load a file if necessary

%% DECLARE OUTPUT VARIABLES
OUT=[]; T=[];

%% GRAB EPOCHED DATA
%   Overridden if DATA included as input parameter.
if ~exist('DATA', 'var') || isempty(DATA)
    [DATA]=MSPE_ERPLAB_getbindata(EEG, BINS, REJ);
end % 

%% AVERAGE CHANNELS
DATA=mean(DATA(CHANNELS,:,:),1); 

%% FIND BL
BL=[find(EEG.times>=BL(1),1,'first'):find(EEG.times<=BL(2),1,'last')];
PT=[find(EEG.times>=PT(1),1,'first'):find(EEG.times<=PT(2),1,'last')];

%% LOOP THROUGH TRIALS
for t=1:length(NTRLS)
    out=[];
    tdata=[]; %zeros(size(DATA,1), size(DATA,2)); 
    for n=1:N
        IND=randperm(size(DATA,3));
        IND=IND(1:NTRLS(t)); 
        data=mean(DATA(:,:,IND),3); 
        out(n)=rms(data(PT))./rms(data(BL));
%         tdata=tdata+data; 
        tdata(n,:)=data;
    end % n
    OUT(t,1)=mean(out); 
    out=abs(out-mean(out));
    %     tdata=tdata./N; % average
    % Find tdata with SNR closest to the average, return that.    
    TDATA(t,:)=tdata(find(out==min(out),1,'first'),:); % just save the last sampling as a representative sample.
end % t

%% FIT DATA WITH POWER FUNCTION
FITOBJ=fit(NTRLS', OUT, 'a*x^b+c', 'start', [0 0.5 1]); % initialize as a sqrt with intercept of 1.
X=min(NTRLS):1:max(NTRLS);
Y=FITOBJ(X);
T=X(find(Y>=TSNR,1,'first'));