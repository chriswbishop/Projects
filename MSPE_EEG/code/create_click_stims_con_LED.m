function train = create_click_stims_con_LED()
%
%
%

i = 1;
click(1:12) = 1;
LEDclick(1:24) = 1;

dbstd = 10 ^ ((-38.62) / 20);
click = click .* dbstd;
LEDclick = LEDclick .* dbstd;





dbdrop = 10 ^ ((- 6) / 20);
while i <= 30
    dur = i / 1000;
    clear space signalE signalP LEDlead LEDlag
    space(1 : (11067 - ((48000 * dur) + 27)),1:2) = 0;

    signalE = horzcat(ceil(zeros(1, 15)), (click .* dbdrop));
    signalE = horzcat(signalE, zeros(1, ceil(dur * 48000) - 27));
    signalE = horzcat(signalE, click);
    signalE = horzcat(signalE, zeros(1, 15));
    
    signalP = horzcat(click, ceil(zeros(1, ceil(dur * 48000) - 12)));
    signalP = horzcat(signalP, zeros(1, 15));
    signalP = horzcat(signalP, (click .* dbdrop));

    LEDlead = horzcat(LEDclick, ceil(zeros(1, ceil(dur * 48000) - 24)));
    LEDlead = horzcat(LEDlead, zeros(1, 27));
    
    out = [signalE;signalP];
    LED = [zeros(1,length(LEDlead));LEDlead];
    
    k = 1;
    
    train = out';
    while k < 10
        train = vertcat(train, space);
        train = vertcat(train, out');
        k = k + 1;
    end
    train = vertcat(train, space);
    
    k = 1;
    tLEDlead = LED';
    while k < 10
        tLEDlead = vertcat(tLEDlead, space);
        tLEDlead = vertcat(tLEDlead, LED');
        k = k + 1;
    end

    tLEDlead = vertcat(tLEDlead, space);
  
    
    clear outl outr LEDl LEDr
    
    outr = train;
    outl(:,1) = train(:,2);
    outl(:,2) = train(:,1);
    LEDr = tLEDlead;
    LEDl(:,1) = tLEDlead(:,2);
    LEDl(:,2) = tLEDlead(:,1);
    
    outlblL = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_L.wav',i);
    outlblR = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_R.wav',i);
    outlblLEDL = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_L_LED.wav',i);
    outlblLEDR = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_R_LED.wav',i);
    wavwrite(outr,48000,outlblR);
    wavwrite(outl,48000,outlblL);
    wavwrite(LEDl,48000,outlblLEDL);
    wavwrite(LEDr,48000,outlblLEDR);
    i = i + 1;
end
    