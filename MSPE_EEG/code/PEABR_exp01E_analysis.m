function [NRESP D]=PEABR_exp01E_analysis(P)
%% DESCRIPTION:
%
%   Plot data for Exp01E.
%
% INPUT:
%
%   P:  each row is a path to a log file (e.g. P=strvcat('XXX.log',
%   'YYY.log').
%
% OUTPUT:
%
%   a figure.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% RETURN VARS
DAPE=[];
GAPE=[];
SAPE=[]; 

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

figure, hold on;

%% EXTRACT RIGHT-ONLY/TEST STIMULI
DAPEind=find(COND<-100 & COND>-200); 
CI=rem(COND,100); 
D=sort(unique(CI(DAPEind)));

for d=1:length(D)
    ind=find(COND<-100 & COND>-200 & CI==D(d));
    DAPE(d,1)=nanmean(RESP_NSTIM(ind));
end % 

% Plot data
if ~isempty(D), plot(D, DAPE, 'rs-', 'linewidth', 2); end

%% EXTRACT LEFT-ONLY/TEST STIMULI
GAPEind=find(COND<-200 & COND>-300); 
CI=rem(COND,100); 
D=sort(unique(CI(GAPEind)));

for d=1:length(D)
    ind=find(COND<-200 & COND>-300 & CI==D(d));
    GAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
end % 

% Plot data
if ~isempty(D), plot(D, GAPE, 'gd-', 'linewidth', 2); end

%% EXTRACT SILENCE/TEST STIMULI
SAPEind=find(COND<-300 & COND>-400); 
CI=rem(COND,100); 
D=sort(unique(CI(SAPEind)));

for d=1:length(D)
    ind=find(COND<-300 & COND>-400 & CI==D(d));
    SAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
end % 

%% RETURN VARIABLE
NRESP=[DAPE GAPE SAPE];

% Plot data
if ~isempty(D), plot(D, SAPE, 'ko-', 'linewidth', 2); end

% Set legend
set(gca, 'YLim', [0 max(NSTIM)]);  
legend('Right-Only/Test', 'Left-Only/Test', 'Silence/Test', 'location', 'best'); 
xlabel('Mean Intensity (dB)');
ylabel('Number on Left Side'); 