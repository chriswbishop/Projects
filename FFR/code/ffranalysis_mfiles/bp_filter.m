% This function will use a zerophase bandpass filter with the specifed
% parameters.
%
%  For project M data fs = 20 kHz.
% waveform is the time-domain waveform that you want to filter
% Fc1 and Fc2 are the low and high cut-off frequencies, respectively
% fs is the sampling rate
% waveform_filtered is is the filtered time-domain version of waveform

function [ waveform_filtered ] = bp_filter(waveform, Fc1, Fc2, fs)
% Zerophase filter the data. filtfilt doubles the filter order.

N = 4; % order of filter, 6dB/octave per order
[b,a] = butter(N/2, [Fc1 Fc2]/(fs/2));
waveform_filtered = filtfilt(b, a, waveform);
end