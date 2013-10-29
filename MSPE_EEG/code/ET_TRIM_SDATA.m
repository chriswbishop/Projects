function [TSDATA TINDEX]=ET_TRIM_SDATA(SDATA, HDR, varargin)
%% DESCRIPTION:
%
%   Function will trim data entries in each entry of SDATA based on
%   field names and [min max] value range.  This is most practically used
%   to exclude data outside of a specified time range (e.g. [0 500]).
%   Any row satisfying any single exclusion criterion will be excluded
%   (i.e. exclusion decision based on a logical OR of exclusion criteria).
%   So, be careful. 
%
% INPUT:
%
%   SDATA:  cell array returned from ET_SORT.m
%   HDR:    cell array returned from ET_read.m 
%   varargin:   cell array, specifications for excluding rows of data.
%               Should be specified in pairs (e.g. 'TIMESTAMPS', [0 500]).
%               Units of parameter inputs should be 
%
% OUTPUT:
%
%   TSDATA: cell array, Trimmed SDATA. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% INPUT CHECK
if mod(length(varargin),2)~=0, error('Exclusion criteria must be in pairs (FLD, PARAMETER)'); end

%% SHOULD ROWS BE EXCLUDED?
for i=1:length(SDATA)
    data=SDATA{i};     
    for v=1:(length(varargin)/2)
        [TINDEX]=ET_HDRIND(HDR, varargin{1+(v-1)*2});         
        EX=find(data(:,TINDEX)>=varargin{2+(v-1)*2}(1) & data(:,TINDEX)<=varargin{2+(v-1)*2}(2));
        data=data(EX,:); 
    end % v   
    
    TSDATA{i}=data; 
end % i