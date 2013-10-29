function [NRESP D]=PEABR_exp01D_analysis(P)
%% DESCRIPTION:
%
%   Plot data for Exp01D.
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

figure

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

%% GRAB UNIQUE CONDITION RANGE
COND=floor(COND./100)*100;

%% GRAB UNIQUE LEAD-LAG DELAYS
D=unique(ALAG);

%% DATA
%   COND x DELAY
C=unique(COND);
for c=1:length(C)
    for d=1:length(D)
        NRESP(d,c)=nanmean(RESP_NSTIM(find(COND==C(c) & ALAG==D(d)))); 
    end % d
end % c

%% plot data

plot(D, NRESP, 's-', 'linewidth', 2); 
legend([num2str(1/LJIT(find(COND==C(1), 1, 'first'))) ' Hz'], [num2str(1/LJIT(find(COND==C(2), 1, 'first'))) ' Hz'], [num2str(1/LJIT(find(COND==C(3), 1, 'first'))) ' Hz'], 'Variable', 'location', 'best'); 
xlabel('Delay (sec)')
ylabel('Number on Left Side'); 