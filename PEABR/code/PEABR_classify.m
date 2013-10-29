function [results cp data PERF]=PEABR_classify(args)
%% DESCRIPTION:
%
%   Perform classification on data.  This performs a leave-One Out
%   classification scheme. This is done using a cross-validation scheme for
%   a set number of iterations.  
%
% INPUT:
%
%   args.
%       BINS:       2x1 cell array, each cell contains the bin information
%                   for trial types to be included.
%       T:          2xN array, time range in each row (e.g. T=[[0 10]; [10 20]])
%                   Feature space is created by averaging amplitude over
%                   each time window. 
%       REPS:       Integer, number of cross-validation iterations.  
%       CHANNELS:   Integer array, channels to include (note, this might 
%                   not work properly with multiple channels until I spend
%                   more time with this). 
%       REJ:        flag, reject trials (1=reject 0=include; default=1);
%       CHUNK:      integer, number of trials to average over (default 1) 
%       SCALE:      flag, do scaling? This performs a basic data
%                   normalization scaling (i.e. divisive scaling)
%       SVM:        flag, use Support Vector Machine (default 0)
%       KERNEL:     string, only applies to SVM. Defines the Kernel to be
%                   used by the classifier. Defaults to whatever libSVM
%                   uses.
%
% OUTPUT:
%
%   results:    holdover from GAB stuff...I've never actually seen a
%               practical use for this.
%   cp:         classifier data. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% ASSUME EEG IS ALREADY LOADED
global EEG;

%% DEFAULTS
if ~isfield(args, 'SVM') || isempty(args.SVM), args.SVM=0; end
if ~isfield(args, 'KERNEL') || isempty(args.KERNEL), args.KERNEL=[]; end 

%% GET GROUP 1 DATA
display('Getting Group 1 Data');
[G1]=MSPE_ERPLAB_getbindata(EEG, args.BINS{1}, args.REJ);

%% GET GROUP 2 DATA
display('Getting Group 2 Data'); 
[G2]=MSPE_ERPLAB_getbindata(EEG, args.BINS{2}, args.REJ);

%% AVERAGE DATA OVER CHANNELS
%   LIBSVM requires data to be in DOUBLE format. I think EEGLAB stores as
%   singles. Caste as a different data type. 
display('Averaging Over Channels');
G1=double(squeeze(mean(G1(args.CHANNELS,:,:),1))'); 
G2=double(squeeze(mean(G2(args.CHANNELS,:,:),1))'); 

%% TRIM DATA
%   This will trim each group to a evenly divisible number of trials.
display('Trimming Data'); 
G1=G1(1:floor(size(G1,1)./args.CHUNK)*args.CHUNK,:); 
G2=G2(1:floor(size(G2,1)./args.CHUNK)*args.CHUNK,:); 

%% NOW AVERAGE OVER CONSECUTIVE TRIALS
display(['Averaging over ' num2str(args.CHUNK) ' trials.']);
% G1
IND=1:args.CHUNK:size(G1,1);
for i=1:length(IND)
    g1(i,:)=mean(G1(IND(i):IND(i)+args.CHUNK-1,:),1);
end % i
G1=g1; 

% G2
IND=1:args.CHUNK:size(G2,1);
for i=1:length(IND)
    g2(i,:)=mean(G2(IND(i):IND(i)+args.CHUNK-1,:),1);
end % i
G2=g2; 

clear g1 g2; 

%% CREATE TIME BINS
%   Average over time windows, minimizes redundancy and feature space.
display('Extracting Features'); 
for t=1:size(args.T,1)
    T=args.T(t,:);
    IND=find(EEG.times<=T(1), 1, 'last') : find(EEG.times<=T(2), 1, 'last'); 
    data(1:size(G1,1),t)=mean(G1(:,IND),2); 
    data(size(G1,1)+1:size(G1,1)+size(G2,1),t)=mean(G2(:,IND),2);
end % t

%% CREATE GROUPING VARIABLE
groups=[ones(size(G1,1),1); 2.*ones(size(G2,1),1)];

%% DATA SCALING
%   This is important apparently, but I dunno precisely why.  Decided to
%   include this as an optional step since it seems that the classifier
%   might automatically do some scaling anyway ... not sure though. 
if args.SCALE
    display('Data scaled!'); 
    S=max(max(abs(data)));
    data=data./S; % normalize data
end 

%% CREATE CLASSIFIER OBJECT
display('Classifying'); 
cp = classperf(groups);

if args.SVM
    for i=1:args.REPS
        %% DISPLAY PERCENT COMPLETE
        %   Useful for command line so user knows what stage things are at.
        if ~mod(i./args.REPS*100, 10)
            display(['Classification ' num2str(i./args.REPS*100) '% Complete']);
        end % if ~mod ...
        [train test]=crossvalind('LeaveMOut',size(groups,1),1); 
        svmStruct=svmtrain(data(train,:), groups(train), 'KERNEL_FUNCTION', 'rbf'); 
        classes=svmclassify(svmStruct,data(test,:)); 
        classperf(cp,classes,test);
        PERF(i,1)=cp.CorrectRate;
    end % for i
else
    %% DON'T USE SVM
    
    for i = 1:args.REPS
        
        %% DISPLAY PERCENT COMPLETE
        %   Useful for command line so user knows what stage things are at.
        if ~mod(i./args.REPS*100, 10)
            display(['Classification ' num2str(i./args.REPS*100) '% Complete']);
        end % if ~mod ...
        
        %
        [train test]=crossvalind('LeaveMOut',size(groups,1),1); 
        class = classify(data(test,:),data(train,:),groups(train,:));
        classperf(cp,class,test);
        PERF(i,1)=cp.CorrectRate;
    end
end % if args.SVM

results='done';

% %% CREATE DATA INPUT FOR SVM
% % data=[G1;G2];
% % groups=[ones(size(G1,1),1); 2.*ones(size(G2,1),1)];
% 
% %% REMOVE OUTLIERS?
% %   Looking at the data here, it seems that there are some obvious outliers
% %   that might confuse things.  Might be good to toss extreme values. 
% %
% %   Coming back to this, it looks like the single trial estimates are just
% %   too noisy, averaging of some kind might be a better way to get around
% %   things. Or, alternatively, applying a more liberal rejection criterion
% %   might work. 
% 
% 
% 
% 
% % Create a 10-fold cross-validation to compute classification error.
% indices = crossvalind('Kfold',groups,10);
% % cp = classperf(groups);
% % for i = 1:100
% %     test = (indices == i); train = ~test;
% %     class = classify(data(test,:),data(train,:),groups(train,:));
% %     classperf(cp,class,test);
% %     PERF(i,1)=cp.CorrectRate;
% % end
% % cp.ErrorRate
% % 
% % for i=1:length(unique(indices))
% %     test=(indices==i); train = ~test; 
% %     svmStruct=svmtrain(data(train,:), groups(train), 'KERNEL_FUNCTION', 'rbf'); 
% %     classes=svmclassify(svmStruct,data(test,:)); 
% %     classperf(cp,classes,test);
% %     PERF(i)=cp.CorrectRate;
% % end % i
% % Try using RBF Kernel non-linear kernel)
% cp = classperf(groups);
% [train, test] = crossvalind('holdout',groups,0.25);
% svmStruct = svmtrain(data(train,:),groups(train), 'KERNEL_FUNCTION', 'rbf', 'showplot', true);
% 
% classes = svmclassify(svmStruct,data(test,:),'showplot',true);
% classperf(cp,classes,test);
% cp.CorrectRate
% 
% %% 
% [train, test] = crossvalind('holdOut',groups);
%  cp = classperf(groups);
