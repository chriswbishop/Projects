function results=MSPE_Events(args)
%% DESCRIPTION
%
%   Redefine event codes in EEG structure
%
% INPUT:
%
%   args:   nothing defined yet
%
% OUTPUT:
%
%   results:    
%
% Bishop, Chris Miller Lab 2010
%
% 100511CWB: 
%   -Changed code considerably to pair all responses with preceding
%   stimulus event. 
%   -Also allowed me to include misses (few, but they happen).


%% EEG Structure should already be loaded
global EEG;

% ind tracks the stimulus event number.
ind=0;
for s=1:length(EEG)
    IN=EEG.event;
    OUT=[]; %struct('type',[],'latency',[],'duration',[],'urevent',[]);
%     for e=1:length(IN)-1 %% 100511CWB: Commented
    for e=1:length(IN) %%100511CWB: Added
        switch num2str(IN(e).type)  %% 100426CWB: Added in num2str
                                    %% conversion here because pop_mergeset
                                    %% seems to convert all event types to
                                    %% strings. Had to merge files for
                                    %% s2102, so it's easier to just treat
                                    %% everything as a string.
        
            % STIMULUS ONSET
            case {'12', '21', '130', '65', '128', '64', '15', '7', '8'}
                ind=ind+1;
                
                % Define event as a miss by default (0=miss)
                OUT(ind).type=[num2str(IN(e).type) '0'];
                OUT(ind).latency=IN(e).latency;
                OUT(ind).duration=0;
                OUT(ind).urevent=[];
                
            % RESPONSE
            %   One or Two-locations. 
%             case {'1', '2'}
%                 % Redefine event if subject made a response
%                 OUT(ind).type(end)=num2str(IN(e).type); 
                
        end % switch IN(e).type
    end % e=1:length(IN)
    
    EEG(s).event=OUT;
    clear IN OUT;
end % s=1:length(EEG)

EEG = eeg_checkset(EEG, 'makeur');
results='done';