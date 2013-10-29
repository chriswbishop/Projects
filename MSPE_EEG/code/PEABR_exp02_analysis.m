function [LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP pRESP_NSTIM THRESH LL]=PEABR_exp02_analysis(P)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
% XASF
%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);


%% ALAG DATA
T=sort(unique(ALAG)); 


%% PLOT NSTIM
for t=1:length(T)
    data(t)=nanmean(RESP_NSTIM(COND~=201 & COND~=202 & ALAG==T(t))); 
    datae(t)=nanstd(RESP_NSTIM(COND~=201 & COND~=202 & ALAG==T(t))); 
end % t

pRESP_NSTIM=data; 

%% plot with STD
figure, hold on


%% Fit the data
X=[T(~isnan(pRESP_NSTIM))*1000]'; % convert from sec to msec
Y=[pRESP_NSTIM(~isnan(pRESP_NSTIM))]'./20;
% fitobj=fit(X, Y, 'A/(B+exp(-C*(x-D))) + E', 'start', [5.21e-02 0.213 8.03e-02 6.97e-02 0.339], 'Algorithm', 'Trust-Region'); % initial parameters from s3101
fitobj=fit(X, Y, '1/(1+exp(-C*(x-D)))', 'Algorithm', 'Levenberg-Marquardt'); % initial parameters from s3101
% fitobj=fit(X, Y, 'A/(B+exp(-C*(x-D))) + E', 'start', [5.21e-02 0.213 8.03e-02 6.97e-02 0.339], 'Algorithm', 'Levenberg-Marquardt', 'Robust', 'on'); % initial parameters from CB
CO=coeffvalues(fitobj); % save coefficients in matrix

%% Plot interpolated fit
plot(X, Y, 'kd', 'linewidth', 2); 
X=min(X):0.01:max(X); Y=fitobj(X); 
plot(X, Y, '--'); 

%% plot 50% point
ind=find(fitobj(X)>=0.5, 1, 'first'); 
THRESH=X(ind)./1000; % threshold in seconds
plot(X(ind), fitobj(X(ind)), 'rs', 'linewidth', 3, 'MarkerSize', 12); 

%% PLOT RAW DATA
IND=find(COND~=201 & COND~=202); 
plot(ALAG(IND).*1000, RESP_NSTIM(IND)./20, 'b+');

xlabel('Echo Delay (msec)'); 
ylabel('Proportion of Clicks reported');
legend('MEAN NSTIM Resp', 'Psychometric Fit', 'Threshold', 'NSTIM Resp', 'location', 'best')
