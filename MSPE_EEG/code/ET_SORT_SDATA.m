function [SINDEX SSDATA]=ET_SORT_SDATA(SDATA, HDR, varargin)
%% DESCRIPTION:
%
%   Function to sort through an Sorted DATA (SDATA) cell array.  Will
%   return an SINDEX into SDATA.
%
%   I originally had much higher hopes for this function.  Specifically, I
%   was hoping to have some standardized way of returning the indexed SDATA
%   matrix to the user in a more useful format (I hate cell arrays).
%   However, the information stored in SDATA is too heterogenous to easily
%   put into a standard data format.  SO, that will have to be handled by
%   another function, I think.  Not 100% sure, this is all coming along
%   very slowly...
%
% INPUT:
%
%   SDATA:  Cell array returned from ET_SORT.m
%   HDR:    HDR returned from ET_read
%   varargin:   Pairs of specifications, FIELDNAME, then PARAMETER. (e.g.
%               'CONDITION', 4, 'NRESP', 1).  Will accept any arbitrary
%               number of specifications.
%
% OUTPUT:
%
%   SINDEX: Integer array, index into SDATA of cells that satisfy all the
%           selection criteria specified in varargin.
%
% NOTES:
%
%   1.  It would be really nice to be able to standardize the output of this
%       beast so data are returned in a much more usable format than the
%       silly cell arrays I have them in now. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% INPUT CHECK
% VARARGIN: First, if it's the wrong length, try grabbing the first cell.
if mod(length(varargin),2)~=0, varargin=varargin{1}; end %
% If that doesn't work, we don't know what it is. Do not pass go. Do write
% your own code.
if mod(length(varargin),2)~=0, error('Field Specs must be in pairs (FLD, PARAMETER)'); end

%% VARIABLES
SINDEX=[]; 

for i=1:length(SDATA)
    inc=1;
    for v=1:(length(varargin)/2)
        [INDEX]=ET_HDRIND(HDR, varargin{1+(v-1)*2}); 
        if isempty(find(ismember(SDATA{i}(:, INDEX), varargin{2+(v-1)*2})==1,1))
            inc=0; break;
        end % isempty
    end % v
    
    % Only return trial index if all criteria are satisfied. 
    if inc, SINDEX(end+1)=i; end
    
end % i

%% ASSIGN SORTED DATA TO OUTPUT
SSDATA={};
for i=1:length(SINDEX)
    SSDATA{i}=SDATA{SINDEX(i)}; 
end % i