function [MAX_NULLDIST MAX_NULLCLUST]=PermTest_maxnull_CORR(B, DV, N, THRESH)
%% DESCRIPTION:
%
%   This is a method for constructing a maximum null distribution for a
%   correlation coefficient between a single variable (B) and many other 
%   variables (DV).  At the time I'm writing this, I'm trying to identify
%   significant between-subject correlations between a behavioral measure
%   (% change) and changes in the many dependent measures (here, many ITPC
%   values in a pre-stimulus baseline).
%
%   A MAXIMUM NULL distribution is created for hypothesis testing (see
%   PermTest_maxnull for a detailed discussion) by randomly changing the
%   sign of B while holding measures in DV constant.  After each
%   permutation, a correlation coefficient is calculated between the
%   (permuted) matrix B and each column of DV.
%
% INPUT:
%
%   B:  1xS (or Sx1) double array, where S is the number of observations (e.g.
%       subjects)
%   DV: SxM double array, where S is the number of observations and each
%       column of M is a measured variable.
%   N:  Number of permutations used to construct null distribution.
%
% OUTPUT:
%
%   MAX_NULLDIST:   Maximum null distribution. Contains N values.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% CHECK INPUTS
if ~exist('N', 'var') || isempty(N), N=10; end
if ~exist('CLUST_DIM', 'var') || isempty(CLUST_DIM), CLUST_DIM=1; end
if ~exist('THRESH', 'var') || isempty(THRESH), THRESH=0; end
if size(B, 1)~=1, B=B'; end

%% INITIALIZE OUTPUT DISTRIBUTIONS
MAX_NULLDIST=[];
MAX_NULLCLUST=[];

%% INITIALIZE RANDOM NUMBER GENERATOR
rand('twister', sum(100*clock)); 

%% CONSTRUCT MAXIMUM NULL DISTRIBUTION
% DIM=size(NDIST);
for i=1:N    
    
    %% NEED TO CHECK THIS RESHAPE CALL! MAKE SURE SHIT IS BEING RESHUFFLED
    %% CORRECTLY! Make sure the ERPs look right in the end. 
    ndist=B.*[ones(size(B,1),1)*sign(rand(size(B,2),1)-.5)']; 
    
    ndist=corr(ndist', DV); 
            
    % Find maximal absolute value
    MAX_NULLDIST(end+1,1)=max(abs(ndist));
    
    % Find maximum CLUSTER
    [CLUST_MAP CLUST_VAL]=PermTest_cluster(ndist, CLUST_DIM, THRESH); 
    
    % Maximum absolute value here allows us to test both tails against the
    % same null distribution. 
    MAX_NULLCLUST(end+1,1)=max(abs(CLUST_VAL)); 
end % i=1:N