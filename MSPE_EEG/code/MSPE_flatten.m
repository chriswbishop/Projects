function [EQL NEQL EQR NEQR HdwL HdwR HdwA]=MSPE_flatten(IN, OUT, DATA, FS, T, HPASS, NFILT, FREQ, PF, N)
%% DESCRIPTION:
%
%   Function to flatten our HRTF playback loop.  However, this can be used
%   to flatten pretty much any signal.  
%
%   Here are instructions on how to setup the HRTF equipment to get results
%   similar to mine.
%
%   XXX
%
% INPUT:
%
%   IN:     string, name of input device (e.g. 'Fireface 800 Analog (3+4)')
%   OUT:    string, name of output device (e.g. 'Gina3G 1-2 Digital Out')
%   DATA:   double array, data to present from output device. This can be
%           either one or two columns.
%           *NOTE*: At several places throughout the code, I do some
%           considerable zero padding to give the filters enough wiggle
%           room to work their magic, even if DATA is defined by the user.
%           So, the filters might introduce some unwanted delays at the end
%           of the day.
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
%   NFILT:  Filter order. Frequency response is also log sampled to this
%           order.
%   FREQ:   2x1 double array, specifies the frequency range (FREQ(1) <= F
%           <= FREQ(2)) that the flattening filters (Hdw*) will attempt to
%           correct.  This is particularly usefuly if the user knows ahead
%           of time that the playback/recording loop does not
%           produce/record sounds beyond a certain frequency range (e.g.
%           the Sensimetrics don't produce sounds very well beyond about 7
%           kHz, the ER-4Bs drop off quickly at about 16 kHz, etc.). 
%   PF:     Character array, file name containing a filter object (Hd) that
%           will be applied to the output sound prior to
%           playback/recording.  For instance, if you know the frequency
%           response of the coupler/microphone being used, then this can be
%           effectively "undone" by applying a filter to ensure that the
%           playback/recording loop is as flat as possible except for the
%           equipment you are trying to calibrate.
%
%   EXAMPLE: 
%
%   IN='Fireface 800 Analog (7+8)'; OUT='Gina3G 1-2 Digital Out'; DATA=[0;1;0]; FS=96000; T=0.5; HPASS=[]; N=1; NFILT=10000;
%
% OUTPUT:
%           
%   EQL:    Recording with corrective filter applied through channel 1
%           (Left-Channel on our system).
%   NEQL:   Recording without corrective filter applied through channe 1
%           (Left-Channel on our system)
%   EQR:    Recording with corrective filter applied through channel 2
%           (Right-Channel on our system)
%   NEQR:   Recording without corrective filter applied through channe 2
%           (Right-Channel on our system)
%   HdwL:   Corrective filter for left-channel for use with filtfilt.
%   HdwR:   Corrective filter for right-channel for use with filtfilt.
%   HdwA:   Average corrective filter for both channels for use with
%           filtfilt.
%
%   *NOTE*: At the time of testing, I found that the average filter doesn't
%           do a terribly great job at correcting the individual
%           microphones.  At the moment, I'd recommend correcting each
%           microphone independently, provided there aren't gross level
%           differences for the two filters (still need to test this).  
%
% EXAMPLES:
%
%   ETYMOTIC ER-4B: IN='Fireface 800 Analog (3+4)'; OUT='Gina3G 1-2 Digital Out'; DATA=[0;1;0]; FS=96000; T=0.5; HPASS=[]; N=1; NFILT=900; FREQ=[100 16000]; PF='';
%   
% NOTES:
%
%   Should probably figure out a way to estimate test-retest in frequency
%   response to see if we are consistently above the noise in our
%   measurements.  If we aren't (and I don't think we are, at least within
%   about 100 - 20000 Hz), then we'll end up "correcting" for things that
%   don't need to be corrected. Keep in mind that the test-retest should
%   include moving and replacing the mics into approximately the same
%   position.  I think the mic placement explains a lot of our variance. 
%
%       - Yeah, every time I move the microphones even slightly, I see a
%       different frequency response.  I commonly notice that large
%       deviations at a single frequency band (e.g. "spikes" in the FFT)
%       are eliminated by slightly repositioning the microphones. 
%
%       -Talked to LMM about this, and we both agree that I should take a
%       bunch of measurements moving the mics around and correct the
%       average frequency response.  
% 
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

    %% DEFAULTS
    %   Defaults are set to what I did the original testing with.  You may get
    %   better results with different settings. 
    if ~exist('DATA', 'var') || isempty(DATA), DATA=[zeros(4000,1); 1; zeros(4000,1)]; end
    if ~exist('FS', 'var'), FS=96000; end
    if ~exist('HPASS', 'var'), HPASS=[]; end
    if ~exist('T', 'var'), T=0.5; end
    if ~exist('FREQ', 'var'), FREQ=[100 25000]; end
    if ~exist('N', 'var'), N=5; end % reps

    %% APPLY COMPENSATORY FILTER
    try 
        load(PF, 'Hdw');
        
        %% Make sure DATA is zero-padded correctly.
        %   Copious padding...
        if length(DATA)<3*length(Hdw.Numerator)
            DATA=[zeros(length(Hdw.Numerator)*2,1); DATA; zeros(length(Hdw.Numerator)*2,1)];
        end % if length
        
        DATA=filtfilt(Hdw.Numerator, 1, DATA); 
    catch
        display('No compensatory filter applied');
    end % try
    
    %% DEFINE FREQUENCY RANGE TO FLATTEN
    %   Often times, it's just not practical to try and flatten the entire
    %   frequency response (e.g. speakers don't represent very low (<~20 Hz) or
    %   very high (>~25 kHz) terribly well.  Trying to correct these
    %   frequencies will very likely lead to issues later.  So, we specify
    %   the range we care about here. 
    Fmin=FREQ(1); Fmax=FREQ(2); 

    %% ESTIMATE INITIAL FREQUENCY RESPONSE
    %   Goal here is to figure out what the frequency response of the system is
    %   before we do anything.
    figure, hold on

    % Record sound using record_data
    for i=1:N
        [NEQ]=record_data(IN, OUT, DATA, FS, T, HPASS); 
    
        %% WINDOW ???
        %   Prevents spectral splatter with zero padding below. 
        RAMP=0.0005; 
        W=[ones(1,round(RAMP*FS))'; ones(size(NEQ,1)-round(2*RAMP*FS),1);flipud(linspace(0,1,round(RAMP*FS))')];
        W=W*ones(1,size(NEQ,2)); 
        NEQ=NEQ.*W; 
    
        %% ADD PAD RATIO
        %   Pad out of 0.5 sec recording. Allows frequency interpolation
        NEQ=[NEQ; zeros(0.5*FS-size(NEQ,1), size(NEQ,2))]; 
    
        % Plot frequency response
        n = size(NEQ,1); % number of samples
        f = FS/2*linspace(0,1,n/2+1); % Frequencies measured.
        Y(:,:,i)=fft(NEQ); 
    end % i

    % Decibels (relative to amplitude of 1)
    Y=20.*log10(abs(Y));
    Y=mean(Y,3); % average over frequency responses. 

    %% ISOLATE FREQUENCIES OF INTEREST
    %   Remember, we aren't correcting the whole frequency spectrum.  So, we
    %   need to isolate the critical frequency range.
    IND=find(f>Fmin, 1, 'first'):find(f<Fmax, 1, 'last');
    F=f(IND)';
    Y=Y(IND,:); 

    %% PLOT FREQUENCY RANGE OF INTEREST
    % plot(F, Y, 'b');
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (dB)');

    %% DESIGN FILTERS
    %   Mean center, invert, and halve dB values for use with filtfit.
    %
    %   Also, normalize filter so we are always making sounds quieter.
    %
    %   Frequency response of filter is interpolated to NFILT log spaced
    %   values.  
    
    Yf= ((Y-(ones(size(Y,1),1)*mean(Y))).*-1)./2; % divide by 2 for filtfilt
