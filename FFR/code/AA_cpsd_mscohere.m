function [Cxy, Pxy, F]=AA_cpsd_mscohere(X, Y, FSx, FSy, varargin)
%% DESCRIPTION:
%
%   Wrapper to generate cross power spectral density, a measure of spectral
%   overlap between two time series of requal length. Also generates the
%   magnitude squared coherence estimate using MATLAB's mscohere function. 
%
%   Computations are performed pairwise between X and all columns (or rows)
%   of Y.
%
%   For details, see 
%   http://www.mathworks.com/help/signal/ug/cross-spectrum-and-magnitude-squared-coherence.html
%   
%   Desired features: 
%       Allow users to pass raw time series, ERP data structures, and
%       filenames pointing to saved ERPs and WAV files. CWB does not think
%       it would be useful to support loading individual EEG datasets.
%
% INPUTS:
%
%   Required:
%
%   X:  XXX
%   Y:  XXX
%   FSx:    Sampling rate for time series X. Only used if X is a double
%           array.
%   FSy:    "" for time series Y. "" Only used if Y is a double array. 
%
%   Additional parameters:
%
%   Data clipping:
%
%       'xsig':     two element array specifying the time (in seconds) that
%                   the signal can be found. This is useful when loading
%                   wave files with extended silence at either beginning or
%                   end OR when focusing on the post-stimulus time period
%                   for ERP data structures. (Ex. [0 0.2] | default=[-Inf
%                   Inf])
%       'ysig':     "" but for Y input. (default=[-Inf Inf])
%
%       NOTE:   For ERPs, time point 0 is the first time point of the *pre
%               stimulus* period! Adjust the time window accordingly. 
%
%   ERPs:
%
%       'chans':    channels to load. Required for ERP file names and ERP
%                   structures. (no default)
%       'bins':     bins to load from ERP structure. (Optional; all bins
%                   loaded by default)
%
%   Analysis:
%       
%       'window':   window for cpsd and mscohere. (default=[]); 
%       'antype':   analysis type. ('mscohere' | 'cpsd' | 'all' (default))
%                   If we have analyses that take a very long time, it
%                   might be necessary to specify which analysis is done.
%                   However, with just mscohere and cpsd with short signals
%                   (<20,000 samples), the computations are *very* fast, so
%                   it's not an issue. This flag is here primarily for
%                   future development or in the event that long time
%                   series are necessary. 
%       'noverlap': number of samples by which sections overlap
%                   (default=[])
%       'nfft':     FFT length (default=[]); 
%
% OUTPUTS:
%
%   Cxy:    complex, cross-spectrum power density function.
%   Pxy:    magnitude-squared coherence estimate
%
% DEVELOPMENT NOTES:
%
%   -Might be useful to perform a time-frequency based CPSD analysis. That
%   is, one that does NOT collapse over section estimates. (low priority).
%
%   - Might be useful to estimate the "apparent latency" of the two
%   signals. 
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INPUT CHECKS

% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
else 
    p=varargin{1};
end %

% Set default values.
%   Note that p.bins is set in lddata if an ERP structure or ERP filename
%   are provided. 
try p.bins; catch p.bins=[]; end 
try p.chans; catch p.chans=[]; end % will throw a shoe during lddata call.
try p.window; catch p.window=[]; end 
try p.antype; catch p.antype='all'; end 
try p.noverlap; catch p.noverlap=[]; end
try p.nfft; catch p.nfft=[]; end %
try p.xsig; catch p.xsig=[-Inf Inf]; end 
try p.ysig; catch p.ysig=[-Inf Inf]; end 

%% INITIALIZE OUTPUT VARIABLES
F=[]; % Frequency bins
Pxy=[]; % magnitude squared coherence estimate
Cxy=[]; % CPSD estimates

%% LOAD TIME SERIES
% Load reference time series to which all others will be compared
%   This should have a maximum of ONE time series. 
p.maxts=1;
[X, fsx]=lddata(X,p);
% Reassign sampling rate if we need to. 
if ~isempty(fsx), FSx=fsx; clear fsx; end 

% Load data to compare to X. Infinite number of time series allowed, but
% will be limited by memory constraints. 
p.maxts=Inf;
[Y, fsy]=lddata(Y,p); 
% Reassign sampling rate if we need to. 
if ~isempty(fsy), FSy=fsy; clear fsy; end

