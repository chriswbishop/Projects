function [gNRESP LEAD_LAG LEAD_SILENCE LAG_SILENCE DGNDIST DSNDIST GSNDIST DGCVAL DGT DSCVAL DST GSCVAL GST]=PEABR_exp01_thresholdtest(SID, EXPID)
%% DESCRIPTION:
%
% INPUT:
%   
%   SID:    character array with each row being a subject ID
%           (e.g. FFSID=strvcat('s3114', 's3116', 's3121', 's3123',
%           's3125', 's3126', 's3128', 's3131', 's3136', 's3137', 's3138', 's3139', 's3141', 's3143'); 
%   EXPID:  string, experiment ID (e.g. EXPID='_PEABR_Exp01C';) 
%
% OUTPUT:
%
%   gNRESP:
%   LEAD_LAG:
%   LEAD_SILENCE:
%   LAG_SILENCE:
%   DGNDIST:
%   DSNDIST:
%   GSNDIST:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

for s=1:size(SID,1)
    
    %% LOAD DATA
    load([SID(s,:) EXPID], 'NRESP', 'D');
    gNRESP(:,:,s)=NRESP;
    clear NRESP;
    
end % s=1:size...


%% COMPARE LEAD-APE and LAG-APE
[DGNDIST LEAD_LAG DGCVAL DGT]=THRESHOLD_PERMTEST(D, gNRESP(:,[1 2],:), 20000);

%% COMPARE LEAD-APE to SILENCE-APE
[DSNDIST LEAD_SILENCE DSCVAL DST]=THRESHOLD_PERMTEST(D, gNRESP(:,[1 3],:), 20000);

%% COMPARE LAG-APE to SILENCE-APE
[GSNDIST LAG_SILENCE GSCVAL GST]=THRESHOLD_PERMTEST(D, gNRESP(:,[2 3],:), 20000);

end % PEABR_exp01_thresholdtest

function [NDIST PVAL CVAL T]=THRESHOLD_PERMTEST(XDATA, YDATA, N, TVAL)
%% DESCRPIPTION
%
%   Function to estimate null distributions by shuffling labels of
%   individual data and recomputing group averages.  Threshold (TVAL) is
%   then estimated using linear interpolation of nearest two points and the
%   absolute difference between the two conditions' echo thresholds is
%   stored as part of the null distribution. Rinse and repeat a lot of
%   times and we have a null distribution. 
%
% INPUT:
%
%   XDATA:  1xD or Dx1 vector, with D being the number of latencies tested.  Units
%           are arbitrary, but during testing I passed echo-delays in
%           seconds (s).
%   YDATA:  Dx2xS matrix, with D equal to the number of (D)elays tested.
%           S is the number of (S)ubjects.  
%   N:      Integer, the number of permutations of subject data to test.
%           Note that the maximum number of unique permutations using this
%           permutation approach is 2^S, where S is the number of subjects.
%   TVAL:   double, (T)hreshold (VAL)ue to test for differences at.  For
%           echo thresholds, this should be set to 50% of the range (e.g.
%           10 for 20 sounds, 0.50 as a proportion, etc.). (default=10) 
%
% OUTPUT:
%   
%   NDIST:  Nx1 vector, null distribution entries for comparison.
%   PVAL:   double, p-value of observed distances compared to NDIST.
%   CVAL:   critical value needed to achieve a designated significance
%           level (currently p<0.05)
%   T:      double, observed difference in threshold between (correctly)
%           labeled group data. 
%
%   Figures:
%       A cumulative histogram plot for the null distribution with the
%       critical value (CVAL) and observed value (T) marked.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% TVAL
if ~exist('TVAL', 'var') || isempty(TVAL), TVAL=10; end
if size(XDATA,1) ~= size(YDATA,1), XDATA=XDATA'; end

%% INITIALIZE RANDOM NUMBER GENERATOR
rand('twister', sum(100*clock)); 

for i=1:N
    
    %% SHUFFLE
    for s=1:size(YDATA,3)
        ydata(:,:,s)=YDATA(:,randperm(size(YDATA,2)),s); 
    end
    
    %% COMPUTE MEAN
    ydata=mean(ydata,3); 
    
    %% CALCULATE THRESHOLDS
    for j=1:size(ydata,2)
        data=ydata(:,j);
        if ~isempty(find(data==TVAL,1))
            t(j)=XDATA(find(data==TVAL,1,'first')); 
        else
            IND=[find(data<TVAL,1,'last') find(data>TVAL,1,'first')];
            p=polyfit(XDATA(IND), data(IND), 1);  
%             x=XDATA(IND(1)):0.00001:XDATA(IND(2));
%             t(j)=x(find(polyval(p, x)>=TVAL, 1, 'first'));
            t(j)=(TVAL-p(2))./p(1); % solve discretely instead of interpolating
        end % if
    end % for j   
    
    NDIST(i)=abs(diff(t));     
    
end % i=1:N

%% PLOT CUMULATIVE HISTOGRAM
figure, hold on
% Divide histogram into maximum number of unique bins (N)
% Convert to proportion (divide by # of permutations)
[Y X]=hist(NDIST,N);
CH=cumsum(Y)./N; 
% CH=cumsum(hist(NDIST,N))./N; 
% X=1/N:1/N:1;
CIND=find(CH>=0.95,1,'first');
CVAL=X(CIND); 
plot(X, CH, 'linewidth', 2); 
plot(X(CIND), CH(CIND), 'r+', 'markersize', 12, 'linewidth', 3); 

%% TEST HYPOTHESIS
YDATA=mean(YDATA,3); 
for j=1:size(YDATA,2)
    data=YDATA(:,j);
    if ~isempty(find(data==TVAL,1))
        T(j)=XDATA(find(data==TVAL,1,'first')); 
    else
        IND=[find(data<TVAL,1,'last') find(data>TVAL,1,'first')];
        p=polyfit(XDATA(IND), data(IND), 1);  
%         x=XDATA(IND(1)):0.00001:XDATA(IND(2));
        T(j)=(TVAL-p(2))./p(1);
%         T(j)=x(find(polyval(p, x)>=TVAL, 1, 'first'));
    end % if
end % for j   

% Calculate P-value
PVAL=length(find(NDIST>=abs(diff(T))))./length(NDIST); 
T=diff(T); 

% Plot observed value
plot(X(find(CH>=(1-PVAL),1,'first')), CH(find(CH>=(1-PVAL),1,'first')), 'gd', 'linewidth', 3)

% markup figure
legend('Cummulative Histogram', 'Critical-Value', 'Observed Difference', 'location', 'best');
xlabel('Absolute Difference');
ylabel('Cummulative Proportion'); 

end % PERMTEST