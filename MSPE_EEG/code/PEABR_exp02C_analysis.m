function [DAPE GAPE D TDIFF TDELAY MSEP_DELAY MSEP]=PEABR_exp02C_analysis(P, COND4LAG)
%% DESCRIPTION:
%
%   Analysis code for Experiment 01C.  
%
% INPUT:
%
%   P:
%
% OUTPUT:
%
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
if ~exist('COND4LAG', 'var') || isempty(COND4LAG), COND4LAG=1; end % use this by default

%% RETURN VARS
DAPE=[];
GAPE=[];

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

figure, hold on;

%% EXTRACT LEAD-APE STIMULI
% DAPEind=find(COND>100 & COND<200); 
%% DO SANITY CHECK ON COND VALUES
DAPEind=find(COND>50 & COND<300 & [NaN COND(1:end-1)]==100 & COND~=100);

%% WHY WE USE COND INSTEAD OF ALAG
%   OK, we have a technical issue: we have to include a dummy stimulus with
%   a fixed lead-lag auditory delay (12 msec currently, but subject to
%   change), but the rest of the stims potentially have a different delay.
%   So, we have to extract the auditory delay from the COND variable
%   instead of ALAG.  There are probably much better ways to do this, but I
%   don't want to take the time to code them currently. 

% Redefine ALAG
if COND4LAG
    ALAG=mod(COND,100);
else
    ALAG=ALAG.*1000; % convert to msec.
end % COND4LAG
% D=sort(unique(mod(COND(DAPEind),100)));
D=sort(unique(ALAG(DAPEind))); 
alag=ALAG(DAPEind);
resp_nstim=RESP_NSTIM(DAPEind);
for d=1:length(D)
    ind=find(alag==D(d));
    DAPE(d,1)=nanmean(resp_nstim(ind)); 
end % 
% for d=1:length(D)
%     ind=find(COND>50 & COND<200 & ALAG==D(d) & COND~=100);
%     DAPE(d,1)=nanmean(RESP_NSTIM(ind));
% end % 
DAPE=DAPE./20*100;
% Plot data
if ~isempty(D), plot(D, DAPE, 'rs-', 'linewidth', 2); end

%% EXTRACT LAG-APE STIMULI
% GAPEind=find(COND>200 & COND<300);
% I opened up the Condition range here so things would be compatible with
% old codes.
GAPEind=find(COND>50 & COND<300 & [NaN COND(1:end-1)]==200 & COND~=200);

D=sort(unique(ALAG(GAPEind))); 
alag=ALAG(GAPEind);
resp_nstim=RESP_NSTIM(GAPEind);
for d=1:length(D)
    ind=find(alag==D(d));
    GAPE(d,1)=nanmean(resp_nstim(ind)); 
end % 
GAPE=GAPE./20*100;
% Plot data
if ~isempty(D), plot(D, GAPE, 'gd-', 'linewidth', 2); end

% Plot difference 
%   Doesn't work if not enough data points.
Y=DAPE-GAPE;
plot(D, Y, 'ko');
% try
%     fitobj=fit(D',Y,'a*exp(-((x-b)/c)^2)', 'StartPoint', [max(Y) D(find(Y==max(Y))) 2], 'Lower', [0 0 0], 'Upper', [100 14 20]); % fit with gaussian
%     plot(fitobj, 'k'); 
%     coeffvals = coeffvalues(fitobj);
%     MSEP_DELAY=coeffvals(2); 
%     MSEP=coeffvals(1); 
% catch
%     MSEP_DELAY=NaN;
%     MSEP=NaN;
% end % try/catch
MSEP=max(Y); 
MSEP_DELAY=D(find(Y==max(Y),1,'last'));

%% ESTIMATE DIFFERENCE between conditions Lead-Only/Ape at XXX %
T=50; % Echo threshold.
ind=find(DAPE==T);
if isempty(find(ind==T))
    % linear interpolation of lead-only/ape.
    ind=[find(DAPE<T, 1, 'last') find(DAPE>T, 1, 'first')];    
else
    ind=[find(DAPE==T,1,'last')-1 find(DAPE==T,1,'last')+1];
end % 

try
    fitobj=fit(D(ind)', DAPE(ind), 'poly1'); 
    coeffvals = coeffvalues(fitobj);
    delay=(T-coeffvals(2))./coeffvals(1);    
    
    % what's the value of lag-only/ape at this lead-lag delay?
    ind=[find(D<delay, 1, 'last') find(D>delay, 1, 'first')];
    fitobj=fit(D(ind)', GAPE(ind), 'poly1');
    TDIFF=T-fitobj(delay);
    TDELAY=delay;
catch
    TDIFF=NaN;
    TDELAY=NaN;
end % try/catch

% plot 
% if ~isempty(D), plot(D, SAPE, 'ko-', 'linewidth', 2); end

% Set legend
axis([-0.5 14 0 101]);
legend('Lead-Ape', 'Lag-Ape', 'Difference', 'Difference Fit', 'location', 'best'); 
xlabel('Delay (msec)');
ylabel('Number on Left Side'); 