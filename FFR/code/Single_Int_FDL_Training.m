function varargout = Single_Int_FDL_Training(varargin)
%% This file will test Tone Detection in Noise using a single-interval,
% yes/no procedure with the Method of Constant Stimuli. The signal level
% will stay constant, and the noise level will vary to change SNR.
% Use Example:
%   Single_Int_FDL_Training (parameter_file), where parameter_file is an m-file
%   function stored in the same folder as the m-files for this gui.
%
%   131015 CWB: Would be useful to have the ability to pickup where we left
%   off in the event the test crashes in the middle. Will need to implement
%   this functionality. 
%
%%
%SINGLE_INT_FDL_TRAINING M-file for Single_Int_FDL_Training.fig
%      SINGLE_INT_FDL_TRAINING, by itself, creates a new SINGLE_INT_FDL_TRAINING or raises the existing
%      singleton*.
%
%      H = SINGLE_INT_FDL_TRAINING returns the handle to a new SINGLE_INT_FDL_TRAINING or the handle to
%      the existing singleton*.
%
%      SINGLE_INT_FDL_TRAINING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SINGLE_INT_FDL_TRAINING.M with the given input arguments.
%
%      SINGLE_INT_FDL_TRAINING('Property','Value',...) creates a new SINGLE_INT_FDL_TRAINING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Single_Int_FDL_Training_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Single_Int_FDL_Training_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Single_Int_FDL_Training

% Last Modified by GUIDE v2.5 12-Oct-2013 21:44:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Single_Int_FDL_Training_OpeningFcn, ...
                   'gui_OutputFcn',  @Single_Int_FDL_Training_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before Single_Int_FDL_Training is made visible.
function Single_Int_FDL_Training_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Single_Int_FDL_Training (see VARARGIN)

% Choose default command line output for Single_Int_FDL_Training
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Single_Int_FDL_Training wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = Single_Int_FDL_Training_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in stim_button.
function stim_button_Callback(hObject, eventdata, handles)
% hObject    handle to stim_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in yes.
function yes_Callback(hObject, eventdata, handles)

% hObject    handle to yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SUBJECT_RESPONSE
SUBJECT_RESPONSE = 1;
end

% --- Executes on button press in no.
function no_Callback(hObject, eventdata, handles)
  
% hObject    handle to no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SUBJECT_RESPONSE
SUBJECT_RESPONSE = 0;
end

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global START
START = 3;
end

% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
% hObject    handle to next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global NEXT
NEXT = 1;
end

% --- Executes on button press in Go.
function Go_Callback(hObject, eventdata, handles)
% hObject    handle to Go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'enable','off','string','...');

global SUBJECT_RESPONSE NEXT

%% Pre-Processing
[args] = Single_Int_FDL_Training_parameter_file; % Load testing parameters (e.g. ISI)
[answer] = info_prompt;   % Get subject #, Age, run/block #, and frequency
args.subject_id   = answer(1);               args.age  = answer(2);
args.freq = answer(3);               args.block_number = answer(4);

frequency  = str2double(args.freq{:});

  % make filename for .mat file (e.g. 111_ToneInNx500Hz_b1TIMESTAMP.mat)
  % %%%%% CGC: MAY ADD if statement to include TRAIN or TEST in the filename  %%%%%%
  % %%%%%  CGC: MAY ALSO ADD SESSION # or 'pre' 'train' or 'post' to filename.
  
ofile = ['../behavior/', num2str(args.subject_id{:}) '_FDL_' num2str(frequency) 'Hz_b' num2str(args.block_number{:})];

%% 131016 CWB: Check to see if file already exists
if exist(ofile, 'file')
    warning([ofile ' already exists!']);
    ow = input('Overwrite file? (Y/N)');
    ow = upper(ow); % force upper case
else
    ow = 'Y'; % "overwrite" flag set to 'Y' by default
end % end file check

% Exit function if we don't want to overwrite
if strcmp(ow, 'N')==1
    return
end 
pause(1.0);

%% Check to do practice/familiarization run
if strcmpi(answer(5), 'yes') == 1   % YES, this is a training run
  args.par_vals =  [0 10 20 40];% deltaf here, shorten number of stimulus levels; 

  par_vals =  args.par_vals;   % assign stimulus levels from parameter file
  args.n_trialsperstim = 3;    % this many trials per stimulus, in practice
  filename = [filename '_PRACT`ICE_'];
else
  par_vals   = args.par_vals;  % test these conditions (delta f)
end

% 131014 CWB: Seed random number generator so we don't get the same
% sequence of events each time.
rng('shuffle', 'twister');

 % Randomize order of signal parameters in Signal+Noise and Noise trials
