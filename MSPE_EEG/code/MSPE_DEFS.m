%% DESCRIPTION
%
%   Store MSPE and PEA Condition names and other defaults.
%
%   Here's a key to the code:
%       AB_CD;
%           A:  Leading side of sound
%           B:  Lagging side of sound (if no echo, X)
%           C:  Timing of light (P, Primary, S, Secondary)
%           D:  Position of light (L, Left, R, Right);
%
% Bishop, Chris Miller Lab 2010

nNRESP=0:1:2;
DEF_SMP_TWIN=[0 2000];

%% Reference CONDition
rCOND={ ...
    'RL_YY', ...    % 1
    'LR_YY', ...    % 2
    'RL_PR', ...    % 3
    'LR_PL', ...    % 4
    'RL_SL', ...    % 5
    'LR_SR', ...    % 6
    'LX_YY', ...    % 7
    'RX_YY', ...    % 8
    'LX_PL', ...    % 9
    'RX_PR', ...    % 10
    'LX_SR', ...    % 11
    'RX_SL', ...    % 12
    'RL_PL', ...    % 13, for PEA
    'LR_PR', ...    % 14, for PEA
    'Blank', ...    % 15, Blanks (important for EEG sometimes)
    'RL_R(+100)', ... % 16, right leading sound, light delayed by 100 msec
    'LR_L(+100)', ... % 17
    'RL_R(+400)', ... % 18
    'LR_L(+400)', ... % 19
    'RL_L(+100)', ... % 20
    'LR_R(+100)', ... % 21
    'RL_L(+400)', ... % 22
    'LR_R(+400)', ... % 23
    'DOUBLE(L)', ... % 24
    'DOUBLE(R)', ... % 25 
   'TEMP1', ... % 26
    'TEMP2', ... % 27
    'TEMP3', ... % 28
    'TEMP4', ... % 29
    'TEMP5', ... % 30
    'RX_PL', ... % 31
    }; % rCOND