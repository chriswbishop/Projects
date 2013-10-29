function [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME APE OS OD]=MSPE_psychometric(P, FLAG)
%% DESCRIPTION:
%
%   This function was a bit more helpful for MSPE_fMRI where we were
%   explicitly constructing a psychometric function for each individual.
%   Basically just reads in the trial information and constructs a
%   psychometric function. Pretty straightforward stuff.
%
% INPUT:
%
% OUTPUT:
%
% my name here. 

%% DEFAULTS
if ~exist('FLAG', 'var') || isempty(FLAG), FLAG=1; end

%% LOAD DATA
%   Either load it from a mat file or create from logfile.
try 
    load(P);
catch
%     [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF S]=MSPE_read(P);
    %% Switched to MSPE_fMRI_read to use the same reading function for the whole experiment. Whoops.
    [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF PCOUNT PTOTAL S M PTIME]=MSPE_fMRI_read(P);
end % try catch

if FLAG
    figure, hold on;
end

%% GET Ape CONDITIONS
%   This is based on MSPE_DEFS. Hard coded, I know, but have to make
%   assumptions somewhere.
APE=[];
APEind=find(COND==1 | COND==2); 

%% GET UNIQUE DELAYS
%   D:  unique delays
D=sort(unique(ALAG(APEind)));
for d=1:length(D)
    ind=find( (COND==1 | COND==2) & (ALAG==D(d)));     
    APE(d)=(length( find(NRESP(ind)==1)) ./ length(find(NRESP(ind)~=0))).*100;
end % 

%% PLOT IT OUT
if FLAG
    plot(abs(D)*1000, APE, 'ks-', 'linewidth', 2); 
end

%% GET OBVIOUS SINGLES
OS=[]; 
OSind=find(COND==7 | COND==8); 

%% GET UNIQUE DELAYS
%   D:  unique delays
D=sort(unique(ALAG(OSind)));
for d=1:length(D)
    ind=find( (COND==7 | COND==8) & (ALAG==D(d)));     
    OS(d)=(length( find(NRESP(ind)==1)) ./ length(find(NRESP(ind)~=0))).*100;
end % 

%% PLOT IT OUT
if FLAG
    plot(abs(D)*1000, OS, 'ro-', 'linewidth', 3); 
end 

%% GET OBVIOUS DOUBLES
OD=[]; 
ODind=find(COND==24 | COND==25); 

%% GET UNIQUE DELAYS
%   D:  unique delays
D=sort(unique(ALAG(ODind)));
for d=1:length(D)
    ind=find( (COND==24 | COND==25) & (ALAG==D(d)));     
    OD(d)=(length( find(NRESP(ind)==1)) ./ length(find(NRESP(ind)~=0))).*100;
end % 

%% PLOT IT OUT
if FLAG
    plot(abs(D)*1000, OD, 'gs-', 'linewidth', 3); 
    xlim([0 40]); 
    ylim([0 101]); 
    legend('Ape', 'Single', 'Double', 'location', 'best'); 
    xlabel('Delay (msec)');
end % 
ylabel('% One-Location'); 
