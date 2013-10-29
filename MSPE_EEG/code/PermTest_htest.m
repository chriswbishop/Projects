function [H T NULLDIST mP mC pT CLUST_MAP CLUST_VAL CLUST_H pCLUST]=PermTest_htest(DATA, NULLDIST, A, CLUST_DIM, THRESH)
%% DESCRIPTION:
%
%   Test hypothesis from known distribution. This, at least in the context 
%   of permutation testing, is typically the empirically derived null
%   distribution.  At the time of writing, this is assumed to be a maximal
%   null distribution, as described in
%
%   1.  Nichols, TE and AP Holmes (2002). "Nonparametric permutation tests
%       for functional neuroimaging: a primer with examples." Hum Brain
%       Mapp 15(1): 1-25
%
% INPUT:
%
%   DATA:   Nx1 vector containing values to test against the null
%           distribution.  This is often the mean of the (correctly
%           labeled) data used to construct the null distribution.
%   NULLDIST:   Mx1 vector containing members of the null distribution.
%               This is assumed to be the Maximal Null Distribution (see
%               PermTest_maxnull. m for details)
%   A:      Alpha level (e.g. 0.05) for comparisons. (default 0.05)
%
%   CLUSTERING VARIABLES:
%
%   CLUST_DIM:  Integer, cluster dimension to work on. Currently only works
%               with CLUST_DIM=1. More to come once I figure out how to
%               cluster in multidimensional arrays without looping and
%               doing dumb neighbor checks.
%   THRESH:     double, threshold value. This should be the same value used
%               to construct the MAXX_NULLCLUST distribution or to perform
%               clustering in PermTest_cluster. 
%
% OUTPUT:
%
%   H:      Nx1 vector containing the result of the hypothesis test for
%           each member of DATA (1=rejuect null hypothesis, 0=fail to
%           reject null hypothesis).
%   T:      Threshold cutoff for significance.  Any absolute difference
%           greater than T rejects the null hypothesis.
%   NULLDIST:   Null distribution used for comparison.
%   mP:     P value of each unique value present in NULLDIST.
%   mC:     Corresponding raw value to member of mP. 
%   pT:     Probability of observing T.  This is the REAL alpha value of
%           the hypothesis test.  It's important to keep in mind that even
%           if the user requests a A=0.005, if max(mP)==0.03, then that's
%           the best we can do in the test. pT reflects what the alpha for
%           the test really is. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
if ~exist('A', 'var') || isempty(A), A=0.05; end
if ~exist('CLUST_DIM', 'var') || isempty(CLUST_DIM), CLUST_DIM=1; end
if ~exist('THRESH', 'var') || isempty(THRESH), THRESH=0; end
% if ~isempty(find(sign(DATA)<0)), warning('Negative values present! Abs(DATA) used.'); end;
% DATA=abs(DATA);

%% DETERMINE P-VALUES FOR DISTRIBUTION
mP=[];
mC=unique(NULLDIST);
for i=1:length(mC)
    mP(i,1)=length(find(NULLDIST>=mC(i)))./length(NULLDIST); 
end % 

%% DETERMINE THRESHOLD CUTOFF OF MAX NULL
%   Values in DATA are compared to T to determine significance. 
T=mC(find(mP<A, 1, 'first'));

% If we can't find a threshold for this P, pick the smallest value.
if isempty(T) || isnan(T)
    T=mC(end);     
end % if 

%% CALCULATE ALPHA USED IN TEST
%   Probability of observing T.
% pT=length(find(NULLDIST==T))./length(NULLDIST);
pT=length(find(NULLDIST>=T))./length(NULLDIST); 

%% DETERMINE SIGNIFICANCE
%   Only reject null hypothesis if DATA>T. H is a matrix of logical values,
%   to make indexing DATA easier.
H=abs(DATA)>T; 

%% TEST AGAINST NULL DISTRIBUTION WITH CLUSTERING
[CLUST_MAP CLUST_VAL]=PermTest_cluster(DATA, CLUST_DIM, THRESH); 
CLUST_H=abs(CLUST_VAL)>T; 

%% DETERMINE APPROXIMATE P-VALUES OF CLUSTERS
for i=1:length(CLUST_VAL)
    pCLUST(i,1)=length(find(NULLDIST>=abs(CLUST_VAL(i))))./length(NULLDIST);
end % i=1:length(CLUST_VAL)