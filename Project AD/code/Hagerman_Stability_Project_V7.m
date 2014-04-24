% Hagerman Stability Project V7
% Oct 2011, by Wu
% The stimulus of this algorhtm has 9 SNR segments
% Each segment has 5 repetitions.
% This algorithm (1) use the 2 and 4 repetitions to derive the stability
% measures and (2) use the 3rd and 4th repetitions to derive the SNR.

% V6.1: Use the average value as the baseline to calculate the attenuation
% V6.1: When calculate the short term data, include the pause

% V6 Use the 5 Repetiton recording
% Repetiton 1  2  3  4  5
% Speech    +  -  +  +  +
% Noise     +  -  +  +  -
% Use Seg 4 and 5 to extract SNR
% Use Seg 3 and 4 to examine if system is time-invariant
% Use Seg 2 and 3 to examine the effect of phase to system

% V7 Correct the error of calculating short term SNR
% V6: change the short term result to 1 sec.

% V5 remove the instability simulation
% V5 improve the file selection and data output

% V4: eliminating silent internval when calculating short term value


tic
clear
%hh = msgbox(['Check the Instability Index!'],'Alert!');
%uiwait(hh);

% dB = 0;                                     % Instability index; default: 0 ==> no instability

segment_num = 8;                            % the SNR condition                            
repeat_passage = 2;                         % 2 * the pair of passage that will be used to derive SNR
nouse_passage = 3;                          % the passages that will be used to stable the HA
Fs = 44100;                                 % sampling rate
passage_interval = 60*Fs;                   % the time duration of each passage
silent_interval = 0*Fs;                     % the duration from the click to the first passage
seg_interval = (repeat_passage+nouse_passage)*passage_interval;       % duration of each SNR segment
short_term_duration = floor((30/1000)* Fs);                         % the time window of short term SNR calculation; default : 30 ms

Fre = [ 25 31.5 40, 50 63 80, 100 125 160, 200 250 315, 400 500 630, ... 
        800 1000 1250, 1600 2000 2500, 3150 4000 5000, 6300 8000 10000, ... 
        12500  ];  
Fre = Fre';


% for excel
warning off MATLAB:xlswrite:AddSheet;


% creating the matrix for results
% Note: Wideband is from 160 to 8k Hz; long term is 1 min, short term is 30 ms.
LTSNR_WB = zeros (1, segment_num);      
STSNR_WB = zeros (1, segment_num);
LTSNR_NB = zeros (length(Fre), segment_num);
STSNR_NB = zeros (length(Fre), segment_num);

%Correlation coefficient
% PP is positive vs. positive (i.e., Repetiton 3 vs 4)
% PN is positive vs. neative (i.e., Repetiton 2 vs. 3)
CorrCoeff_WB_long_PP = zeros (1, segment_num);
CorrCoeff_WB_short_PP = zeros (1, segment_num);
CorrCoeff_NB_long_PP = zeros (length(Fre), segment_num);
CorrCoeff_NB_short_PP = zeros (length(Fre), segment_num);

CorrCoeff_WB_long_PN = zeros (1, segment_num);
CorrCoeff_WB_short_PN = zeros (1, segment_num);
CorrCoeff_NB_long_PN = zeros (length(Fre), segment_num);
CorrCoeff_NB_short_PN = zeros (length(Fre), segment_num);

% Attenuation amount
Atten_WB_long_PP = zeros (1, segment_num);
Atten_WB_short_PP = zeros (1, segment_num);
Atten_NB_long_PP = zeros (length(Fre), segment_num);
Atten_NB_short_PP = zeros (length(Fre), segment_num);

Atten_WB_long_PN = zeros (1, segment_num);
Atten_WB_short_PN = zeros (1, segment_num);
Atten_NB_long_PN = zeros (length(Fre), segment_num);
Atten_NB_short_PN = zeros (length(Fre), segment_num);

