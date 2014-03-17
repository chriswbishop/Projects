function [X, FS, LABELS, ODAT]=AA_loaddata(X, varargin)
%% DESCRIPTION:
%
%   Generalized function to load data from common file types used in
%   project AA (and probably others) as well as generate standardized data
%   format for data matrices, provided some sensible assumptions are met.
%
% INPUT:
%
%   Required:
%       X:  XXX
%
%   Sometimes Required Inputs:
%       'fs': double, sampling rate of data. XXX
%       
% OUTPUT:
%   
%   X:  double matrix, the data XXX
%   FS: double, sampling rate of the data.
%   LABELS: data trace labels. This is useful when loaded data are actually
%           ERP files from ERPLAB, CNT files, or several other data types
%           that have strings associated with their data traces. 
%   
% Christopher W. Bishop
%   University of Washington
%   3/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

%% INITIALIZE VARIABLES

% Check for initialized sampling rate
try FS=p.fs; catch FS=[]; end 

% LABELS as empty cell (for now). Populated below.
LABELS={}; 

%% DETERMINE DATA TYPE AND WHAT TO DO
if isa(X, 'double')
    % If it's a double, just make sure it's the proper dimensions
    
    % Input check
    %   If maximum number of time series is not defined, then assume it's
    %   infinite. 
    if ~isfield(p, 'maxts'), p.maxts=Inf; end 
    
    % If the number of time series exceeds p.maxts, throw an error. Useful
    % when ensuring that a loaded wav file is not (or is) stereo. Typically
    % we want a single time series for the "X" input to the parent
    % function. 
    if min(size(X))>p.maxts
        error('Exceeds maximum number of dimensions'); 
    end % if min(size(X))>1
    
    % Dimension checks
    %   Assume that the shortest dimension are the individual time series. 
    if numel(size(X))>2
        error('Too many dimensions');
    elseif size(X,1) == size(X,2)
        error('This is a square matrix, not sure what to do with it');
    elseif size(X,1)==min(size(X))
        X=X';
    end % if ... 
    
    % Create default labels for plotting
    for n=1:size(X,2)
        LABELS{n}=['TimeSeries (' num2str(n) ')'];
    end % for n=1:size(X,2)
    
elseif isa(X, 'cell') 
    % Filenames will be necessarily stored in a cell array.
    
    % Try reading in as a wav file. If that fails, assume it's an ERP file.
    % If THAT fails, then we're clueless.
    for n=1:length(X)
        [pathstr,name,ext]= fileparts(X{n});
        
        % Determine file type to load. 
        switch lower(ext)
            case {'.wav'}
                % If this is a WAV file
                [tx, FS]=wavread(X{n});  %#ok<DWVRD>
                x(:,n)=tx; % assumes a single channel file, which is fine
            case {'.mat', '.erp', '.set'}
                % If the data are either an ERP structure (stored as a .mat
                % or .erp file extension) or an EEG struture (stored as a
                % .mat or .set file)
                
                % First, try loading the ERP, then try loading the EEG data
                % set.
                try 
                    x(n)=pop_loaderp('filename', [name ext], 'filepath', pathstr); 
                catch
                    x(n)=pop_loadset('filename', [name ext], 'filepath', pathstr); 
                end % try/catch
            case {'.cnt'}
                % If it's a CNT file
                x(n)=loadcnt(X{n}); 
            otherwise
                error('File extension not recognized');         
        end % switch 
    end % for n=1:length(X)
    
    % Reassign to X.
    X=x;
    ODAT=X; % save original data structures
    
    % Sommersault to check data size and dimensions. Also load label
    % information
    
    % If we know the sampling rate, then pass hold it constant in
    % sommersault. 
    if ~isempty(FS), p.fs=FS; end 
    [X, FS, LABELS]=AA_loaddata(X, p);              
    
elseif iserpstruct(X)
    
    % Defaults
    
    % Load all channels by default
    try p.chans; catch p.chans=size(X(1).bindata, 1); end  
    
    % Load all bins by default
    try p.bins; catch p.bins=size(X(1).bindata(3)); end 
    
    % Set sampling rate
    %   Assumes all sampling rates are equal
    %   Also assumes that bin labels are the same across all ERP
    %   structures. Reasonably safe.
    FS=X(1).srate;    
    LABELS={X(1).bindescr{p.bins}}; % bin description labels
    for n=1:length(X)
    
        % Truncate data
        for c=1:length(p.chans)
            tx=squeeze(X(n).bindata(p.chans(c), :, p.bins)); 
        
            % Sommersault to reset data dimensions if necessary
            [tx]=AA_loaddata(tx, p); 
            
            % Assign to growing data structure
            x(c,:,:,n)=tx; 
        end % c=p.chans
        
    end % for n=1:length(X)
    
    % Reassign to return variable X
    X=x; 
    clear x; 
    
else
    error('Dunno what this is, kid.');
end  % if ...

end % function AA_loaddata