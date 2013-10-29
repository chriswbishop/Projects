function [gNRESP gD rmNRESP]=PEABR_exp01E_group(SID, EXPID)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:%
%
%

for s=1:size(SID,1)    
    %% LOAD DATA
    load([SID(s,:) EXPID], 'NRESP', 'D');
    gNRESP(:,:,s)=NRESP./20.*100; % Convert to percentage
    gD(:,s)=D+121;  % Transform to match actual intensities. Assumes an amplitude of 0.31= ~111 dB(A, peak)
                    % Here's how I arrived at this value
                    %   111-(db(0.31)-(db(0.0001)-6)) % 35.1728
                    %   (db(0.0001)-6)+X=35.1728; % solve for X
                    %       X=~121 dB
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
X=gD(:,1)*ones(1,size(Y,2));
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,3)), 'rs-', 'linewidth', 2);

%% PLOT LAG-APE
Y=gNRESP(:,2,:); 
X=gD(:,1)*ones(1,size(Y,2));
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,3)), 'gd-', 'linewidth', 2);

%% PLOT SILENCE-APE
Y=gNRESP(:,3,:); 
X=gD(:,1)*ones(1,size(Y,2));
errorbar(X, mean(Y,3), std(Y,0,3)./sqrt(size(Y,3)), 'ko-', 'linewidth', 2);

%% MARKUP
xlabel('Mean Intensity (dB)'); 
ylabel('Number of Clicks Reported');
legend('Right-Only/APE', 'Left-Only/APE', 'Silence/APE', 'location', 'best'); 

%% PLOT CONDITION COMPARISONS
Y=squeeze(mean(gNRESP,1));
Y(1,:)=Y(1,:)-Y(3,:); % Lead-APE vs Silence
Y(2,:)=Y(2,:)-Y(3,:); % Lag-APE vs Silence
Y=Y(1:2,:); % Get rid of silence

% plot group average
figure, hold on
% bar(1:2, mean(Y,2)); 
E=std(Y,0,2)./sqrt(size(Y,2));
barweb(mean(Y,2), E);
ymax=max([abs(mean(Y,2)+E); abs(mean(Y,2)-E)]);
if ymax<5, ymax=5; end % 
% errorbar(1:2, mean(Y,2), std(Y,0,2)./sqrt(size(Y,2)), 'ko', 'linewidth', 2);
set(gca, 'YLim', [-1.1*ymax 1.1*ymax] );
% plot individual data
% plot(1:2, Y, 'k*'); 
% set(gca, 'XTick', [1 2])
% set(gca, 'XTickLabel', {'Right-Only/APE', 'Left-Only/APE'}) 
% set(gca, 'XLim', [0.75 1.25])
legend('Right-Only/APE', 'Left-Only/APE', 'location', 'best'); 
set(gca, 'YLim', [-1*max(abs(get(gca, 'YLim'))) max(abs(get(gca, 'YLim')))]);
ylabel('% Difference (RE: Silence/APE)'); 