%HINT_noPause_start = [8902	102031	186124	283913	379968	464983	550611	646823	751764	844942	953870	1034974	1129742	1217971	1305612	1398468	1495422	1582855	1673437	1759611	1846390	1936244	2026428	2124580	2216798	2297652	2378758	2467716	2557229];
%HINT_noPause_end =   [81196	167456	265341	357073	443233	529318	626726	722585	823017	935960	1015130	1109492	1199805	1284762	1379616	1476570	1560597	1643756	1743777	1832083	1909914	2007447	2104817	2198358	2278935	2361786	2448996	2535558	2631238];

%for bandpass filter
N   = 10;    % Order
Fc1 = 141;   % First Cutoff Frequency
Fc2 = 8913;  % Second Cutoff Frequency

[filename, pathname] = uigetfile('*.wav', 'Pick a wav-file',  'MultiSelect', 'on');
if ischar(filename) == 1
    GGGGset = 1;
else
    GGGGset = length(filename);
    
    prompt = {'Enter the name of Summary file'};
    dlg_title = 'Entering...';
    num_lines = 1;
    def = {''};
    Summary_name = inputdlg(prompt,dlg_title,num_lines,def);  
    pathXLS_summary = [pathname, 'Summary_',char(Summary_name),'.xls'];
end



    
for GGGG = 1: GGGGset
    %Pathway of the sound files
    if GGGGset ==1
        CharPathname = filename;
    else
        CharPathname = char (filename(GGGG));
    end
    pathway_results = [pathname,CharPathname];
    %pathway_done = ['C:\Research File\Wu\Curtis Hartling_HAL Study\Matlab\Done.wav'];
    pathXLS = [pathname, CharPathname,'.xls'];
    


    %%

%     % the scaler to create unstability
%     %create a random noise
%     scaler = rand(passage_interval,1)-0.5;
%     % lowpass filter the random noise
%     Fc = 50;                % Cutoff Frequency is 50 Hz, that is, most unstable occurs within a window of 20 ms or longer
%     [B,A] = butter(1, Fc/(Fs/2));
%     LP_scaler = filter (B, A, scaler);
% 
%     scaler_linear = ones (1, passage_interval);
%     LP_scaler_rescale = LP_scaler.*((dB/3)/std(LP_scaler));     % rescale the scaler to stretch that 99% (3 SD) of the unstability to the range assigned   
%     for iii = 1: passage_interval                               % convert the unstability in dB to linear scale
%         scaler_linear (iii) = 10^(LP_scaler_rescale(iii)/20);
%     end

    %Decide the start point
    raw_total = wavread (pathway_results, [1, 6*Fs]);

    Calib_A = raw_total (ceil(1*Fs): ceil(4*Fs));
    max_Calib_A = ((sum(Calib_A.^2)/length(Calib_A))^0.5)*4;    %four times rms amplitude

    start_point_noise = 4*Fs;
    while abs(raw_total(start_point_noise)) <= 10*max_Calib_A
      start_point_noise = start_point_noise + 1;
    end    

    %calculation
    for seg_count = 1:segment_num 
        %% PP part
        %Long term quantification (1 min)
        %Extract Repetiton 3 and 4
        Raw_A = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (2)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (2)*passage_interval + passage_interval]);

        Raw_B = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (3)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (3)*passage_interval + passage_interval]);

        %Raw_B = Raw_B.*scaler_linear';

        %WB correlation. Wideband is from 160 to 8k Hz
        [B,A] = butter(N/2, [Fc1 Fc2]/(Fs/2));      %bandpass filter 160 to 8k Hz (SII range)
        CorrA = filter(B,A,Raw_A);
        CorrB = filter(B,A,Raw_B);
        %remove first and last 30 ms
        CorrA = CorrA (short_term_duration: length(CorrA)-short_term_duration); 
        CorrB = CorrB (short_term_duration: length(CorrB)-short_term_duration);
        CorrCoeff_WB_long_PP (1,seg_count)  = corr(CorrA, CorrB);                                              %Correlation, Long, WB

        %Quantification method 2: The amount of attenuation
        Ave = (CorrA + CorrB)/2;
        Residual = (CorrA - CorrB)/2;
        Atten_WB_long_PP(1,seg_count) = leq(Ave, length(Ave))- leq(Residual, length(Residual));                %Atten, Long, WB

        %short term, WB quantification (1000 ms) 