%     Yf= ((Y-(ones(size(Y,1),1)*mean(Y))).*-1); % don't divide for fftfilt

    % interpolate smoothed spectrum to order N
    intfxx = [logspace(log10(F(1)),log10(F(end)),NFILT)]; % don't use Fmin and Fmax, could lead to discrepencies. 
    PdBint = interp1(F,Yf,intfxx,'spline');
    plot(F, Yf, 'k');
    plot(intfxx,PdBint,'+');
    xlabel('Frequency (Hz)'); 
    ylabel('Magnitude (dB)'); 
    title('Frequency Response and Estimated Filter');
    legend('Frequency Response', 'Desired Filter', 'Interpolated Filter'); 
    set(gca, 'XScale', 'log'); 
    
    % Create Arbitrary Magnitude Filter for Left Channel
    M=[1; 10.^(PdBint(:,1)./20); 1];  % convert to mag; changed 0 and nyquist to Mag of 1, makes filter behave better. 
    F=[0 intfxx./(FS./2) 1]'; % normalized to nyquist
    dw = fdesign.arbmag('N,F,A',NFILT,F,M);
    HdwL = design(dw,'freqsamp');
    HdwL.Numerator=HdwL.Numerator./max(abs(HdwL.Numerator));
    
    % Create Arbitrary Magnitude Filter for Right Channel
    M=[1; 10.^(PdBint(:,2)./20); 1];  % convert to mag
    F=[0 intfxx./(FS./2) 1]'; % normalized to nyquist
    dw = fdesign.arbmag('N,F,A',NFILT,F,M);
    HdwR = design(dw,'freqsamp');
    HdwR.Numerator=HdwR.Numerator./max(abs(HdwR.Numerator));
    
    % Create Arbitrary Magnitude Filter for Average Channel
    M=[1; 10.^(mean(PdBint,2)./20); 1];  % convert to mag
    F=[0 intfxx./(FS./2) 1]'; % normalized to nyquist
    dw = fdesign.arbmag('N,F,A',NFILT,F,M);
    HdwA = design(dw,'freqsamp');
    HdwA.Numerator=HdwA.Numerator./max(abs(HdwA.Numerator));
    
    %% ASSESS FILTERS
    [EQL NEQL]=test_filter(IN, OUT, DATA, FS, T, HPASS, HdwL, FREQ, 'Channel 01', N);
    EQR=[]; NEQR=[];
