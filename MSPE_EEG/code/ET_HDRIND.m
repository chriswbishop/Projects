function [INDEX]=ET_HDRIND(HDR, FLD)
%% DESCRIPTION:
%
%   Identify which column a specified header is in a file. Returns an index
%   to the correct column of data. 
%
% INPUT:
%
%   HDR:    HDR can take two forms. Either will work just about as fast.
%               1. A name (including path) of a file whose header you would
%               like to read in.
%               2. A HDR cell array returned from ET_read.m. 
%   FLD:    String (e.g. 'RIGHT_GAZE_X') of field user would like to find.
%
% OUTPUT:
%
%   INDEX:  integer, the column number the specified header field can be
%           found at.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% VARIABLES
INDEX=[]; 

%% GET HEADER
try     
    [DATA HDR EX]=ET_read(HDR, [], [], 0); % just read headers
catch
    %% ASSIGN HEADER
    %   If we can't read in the data, assume it's the actual header.
%     display('Assuming this is a HDR.');        
end % try catch

%% FIND HEADER INDEX 
for i=1:length(HDR)
    if ~isempty(strmatch(HDR{i}, FLD))
        INDEX(end+1,1)=i;  %#ok<*AGROW>
    end % if 
end % for 