%%        
% %         ===Old part from V 6 ===        
% %         tempA = [];
% %         tempB = [];
% %         for ixx = 1: length (HINT_noPause_start)
% %             tempA = cat(1, tempA, Raw_A (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %             tempB = cat(1, tempB, Raw_B (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %         end
% % 
% %         CorrA = filter(B,A,tempA);
% %         CorrB = filter(B,A,tempB);
%%

        Counter = 0;
        CorrCoeff_temp = 0;
        %Atten_temp = 0;
        Ave_rms_temp = 0;
        Residual_rms_temp = 0;

        for uu = 1: short_term_duration :length(CorrA)-short_term_duration    
            CorrA_short = CorrA(uu: uu+ short_term_duration);
            CorrB_short = CorrB(uu: uu+ short_term_duration);

            %Correlation
            CorrCoeff_temp = CorrCoeff_temp + corr(CorrA_short, CorrB_short);

            %Amount of attenuation
            Ave = (CorrA_short + CorrB_short)/2;
            Residual = (CorrA_short - CorrB_short)/2;
            Ave_rms_temp = Ave_rms_temp + (mean(Ave.^2)^0.5);
            Residual_rms_temp = Residual_rms_temp + (mean(Residual.^2)^0.5);
            %Atten_temp = Atten_temp + leq(Ave, length(Ave))- leq(Residual, length(Residual));

            Counter = Counter +1;
        end
            CorrCoeff_WB_short_PP (1,seg_count) = CorrCoeff_temp/Counter;                                      %Correlation, Short, WB
            Atten_WB_short_PP(1,seg_count) = 20*log10(Ave_rms_temp/Counter) - 20*log10(Residual_rms_temp/Counter); %Atten, Short, WB
            % Atten_WB_short_PP(1,seg_count)= Atten_temp/Counter;                                                


        %NB calculation
        for OB_count = 9: 26    %from 160 to 8000 Hz    
            %Filter
            [B,A] = oct3dsgn(Fre(OB_count),Fs);
            CorrA_temp = filter(B,A,Raw_A); 
            CorrB_temp = filter(B,A,Raw_B); 
            %remove first and last 30 ms
            CorrA_OB = CorrA_temp (short_term_duration: length(CorrA_temp)-short_term_duration); 
            CorrB_OB = CorrB_temp (short_term_duration: length(CorrA_temp)-short_term_duration);

            %Correlation, Long, NB
            CorrCoeff_NB_long_PP (OB_count, seg_count)  = corr(CorrA_OB, CorrB_OB);                            %Correlation, long, NB

            Ave = (CorrA_OB + CorrB_OB)/2;   
            Residual = (CorrA_OB - CorrB_OB)/2;    
            Atten_NB_long_PP (OB_count, seg_count)= leq(Ave, length(Ave))- leq(Residual, length(Residual));    %Atten, Long, NB

            %short term quantification (1000 ms)  
            %%
% %             CorrA_OB = filter(B,A,tempA); 
% %             CorrB_OB = filter(B,A,tempB); 
%%


            Counter = 0;
            CorrCoeff_temp = 0;
            %Atten_temp = 0;
            Ave_rms_temp = 0;
            Residual_rms_temp = 0;

            for uu = 1: short_term_duration :length(CorrA_OB)-short_term_duration  
                CorrA_short = CorrA_OB(uu: uu+ short_term_duration);
                CorrB_short = CorrB_OB(uu: uu+ short_term_duration);

                %Correlation
                CorrCoeff_temp = CorrCoeff_temp + corr(CorrA_short, CorrB_short);

                %Attenuation
                Ave = (CorrA_short + CorrB_short)/2;
                Residual = (CorrA_short - CorrB_short)/2;
                Ave_rms_temp = Ave_rms_temp + (mean(Ave.^2)^0.5);
                Residual_rms_temp = Residual_rms_temp + (mean(Residual.^2)^0.5);
                %Atten_temp = Atten_temp + leq(Ave, length(Ave))- leq(Residual,length(Residual));
                
                Counter = Counter +1;
            end

            CorrCoeff_NB_short_PP (OB_count,seg_count) = CorrCoeff_temp/Counter;                               %Correlation, Short, NB
            Atten_NB_short_PP(OB_count,seg_count) = 20*log10(Ave_rms_temp/Counter) - 20*log10(Residual_rms_temp/Counter); %Atten, Short, NB
            %Atten_NB_short_PP(OB_count,seg_count) = Atten_temp/Counter;                                        %Atten, Short, NB
        end     
        
    %% PN part
        %Long term quantification (1 min)
        %Extract Repetiton 2 and 3
        Raw_A = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (1)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (1)*passage_interval + passage_interval]);

        Raw_B = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (2)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (2)*passage_interval + passage_interval]);

        %Raw_B = Raw_B.*scaler_linear';

        %WB correlation. Wideband is from 160 to 8k Hz
        [B,A] = butter(N/2, [Fc1 Fc2]/(Fs/2));      %bandpass filter 160 to 8k Hz (SII range)
        CorrA = filter(B,A,Raw_A);
        CorrB = filter(B,A,Raw_B);
        %remove first and last 30 ms
        CorrA = CorrA (short_term_duration: length(CorrA)-short_term_duration); 
        CorrB = CorrB (short_term_duration: length(CorrB)-short_term_duration);
        CorrCoeff_WB_long_PN (1,seg_count)  = corr(CorrA, CorrB);                                              %Correlation, Long, WB

        %Quantification method 2: The amount of attenuation
        Ave = (CorrB - CorrA)/2;
        Residual = (CorrA + CorrB)/2;
        Atten_WB_long_PN(1,seg_count) = leq(Ave, length(Ave))- leq(Residual, length(Residual));                %Atten, Long, WB

        %short term, WB quantification (1000 ms) 
        %%
