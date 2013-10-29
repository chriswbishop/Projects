function MSPE_spect_group(ApeSERSP, ApeSITC, ApeSPOWBASE, ApeNSERSP, ApeNSITC, ApeNSPOWBASE, ApeVSERSP, ApeVSITC, ApeVSPOWBASE, ApeVNSERSP, ApeVNSITC, ApeVNSPOWBASE, ApeSTRLS, ApeNSTRLS, ApeVSTRLS, ApeVNSTRLS, ApeSITCz, ApeNSITCz, ApeVSITCz, ApeVNSITCz, ApeSITCk, ApeNSITCk, ApeVSITCk, ApeVNSITCk, times, freqs, SID)
%% DESCRIPTION:
%
% INPUT:
%
%   A lot of shit
%
% OUTPUT:
%
%   More shit and Figures Galore.

close all;

%% MAKE SURE WE HAVE VECTOR LENGTHS (abs of complex numbers)
ApeSITC=abs(ApeSITC);
ApeNSITC=abs(ApeNSITC);
ApeVSITC=abs(ApeVSITC);
ApeVNSITC=abs(ApeVNSITC);

ApeSITCz=abs(ApeSITCz);
ApeNSITCz=abs(ApeNSITCz);
ApeVSITCz=abs(ApeVSITCz);
ApeVNSITCz=abs(ApeVNSITCz);

% %% SINGLE CONDITION PLF
% Ape(S)
X=abs(ApeSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: Ape(S) : (N=' num2str(size(X,4)) ')']);

% Ape(NS)
X=abs(ApeNSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: Ape(NS) : (N=' num2str(size(X,4)) ')']);

% ApeV(S)
X=abs(ApeVSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: ApeV(S) : (N=' num2str(size(X,4)) ')']);

% ApeV(NS)
X=abs(ApeVNSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: ApeV(NS) : (N=' num2str(size(X,4)) ')']);
% 
% %% SINGLE CONDITION KOLEV
% 
% % AVERAGE
% X=(abs(ApeVSITCk) + abs(ApeVNSITCk) + abs(ApeSITCk) + abs(ApeNSITCk))./4;
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev-PLF: ALL : (N=' num2str(size(X,4)) ')']);
% 
% % Ape(S)
% X=abs(ApeSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev-PLF: Ape(S) : (N=' num2str(size(X,4)) ')']);
% 
% % Ape(NS)
% X=abs(ApeNSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev-PLF: Ape(NS) : (N=' num2str(size(X,4)) ')']);
% 
% % ApeV(S)
% X=abs(ApeVSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev-PLF: ApeV(S) : (N=' num2str(size(X,4)) ')']);
% 
% % ApeV(NS)
% X=abs(ApeVNSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev-PLF: ApeV(NS) : (N=' num2str(size(X,4)) ')']);
% 
% % %% SINGLE CONDITION zPLF
% % % Ape(S)
% % X=ApeSITCz;
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: Ape(NS) : (N=' num2str(size(X,4)) ')']);
% % 
% % % Ape(NS)
% % X=ApeNSITCz;
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: Ape(NS) : (N=' num2str(size(X,4)) ')']);
% % 
% % % ApeV(S)
% % X=abs(ApeVSITCz);
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: ApeV(S) : (N=' num2str(size(X,4)) ')']);
% % 
% % % ApeV(NS)
% % X=abs(ApeVNSITCz);
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: ApeV(NS) : (N=' num2str(size(X,4)) ')']);
% % 
% %% PLF COMPARISONS
% Ape(S)-Ape(NS)
X=abs(ApeSITC)-abs(ApeNSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')']);

% ApeV(S-NS)
X=abs(ApeVSITC)-abs(ApeVNSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')']);

% Interaction
X=(ApeVSITC-ApeVNSITC)-(ApeSITC-ApeNSITC);
MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average PLF: Interaction : (N=' num2str(size(X,4)) ')']);
% % 
% % %% zPLF COMPARISONS
% % % Ape (S-NS)
% % X=ApeSITCz-ApeNSITCz;
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')']);
% % 
% % % ApeV(S-NS)
% % X=abs(ApeVSITCz)-abs(ApeVNSITCz);
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')']);
% % 
% % % Interaction
% % X=(ApeVSITCz-ApeVNSITCz)-(ApeSITCz-ApeNSITCz);
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average zPLF: Interaction : (N=' num2str(size(X,4)) ')']);
% 
% %% KOLEV COMPARISONS
% % S-NS
% X=(ApeSITCk+ApeVSITCk)-(ApeVNSITCk+ApeNSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev: S-NS : (N=' num2str(size(X,4)) ')']);
% 
% % Ape(S-NS)
% X=ApeSITCk-ApeNSITCk;
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev: Ape(S-NS) : (N=' num2str(size(X,4)) ')']);
% 
% % ApeV(S-NS)
% X=ApeVSITCk-ApeVNSITCk;
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev: ApeV(S-NS) : (N=' num2str(size(X,4)) ')']);
% 
% % Interaction
% X=(ApeVSITCk-ApeVNSITCk) - (ApeSITCk-ApeNSITCk);
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Frequency (Hz)', ['Average Kolev: Interaction : (N=' num2str(size(X,4)) ')']);
% 
% %% THETA-ROI zPLF COMPARISONS
% % Define frequency range and time window for permutation tests for Null
% % Distribution.
% FWIN=[4 12];
% TWIN=[times(1) 0]; 


% % 
% % % Ape(S-NS)
% % X=ApeSITCz-ApeNSITCz;
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% % 
% % % ApeV(S-NS)
% % X=ApeVSITCz-ApeVNSITCz;
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% % 
% % % ApeV(S-NS)
% % X=(ApeVSITCz-ApeVNSITCz) - (ApeSITCz-ApeNSITCz);
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 

%% SOME TIME-FREQUENCY PLOTS FOR DIFFERENCES

%% THETA-ROI PLF Comparisons
% Ape(S-NS)
%% ALPHA/BETA ROI (BASED ON BACKER (2010))
FWIN=[8 28];
TWIN=[50 212]; 
X=ApeSITC-ApeNSITC;
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);

% ApeV(S-NS)
X=ApeVSITC-ApeVNSITC;
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);

% Interaction
X=(ApeVSITC-ApeVNSITC) - (ApeSITC-ApeNSITC);
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);

