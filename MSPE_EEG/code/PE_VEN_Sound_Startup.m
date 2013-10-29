hw=daqhwinfo('winsound');

LED=strmatch('Fireface 800 Analog (1+2)',hw.BoardNames,'exact')-1;
A=strmatch('Fireface 800 Analog (3+4)',hw.BoardNames,'exact')-1;

LEDo=analogoutput('winsound', LED);
addchannel(LEDo,1:2);
set(LEDo,'StandardSampleRates','Off')
set(LEDo,'SampleRate',48000);

Ao=analogoutput('winsound', A);
addchannel(Ao,1:2);
set(Ao,'StandardSampleRates','Off')
set(Ao,'SampleRate',48000);

set(LEDo,'ManualTriggerHwOn','Trigger')
set(Ao,'ManualTriggerHwOn','Trigger')