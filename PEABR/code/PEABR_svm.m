function [results]=PEABR_svm(args)
%% DESCRIPTION:
%
%   Perform SVM classification on data.
%
% INPUT:
%
%   args.
%       BINS:       2x1 cell array, each cell contains the bin information
%                   for trial types to be included.
%       T:          2xN array, time range in each row (e.g. TIME=[0 10])
%       REPS:       Integer, number of cross-validation iterations.
%       CHANNELS:   Integer array, channels to include (note, this might 
%                   not work properly with multiple channels until I spend
%                   more time with this). 
%       REJ:        flag, reject trials (1=reject 0=include; default=1);
%
% OUTPUT:
%
%


%% ASSUME EEG IS ALREADY LOADED
global EEG;

%% CHECK INPUTS
% REJ
% REPS

% Convert T to samples
% args.T=find(EEG.times<=args.T(1), 1, 'last') : find(EEG.times<=args.T(2), 1, 'last'); 

%% GET GROUP 1 DATA
[G1]=MSPE_ERPLAB_getbindata(EEG, args.BINS{1}, args.REJ);

%% GET GROUP 2 DATA
[G2]=MSPE_ERPLAB_getbindata(EEG, args.BINS{2}, args.REJ);

%% TRIM DATA
G1=double(squeeze(G1(args.CHANNELS,:,:))'); 
G2=double(squeeze(G2(args.CHANNELS,:,:))'); 

%% CREATE TIME BINS
%   Average over time windows, minimizes redundancy and feature space.
for t=1:size(args.T,1)
    T=args.T(t,:);
    IND=find(EEG.times<=T(1), 1, 'last') : find(EEG.times<=T(2), 1, 'last'); 
    data(1:size(G1,1),t)=mean(G1(:,IND),2); 
    data(size(G1,1)+1:size(G1,1)+size(G2,1),t)=mean(G2(:,IND),2);
end % t
groups=[ones(size(G1,1),1); 2.*ones(size(G2,1),1)];

%% CREATE DATA INPUT FOR SVM
% data=[G1;G2];
% groups=[ones(size(G1,1),1); 2.*ones(size(G2,1),1)];

%% REMOVE OUTLIERS?
%   Looking at the data here, it seems that there are some obvious outliers
%   that might confuse things.  Might be good to toss extreme values. 

%% DATA SCALING
%   This is important apparently, but I dunno precisely why.
% S=max(abs(data)); 
% S=(ones(size(data,1),1)*S); 
S=max(max(abs(data)));
data=data./S; % normalize data



% Create a 10-fold cross-validation to compute classification error.
indices = crossvalind('Kfold',groups,10);
% cp = classperf(groups);
% for i = 1:100
%     test = (indices == i); train = ~test;
%     class = classify(data(test,:),data(train,:),groups(train,:));
%     classperf(cp,class,test);
%     PERF(i,1)=cp.CorrectRate;
% end
% cp.ErrorRate
% 
% for i=1:length(unique(indices))
%     test=(indices==i); train = ~test; 
%     svmStruct=svmtrain(data(train,:), groups(train), 'KERNEL_FUNCTION', 'rbf'); 
%     classes=svmclassify(svmStruct,data(test,:)); 
%     classperf(cp,classes,test);
%     PERF(i)=cp.CorrectRate;
% end % i
% Try using RBF Kernel non-linear kernel)
cp = classperf(groups);
[train, test] = crossvalind('holdout',groups,0.25);
svmStruct = svmtrain(data(train,:),groups(train), 'KERNEL_FUNCTION', 'rbf', 'showplot', true);

classes = svmclassify(svmStruct,data(test,:),'showplot',true);
classperf(cp,classes,test);
cp.CorrectRate

%% 
[train, test] = crossvalind('holdOut',groups);
 cp = classperf(groups);
results='done';