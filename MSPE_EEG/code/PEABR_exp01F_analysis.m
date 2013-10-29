function [NRESP D]=PEABR_exp01F_analysis(P)
%% DESCRIPTION:
%
%   Analysis code for Experiment 01F.  
%
% INPUT:
%
%   P:  character array, each row is the path to a log file (e.g.
%       P=strvcat('../logs/s3144-PEABR_Exp01C-D1.log');
%       PEABR_exp01_analysis(P);)
%
% OUTPUT:
%
%   NRESP:  DxC matrix, with each row equal to a specific delay, and each
%           column corresponding to a different condition. Currently,
%           column 1 = Lead-Ape, 2=Lag-Ape, 3=Silence-Ape.
%   D:      1xD array, with each column equal to a specific delay. Sorted
%           in ascending order.  
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% RETURN VARS
DAPE=[];
GAPE=[];
SAPE=[]; 
APE=[];

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

figure, hold on;

%% EXTRACT LEAD-APE STIMULI
%   Codes range from (100-200)
DAPEind=find(COND>100 & COND<200); 

D=sort(unique(ALAG(DAPEind))); 

for d=1:length(D)
    ind=find(COND>100 & COND<200 & ALAG==D(d));
    DAPE(d,1)=nanmean(RESP_NSTIM(ind));
end % 

% Plot data
if ~isempty(D), plot(D, DAPE, 'rs-', 'linewidth', 2); end

%% EXTRACT LAG-APE STIMULI
%   Codes range from (200 - 300)
GAPEind=find(COND>200 & COND<300); 

D=sort(unique(ALAG(GAPEind))); 

for d=1:length(D)
    ind=find(COND>200 & COND<300 & ALAG==D(d));
    GAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
end % 

% Plot data
if ~isempty(D), plot(D, GAPE, 'gd-', 'linewidth', 2); end

%% EXTRACT SILENCE-APE STIMULI
%   Codes range from (300 - 400)
SAPEind=find(COND>300 & COND<400);

D=sort(unique(ALAG(SAPEind))); 

for d=1:length(D)
    ind=find(COND>300 & COND<400 & ALAG==D(d));
    SAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
end % 

% Plot data
if ~isempty(D), plot(D, SAPE, 'ko-', 'linewidth', 2); end

%% EXTRACT APE STIMULI
%   Codes range from (300 - 400)
APEind=find(COND>400 & COND<500);

D=sort(unique(ALAG(APEind))); 

for d=1:length(D)
    ind=find(COND>400 & COND<500 & ALAG==D(d));
    APE(d,1)=nanmean(RESP_NSTIM(ind)); 
end % 

% Plot data
if ~isempty(D), plot(D, APE, 'c*-', 'linewidth', 2); end

% Set legend
axis([min(ALAG)-0.001 max(ALAG)+0.001 0 20]);
legend('Lead-Ape', 'Lag-Ape', 'Silence-Ape', 'Ape', 'location', 'best'); 
xlabel('Delay (sec)');
ylabel('Number on Left Side'); 

%% RETURN VARIABLE
NRESP=[DAPE GAPE SAPE APE];