par_vals   = repmat(par_vals,1,args.n_trialsperstim); % preset numbers
par_vals   = par_vals(randperm(length(par_vals)));    % shuffle trials
catch_vals = par_vals(randperm(length(par_vals)));    % shuffle trials

 % Randomize order of signal+noise and noise trials
 % Make equal numbers of S+N and N trials; 1 is S+N trial, 0 is N trial
order      = [ones(1,length(par_vals))      zeros(1,length(par_vals))];  
% order      = [ones(1,length(par_vals))      ones(1,length(par_vals))];%all S+N trials

order      = order(randperm(length(order))); % shuffle order of S+N and N trials

%  % AM Tone will have two halves:
% carrier_freq1 = frequency; % First part of AM tone has freq of 1000 Hz.
%                            % 2nd half of AM stimulus has freq of par_vals
%% Calibrate?
calibrate = 0;                   % 0 will run normal, 1 will calibrate
if calibrate == 1                % calibrate at poorest SNR(loudest noise)

   par_vals = [0 20 40];

%    order = order(ones(1,length(par_vals)*2)); % present all signal trials
   order = ones(1,length(par_vals)*5); % present all signal trials

    %Ask if calibration mode should be on (Function at end of m-file).
   calibration_check; 
end

safety_check; % Safety Check: Prompt lab staff to check attenuator settings

%%% Start button
set(handles.pushbutton8,'Visible','on');    
press_start = importdata('press_start.jpg');
set(handles.pushbutton8,'CDATA',press_start);

%%% When Start button is pressed
global START
START = nan;
while isnan(START);
    pause(0.5);
end

set(handles.pushbutton8,'Visible','off');

%% Main Trial Loop
stopnow = 0;                % whether to stop testing or not
i = 0;                      % trial number index
signal_trials = 0;          % signal trial index
catch_trials = 0;           % catch  trial index
grey = [0.925,0.94,0.847];
time_start = clock;         % Begin the stopwatch to run until end of test
while ~stopnow
    i = i+1;
    
  %%%% First frequency of tone is 1000 Hz; 2nd tone varies by deltaf
      % Order == 1 means SIGNAL+NOISE, Order == 0 means NOISE trial
     
      % change the stimulus for this trial (par_vals is spectrum level)
  if calibrate == 0
    if order(i) == 1;    % present SIGNAL+NOISE trial
      signal_trials = signal_trials + 1;
       % specify stimulus frequencies
%       [tone noise]  = make_tone_plus_noise(frequency, par_vals(signal_trials));  %%%%%%%%% 6/13/2012 
%       [tone_final] = make_AM_FDL_tones_2freq_4FFR(fs, carrier_freq1, carrier_freq2, calibrate, save_wav)
      carrier_freq2 = frequency - par_vals(signal_trials);
      [tone] = make_AM_FDL_tones_2freq_4FFR(args.samprate, frequency, carrier_freq2, false, false, args.AM, args.duration, false, 'SIN');
      par_by_trial(i) = par_vals(signal_trials);
      
    else                 % present NOISE only or CATCH trial
      catch_trials = catch_trials + 1;
