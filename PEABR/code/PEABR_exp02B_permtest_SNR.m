function [NULLDIST dNULLDIST DATA dSNR GROUP H T mP mC pT CLUST_MAP CLUST_VAL CLUST_H]=PEABR_exp02B_permtest_SNR(EEG, BINS, CHANNELS, BL, PT, REJ, N, A)
%% DESCRIPTION:
%
%   Permutation test for SNR.
%
% INPUT:
%
% OUTPUT:
%
% XXX

%% DEFAULTS
if ~exist('N', 'var') || isempty(N), N=100; end
if ~exist('A', 'var') || isempty(A), A=0.05; end %

%% LOAD EEG?
if ~isstruct(EEG), load(EEG, 'EEG'); end

%% FIND BL
BL=[find(EEG.times>=BL(1),1,'first'):find(EEG.times<=BL(2),1,'last')];
PT=[find(EEG.times>=PT(1),1,'first'):find(EEG.times<=PT(2),1,'last')];

%% GRAB DATA FOR EACH CONDITION
DATA=[];
GROUP=[];
for i=1:length(BINS) % only designed to work with two conditions
    
    [data]=MSPE_ERPLAB_getbindata(EEG, BINS{i}, REJ);
    data=squeeze(mean(data(CHANNELS,:,:),1))';
    DATA=[DATA; data];
    GROUP=[GROUP; i.*ones(size(data,1),1)]; % assign group labels

end % i

%% NULL DISTRIBUTION
NULLDIST=[];
dNULLDIST=[];
for n=1:N
    group=GROUP(randperm(length(GROUP))); 
    
    tdata=mean(DATA(group==1,:));     
    snr(1,1)=db(rms(tdata(PT))./rms(tdata(BL)));
    
    tdata=mean(DATA(group==2,:));     
    snr(1,2)=db(rms(tdata(PT))./rms(tdata(BL)));
    
    NULLDIST(n,:)=snr;
    dNULLDIST(n,:)=diff(snr);
end % n

%% TEST HYPOTHESIS
tdata=mean(DATA(GROUP==1,:));     
snr(1,1)=db(rms(tdata(PT))./rms(tdata(BL)));

tdata=mean(DATA(GROUP==2,:));     
snr(1,2)=db(rms(tdata(PT))./rms(tdata(BL)));

data=diff(snr); 
dSNR=data; 
%% TEST HYPOTHESIS
[H T NULLDIST mP mC pT CLUST_MAP CLUST_VAL CLUST_H]=PermTest_htest(data, dNULLDIST, A, [], []);