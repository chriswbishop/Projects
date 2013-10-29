function PE_VEN_STIM_PLAY(del, side, condition, LEDo, Ao)
%
%
%

if side == 1
    fnS = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_L.wav',del*10000);
    fnLED = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_L_LED.wav',del*10000);
else
    fnS = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_R.wav',del*10000);
    fnLED = sprintf('C:\\Documents and Settings\\slondon\\My Documents\\PE Ventriloquism\\PE Stims\\PE_VEN_Clicks_%d_R_LED.wav',del*10000);
end

S = wavread(fnS);
LED = wavread(fnLED);

switch (condition)
    case 1
        putdata(LEDo,LED);
        putdata(Ao,S);
        start([LEDo Ao]);
        trigger([LEDo Ao]);
        wait(1);
        stop([LEDo Ao]);
    case 2
        putdata(Ao,S);
        start(Ao);
        trigger(Ao);
        wait(1);
        stop(Ao);
    case 3
        putdata(LEDo,LED);
        putdata(Ao,S);    
        start([LEDo Ao]);
        trigger([LEDo Ao]);
        wait(1);
        stop([LEDo Ao]);
end
    