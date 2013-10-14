function [signal_1, signal_2] = buffer_sounds(sampling_rate, signal_1, signal_2 )

 % buffer sounds with zeros to avoid transients at onset/offset in Win7
 % seconds of buffering = (sampling rate/100)/sampling rate
 %                0.010 =         (20000/100)/20000  
% silence = zeros([1 floor(sampling_rate/100)]); % 10 milliseconds of zeros
% silence = zeros([1 floor(sampling_rate/80)]); % 12.5 milliseconds of zeros
% silence = zeros([1 floor(sampling_rate/60)]); % 16.7 milliseconds of zeros
% silence = zeros([1 floor(sampling_rate/30)]); % 33.3 milliseconds of zeros
silence = zeros([1 floor(sampling_rate/10)]); % 100.0 milliseconds of zeros

% tone  = [silence tone  silence];
% noise = [silence noise silence];
signal_1 = [silence signal_1 silence];
if nargin > 2
signal_2 = [silence signal_2 silence];
end
    
    


