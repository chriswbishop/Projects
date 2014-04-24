function PlayVideo(P)

Screen('Preference', 'SuppressAllWarnings', 1); % Suppress screen warnings
Screen('Preference', 'SkipSyncTests', 2 );      % Skip calibration tests. We don't care. 
screenNum = 0;
[window, rect] = Screen('OpenWindow', screenNum, 1);
moviePtr = Screen('OpenMovie', window, P);
Screen('PlayMovie', moviePtr, 1); 