%% Gamma ROI (BASED ON BACKER (2010))
FWIN=[30 60];
TWIN=[0 82]; 
X=ApeSITC-ApeNSITC;
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);

% ApeV(S-NS)
X=ApeVSITC-ApeVNSITC;
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);

% Interaction
X=(ApeVSITC-ApeVNSITC) - (ApeSITC-ApeNSITC);
MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'PLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' PLF: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% %% THETA-ROI KOLEV COMPARISONS
% % Ape(S-NS)
% X=ApeSITCk-ApeNSITCk;
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% % ApeV(S-NS)
% X=ApeVSITCk-ApeVNSITCk;
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% % Interaction
% X=(ApeVSITCk-ApeVNSITCk) - (ApeSITCk-ApeNSITCk);
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% %% GAMMA-ROI zPLF COMPARISONS
% % Define frequency range and time window for permutation tests for Null
% % Distribution.
% FWIN=[34 42];
% TWIN=[times(1) 0]; 
% 
% % % Ape(S-NS)
% % X=ApeSITCz-ApeNSITCz;
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% % 
% % % ApeV(S-NS)
% % X=ApeVSITCz-ApeVNSITCz;
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% % 
% % % ApeV(S-NS)
% % X=(ApeVSITCz-ApeVNSITCz) - (ApeSITCz-ApeNSITCz);
% % MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'zPLF', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' zPLF: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% %% GAMMA-ROI KOLEV COMPARISONS
% % Ape(S-NS)
% X=ApeSITCk-ApeNSITCk;
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: Ape(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% % ApeV(S-NS)
% X=ApeVSITCk-ApeVNSITCk;
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: ApeV(S-NS) : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);
% 
% % ApeV(S-NS)
% X=(ApeVSITCk-ApeVNSITCk) - (ApeSITCk-ApeNSITCk);
% MSPE_TF_ROI(X, times, freqs, 'Time (msec)', 'Kolev', [ '[' num2str(FWIN(1)) ' ' num2str(FWIN(2)) ']' ' Kolev: Interaction : (N=' num2str(size(X,4)) ')'], TWIN, FWIN, SID);



