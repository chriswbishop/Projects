function [DATA HDR EX]=ET_read(P, DV, DVINT, RDATA, CIV)
%% DESCRIPTION:
%
%   Generalized reading function that makes minimal assumptions about the
%   structure of the data. User can also tell ET_read how to interpolate
%   missing values (usually denoted as '.' in DataViewer generated files). 
%
% INPUT:
%
%   P:  character array, list of file names. Each row is a file name.
%   DV: Index for dependent variables (DV) (default DV=1; )
%   DVINT:  double or NaN, set missing (NaN) values of dependent measures
%           to this (default NaN)
%   RDATA:  flag, Read DATA (RDATA). (0=no data; 1=read data (default=1))
%   CIV:    flag, Clean Independent Variables (CIV). This specifies whether
%           or not data rows with missing independent variable data (e.g.
%           trial condition) are tossed before being returned to the user.
%           (0=all data returned; 1=data cleaned; default=1); 
%
% OUTPUT:
%
%   DATA:   imported information.
%   HDR:    Header information from imported file.
%   EX:     Integer array.  Excluded data due to missing independent data. 
%
% Bishop, Christopher W. 
%   UC Davis
%   Miller Lab 2011

%% DEFAULTS
if ~exist('DV', 'var') || isempty(DV), DV=1; end;
if ~exist('DVINT', 'var') || isempty(DVINT), DVINT=NaN; end % Replace missing data with NaNs be default.
if ~exist('RDATA', 'var') || isempty(RDATA), RDATA=1; end 
if ~exist('CIV', 'var') || isempty(CIV), CIV=1; end 

%% VARIABLES
HDR={};
DATA=[]; 
EX=[];

%% FILE SIZE
%   Count up the number of columns in the file (needed for textscan call
%   below).
ptr=fopen(P, 'r'); 
nl=fgetl(ptr); 
frewind(ptr); 
h='';
d='';
while ~isempty(nl)    
    [rmd, nl]=strtok(nl);
    h=[h '%s'];     
    d=[d '%f'];
end % while

%% HEADER
%   Assume first row is header information in file (default from SR
%   Research DataViewer export tool). 
HDR=textscan(ptr,h,1);

% Fix Header
%   Not sure why, but there are always 3 extra characters at the beginning
%   of these files. They don't show up in any other program...not sure what
%   it is. They're read into the first HDR field though, so we need to get
%   rid of them.
%
%   HM, this doesn't always happen either (see s2619's data). I don't
%   understand this.  There's gotta be something wonky going on with the
%   data files... no flippin clue what that might be. 
%
%   Whatever it is, it seems to be predictably a '﻿' (ASCII 239 187 191).
%   So, check for that, and skip if necessary. 
if ~isempty(cell2mat(strfind(HDR{1}, '﻿'))) 
    tmphdr=cell2mat(HDR{1}); 
    HDR{1}={tmphdr(4:end)}; 
end % if strcmp 

%% READ IN DEPENDENT AND INDEPENDENT DATA
%   If data are missing ('.'), replace it with a NaN.
if RDATA
    data=textscan(ptr, d, 'TreatAsEmpty', '.'); 
end % RDATA

%% CLOSE FILE
%   Booo for memory leaks!
fclose(ptr);

%% EXCLUDE DEPENDENT DATA WITH UNSPECIFIED INDEPENDENT VARIABLES
%   This often happens if communication is severed between the host and
%   display PC during data collection. Recall that missing data are 
%   saved as '.' by SR-Research's DataViewer software, but we replace all
%   the '.' values with a NaN.
if RDATA % Only need to do this if user wants the data read in. 
    %% DETERMINE INDEPENDENT VARIABLES
    %   All non-dependent variables are assumed to be independent (predictors).
    IV=1:length(data);
    IV=IV(~ismember(IV,DV));
    
    %% CLEAN UP THE DATA
    %   Data are removed if independent variables are missing (e.g. no
    %   trial condition information).  This is only done if the user
    %   specifies it. 
    if CIV
        for i=IV
%             EX=[EX; strmatch('.', data{i})]; 
            EX=[EX; find(isnan(data{i}))];
        end % i    
        EX=unique(EX); 
    end % CIV
    in=~ismember(1:length(data{1}), EX); 

    %% MOVE INDEPENDENT DATA TO DATA    
    for i=IV
    %     DATA(:,i)=str2num(data{i});  %#ok<*AGROW>
        DATA(:,i)=data{i}(in); 
    end % i

    %% MOVE DEPENDENT DATA
    for i=DV
        DATA(:,i)=data{i}(in);     
    end 

    %% RESET MISSING DV VALUES
    %   Had to do a little dance to make this flexible enough to allow users to
    %   specify multiple dependent variables.  
    tmp=DATA(:,DV); 
    RIND=isnan(tmp); 
    tmp(RIND)=DVINT;
    DATA(:,DV)=tmp; 
end % RDATA    