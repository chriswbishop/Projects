%% function master_batch
%   This function allows an m-file written for single-file analysis to be
%   used as a batch file, so you can avoid having to modify an existing 
%   m-file for use as a batch file.  For example:
%       >> Meeg2ascii(fileName) 
%     requires a manual command line entry for each file to be analyzed
%  
%   master_batch.m uses a list of file names to perform the analysis for
%   the files listed in the .txt file
%
%   read inFileList which has lines of input files 
%    e.g., )  fileName1
%             fileName2
%              ...
%   Get the filenames one at a time, send them to a function as an input
%   argument.
%
%   If additional input arguments are used at the command line, 
%   they will be passed along as input arguments to the function that is
%   called.
%      
%   usage examples:
%    >> master_batch ('master_batch_test', 'fileName_list_500Hz.txt')
%    >> master_batch ('master_batch_test', 'fileName_list_500Hz.txt', 999, 'blah')
%
%  by C Clinard, May 2009
%%
function master_batch (function_name, inFileList, varargin)
%
% Useage example master_batch ('master_batch_test', 'fileName_list_500Hz.txt')
%
%% define Path and input arguments
p = 'F:\Tera\Proj M\';
% p = cd;

optargin = size(varargin,2);  % number of optional arguments from varargin
stdargin = nargin - optargin; % number of standard input arguments

%% Open inFileList, the batch list OR the single file name
in_file_list = [p, inFileList];
fprintf('\n opening input list file %s \n ', in_file_list)
fid = fopen(in_file_list, 'r');             % Open a file for reading
if fid < 0                                  % fid == -1 means "cannot open"
	fprintf(2,['Error: File ' in_file_list ' not found\n']);  
	return;
end;
%% Begin batch processing

while feof(fid) == 0 % tests for end of file, feof == 1 means end of file
    
    fline = fgetl(fid);  % "fgetl" gets a line from the file given by fid
    if isempty(fline)    % stop processing when an empty line is reached
        return;
    end

    fileName = [p, fline];        % use as file name during the loop
    fprintf('\n opening inFile %s \n\r ', fileName)

%%  Do this to each file in the list of filenames
    if optargin ==0 
       s = [function_name ' (fline)' ];
    else % if there are input arguments in the command line, send 'em along
       s = [function_name ' (fline, varargin{:})' ];
    end
    
    eval(s)         % call the function
%%  
end;

fclose(fid);