% %% ERSP ANALYSES
% 
% %% SINGLE CONDITION/PERCEPT PLOTS
% 
% % Ape(S)
% X=ApeSERSP; 
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Freqs (Hz)', ['Ape(S) ERSP (N=' num2str(size(X,4)) ')']);
% 
% % Ape(NS)
% X=ApeNSERSP; 
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Freqs (Hz)', ['Ape(NS) ERSP (N=' num2str(size(X,4)) ')']);
% 
% % ApeVLead(S)
% X=ApeVSERSP; 
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Freqs (Hz)', ['ApeV(S) ERSP (N=' num2str(size(X,4)) ')']);
% 
% % ApeVLead(NS)
% X=ApeVNSERSP; 
% MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Freqs (Hz)', ['ApeV(NS) ERSP (N=' num2str(size(X,4)) ')']);
% 
% %% ERSP COMPARISONS
% BL=[-800 0]; 
% T=[-800 800]; 
% N=1000; 
% P=0.05;
% 
% % Ape(S-NS)
% X=ApeSERSP-ApeNSERSP; 
% XLAB='Time (msec)'; 
% YLAB='Freqs (Hz)';
% TIT=['Ape(S-NS) ERSP (N=' num2str(size(X,4)) ')']; 
% 
% MSPE_TF_image(X, times, freqs, XLAB, YLAB, TIT);
% 
% X=squeeze(mean(X,3)); 
% MSPE_TF_PERMTEST(X, times, freqs, BL, T, N, P, XLAB, YLAB, TIT);
% 
% % ApeVlead(S-NS)
% X=ApeVSERSP-ApeVNSERSP; 
% XLAB='Time (msec)'; 
% YLAB='Freqs (Hz)';
% TIT=['ApeV(S-NS) ERSP (N=' num2str(size(X,4)) ')']; 
% 
% MSPE_TF_image(X, times, freqs, XLAB, YLAB, TIT);
% 
% X=squeeze(mean(X,3)); 
% MSPE_TF_PERMTEST(X, times, freqs, BL, T, N, P, XLAB, YLAB, TIT);
% 
% % MSPE_TF_image(X, times, freqs, 'Time (msec)', 'Freqs (Hz)', ['ApeV(S-NS) ERSP (N=' num2str(size(X,4)) ')']);
% 
% % Interaction
% X=(ApeVSERSP-ApeVNSERSP)-(ApeSERSP-ApeNSERSP); 
% XLAB='Time (msec)'; 
% YLAB='Freqs (Hz)';
% TIT=['Interaction ERSP (N=' num2str(size(X,4)) ')']; 
% 
% MSPE_TF_image(X, times, freqs, XLAB, YLAB, TIT);
% 
% X=squeeze(mean(X,3)); 
% MSPE_TF_PERMTEST(X, times, freqs, BL, T, N, P, XLAB, YLAB, TIT);

end % MSPE_spect_group

function MSPE_TF_image(X, times, freqs, XLAB, YLAB, TIT)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
%

figure
X=(mean(X,3)); % average over channels
imagesc(times, freqs, squeeze(mean(X,4))); % average over subjects
set(gca, 'ydir', 'normal');
set(gcf, 'Position', [107 677 631 420]);
colorbar;
xlabel(XLAB);
ylabel(YLAB); 
title(TIT); 

end % MSPE_TF_image

function X=MSPE_TF_ROI(X, times, freqs, XLAB, YLAB, TIT, TWIN, FWIN, SID)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%

%% DEFINE FREQUENCY ROI
FWIN(1)=find(freqs<=FWIN(1), 1, 'last'); 
FWIN(2)=find(freqs>=FWIN(2), 1, 'first'); 
X=X(FWIN(1):FWIN(2),:,:,:);

figure, hold on
X=mean(X,3); % average over channels
X=mean(X,1); % average over frequencies
X=squeeze(X); 

%% PLOT SUBJECT DATA
plot(times, X, 'linewidth', 2);

%% PLOT SEM
M=mean(X,2);
SX=std(X,0,2)./sqrt(size(X,2)); 
ciplot(M-SX, M+SX, times, 'k', 0.1);

%% PLOT MEAN
plot(times, M, 'k--', 'linewidth', 3);

%% MARKUP FIGURE
xlabel(XLAB);
ylabel(YLAB);
title(TIT);
legend(strvcat(SID, 'SEM', 'Mean'));
set(gcf, 'Position', [279 387, 855, 600]); % set figure size
H=get(gcf, 'Children');
set(H(1), 'Position', [0.1792 0.1975 0.1035 0.4479]); % move legend box

end % MSPE_TF_ROI

function MSPE_TF_PERMTEST(X, times, freqs, BL, T, N, P, XLAB, YLAB, TIT)
%% DESCRIPTION:
%
%   Perform a permutation test on a time frequency matrix.
%
% INPUT:
%
%   X:  data
%   
%
% OUTPUT:
%
%

%% DEFINE VARS

%% DEFINE BASELINE
BL=find(times>=BL(1),1,'first'):find(times<=BL(2),1,'last'); 
T=find(times>=T(1),1,'first'):find(times<=T(2),1,'last'); 

%% CONSTRUCT DATA FOR NULL
for s=1:size(X,3)
    NDIST(:,s)=reshape(squeeze(X(:,:,s)), prod(size(squeeze(X(:,:,s)))),1);
end % s

%% CONSTRUCT NULL DISTRIBUTION
[MAX_NULLDIST]=PermTest_maxnull(NDIST, N);
figure;
hist(MAX_NULLDIST); 
title([TIT '-MaxNull']); 
xlabel('Maximum Absolute Value'); 
ylabel('Frequency');

%% GET DATA FOR HYPOTHESIS TESTING
DATA=mean(X,3); 
DATA=reshape(DATA,prod(size(DATA)),1); 

% Recall that htest no longer automatically takes abs of data.  
[H CV NULLDIST mP mC pT]=PermTest_htest(abs(DATA), MAX_NULLDIST, P);
H=(reshape(H, size(X,1), size(X,2)));

MSPE_TF_image(H, times, freqs, XLAB, YLAB, [TIT '-HTest'])
end % MSPE_TF_PERMTEST