%% WINDOW DATA
%   Set analysis window as specified by p.xsig and p.ysig
X=windowdata(X, FSx, p.xsig); 
Y=windowdata(Y, FSy, p.ysig); 

%% MASSAGE DATA FOR MSCOHERE AND CPSD
% Match sampling rates
MAXFS= max([FSx FSy]); 
X=resample4TDT(X, MAXFS, FSx);
Y=resample4TDT(Y, MAXFS, FSy);

% Match stimulus length
MAXLN= max([size(X,1) size(Y,1)]);
X=[X; zeros(MAXLN-size(X,1),size(X,2))];
Y=[Y; zeros(MAXLN-size(Y,1),size(Y,2))];

% X=match_fs_length(X, FSx, MAXFS, MAXLN, p);
% Y=match_fs_length(Y, FSy, MAXFS, MAXLN, p);

%% COMPUTE MSCOHERE
%   Magnitude-squared coherence.
if strcmpi(p.antype, 'mscohere') || strcmpi(p.antype, 'all')
    for i=1:size(Y,2)        
        [pxy, F]=mscohere(X,Y(:,i),p.window,p.noverlap,p.nfft, MAXFS);
        Pxy(:,i)=pxy; 
        clear pxy
    end % for i=1:size(Y,2)
end % strcmpi(p.antype)

%% COMPUTE CPSD
%   Cross power spectral density
%
%   This computation averages over time windows.
if strcmpi(p.antype, 'cpsd') || strcmpi(p.antype, 'all')
   for i=1:size(Y,2)        
       [cxy, F]=cpsd(X,Y(:,i),p.window,p.noverlap,p.nfft, MAXFS);
       Cxy(:,i)=cxy; 
       clear cxy
    end % for i=1:size(Y,2)
end % strcmpi(p.antype)

%% ESTIMATE TIME DELAY BETWEEN TWO SIGNALS 
%   Y relative to X (+ values mean that Y starts after X, - values mean
%   that Y starts before X). 
%
%   Estimate phase delay as a measure of latency offset. For broadband
%   stimuli (e.g., speech), might be useful to use a linear fit to
%   unwrapped phase angles vs. frequency plot. 
%
%   Ah, I can see that this is actually suggested in
%
%   Picton, T. W., et al. (2003). "Human auditory steady-state responses." Int J Audiol 42(4): 177-219.
%
%   See "apparent latency" estimates and Figure 2. 
%
%   Limit slope estimate to frequencies that are well-represented in both
%   signals?? (MSCOHERE)?
%
%   Not sure how informative this will be. Reconsider before writing. 

%% TIME-FREQUENCY CPSD
%   Might be helpful to show CPSD as a function of time, rather than
%   averaging over all time windows. 
%   
%   Actually, CWB doesn't think this would be very useful, particularly for
%   temporally offset signals. 
%
%   Reconsider before writing. 

end % AA_cpsd_mscohere

function [X, FS]=lddata(X, p)
%% DESCRIPTION:
%
%   Function to dynamically load data with various input types. Kicks back
%   data in double format.
%
% INPUT:
%
%   Required
%       X:      input data, or string to ERP file/wav file.
%   
%   Optional (sometimes)
%       p:      additional parameters for loading data.
%
% OUTPUT:
%   
%   Y:  double array, loaded data. NxM array. 
%   FS: sample rate of data if data are loaded from file or contained in an
%       ERP structure.
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INITIALIZE FS
FS=[]; 

%% DETERMINE DATA TYPE AND WHAT TO DO
if isa(X, 'double')
    % If it's a double, just make sure it's the proper dimensions
    % XXX
    
    % If this is a multiple channel data set, throw an error
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
    
elseif isa(X, 'char')
    
    % Try reading in as a wav file. If that fails, assume it's an ERP file.
    % If THAT fails, then we're clueless.
    try
        [X, FS]=wavread(X);  %#ok<DWVRD>
        
        % Sommersault to check data size and dimensions
        X=lddata(X, p); 
    catch
        [pathstr,name,ext]= fileparts(X);
        X=pop_loaderp('filename', [name ext], 'filepath', pathstr);   
        
        % Sommersault to load ERP structure
        %   Include additional parameters in call so we know what to do
        %   with the data.
        [X, FS]=lddata(X, p); 
    end % try/catch   
    
