% Now, for each cluster, do a permutation test
OUT_H=[]; OUT_PCLUST=[];
for i=1:length(CLUST_MAP)
    display([num2str(i) ' of ' num2str(length(CLUST_MAP))]);
    
	% Define the time mask for cluster
	%  This allows us to mask the time waveform for each subject so we are only looking at the time course of the appropriate cluster.
	mask=logical(abs(CLUST_MAP{i}));
	
	
	% Create max null (Cluster)
	%  Returns a maximum null distribution and a maximum null (cluster) distribution.  The latter is what I'm interested in using since it is most informative (treats like signed, consecutive time points together rather than separately.  
	% This is done for each CLUSTER individually.  
	[MAX_NULLDIST MAX_NULLCLUST]=PermTest_maxnull(Y(mask,:), N, CLUST_DIM, CLUST_THRESH, true); % notice the EXACT is set to true here
	
	% Test hypothesis
	[H t NULLDIST mP mC pT clust_map CLUST_VAL CLUST_H pCLUST]=PermTest_htest(mean(Y(mask,:),2), MAX_NULLCLUST, 0.05, CLUST_DIM, CLUST_THRESH);
	
	OUT_H(i,:)=CLUST_H; OUT_PCLUST(i,:)=pCLUST;

end % i
