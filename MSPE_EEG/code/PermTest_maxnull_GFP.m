function [MAX_NULLDIST MAX_NULLCLUST]=PermTest_maxnull_GFP(NDIST, N, CLUST_DIM, THRESH)
%% DESCRIPTION:
%
%   Function to create maximum null distribution based on Mean Global Field
%   Potential (GFP).  Mean GFP is calculated by permuting subject specific
%   data, calculating the group average ERP, and calculating the Mean GFP
%   based on the group average ERP. The maximum null distribution is
%   constructed in one of two ways:
%
%       1. based on the maximum GFP (std) across all time (default)
%       2. based on the maximum summed test statistic over clustered data.
%          I haven't written this little diddy yet. 
%
%   These procedures are described in detail in:
%
%   1. Maris, E. and R. Oostenveld (2007). "Nonparametric statistical 
%      testing of EEG- and MEG-data." J Neurosci Methods 164(1): 177-190.
%
% INPUT:
%
%   NDIST:  CxTxS matrix, where C is the number of sensors, T is the number
%           of time-points, and S is the number of subjects.
%   N:      Integer, number of permutations
%   CLUST_DIM:  which dimension(s) to cluster along
%   THRESH: double, threshold cutoff for clustering. 
%
% OUTPUT:
%
%   MAX_NULLDIST:   Maximum null distribution.
%   MAX_NULLCLUST:  Maximum clustered distribution. 
%
%   Notes:
%
%       Need to figure out a way to add in clustering and clustering
%       thresholds. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% CHECK INPUTS
if ~exist('N', 'var') || isempty(N), N=10; end
if ~exist('CLUST_DIM', 'var') || isempty(CLUST_DIM), CLUST_DIM=1; end
if ~exist('THRESH', 'var') || isempty(THRESH), THRESH=0; end

%% INITIALIZE OUTPUT DISTRIBUTIONS
MAX_NULLDIST=[];
MAX_NULLCLUST=[];

%% INITIALIZE RANDOM NUMBER GENERATOR
rand('twister', sum(100*clock)); 

%% CONSTRUCT MAXIMUM NULL DISTRIBUTION
DIM=size(NDIST);
for i=1:N    
    
    %% NEED TO CHECK THIS RESHAPE CALL! MAKE SURE SHIT IS BEING RESHUFFLED
    %% CORRECTLY! Make sure the ERPs look right in the end. 
    ndist=reshape(NDIST, prod(DIM(1:2)), DIM(3)); 
    
    % Permute sign of NDIST
    s=ones(size(ndist,1),1)*sign(rand(size(ndist,2),1)-.5)'; 
    
    % Modify NDIST
    ndist=(s.*ndist);    
    ndist=mean(ndist,2);

    % Back to Sensor X Time space
    ndist=reshape(ndist, DIM(1), DIM(2));
    ndist=std(ndist,0,1);
    
    % Find maximal absolute value
    MAX_NULLDIST(end+1,1)=max(abs(ndist));
    
    % Find maximum CLUSTER
    [CLUST_MAP CLUST_VAL]=PermTest_cluster(ndist, CLUST_DIM, THRESH); 
    
    % Maximum absolute value here allows us to test both tails against the
    % same null distribution. 
    try
        MAX_NULLCLUST(end+1,1)=max(abs(CLUST_VAL)); 
    catch
        MAX_NULLCLUST(end+1,1)=NaN; % why did I put a NaN in here? Maybe if we're only testing a single point, so no clusters?
    end % try
end % i=1:N