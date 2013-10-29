function [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF S]=MSPE_read(P)
%% DESCRIPTION:
%
%   Parse subject log files.
%
% INPUT:
%
%   P:  character array, each row is a full path to the logfile.
%
% OUTPUT:
%
% STIMULUS DATA
%
%   LAC:    see MSPE_stim
%   RAC:    see MSPE_stim
%   ALAG:   see MSPE_stim
%   VCOD:   see MSPE_stim
%   COND:   see MSPE_stim
%   VOFF:   see MSPE_stim (Note: this will be full of NaNs if a Visual 
%                                OFFset (VOFF) is not defined for the
%                                experiment).
%
% RESPONSE DATA
%
%   NRESP:  Number of objects RESPonse (NRESP). Response to question of
%           number of objects (1 or 2).
%   SRESP:  Side RESPonse (SRESP). Response to side objects are heard.
%   NRT:    Number of objects Reaction Time (NRT).
%   SRT:    Side of response Reaction Time (SRT).
%   STIME:  Stimulus TIME (STIME). Time of stimulus presentation as recorded 
%           in log file.
%
% OTHER:
%
%   S:      Session (S). Index into which logfile stimulus was  read from.
%
% Bishop, Chris Miller Lab 2010

%% INITIALIZE VARIABLES
%
% STIMULUS DATA
%
%   LAC:    see MSPE_stim
%   RAC:    see MSPE_stim
%   ALAG:   see MSPE_stim
%   VCOD:   see MSPE_stim
%   COND:   see MSPE_stim
%   VOFF:   see MSPE_stim
%
% RESPONSE DATA
%
%   NRESP:  Number of objects RESPonse (NRESP). Response to question of
%           number of objects (1 or 2).
%   SRESP:  Side RESPonse (SRESP). Response to side objects are heard.
%   NRT:    Number of objects Reaction Time (NRT).
%   SRT:    Side of response Reaction Time (SRT).
%   STIME:  Stimulus TIME (STIME). Time of stimulus presentation as recorded 
%           in log file.
%
% OTHER
%
%   S:      Session (S). Index into which logfile stimulus was  read from.
LAC=[];
RAC=[];
ALAG=[];
VCOD=[];
COND=[];
VOFF=[];
NRESP=[];
SRESP=[];
NRT=[];
SRT=[];
STIME=[];
S=[];
X=[];
Y=[];
%% READ LOG FILE
for f=1:size(P,1)
    
    % Open file
    ptr=fopen(P(f,:),'r');
    display(P(f,:));
    
    % Skip over header information
    for i=1:5 fgetl(ptr); end
    nl=fgetl(ptr);
    while isstr(nl)
        
        % PARSE NEW LINE (nl)
        [SID,rmd]=strtok(nl);
        [TRL,rmd]=strtok(rmd);
        [ET,rmd]=strtok(rmd);
        [COD,rmd]=strtok(rmd);
        [TIME,rmd]=strtok(rmd);
        [TTIME,rmd]=strtok(rmd);
        
        % PARSE SOUND ENTRIES
        if strcmp(ET,'Sound')
            
            % PARSE CODE ENTRY FOR SOUND
            [lac,rmd]=strtok(COD,';');
            [rac,rmd]=strtok(rmd,';');
            [alag,rmd]=strtok(rmd,';');
            [vcod,rmd]=strtok(rmd,';');
            [cond,rmd]=strtok(rmd,';');
            [voff,rmd]=strtok(rmd,';');
            
            % ASSIGN TO DATA ARRAYS
            LAC(end+1)=str2num(lac);
            RAC(end+1)=str2num(rac);
            ALAG(end+1)=str2num(alag);
            VCOD(end+1)=str2num(vcod);
            COND(end+1)=str2num(cond);
            
            % 101017CB: Reverse Compatibility
            % This line is primarily for reverse compatibility.  Older
            % experiments will not have this information defined.  We need
            % the reading script to work with both the old and the new. 
            try VOFF(end+1)=str2num(voff); catch VOFF(end+1)=NaN; end;
            
            % INITIALIZE RESPONSE VARIABLES
            NRESP(length(LAC))=0;
            SRESP(length(LAC))=0;
            NRT(length(LAC))=NaN;
            SRT(length(LAC))=NaN;
            
            % RECORD WHICH LOG FILE IT CAME FROM
            S(length(LAC))=f;
            
            % STIMULUS PRESENTATION TIMES
            %   Used when calculation response latencies below.
            [stime]=str2num(TIME);
            STIME(length(LAC))=stime;
            
        end % Sound
        
        % PARSE RESPONSE ENTRIES
        if strcmp(ET, 'Response')
            
            % PARSE RESPONSE DATA
            [resp]=str2num(COD);
            [rtime]=str2num(TIME);
            rt=(rtime-stime)./10; % convert to milliseconds
            
            % TOSS OUT BOGUS REACTIONS
            %   While looking at MSPE Reaction times, CB noticed that the
            %   response latency can almost completely predict response
            %   category. WEIRD! So, needed to toss out super short
            %   reactions.
            %
            %   OH, and we now convert to msec instead of tenths of
            %   milliseconds.   
%             if rt<100
%                 resp=0; % count it as a miss
%                 rt=NaN; % exclude reaction time
%             end 
            
            % BIN RESPONSES
            switch resp
                
                case {1, 2}
                    % Number of bjects RESPonse (NRESP)
                    NRESP(length(LAC))=resp;
                    NRT(length(LAC))=rt;                    
                case {3, 4, 5} % Explicitly listed response variables
                                     % to prevent future bugs. Keep it this
                                     % way.
                    % Side RESPonse
                    SRESP(length(LAC))=resp;
                    SRT(length(LAC))=rt;
            end % switch resp
        end % RESPONSE
        
        if strcmp(ET, 'Manual') && ~isempty(strfind(nl, ';'))
            [x rmd]=strtok(COD, ';');
            [y rmd]=strtok(rmd, ';');
            
            X(length(LAC))=str2num(x);
            Y(length(LAC))=str2num(y);
        end % Manual
        % Grab a new line
        nl=fgetl(ptr);
    end % while
    fclose(ptr);
end % f
        