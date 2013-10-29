function [LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP pRESP_NGROUP pRESP_NSTIM LEADONLY LAGONLY GMC P]=PEABR_exp01_analysis(P)
%% DESCRIPTION:
%
%
%   Super sloppy analysis function to look at data for Experiment 01 on the
%   fly.
% INPUT:
%
% OUTPUT:%
%
%
% exhausted graduate student

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

N=unique(NSTIM);

%% CORRECT GROUP NUMBER RESPONSE PROPORTION
for n=1:length(N)
    data(n)=(length(find(COND~=201 & COND~=202 & NSTIM==N(n) & (RESP_NGROUP==NBREAKS+1)))./length(find(COND~=201 & COND~=202 & NSTIM==N(n))));
end % for n=1: ... 

pRESP_NGROUP=data; 

figure, hold on
bar(N, data); 

%% CONFUSION MATRIX FOR GROUP NUMBER RESPONSE
G=unique(NBREAKS+1);
for g=1:length(G)
    for j=1:length(G)
        GMC(g,j)=length(find(COND~=201 & COND~=202 & NBREAKS+1==G(g) & RESP_NGROUP==G(j)))./length(find(COND~=201 & COND~=202 & NBREAKS+1==G(g)));
    end % j
    % Tack on remainder (impossible response categories)
    GMC(g,length(G)+1)=1-sum(GMC(g,:)); 
end % 

%% ONLY PLOT NON_CONTROL DATA
IND=find(COND~=201 & COND~=202 & COND~=203);
nstim=NSTIM(IND); resp_nstim=RESP_NSTIM(IND); 

% plot raw data
plot(NSTIM(IND), RESP_NSTIM(IND), '+');

N=unique(nstim); 

% plot unity line
plot(N, N, 'ro-', 'linewidth', 3); 

% plot mean
data=[];
for n=1:length(N)
    data(n)=nanmean(resp_nstim(find(nstim==N(n))));
    datae(n)=nanstd(resp_nstim(find(nstim==N(n))),0,2);
end % n=1:length(N)
pRESP_NSTIM=data; 

errorbar(N, data, datae, 'kd', 'linewidth', 2); 

%% PLOT OBVIOUS LEAD/LAG
try
    % obvious lead
    N=NSTIM(find(COND==201, 1, 'first')); 
    data=[];
    for n=1:length(N)
        data(n)=nanmean(RESP_NSTIM(find(COND==201 & NSTIM==N(n))));
    %     (length(find(COND==201 & NSTIM==N(n) & (RESP_NSTIM==N(n))))./length(find(COND==201 & NSTIM==N(n))));
    end % for n=1: ... 
    LEADONLY=data; 
    plot(0, data, 'sm', 'MarkerSize', 12, 'linewidth', 3); 
catch
    warning('No Obvious Lead Detected');
end % try

% obvious lag 
try 
    N=NSTIM(find(COND==202, 1, 'first')); 
    data=[];
    for n=1:length(N)
        data(n)=nanmean(RESP_NSTIM(find(COND==202 & NSTIM==N(n))));
    %     data(n)=(length(find(COND==202 & NSTIM==N(n) &
    %     (RESP_NSTIM==N(n))))./length(find(COND==202 & NSTIM==N(n))));
    end % for n=1: ... 
    LAGONLY=data; 
    plot(N, data, 'sb', 'MarkerSize', 12, 'linewidth', 3);    
catch 
    warning('No Obvious Lag Detected'); 
end %  try

% plot(N, data, 'kd', 'linewidth', 2); 
legend('Groups: Proportion Correct', 'NSTIM Resp', 'Perfect Performance', 'Mean NSTIM Resp (+/- STD)','Lead-Only', 'Lag-Only', 'location','Best');
xlabel('Lagging Clicks Presented'); 
ylabel('Lagging Clicks Reported'); 
