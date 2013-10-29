function [gRESP_NGROUP gRESP_NSTIM gP]=PEABR_exp01_group(SID, EXPID)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
% akl;sjdf

% close all;
figure, hold on;

gRESP_NGROUP=[];
gRESP_NSTIM=[]; 
gP=[]; 

N=2:2:18;

%% COMPILE GROUP DATA
for s=1:size(SID,1)
    sid=deblank(SID(s,:)); 
    load([sid EXPID]); 
    
    gRESP_NGROUP(end+1,:)=pRESP_NGROUP;
    gRESP_NSTIM(end+1, :)=pRESP_NSTIM; 
    
    gP=strvcat(gP, P); 
end % s

%% PLOT NSTIM RESPONSE
% plot unity line
plot(N, N, 'ro-', 'linewidth', 3); 

errorbar(N, nanmean(gRESP_NSTIM,1), nanstd(gRESP_NSTIM,0,1)./sqrt(size(gRESP_NSTIM,1)), 'kd', 'linewidth', 2); 

%% PLOT NGROUP RESPONSE
bar(N, nanmean(gRESP_NGROUP,1)); 
errorbar(N, nanmean(gRESP_NGROUP,1), nanstd(gRESP_NGROUP,0,1)./sqrt(size(gRESP_NGROUP,1)), 'ks', 'linewidth', 2); 
legend('Perfect Performance', 'Mean NSTIM Resp (+/- SEM)', 'Groups: Proportion Correct', 'Mean Group (+/- SEM)', 'location', 'best');
% legend('Groups: Proportion Correct', 'NSTIM Resp', 'Perfect Performance', 'Mean NSTIM Resp','location','Best');
xlabel('Clicks Presented'); 
ylabel('Clicks Reported');
title(['Group Data (N=' num2str(size(SID,1)) ')']); 