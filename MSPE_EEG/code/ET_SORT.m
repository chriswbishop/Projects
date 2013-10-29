function [SDATA]=ET_SORT(DATA, HDR, FLD)
%% DESCRIPTION:
%
%   This function sorts a data matrix according to a specific column in the
%   data.  For instance, if 'TRIALN' is used, the data will be broken up
%   into a cell array with each element of the array containing all the
%   data within one continuous value of TRIALN.  This might not be clear,
%   but read on, it should make more sense.
%
% INPUT:
%
%   DATA:   DATA matrix returned from ET_read
%   HDR:    HDR structure returned from ET_read
%   EX:     EX data returned from ET_read
%   FLD:    string, field name of HDR field to sort data by (e.g.
%           the default 'TRIAL_INDEX').
%           *NOTE* Must be careful to pick values that change at trial
%           boundaries. If you don't, sorted data won't make any sense.
%
% OUTPUT:
%
%   SDATA:  cell array, each element is a chunk of the data from DATA
%           matrix (e.g. with default settings, each cell contains the data
%           of a single trial). 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
if ~exist('FLD', 'var') || isempty(FLD), FLD='TRIAL_INDEX'; end 

%% WHICH COLUMN DO WE SORT BY?
%   Need to figure out which column of DATA corresponds to FLD.
[IND]=ET_HDRIND(HDR, FLD); 
REF=DATA(:,IND); 

%% FIND RUNS OF VALUES OF REF
D=diff(REF); 
DIND=find(D~=0); 

%% ASSIGN DATA TO SDATA
for i=1:length(DIND)
    if i==1
        SDATA{i}=DATA(1:DIND(i),:);
    else
        SDATA{i}=DATA(DIND(i-1)+1:DIND(i),:); 
    end % if i==1
    
    % Found a small bug where the last entry of data was being skipped.
    % Counting is hard. 
    if i==length(DIND)
        SDATA{i+1}=DATA(DIND(i)+1:end,:); 
    end % i
end % i=DIND