% %         === Old part from V6 ===
% %         tempA = [];
% %         tempB = [];
% %         for ixx = 1: length (HINT_noPause_start)
% %             tempA = cat(1, tempA, Raw_A (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %             tempB = cat(1, tempB, Raw_B (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %         end
% % 
% %         CorrA = filter(B,A,tempA);
% %         CorrB = filter(B,A,tempB);
%%


        Counter = 0;
        CorrCoeff_temp = 0;
        %Atten_temp = 0;
        Ave_rms_temp = 0;
        Residual_rms_temp = 0;

        for uu = 1: short_term_duration :length(CorrA)-short_term_duration    
            CorrA_short = CorrA(uu: uu+ short_term_duration);
            CorrB_short = CorrB(uu: uu+ short_term_duration);

            %Correlation
            CorrCoeff_temp = CorrCoeff_temp + corr(CorrA_short, CorrB_short);

            %Amount of attenuation
            Ave = (CorrB_short - CorrA_short)/2;
            Residual = (CorrA_short + CorrB_short)/2;
            Ave_rms_temp = Ave_rms_temp + (mean(Ave.^2)^0.5);
            Residual_rms_temp = Residual_rms_temp + (mean(Residual.^2)^0.5);
            %Atten_temp = Atten_temp + leq(Ave, length(Ave))- leq(Residual, length(Residual));

            Counter = Counter +1;
        end
            CorrCoeff_WB_short_PN (1,seg_count) = CorrCoeff_temp/Counter;                                      %Correlation, Short, WB
            Atten_WB_short_PN(1,seg_count) = 20*log10(Ave_rms_temp/Counter) - 20*log10(Residual_rms_temp/Counter); %Atten, Short, WB
            %Atten_WB_short_PN(1,seg_count)= Atten_temp/Counter;                                                %Atten, Short, WB


        %NB calculation
        for OB_count = 9: 26    %from 160 to 8000 Hz    
            %Filter
            [B,A] = oct3dsgn(Fre(OB_count),Fs);
            CorrA_temp = filter(B,A,Raw_A); 
            CorrB_temp = filter(B,A,Raw_B); 
            %remove first and last 30 ms
            CorrA_OB = CorrA_temp (short_term_duration: length(CorrA_temp)-short_term_duration); 
            CorrB_OB = CorrB_temp (short_term_duration: length(CorrA_temp)-short_term_duration);

            %Correlation, Long, NB
            CorrCoeff_NB_long_PN (OB_count, seg_count)  = corr(CorrA_OB, CorrB_OB);                            %Correlation, long, NB

            Ave = (CorrB_OB - CorrA_OB)/2;  
            Residual = (CorrA_OB + CorrB_OB)/2;    
            Atten_NB_long_PN (OB_count, seg_count)= leq(Ave, length(Ave))- leq(Residual, length(Residual));    %Atten, Long, NB

            %short term quantification (1000 ms)    
            %%
% %             CorrA_OB = filter(B,A,tempA); 
% %             CorrB_OB = filter(B,A,tempB); 
%%

            Counter = 0;
            CorrCoeff_temp = 0;
            %Atten_temp = 0;
            Ave_rms_temp = 0;
            Residual_rms_temp = 0;

            for uu = 1: short_term_duration :length(CorrA_OB)-short_term_duration  
                CorrA_short = CorrA_OB(uu: uu+ short_term_duration);
                CorrB_short = CorrB_OB(uu: uu+ short_term_duration);

                %Correlation
                CorrCoeff_temp = CorrCoeff_temp + corr(CorrA_short, CorrB_short);

                %Attenuation
                Ave = (CorrB_short - CorrA_short)/2;
                Residual = (CorrA_short + CorrB_short)/2;
                Ave_rms_temp = Ave_rms_temp + (mean(Ave.^2)^0.5);
                Residual_rms_temp = Residual_rms_temp + (mean(Residual.^2)^0.5);
                %Atten_temp = Atten_temp + leq(Ave, length(Ave))- leq(Residual, length(Residual));

                Counter = Counter +1;
            end

            CorrCoeff_NB_short_PN (OB_count,seg_count) = CorrCoeff_temp/Counter;                               %Correlation, Short, NB
            Atten_NB_short_PN(OB_count,seg_count) = 20*log10(Ave_rms_temp/Counter) - 20*log10(Residual_rms_temp/Counter);%Atten, Short, NB
            %Atten_NB_short_PN(OB_count,seg_count) = Atten_temp/Counter;                                        %Atten, Short, NB
        end     
    
    


    %%            
        %SNR calculation    Repetition 4 vs. 5
        %Obtain speech and nosie
        Raw_A = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (3)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (3)*passage_interval + passage_interval]);

        Raw_B = wavread (pathway_results,...
             [start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (4)*passage_interval+1,...
             start_point_noise + silent_interval + seg_interval*(seg_count-1)  + (4)*passage_interval + passage_interval]);

        %Raw_B = Raw_B.*scaler_linear';

        mean_passage = (Raw_A + Raw_B)/2;
        mean_noise = (Raw_A - Raw_B)/2; 

        %WB SNR
        %filter from 160 to 8k Hz (SII range)
        [B,A] = butter(N/2, [Fc1 Fc2]/(Fs/2));      
        mean_passage_160_8 = filter(B,A,mean_passage);
        mean_noise_160_8 = filter(B,A,mean_noise);
        %remove first and last 30 ms
        mean_passage_160_8 = mean_passage_160_8 (short_term_duration: length(mean_passage_160_8)-short_term_duration); 
        mean_noise_160_8 = mean_noise_160_8 (short_term_duration: length(mean_noise_160_8)-short_term_duration);

        LTSNR_WB (1,seg_count) = ...
            leq( mean_passage_160_8, length( mean_passage_160_8)) - leq(mean_noise_160_8, length(mean_noise_160_8));    %SNR, Long, WB

        %Short term SNR
        %%
% %         tempA = [];
% %         tempB = [];
% %         for ixx = 1: length (HINT_noPause_start)
% %             tempA = cat(1, tempA, mean_passage (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %             tempB = cat(1, tempB, mean_noise (HINT_noPause_start(ixx):HINT_noPause_end(ixx)));
% %         end
% % 
% %         mean_passage_160_8 = filter(B,A,tempA);
% %         mean_noise_160_8 = filter(B,A,tempB);
%%

        tempSNR = 0;
        cc = 0;
        passage_rms_temp = 0;
        noise_rms_temp = 0;

      
        for uu = 1: short_term_duration :length( mean_passage_160_8)-short_term_duration
            passage_short = mean_passage_160_8(uu: uu+short_term_duration);
            noise_short = mean_noise_160_8(uu: uu+short_term_duration);
            passage_rms_temp = passage_rms_temp + (mean(passage_short.^2)^0.5);
            noise_rms_temp = noise_rms_temp + (mean(noise_short.^2)^0.5);
            
            % tempSNR = tempSNR + leq( passage_short, length( passage_short)) - leq(noise_short, length(noise_short));
            cc = cc +1;

        end
        STSNR_WB (1,seg_count)= 20*log10(passage_rms_temp/cc) - 20*log10(noise_rms_temp/cc);                    %SNR, Short, WB                                                         %SNR, Short, WB

        %NB SNR    
        for OB_count = 9: 26    %from 160 to 8000 Hz    
            %Filter
            [B,A] = oct3dsgn(Fre(OB_count),Fs);
            mean_passage_OB = filter(B,A,mean_passage); 
            mean_noise_OB = filter(B,A,mean_noise); 
            %remove first and last 30 ms
            mean_passage_OB = mean_passage_OB (short_term_duration: length(mean_passage_OB)-short_term_duration);
            mean_noise_OB = mean_noise_OB (short_term_duration: length(mean_noise_OB)-short_term_duration);

            LTSNR_NB (OB_count,seg_count) = ...
                leq( mean_passage_OB, length( mean_passage_OB)) - leq(mean_noise_OB, length(mean_noise_OB));            %SNR, Long, NB

            %short term SNR OB (30 ms)  
            %%
% %             mean_passage_OB = filter(B,A,tempA);
% %             mean_noise_OB = filter(B,A,tempB);
%%

            tempSNR = 0;
            cc = 0;
            passage_rms_temp = 0;
            noise_rms_temp = 0;
        
            for uu = 1: short_term_duration :length(mean_passage_OB)-short_term_duration  
                mean_passage_OB_short = mean_passage_OB(uu: uu+ short_term_duration);
                mean_noise_OB_short = mean_noise_OB(uu: uu+ short_term_duration);
                passage_rms_temp = passage_rms_temp + (mean(mean_passage_OB_short.^2)^0.5);
                noise_rms_temp = noise_rms_temp + (mean(mean_noise_OB_short.^2)^0.5);
                
                %tempSNR = tempSNR + leq( mean_passage_OB_short, length( mean_passage_OB_short)) - leq(mean_noise_OB_short, length(mean_noise_OB_short));
                cc = cc +1;
            end
            STSNR_NB (OB_count,seg_count)= 20*log10(passage_rms_temp/cc) - 20*log10(noise_rms_temp/cc);         %SNR, Short, NB
            %STSNR_NB (OB_count,seg_count)= tempSNR/cc;                                                              

        end            

    end
    xlswrite (pathXLS, LTSNR_WB, 'LTSNR_WB');
    xlswrite (pathXLS, LTSNR_NB, 'LTSNR_NB');
    xlswrite (pathXLS, STSNR_WB, 'STSNR_WB');
    xlswrite (pathXLS, STSNR_NB, 'STSNR_NB');


    xlswrite (pathXLS, CorrCoeff_WB_long_PP, 'CorrCoeff_WB_long_PP');
    xlswrite (pathXLS, CorrCoeff_NB_long_PP, 'CorrCoeff_NB_long_PP');
    xlswrite (pathXLS, CorrCoeff_WB_short_PP, 'CorrCoeff_WB_short_PP');
    xlswrite (pathXLS, CorrCoeff_NB_short_PP, 'CorrCoeff_NB_short_PP');

    xlswrite (pathXLS, CorrCoeff_WB_long_PN, 'CorrCoeff_WB_long_PN');
    xlswrite (pathXLS, CorrCoeff_NB_long_PN, 'CorrCoeff_NB_long_PN');
    xlswrite (pathXLS, CorrCoeff_WB_short_PN, 'CorrCoeff_WB_short_PN');
    xlswrite (pathXLS, CorrCoeff_NB_short_PN, 'CorrCoeff_NB_short_PN');

    xlswrite (pathXLS, Atten_WB_long_PP, 'Atten_WB_long_PP');
    xlswrite (pathXLS, Atten_NB_long_PP, 'Atten_NB_long_PP');
    xlswrite (pathXLS, Atten_WB_short_PP, 'Atten_WB_short_PP');
    xlswrite (pathXLS, Atten_NB_short_PP, 'Atten_NB_short_PP');

    xlswrite (pathXLS, Atten_WB_long_PN, 'Atten_WB_long_PN');
    xlswrite (pathXLS, Atten_NB_long_PN, 'Atten_NB_long_PN');
    xlswrite (pathXLS, Atten_WB_short_PN, 'Atten_WB_short_PN');
    xlswrite (pathXLS, Atten_NB_short_PN, 'Atten_NB_short_PN');
    
    if GGGGset == 1
    else
        
        %For Summary
        ssss = num2str(GGGG);
        xlswrite (pathXLS_summary, filename(GGGG), 'LTSNR_WB', ['A',ssss]);
        xlswrite (pathXLS_summary, LTSNR_WB, 'LTSNR_WB', ['B',ssss]);
        
        xlswrite (pathXLS_summary, filename(GGGG), 'CorrCoeff_WB_long_PP', ['A',ssss]);
        xlswrite (pathXLS_summary, CorrCoeff_WB_long_PP, 'CorrCoeff_WB_long_PP', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'CorrCoeff_WB_short_PP', ['A',ssss]);
        xlswrite (pathXLS_summary, CorrCoeff_WB_short_PP, 'CorrCoeff_WB_short_PP', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'CorrCoeff_WB_long_PN', ['A',ssss]);
        xlswrite (pathXLS_summary, CorrCoeff_WB_long_PN, 'CorrCoeff_WB_long_PN', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'CorrCoeff_WB_short_PN', ['A',ssss]);
        xlswrite (pathXLS_summary, CorrCoeff_WB_short_PN, 'CorrCoeff_WB_short_PN', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'Atten_WB_long_PP', ['A',ssss]);
        xlswrite (pathXLS_summary, Atten_WB_long_PP, 'Atten_WB_long_PP', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'Atten_WB_short_PP', ['A',ssss]);
        xlswrite (pathXLS_summary, Atten_WB_short_PP, 'Atten_WB_short_PP', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'Atten_WB_long_PN', ['A',ssss]);
        xlswrite (pathXLS_summary, Atten_WB_long_PN, 'Atten_WB_long_PN', ['B',ssss]);

        xlswrite (pathXLS_summary, filename(GGGG), 'Atten_WB_short_PN', ['A',ssss]);
        xlswrite (pathXLS_summary, Atten_WB_short_PN, 'Atten_WB_short_PN', ['B',ssss]);
    end
    
end




AA = wavread (pathway_done);
wavplay(AA, 44100);
wavplay(AA, 44100);
wavplay(AA, 44100);
toc