%     [EQR NEQR]=test_filter(IN, OUT, DATA, FS, T, HPASS, HdwR, FREQ, 'Channel 02', 2); 
%     test_filter(IN, OUT, DATA, FS, T, HPASS, HdwA, FREQ, 'Ave', 1); 

end % MSPE_flatten

function [EQ NEQ]=test_filter(IN, OUT, DATA, FS, T, HPASS, Hdw, FREQ, FSTR, N)
%% DESCRIPTION:
%
%   Small script for testing the efficacy of designed filters.  The basic
%   idea is to play an unfiltered and filtered sound through the sound
%   playback/recording loop, and compare the outputs.  The corrected
%   recording should be very close to white.
%
%   Function generates several plots that should be helpful in assessing
%   how effective a corrective filter is.  
%
% INPUT:
%
%   IN:     See MSPE_flatten.
%   OUT:    See MSPE_flatten.
%   DATA:   See MSPE_flatten.
%   FS:     See MSPE_flatten.
%   T:      See MSPE_flatten.
%   HPASS:  See MSPE_flatten.
%   FREQ:   See MSPE_flatten.
%
%   Hdw:    filter object.
%   FSTR:   string, title for plot
%   C:      index into recording (e.g. 1=Left channel, 2=Right Channel)
%
% OUTPUT:
%
%   EQ:     Recording with corrective filter applied.
%   NEQ:    Recordings without corrective filter applied.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

    Fmin=FREQ(1); Fmax=FREQ(2); 
    % Zero-pad if necessary for filtering
    if length(DATA)<length(Hdw.Numerator)
        data=[zeros(length(Hdw.Numerator)*3,1); DATA; zeros(length(Hdw.Numerator)*3,1)]; % pad the bejeebus out of it
    else
        data=DATA;
    end % if 

    % Record sound without filter applied  
    for i=1:N
        [NEQ]=record_data(IN, OUT, data, FS, T, HPASS); 
