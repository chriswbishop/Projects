function PEABR_exp01D_group(SID, EXPID)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:%
%
%

for s=1:size(SID,1)    
    %% LOAD DATA
    load([deblank(SID(s,:)) EXPID], 'NRESP', 'D');
    gNRESP(:,:,s)=NRESP;
    gD(:,s)=D; 
    clear NRESP D;    
end % s=1:size...

figure, hold on

%% PLOT 1 Hz
Y=gNRESP; 
X=gD(:,1)*ones(1,size(Y,2));
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,1)), 's-', 'linewidth', 2);

%% MARKUP
xlabel('Delay (sec)'); 
ylabel('Number of Clicks Reported');
legend('1.0 Hz', '3.5 Hz', '6.25 Hz', 'Variable(1-6.25 Hz)', 'location', 'best'); 