elseif iserpstruct(X)
    
    % Parameter checks
    %   We can't support more than a single channel. Do NOT set a default
    %   channel, however, since this could lead to some undetected wonky
    %   results.
    if numel(p.chans)>1
        error('Cannot support multi-channel data (yet)'); 
    elseif isempty(p.chans)
        error('No channels specified'); 
    elseif isempty(p.bins)        
        % If bins are not defined, then load all bins. 
        p.bins=1:size(X.bindata,3); 
    end % if numel(p.chans)>1
    
    % Set sampling rate
    FS=X.srate; 
    
    % Get a mask for the time domain of ERP data.
    %   Masking is more generalized now and will be done in a call to
    %   windowdata. 
%     tmask=AA_maskdomain(X.times, p.tsig); 
    
    % Truncate data
    X=squeeze(X.bindata(p.chans, :, p.bins)); 
    
    % Sommersault to reset data dimensions if necessary
    %   Recursive calls are cool, aren't they?
    [X]=lddata(X, p); 
else
    error('Dunno what this is, kid');
end  % if ...

end % function lddata

function [X]=match_fs_length(X, FS, MAXFS, MAXLN, p)
%% DESCRIPTION:
%
%   Function to resample (interpolate) stimuli and zero pad to a specified
%   length.
%
% INPUT:
%
%   X:  data series as returned from lddata.m.
%   FS: data sampling rate as returned from lddata.m
%   MAXFS:  Maximum sampling rate. Lower sampling rates are interpolated to
%           match the highest sampling rate.
%   MAXLN:  time series are zeropadded to match the maximum stimulus
%           length
% OUTPUT:
%
%   X:  interpolated and zero padded time series.
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INPUT CHECKS

% We don't currently support down sampling. This should never happen if the
% user provides sensible inputs, but you never know. 
if FS>MAXFS
    error('Not intended for down sampling'); 
end % if FS<MAXFS

%% INTERPOLATE DATA
% Interpolate using whatever we used for the TDT presentation system 
%   Note that there might be some imprecision in this method. See
%   resample4TDT.m for additional information
X=resample4TDT(X, MAXFS, FS);

% ERror checking to make sure our resampling didn't make the input longer
% than the mwhat we think is the maximum length. 
%   Must do this AFTER resampling to be safe. Errors generated during use
%   on 3/6/2014 when resampling resulted in data with more samples than
%   specified by MAXLN.
if length(X)>MAXLN
    error(['Your stimulus is bigger than the specified maximum length. ' ...
        'Reconsider your input order. ' ...
        'This could also be a problem with resampling']); 
end % if length(X)>MAXLN

%% DOUBLE CHECK DIMENSIONS
%   Call lddata to make sure our stimulus dimensions are correct.
p.maxts=Inf; % infinite number of data traces OK. 
X=lddata(X, p); 

%% ZERO PAD
%   Zero pad each column
X=[X; zeros(MAXLN-size(X,1),size(X,2))];

end % function match_fs_length

function X=windowdata(X, FS, TWIN)
%% DESCRIPTION:
%
%   Function to window data based on sampling rate and user specified time
%   windows.
%
% INPUT:
%
%   X:  data series as returned from lddata.
%   FS: sampling rate of data
%   TWIN:   two element array specifying the time window. (E.g. [0 Inf]). 
%
% OUTPUT:
%
%   X:  windowed data
%
% Christopher W. Bishop
%   University of Washington 
%   3/14

%% CREATE TIME VECTOR
%   lnspace
t=(0 : 1/FS : size(X,1)/FS-1/FS)';

% Was going to do input checks, but we can't do this easily with Inf and
% -Inf input arguments. So let it throw an uninformative error. 

% %% INPUT CHECKS
% %   Make sure time window fits the stimulus (e.g., window isn't too wide)
% if TWIN(2) > t(end)
%     error('Specified time window is too wide');
% end % if TWIN(2) > t(end)

% Generate a time mask
tmask=AA_maskdomain(t, TWIN); 

% Apply mask
X=X(tmask,:); 

disp('CWB: Should we use a smarter windowing function (e.g., hamming??). Will likely reduce spectral splatter effects'); 

end % X=windowdata(X, FS, p)
