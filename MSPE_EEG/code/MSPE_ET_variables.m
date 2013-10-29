function MSPE_ET_variables(P, FNAME)
%% DESCRIPTION:
%
%   Function to create message list to send to DataViewer software to
%   overwrite variables in EDF files.  Only use this if you have some sort
%   of issue with variable values not being set properly by default (this
%   occured for MSPE_EEG_Pilot02).
%   
% INPUT:
%
%   P:  string, matrix of filenames to create output for OR full path to
%       mat-file with data you want to use in it.  
%
%   FNAME:  string, output file name.
%
% OUTPUT:
%
%   Tab delimited text file with the following form:
%       Column 1:   MSG
%       Column 2:   -1, -2, ... -{trial number}
%       Column 3:   !V TRIAL_VAR
%       Column 4:   variable list (currently CONDITION NRESP SRESP)
%
% Bishop, Chris Miller lab 2010

%% LOAD VARIABLES
try 
    load(P, 'COND', 'SRESP', 'NRESP');
catch
    [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y]=MSPE_read(P);
end % 

FPTR=fopen(FNAME, 'w'); 

for i=1:length(COND)
    fprintf(FPTR, 'MSG\t');
    fprintf(FPTR, ['-' num2str(i) '\t']); 
    fprintf(FPTR, '!V TRIAL_VAR\t');
    fprintf(FPTR, ['CONDITION ' num2str(COND(i))]);
    fprintf(FPTR, '\n');
    fprintf(FPTR, 'MSG\t');
    fprintf(FPTR, ['-' num2str(i) '\t']); 
    fprintf(FPTR, '!V TRIAL_VAR\t');
    fprintf(FPTR, ['NRESP ' num2str(NRESP(i))]);
    fprintf(FPTR, '\n');
    fprintf(FPTR, 'MSG\t');
    fprintf(FPTR, ['-' num2str(i) '\t']); 
    fprintf(FPTR, '!V TRIAL_VAR\t');
    fprintf(FPTR, ['SRESP ' num2str(SRESP(i))]);
    fprintf(FPTR, '\n');
end % i

fclose(FPTR);