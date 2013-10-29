function [MAX_NULLDIST MAX_NULLCLUST]=PermTest_maxnull(NDIST, N, CLUST_DIM, CLUST_THRESH, EXACT)
%% DESCRIPTION:
%
%   Performs permutation on data several ways. Notably, this includes a
%   maximal null distrubtion method for correction for multiple
%   comparisons.  To perform hypothesis testing using such a distribution,
%   see PermTest_htest.m.
%
%   The general procedure is discussed in 
%
%   1.  Nichols, TE and AP Holmes (2002). "Nonparametric permutation tests
%       for functional neuroimaging: a primer with examples." Hum Brain
%       Mapp 15(1): 1-25
%
%   Also, the specific methods used to construct and apply the maximual
%   null distribution were derived from the following two references. 
%
%   2.  Chau, W., A.R. McIntosh et al. (2004). "Improving permutation test
%       power for group analysis of spatially filtered MEG data."
%       Neuroimage 23(3): 983-996
%   3.  Shahin, AJ, LE Roberts et al. (2008). "Music training leads to the
%       development of timbre-specific gamma band activity." Neuroimage
%       41(1): 113-122
%
% INPUT:
%
%   NDIST:  MxS data matrix, with M corresponding the the number of data
%           points for a given subject, and S corresponding to the number
%           of subjects.
%   N:      Number of permutations used to construct null distribution.
%   CLUST_DIM:  integer, clustering dimension (really only works with 1
%               right now).
%   CLUST_THRESH:   threshold level for clustering (see PermTest_cluster for
%                   details; default=0)
%
%   EXACT:  bool, specifies whether or not to construct an exact null
%           distribution using the 2^S possible sign combinations. (default
%           = false). NOTE: setting EXACT to TRUE will override the value
%           of N.
% OUTPUT:
%
%   MAX_NULLDIST:   Maximal null distribution.
%
%   MAX_NULLCLUST:  maximal clustered distribution
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% CHECK INPUTS
if ~exist('N', 'var') || isempty(N), N=10; end
if ~exist('CLUST_DIM', 'var') || isempty(CLUST_DIM), CLUST_DIM=1; end
if ~exist('CLUST_THRESH', 'var') || isempty(CLUST_THRESH), CLUST_THRESH=0; end
if ~exist('EXACT', 'var') || isempty(EXACT), EXACT=false; end

% If we are using the exact method, then reset N
if EXACT, N=2^size(NDIST,2); R=0:N-1; else R=1:N; end

%% INITIALIZE OUTPUT DISTRIBUTIONS
MAX_NULLDIST=[];
MAX_NULLCLUST=[];

%% INITIALIZE RANDOM NUMBER GENERATOR
rand('twister', sum(100*clock)); 

%% CONSTRUCT MAXIMUM NULL DISTRIBUTION
for i=R   
    s=[];
    % Permute sign of NDIST
    if EXACT
        
        % Create a binary string
        str=dec2bin(i, size(NDIST,2));
        
        % Convert string to an integer array
        for j=1:length(str)
            s(j)=str2num(str(j));
        end %
        
        % Replace zeros with -1
        s(s==0)=-1;
        
        % Match dimensions
        s=ones(size(NDIST,1),1)*s; 
    else
        s=ones(size(NDIST,1),1)*sign(rand(size(NDIST,2),1)-.5)'; 
    end % if EXACT
    
    % Modify NDIST
    ndist=(s.*NDIST);
    ndist=mean(ndist,2);

    % Find maximal absolute value
    MAX_NULLDIST(end+1,1)=max(abs(ndist));
    
    % Find maximal cluster value
    [CLUST_MAP CLUST_VAL]=PermTest_cluster(ndist, CLUST_DIM, CLUST_THRESH); 
    try
        MAX_NULLCLUST(end+1,1)=max(abs(CLUST_VAL)); 
    catch
        MAX_NULLCLUST(end+1,1)=NaN; % why did I put a NaN in here? Maybe if we're only testing a single point, so no clusters?
    end % try
end % i=1:N