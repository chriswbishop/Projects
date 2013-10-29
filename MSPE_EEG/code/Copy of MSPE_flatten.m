function MSPE_flatten(IN, OUT, DATA, FS, T, HPASS, N, Nfilt)
%% DESCRIPTION:
%
%   Function that will *hopefully* design filters to flatten any playback
%   loop. 
%
% INPUT:
%
%   IN:     string, name of input device (e.g. 'Fireface 800 Analog (3+4)')
%   OUT:    string, name of output device (e.g. 'Gina3G 1-2 Digital Out')
%   DATA:   double array, data to present from output device. This can be
%           either one or two columns.
%   FS:     double, sampling rate (e.g. 96000)
%   T:      double, total recording time (seconds).  Notice that the
%           recording time is set to slightly longer than the DATA input if
%           DATA is defined. If DATA is not defined, then T must be
%           specified.  Alternatively, if T is longer than DATA, the
%           recording will last for T seconds. (default is duration DATA +
%           some short amount of time (currently 1.5 msec)).
%   HPASS:  double, cutoff for highpass filter (Hz) (e.g. 10)
%   CLEAN:  double, cutoff value used to remove silence before and after
%           recording.  (default=0, so nothing done).
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
if ~exist('DATA', 'var'), DATA=[1; zeros(4000,1)]; end
if ~exist('FS', 'var'), FS=96000; end
if ~exist('HPASS', 'var'), HPASS=[]; end
if ~exist('T', 'var'), T=[]; end
if ~exist('CLEAN', 'var'), CLEAN=0; end 
if ~exist('N', 'var'), N=10; end 

%% ESTIMATE FREQUENCY RESPONSE

% Record sound
for i=1:N
    [NEQ(:,i)]=record_data(IN, OUT, DATA, FS, T, HPASS, CLEAN); 
end % i

% plot fft
n = size(NEQ,1);
% Mean mag at each frequency
%   We toss out phase information because we aren't trying to correct for
%   that.
Y=mean(abs(fft(NEQ)),2); 
f = FS/2*linspace(0,1,n/2+1);

% Convert mag to dB
Y = db(Y); 
Y = (Y(1:floor(n/2)+1));
% Plot power
plot(f, Y);
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)');


%% CREATE FILTER
IND=find(f>80, 1, 'first'):find(f<20000, 1, 'last');
% Y=10.^(Y./10); % convert to magnitude
Yf=(Y(IND)-mean(Y(IND))).*-1;
F=f(IND)'; 

% Make sure Maximum dB is 0 (corresponds to amplitude of 1)
Yf=(Yf-max(Yf)); 

% Convert to magitude
Yf=10.^(Yf./10); 

% downsample for testing
% F=F(1:1000:end); 
% Yf=Yf(1:1000:end);

% Add in some points
% F=[0; 40; F; 48000]; % this is dumb, should be normalized frequency
% M=[0; 1; Yf; 0]; % maybe dumb?
% W=[0.0001; 0.0001; ones((size(F,1)./2)-2,1)]; % weight vector

% F=[0; F; 48000]; % this is dumb, should be normalized frequency
% M=[1;  Yf; 1]; % maybe dumb?
% W=[0.0001; ones((size(F,1)./2)-2,1)]; % weight vector

% pwelch estimation
[Y F]=pwelch(NEQ, round(size(NEQ,1)./100),[],[],FS);
F=F(IND); 
Y=Y(IND); 

Yf=(Y-mean(Y)).*-1; % inverse filter
% Make sure Maximum dB is 0 (corresponds to amplitude of 1)
Yf=(Yf-max(Yf)); 

% Convert to magitude
Yf=10.^(Yf./10); 

% compare pwelch with fft
%   Want to make sure that whatever our PWELCH estimation is doing is
%   sufficiently smooth, but not TOO smooth so we aren't capturing the bulk
%   of the variance with the estimate. 

% determine arbitrary magnitude over relevant frequency range (e.g.
% 50-20000 Hz) 

% Design filter

% Filter DATA

% Record Flattened sound

% Compare NEQ and EQ frequency responses (focusing on frequency range of
% interest). 

