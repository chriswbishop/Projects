function LoopPlayback(X, Y, varargin)

nchans=8;
[X, FS]=AA_loaddata(X); 
X=X*ones(1, nchans); 
X=resample(X, 44100, FS); 
% [Y, FS]=AA_loaddata(Y);

InitializePsychSound;
portaudio = PsychPortAudio('Open', 20, [], 0, 44100, size(X,2)); 

% Divide X into chunks
%   Load it into the buffer in chunks
nreps=10; 
nblocks=3;
blocksize=ceil(size(X,1)/nblocks); %
disp(num2str(blocksize/FS)); 
% nblocks=ceil(size(X,1)/blocksize); 

% Fill sound buffer with first two blocks
PsychPortAudio('FillBuffer', portaudio, X(1:blocksize*2,:)');

% Fill buffer as we move through
for i=3:nblocks
    
    % Start two-channel audio playback
    PsychPortAudio('Start', portaudio, inf, 0, 1, [], 1);  
    
    % Wait for block to finish
    status=PsychPortAudio('GetStatus', portaudio);
    startpos=status.PositionSecs; 
    while status.PositionSecs - startpos <blocksize/FS
        status=PsychPortAudio('GetStatus', portaudio);
    end % Loop for a bit
    
    % If it's even, replace the second half of buffer
    %   If it's odd, replace the first half of buffer
    if mod(i,2)==0
        sindex=1;
       % For even sounds, replace the first half of buffer
%        PsychPortAudio('FillBuffer', portaudio, X(1+(i-1)*blocksize:i*blocksize,:)', 1, 1);
    else
        sindex=1+blocksize*2;
%        PsychPortAudio('FillBuffer', portaudio, X(1+(i-1)*blocksize:i*blocksize,:)', 1, 1+blocksize*2);
    end % 
    
    if i==nblocks 
        PsychPortAudio('FillBuffer', portaudio, X(1+(i-1)*blocksize:size(X,1),:)', 1, sindex);
    else
        PsychPortAudio('FillBuffer', portaudio, X(1+(i-1)*blocksize:i*blocksize,:)', 1, sindex);
    end % if i==nblocks
    
end % for i=3:nblocks

% for i=1:nblocks
       
%     if i==1
%         PsychPortAudio('FillBuffer', portaudio, zeros(size(X))');
%         PsychPortAudio('FillBuffer', portaudio, X(1+blocksize*(i-1):blocksize*i,:)');
%         PsychPortAudio('FillBuffer', portaudio, X(1:blocksize*(nblocks-1))');
%         PsychPortAudio('Start', portaudio, 2, 0, 1, [], 1);  
%   
%         status=PsychPortAudio('GetStatus', portaudio);
%         while status.PositionSecs<blocksize/FS
%             status=PsychPortAudio('GetStatus', portaudio);
%         end % Loop for a bit
%         
%         PsychPortAudio('FillBuffer', portaudio, Y', 1);
% %     end % if i==1:
%     
% % end % for i=1:nblocks
% 
% disp('Blah');
%         
