function [gNRESP gD rmNRESP Y]=PEABR_exp01F_group(SID, EXPID)
%% DESCRIPTION:
%
%   Group plotting function for PEABR Experiment 01F.
%   
% INPUT:
%
%
%
% OUTPUT:
%
%

for s=1:size(SID,1)    
    %% LOAD DATA
    load([SID(s,:) EXPID], 'NRESP', 'D');
    gNRESP(:,:,s)=NRESP./20.*100; % Convert to percentage
%     gNRESP(:,:,s)=NRESP; % Convert to percentage
    gD(:,s)=D; 
    clear NRESP D;    
end % s=1:size...

%% Transform gNRESP into Statistica friendly structure
rmNRESP=[];
for s=1:size(gNRESP,3)
    tmp=[];
    for j=1:size(gNRESP,2)
        tmp=[tmp gNRESP(:,j,s)'];
    end % j
    rmNRESP(s,:)=tmp;
end % i

figure, hold on
%% PLOT LEAD-APE
Y=gNRESP(:,1,:); 
X=gD(:,1)*ones(1,size(Y,2)).*1000;
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,1)), 'rs-', 'linewidth', 2);

%% PLOT LAG-APE
Y=gNRESP(:,2,:); 
X=gD(:,1)*ones(1,size(Y,2)).*1000;
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,1)), 'gd-', 'linewidth', 2);

%% PLOT SILENCE-APE
Y=gNRESP(:,3,:); 
X=gD(:,1)*ones(1,size(Y,2)).*1000;
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,1)), 'ko-', 'linewidth', 2);

%% PLOT APE
Y=gNRESP(:,4,:); 
X=gD(:,1)*ones(1,size(Y,2)).*1000; 
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,1)), 'c*-', 'linewidth', 2);

%% MARKUP
xlabel('Delay (msec)'); 
ylabel('Number of Clicks Reported');
legend('Lead-Ape', 'Lag-Ape', 'Silence-Ape', 'Ape', 'location', 'best'); 
% ylim([0 105]); 
ylim([0 20]); 

%% PLOT CONDITION COMPARISONS
Y=squeeze(mean(gNRESP,1));
Y(1,:)=Y(1,:)-Y(3,:); % Lead-APE vs Silence
Y(2,:)=Y(2,:)-Y(3,:); % Lag-APE vs Silence
Y(4,:)=Y(4,:)-Y(3,:); % APE vs. Silence
Y=Y([1:2 4],:); % Get rid of silence

% plot group average change
figure, hold on
% bar(1:2, mean(Y,2)); 
barweb(mean(Y,2), std(Y,0,2)./sqrt(size(Y,2)));
% errorbar(1:2, mean(Y,2), std(Y,0,2)./sqrt(size(Y,2)), 'ko', 'linewidth', 2);

% plot individual data
% plot(1:2, Y, 'k*'); 
% set(gca, 'XTick', [1 2])
% set(gca, 'XTickLabel', {'Right-Only/APE', 'Left-Only/APE'}) 
% set(gca, 'XLim', [0.75 1.25])
legend('Lead-APE vs Silence', 'Lag-APE vs Silence', 'APE vs Silence', 'location', 'best'); 
set(gca, 'YLim', [-1*max(abs(get(gca, 'YLim'))) max(abs(get(gca, 'YLim')))]);
ylabel('% Difference (RE: Silence/APE)'); 
ylim([-2 2]);
