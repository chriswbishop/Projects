function [DATA]=MSPE_ERPLAB_getbindata(EEG, BINS, REJ)
%% DESCRIPTION:
%
%   This function is designed to grab (epoched) data from an EEG structure
%   whose EVENTLIST field has been populated with ERPLAB to included
%   BINLABELs.  
%
% INPUT:
%
%   EEG:    EEG structure.
%   BINS:   double array, bin numbers
%   BL:     2x1 double, time range for baselineing
%   REJ:    Integer, Rejection flag. 1=exclude rejected trials, 0=include
%           rejected trials (default=1)
%
% OUTPUT:
%
%   DATA:   CxTxN data matrix, where C=the number of channels, T=the number
%           of time points and N is the number of epochs.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu


%% DEFAULTS
if ~exist('REJ', 'var') || isempty(REJ), REJ=1; end
if ~exist('BL', 'var'), BL=[]; end

%% EXTRACT EPOCHS BASED ON BIN GROUPING
%   I stole some code from ERPLAB to figure out which trials are rejected.
% averager.m (80-
F = fieldnames(EEG.reject);
sfields1 = regexpi(F, '\w*E$', 'match');
sfields2 = [sfields1{:}];
fields4reject  = regexprep(sfields2,'E','');

DATA=[];
IND=[];
trls=0;
for i=1:length(EEG.EVENTLIST.eventinfo)
    bini=EEG.EVENTLIST.eventinfo(i).bini;
        
    % Flag set to 1 if included, set to 0 if rejected.
    %   Recall that rejection information is stored based on EPOCH
    %   information, not on individual eventinfo.
    bepoch=EEG.EVENTLIST.eventinfo(i).bepoch;
    try
        flag = eegartifacts(EEG.reject, fields4reject, bepoch);
    catch
        flag=0; % toss trial if we can't be sure it's OK.
    end; 
    
    if REJ==0, flag=1; end % include it if REJ is set to 0
    
    if ~isempty(find(ismember(bini, BINS),1)) && flag
        IND(end+1)=bepoch;
%         data=EEG.data(:,:,bepoch);
%         trls=trls+1;
        %% BASELINE?
%         DATA(:,:,trls)=data;
    end % if 
end % i

DATA=EEG.data(:,:,IND); 
trls=length(IND); 