%       [tone noise]  = make_tone_plus_noise(frequency, catch_vals(catch_trials));  %%%%%%%%% 6/13/2012 
       carrier_freq2 = frequency - catch_vals(catch_trials);
       %%% In Catch Trials, present both halves as the deltaf(e.g., 990 Hz)
      [tone] = make_AM_FDL_tones_2freq_4FFR(args.samprate, carrier_freq2, carrier_freq2, false, false, args.AM, args.duration, false, 'SIN');

      par_by_trial(i) = catch_vals(catch_trials);
    end
    
  elseif calibrate == 1
      signal_trials = signal_trials + 1;
      [tone noise]  = make_tone_plus_noise(frequency, par_vals(i), 1);

      par_by_trial(i) = par_vals(signal_trials);    
  end
      

     % buffer sounds with zeros to avoid transients at onset/offset in Win7
    % [tone noise] = buffer_sounds(args.samprate, tone, noise');
    [tone] = buffer_sounds(args.samprate, tone);
    
    %%%%% Plot tone and noise for debugging  %%%%%%
    % figure; plot(tone, 'r'); hold on; plot(noise)
    
      % Alert subject of upcoming trial
    SUBJECT_RESPONSE = nan;
    if args.warn_subject == 1  % make the stim button blink
      for k = 1:3
        set(handles.stim_button, 'BackgroundColor', 'b' );  % Warning Light
          pause(0.1)                        % hold color change for 500 ms
        set(handles.stim_button, 'BackgroundColor', grey);
          pause(0.1)
      end
        pause(0.4)  % insert pause between flashing & sound
    end
      % Turn buttons off so subject can only respond after end of sound.
    set(handles.yes, 'Enable', 'off');  set(handles.no, 'Enable', 'off');

      % Present Stimuli
    if order(i) == 1       % SIGNAL+NOISE trial
        set(handles.stim_button,'BackgroundColor', 'b' );
        %% 131016 CWB: Use audioplayer to allow play blocking.
        player = audioplayer(tone, args.samprate); 
        player.playblocking(); 
%           sound(tone   ,args.samprate);        
        set(handles.stim_button,'BackgroundColor', grey);
    else                   % NOISE trial
        set(handles.stim_button,'BackgroundColor', 'b' );
        player = audioplayer(tone, args.samprate); 
        player.playblocking(); 
%           sound(tone   ,args.samprate);   
        set(handles.stim_button,'BackgroundColor', grey);
    end

    % Record time to calculate 1) reaction time and 2) inter-trial time
    time_begin_trial(i,:) = clock; % Record timestamp after each trial
    tic;                           % toc will be used for reactiontime
    
    pause(0.2)          % Turn buttons back on & Get Subject's Response
    set(handles.yes, 'BackgroundColor', 'y' , 'Enable', 'on');
    set(handles.no , 'BackgroundColor', 'y' , 'Enable', 'on');
    while isnan(SUBJECT_RESPONSE)   % wait for user input
      pause(0.1);       % check every 0.1 seconds for response
    end
    toc  % Record reaction time (windows allegedly has jitter doing this)
    reaction_time(i) = toc;
      % Change button color so subject knows they responded.
    set(handles.yes, 'BackgroundColor', grey);
    set(handles.no , 'BackgroundColor', grey);
 
      % Was the subject's response correct?  
    response(i) =  SUBJECT_RESPONSE; 
    correct (i) = (SUBJECT_RESPONSE == 1 & order(i) == 1) |...
                  (SUBJECT_RESPONSE == 0 & order(i) == 0) ;

    % NOTE:          
    % if SUBJECT_RESPONSE == 1 is YES and args.order(i) == 1 then subject %
    %    correctly judged a signal to be present on that trial            %
    % else SUBJECT_RESPONSE == 0 is NO and args.order(i) == 0 then subject%
    %    correctly identified a noise only trial                          %
    %  correct(i) == 1 is correct, correct(i) == 0 is NOT correct         %

     % command line display during debugging
    if args.trial_display == 1
      str_correct = {'incorrect' 'correct'};    
      stim_type = {'Noise' 'Signal+Noise'};    
      fprintf('Trial %d (%s) SNR = %.2f dB; Tone Int: %.2f Response: %d (%s)\n', ...
        i,stim_type{order(i)+1},par_by_trial(i),args.intensity,response(i),str_correct{correct(i)+1});
    end    
     
    % Enable button for next trial
    set(handles.next,'enable','on')
    set(handles.next,'BackgroundColor','b');%Make "Next" button blue
    
    % 131015 CWB: Added OR isempty(NEXT) to satisfy first time through
    % loop. 
    NEXT = nan;
    while isnan(NEXT)
        pause(0.1)
    end
    
    set(handles.next,'BackgroundColor',[0.925,0.94,0.847]); 
    set(handles.next,'enable','off') % disable next button
    
  %% SAVE SUBJECT SPECIFIC MAT FILE AFTER EACH TRIAL
  % Save stack after each trial. This way if it crashes we can potentially
  % pick up where we left off. 
    % Save temporary .mat file after each trial, overwrite each time
     
    if calibrate < 1
        save(ofile);
    end
   
     % Time to stop test?
    if i >= length(order);       stopnow = 1;         end
    
end

time_end = clock; % End the stopwatch
test_duration = time_end - time_start;  % it took this long to complete the test
disp('DONE WITH THE TEST!')
close(gcf)                              % Close the GUI figure

  % Call Script to calculate d' and plot results
% FDL_Training_Post_Processing  
end

function [answer] = info_prompt
  % Open a dialog window asking for the info below
% prompt = {'Enter Participant Number:','Enter Participant Age:', 'Enter Block Number:', 'Enter Frequency:'};
% dlg_title = 'ToneInNx';    num_lines = 1;     default = {'000','', '', ''};
% answer = inputdlg(prompt,dlg_title,num_lines,default);

prompt = {'Enter Participant Number:'   , ...
          'Enter Participant Age:'      , ...
          'Enter Frequency:'            , ...
          'Enter Block Number'          , ...
          'Is this a training run?'     };
dlg_title = 'FDL';
num_lines = 1;
default = {'000','', '', '', 'NO'};
answer = inputdlg(prompt, dlg_title, num_lines, default);
end

function calibration_check
h = msgbox({'Program running in CALIBRATION Mode!' , ...
            '****        Is this right?      ****'},'','warn', 'modal' );
uiwait(h);   % Halt processing until Attenuator Check.
end

function safety_check
h = msgbox('Check Attenuator Settings','','help', 'modal' );
uiwait(h);   clear h info  % Halt processing until Attenuator Check.
end
