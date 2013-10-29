function [CLUST_MAP CLUST_VAL]=PermTest_cluster(DATA, CLUST_DIM, THRESH)
%% DESCRIPTION:
%
%   Function to identify adjacent clusters in arbitrary data.  Can perform
%   clustering over several dimensions through a recursive call.
%
%   Currently has only been tested clustering along the first dimension.
%
% INPUT:
%
%   DATA:   matrix, data matrix. Arbitrary dimension.
%   DIM:    integer array, dimensions of DATA to cluster over.
%   THRESH: double, threshold value used to define positively and
%           negatively signed clusters.
%
% OUTPUT:
%
%   CLUST_MAP:  cell array of cluster maps. Act as a (signed) mask of DATA.
%   CLUST_VAL:  double array, integrated value of each cell of CLUST_MAP.
%   
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS:
% Cluster along first dimension by default
if ~exist('CLUST_DIM', 'var') || isempty(CLUST_DIM), CLUST_DIM=1; end 
% Set THRESHOLD to 0 by default
if ~exist('THRESH', 'var') || isempty(THRESH), THRESH=0; end

%% OUTPUT VARIABLES
CLUST_MAP={}; 
CLUST_VAL=[];

%% DATA DIMENSIONS
DIM=size(DATA); 

%% ASSIGN SIGN TO ALL DATA POINTS ALONG FIRST DIMENSION
DATA=DATA-THRESH; % important to do this so negative/positve values relative to threshold are preserved. 
S=sign(DATA); 

%% FIND CLUSTER EDGES
dS=diff(S); 
dSi=find(dS~=0);

for i=1:length(dSi)
    CLUST_MAP{end+1}=zeros(size(DATA));
    
    if i==1 && length(dSi)>1
        CLUST_MAP{end}(1:dSi(i))=S(1:dSi(i)); 
    elseif i==1 && length(dSi)==1
        
        %% Obnoxious case when there is only one change in the waveform.
        CLUST_MAP{end}(1:dSi(i))=S(1:dSi(i));
        CLUST_VAL(length(CLUST_MAP),1)=sum(DATA.*abs(CLUST_MAP{end})); 
        
        CLUST_MAP{end+1}=zeros(size(DATA));
        CLUST_MAP{end}(dSi(i)+1:length(DATA))=S(dSi(i)+1:length(DATA));
    elseif i==length(dSi) % do something slightly different for the end
%         CLUST_MAP{end+1}=zeros(size(DATA));
        CLUST_MAP{end}(dSi(i)+1:length(DATA))=S(dSi(i)+1:length(DATA));
        CLUST_VAL(length(CLUST_MAP),1)=sum(DATA.*abs(CLUST_MAP{end}));
        
        CLUST_MAP{end+1}=zeros(size(DATA));
        CLUST_MAP{end}(dSi(i-1)+1:dSi(i))=S(dSi(i-1)+1:dSi(i));
    else
        CLUST_MAP{end}(dSi(i-1)+1:dSi(i))=S(dSi(i-1)+1:dSi(i));
    end % if 
    CLUST_VAL(length(CLUST_MAP),1)=sum(DATA.*abs(CLUST_MAP{end})); 
end % i

% Special case with no inflection points detected.  This occurred often
% when doing permutation tests for PEABR project.
if isempty(CLUST_MAP)
    CLUST_MAP{1}=S; 
    CLUST_VAL(length(CLUST_MAP),1)=sum(DATA.*abs(CLUST_MAP{end})); 
end % if length(CLUST_MAP==1)
%% SORT OUTPUT
[CLUST_VAL I]=sort(CLUST_VAL);
CLUST_MAP={CLUST_MAP{I}}; 