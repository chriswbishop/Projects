function [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME ...
    SRATE NRATE RESP RT SCON]=MSPE_analysis(P)
%% DESCRIPTION:
%
%   Code to analyze subject specific data for MSPE and PEA. 
%
% INPUT:
%
%   P:  character matrix, each row is the path to a logfile.  If subject
%       has more than one logfile, then vertically concatenate the
%       pathnames using strvcat.  Absolute or relative paths may be used.
%
%       Alternatively, P can be a string to a MAT-file containing the
%       output from MSPE_read.m.  If this string cannot be loaded, then
%       script assumes it's a logfile and tries to read in the data.
%
% OUTPUT:
%
%   SRATE:  Suppresion RATE, Cx2 matrix, where C is the number of
%           conditions.  First column is the number of ONE responses.
%           Second column is the total number of responses (excludes
%           misses).  Data based on response to number of locations. Poorly
%           named variable. Should probably change it eventually. 
%
%   NRATE:  I don't remember why I named this variable NRATE, but it is an
%           CxRx2 matrix, where C is the number of conditions and R is the
%           number of possible responses (3 at the moment).  The third
%           dimension holds the total number of a specific response (1) and
%           the total number of responses (2, excludes misses).  
%
%   RESP:   RESPonse data, CxRx2, where C is the number of conditions, R is
%           the total number of response combinations (including Side and
%           Number of Locations, total of 6 at the moment). Third dimension
%           stores the number of times a subject responded with a specific
%           response combination (1, e.g., both sides, two locations) and
%           the total number of responses in response to a specific
%           stimulus configuration (e.g. right leading sound).  This
%           variable is really just a detailed version of SRATE and NRATE,
%           but each provides slightly different insight.
%       
%   RT:     Reaction Time data, same dimensions as RESP.  RTs stored in
%           milliseconds.  
%
%   For all other output, see MSPE_read.m.
%
% Bishop, Chris Miller Lab 2010

%% LOAD DEFAULTS
MSPE_DEFS;

%% LOAD DATA
%   Either load it from a mat file or create from logfile.
try 
    load(P);
catch
    [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME]=MSPE_read(P);
end % try catch

%% PARSE SUBJECT DATA
%   
for c=1:length(rCOND)
    SRATE(c,1)=length(find(NRESP(find(COND==c))==1));
    SRATE(c,2)=length(find(NRESP(find(COND==c))~=0)); % exclude misses
    
    % Number of Locations response (1 or 2)
    for z=1:2
        % Side Response (3,4, or 5)
        for i=1:3
            NRATE(c,i,1)=length(find(SRESP(find(COND==c))==i+2));
            NRATE(c,i,2)=length(find(SRESP(find(COND==c))~=0)); % exclude misses    
            RESP(c,((z-1)*3)+i,1)=...
                length( find(COND==c & NRESP==z & SRESP==i+2));
            RESP(c,((z-1)*3)+i,2)=length( find(COND==c & NRESP~=0 & SRESP~=0));
            RT(c,((z-1)*3)+i,1)=sum( SRT(find(COND==c & NRESP==z & SRESP==i+2)));
            RT(c,((z-1)*3)+i,2)=length( find(COND==c & NRESP==z & SRESP==i+2));
        end % i=3:5
    end % z
end % c

%% CONTEXT EFFECT ANALYSIS
%   Here, we're trying to look at how context effects from a previous trial
%   affects suppression rates (as measured by SRATE).
%
%   SCON(c,i,X,Y):  
SCON=zeros(length(rCOND), length(rCOND), 2, 2); 
% for i=2:length(COND)
%     if NRESP(i)~=0 && NRESP(i-1)~=0
%     SCON(COND(i), COND(i-1), NRESP(i-1), NRESP(i))=...
%         SCON(COND(i), COND(i-1), NRESP(i-1), NRESP(i))+1;
%     end % NRESP(i)~=0
% end % i