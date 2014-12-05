function [rf, pcc, audio_env, erp_data, FS] = erp_revcorr(ERP, audio_track, varargin)
%% DESCRIPTION:
%
%   This function performs reverse correlation between an ERP data set and
%   an acoustic waveform. This is essentially a semi-convenient wrapper for
%   J. Simon and Nai Ding's reverse correlation code. Please contact these
%   authors directly for code (jzsimon@umd.edu). This also relies on the
%   NSL software suite (<http://www.isr.umd.edu/Labs/NSL/Software.htm>)
%   which must be downloaded and in your path. 
%
% INPUT:
%
%   ERP:    ERPLab structure. 
%
%   audio_track:    can be any data format supported by SIN_loaddata. This
%                   includes a filename, audio track, etc. However, this
%                   must be a single-channel audio track. If it's
%                   multichannel, the code will only use the first channel.
%
%                   Actually, we'll only allow filenames for now. 
%                   
% Parameters:
%
%   'erp_channels': double array, ERP channels to perform reverse
%                   correlation with. 
%
%   'erp_bins':     double array, bins to include in reverse correlation
%                   routine.
%
%   'time_window':  two-element array, specifies the time window for
%                   analysis (e.g., [5 inf] excludes the first 5 sec from
%                   the ERP and audio_track
%   
%   'n_frequency_bands':    number of frequency bands to use in audio track
%                           envelope estimation.
%
% Development:
%
%   None (yet)
%
% Christopher W. Bishop
%   University of Washington
%   12/14

%% LOAD PARAMETERS
opts = varargin2struct(varargin{:});

% Load the ERPLab structure
[erp_data, erp_fs] = SIN_loaddata(ERP, ...
    'chans', opts.erp_channels, ...
    'bins', opts.erp_bins, ...
    'time_window',  opts.time_window .* 1000);  % convert time stamp to millisecond

% Time-frequency decomposition and envelope estimation of audio_track
%   This also resamples the audio data to match the sampling rate of our
%   ERP data. 
[audio_env, audio_fs, CF] = audSpec_env(audio_track, erp_fs, opts.n_frequency_bands);

% Only use first channel
audio_env = audio_env{1}; 

% Copy envelope for each condition
audio_env = repmat(audio_env, 1, 1, size(erp_data,3)); 

% Run reverse correlation
[rf, pcc] = RFgen_multichan(audio_env, erp_data, erp_fs, 1, opts.n_frequency_bands > 1); 

% Create some potentially useful plots
if opts.pflag
    
    % STRF Plot
    
    % Predictive Plot
    
    % 
    
end % if opts.pflag