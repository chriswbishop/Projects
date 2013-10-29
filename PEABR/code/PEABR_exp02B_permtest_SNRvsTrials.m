function [SNRvsTRIALS PERM iSNR NULLDIST]=PEABR_exp02B_permtest_SNRvsTrials(EEG, CHANNELS, BINS, NTRLS, N4NULL, N4CURVE, TSNR, BL, PT, REJ)
%% DESCRIPTION:
%
%   Create an SNR vs. Trial Number curve for a two sets of data and
%   compare SNR over curve. 
%
% INPUT:
%
% OUTPUT:
%
% XXX

%% EEG
if ~isstruct(EEG), load(EEG, 'EEG'); end 

%% GRAB DATA FOR EACH CONDITION
DATA=[];
GROUP=[];
for i=1:length(BINS) % only designed to work with two conditions
    
    [data]=MSPE_ERPLAB_getbindata(EEG, BINS{i}, REJ);
    data=squeeze(mean(data(CHANNELS{i},:,:),1));
    DATA=[DATA data];
    GROUP=[GROUP; i.*ones(size(data,2),1)]; % assign group labels
    tdata(1,:,:)=DATA(:,GROUP==i); 
    [OUT]=PEABR_ABR_SNRanalysis(EEG, 1, BINS, NTRLS, N4CURVE, TSNR, BL, PT, REJ, tdata);
    SNRvsTRIALS{i,1}=db(OUT); 
    clear tdata; 
end % i

iSNR=mean(SNRvsTRIALS{2,1}-SNRvsTRIALS{1,1}); 

%% RANDOMIZE AND GET SNRvsTRIALS CURVES
PERM={};
NULLDIST=[];
for n=1:N4NULL
    display(num2str(n));
    group=GROUP(randperm(length(GROUP))); 
    
    tdata(1,:,:)=DATA(:, group==1); 
    [OUT]=PEABR_ABR_SNRanalysis(EEG, 1, BINS, NTRLS, N4CURVE, TSNR, BL, PT, REJ, tdata);
    PERM{n,1}=db(OUT);
    clear tdata; 
    tdata(1,:,:)=DATA(:, group==2); 
    [OUT]=PEABR_ABR_SNRanalysis(EEG, 1, BINS, NTRLS, N4CURVE, TSNR, BL, PT, REJ, tdata);
    PERM{n,2}=db(OUT); 
    clear tdata;
    
    NULLDIST(n,1)=mean(PERM{n,2}-PERM{n,1}); 
end % n