%         NEQ=NEQ(:,C); 
    
        YNEQ(:,:,i)=fft(NEQ);
    end % i
    YNEQ=20.*log10(abs(YNEQ));
    YNEQ=mean(YNEQ,3);
    
    % Filter
    %   filtfilt gives zero phase delay filter. 
    DATAEQ=filtfilt(Hdw.Numerator, 1, data);
%     DATAEQ=DATAEQ(:,C);     
%     DATAEQ=fftfilt(Hdw.Numerator, data); 
    
    % Normalize Amplitude
    DATAEQ=DATAEQ./(max(max(abs(DATAEQ)))); 

    % Record sound
    for i=1:N
        [EQ]=record_data(IN, OUT, DATAEQ, FS, T, HPASS); 
%     EQ=EQ(:,C); 
        YEQ(:,:,i)=fft(EQ);
    end % i
    YEQ=20.*log10(abs(YEQ));
    YEQ=mean(YEQ,3);
    
    
    % Plot frequency response
    figure, hold on
%     subplot(2,1,1); hold on;
    
    % Zero-pad FFTs
%     if length(NEQ)>length(EQ)
%         EQ=[EQ; zeros(length(NEQ)-length(EQ),size(EQ,2))];
%     elseif length(EQ)>length(NEQ)
%         NEQ=[NEQ; zeros(length(EQ)-length(NEQ),size(NEQ,2))];
%     end % if 

    n=length(EQ); % number of samples.
    f = FS/2*linspace(0,1,n/2+1);
    IND=find(f>Fmin, 1, 'first'):find(f<Fmax, 1, 'last');

    % YEQ: recorded data with filter applied.
%     YEQ=fft(EQ);
%     YEQ=20.*log10(abs(YEQ));

    % YNEQ: recorded data without filter applied. 
%     YNEQ=fft(NEQ);
%     YNEQ=20.*log10(abs(YNEQ));

    % Define frequencies
    F=f';

    % Mean center within frequency range specified by user.
    %   Allows for easier comparison within this region and allows the user to
    %   easily spot of the filter is doing something really silly in the
    %   unspecified time range.
    YEQ=YEQ-mean(YEQ(IND)); 
    YNEQ=YNEQ-mean(YNEQ(IND)); 

    % Plot data    
    plot(F, YNEQ(1:length(F)), 'r'); 
    plot(F, YEQ(1:length(F)), 'k'); 
    plot(F(IND), YEQ(IND), 'b', 'linewidth', 2); 
    xlabel('Frequency (Hz)'); 
    ylabel('Magnitude (dB)'); 
    legend('Unfiltered Frequency Response', 'Filtered Frequency Response', 'Corrected Frequency Range'); 
    set(gca, 'XScale', 'log', 'XGrid', 'On', 'YGrid', 'On');     
    title(FSTR); 
    
    % Plot filter frequency response
    figure, hold on
    n=length(Hdw.Numerator); 
    f = FS/2*linspace(0,1,n/2+1);
    Y=db(abs(fft(Hdw.Numerator)));
    plot(f, Y(1:length(f)), 'linewidth', 2); 
    title('Filter Frequency Response');
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (dB)'); 
    set(gca, 'XScale', 'log', 'XGrid', 'On', 'YGrid', 'On');     
    
end % test_filter