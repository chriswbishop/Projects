function [LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP pRESP_NSTIM LEADONLY LAGONLY P LL]=PEABR_exp03_analysis(P)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

figure, hold on;
N=unique(NSTIM);

%% ONLY PLOT NON_CONTROL DATA
IND=find(COND~=201 & COND~=202);
nstim=NSTIM(IND); resp_nstim=RESP_NSTIM(IND); 

% plot raw data
plot(NSTIM(IND), RESP_NSTIM(IND), '+');

N=unique(nstim); 

% plot unity line
plot(20, N, 'ro-', 'linewidth', 3); 

% plot mean
data=[];
for n=1:length(N)
    data(n)=nanmean(resp_nstim(find(nstim==N(n))));
    datae(n)=nanstd(resp_nstim(find(nstim==N(n))),0,2);
end % n=1:length(N)
pRESP_NSTIM=data; 

errorbar(N, data, datae, 'kd', 'linewidth', 2); 

%% PLOT OBVIOUS LEAD/LAG

% obvious lead
N=NSTIM(find(COND==201, 1, 'first')); 
data=[];
for n=1:length(N)
    data(n)=nanmean(RESP_NSTIM(find(COND==201 & NSTIM==N(n))));
%     (length(find(COND==201 & NSTIM==N(n) & (RESP_NSTIM==N(n))))./length(find(COND==201 & NSTIM==N(n))));
end % for n=1: ... 
LEADONLY=data; 
plot(20, data, 'sm', 'MarkerSize', 12, 'linewidth', 3); 

% obvious lag 
N=NSTIM(find(COND==202, 1, 'first')); 
data=[];
for n=1:length(N)
    data(n)=nanmean(RESP_NSTIM(find(COND==202 & NSTIM==N(n))));
%     data(n)=(length(find(COND==202 & NSTIM==N(n) &
%     (RESP_NSTIM==N(n))))./length(find(COND==202 & NSTIM==N(n))));
end % for n=1: ... 
LAGONLY=data; 
plot(20, data, 'sb', 'MarkerSize', 12, 'linewidth', 3);
% plot(N, data, 'kd', 'linewidth', 2); 
legend('NSTIM Resp', 'Perfect Performance', 'Mean NSTIM Resp (+/- STD)','Lead-Only', 'Lag-Only', 'location','Best');
xlabel('Lagging Clicks Presented'); 
ylabel('Lagging Clicks Reported');
axis([18 22 0 20]);

%% GROUPING HISTOGRAM
figure, hold on
hist(RESP_NGROUP(IND), 0:1:10); 
xlabel('Groups Reported'); 
ylabel('Frequency'); 

%% CONTEXT EFFECT (preceded by Lag- or Lead-Only.
IND=COND~=201 & COND~=202; 
T=unique(ALAG(IND)); 

for t=1:length(T)
    LL(t,1)=nanmean(RESP_NSTIM((find(ALAG==T(t) & [0 COND(1:end-1)]==201))));
    LL(t,2)=nanmean(RESP_NSTIM((find(ALAG==T(t) & [0 COND(1:end-1)]==202))));
end % t


