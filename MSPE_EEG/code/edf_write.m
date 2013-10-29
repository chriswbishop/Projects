function edf_write(data,hdr,filename)
%function to write european data format files (.edf) to be read by curry.
%Needed because eeglab's builting function doesn't seem to handle floating
%point data well. specs for .edf can be found @
%http://www.edfplus.info/specs/edf.html

%first, set some defaults

format('short') %prevent overspecifying floats and ruining the required field lengths

if ~isstruct(hdr), hdr=struct(); end

if ~isfield(hdr,'version') || isempty(hdr.version), hdr.version='0';end
if ~isfield(hdr,'subID') || isempty(hdr.subID), hdr.subID='';end
if ~isfield(hdr,'recID') || isempty(hdr.recID), hdr.recID='';end
if ~isfield(hdr,'startDate') || isempty(hdr.startDate), hdr.startDate=datestr(now,'dd.mm.yy');end
if ~isfield(hdr,'startTime') || isempty(hdr.startTime), hdr.startTime=datestr(now,'HH:MM:SS');end
hdr.numByte = (size(data,2)+1) * 256; %size of header depends on number of channels
if ~isfield(hdr,'reserved') || isempty(hdr.reserved), hdr.reserved='';end
hdr.numRec = size(data,3);
if ~isfield(hdr,'recDur') || isempty(hdr.recDur), hdr.recDur=size(data,1)/256; end %default to a sampling rate of 256
hdr.numChan = size(data,2);
if ~isfield(hdr,'label') || isempty(hdr.label), hdr.label=repmat({''},[1 hdr.numChan]);end
if ~isfield(hdr,'transducer') || isempty(hdr.transducer), hdr.transducer=repmat({''},[1 hdr.numChan]);end
if ~isfield(hdr,'units') || isempty(hdr.units), hdr.units=repmat({'uV'},[1 hdr.numChan]);end
if ~isfield(hdr,'phMin') || isempty(hdr.phMin), hdr.phMin=repmat(-max(max(max(abs(data)))),[1 hdr.numChan]);end
if ~isfield(hdr,'phMax') || isempty(hdr.phMax), hdr.phMax=-hdr.phMin;end
if ~isfield(hdr,'digMin') || isempty(hdr.digMin), hdr.digMin=repmat(-32767,[1 hdr.numChan]);end
if ~isfield(hdr,'digMax') || isempty(hdr.digMax), hdr.digMax=-hdr.digMin;end
if ~isfield(hdr,'prefilt') || isempty(hdr.prefilt), hdr.prefilt=repmat({''},[1 hdr.numChan]);end
if ~isfield(hdr,'numSamp') || isempty(hdr.numSamp), hdr.numSamp=repmat(size(data,1),[1 hdr.numChan]);end
if ~isfield(hdr,'chanReserved') || isempty(hdr.chanReserved), hdr.chanReserved=repmat({''},[1 hdr.numChan]);end


%now actually write the ascii header

%first the fixed part
fid=fopen(filename,'w');
fprintf(fid,'%-8s%-80s%-80s%-8s%-8s%-8d%-44s%-8d%-8f%-4d',...
    hdr.version,...
    hdr.subID,...
    hdr.recID,...
    hdr.startDate,...
    hdr.startTime,...
    hdr.numByte,...
    hdr.reserved,...
    hdr.numRec,...
    hdr.recDur,...
    hdr.numChan);

%there are a few values in the variable part of the header that can end up
%causing problems with overruns, so we'll fix those with some string magic
temp=num2str(hdr.phMin','%-8f'); %any sci-notation will mess things up
hdr.phMin=cellstr(temp(:,1:8)); %only take the first 8 chars

temp=num2str(hdr.phMax','%-8f'); %any sci-notation will mess things up
hdr.phMax=cellstr(temp(:,1:8)); %only take the first 8 chars


%now the variable parts
fprintf(fid,'%-16s',hdr.label{:});
fprintf(fid,'%-80s',hdr.transducer{:});
fprintf(fid,'%-8s',hdr.units{:});
fprintf(fid,'%-8s',hdr.phMin{:});
fprintf(fid,'%-8s',hdr.phMax{:});
fprintf(fid,'%-8d',hdr.digMin);
fprintf(fid,'%-8d',hdr.digMax);
fprintf(fid,'%-80s',hdr.prefilt{:});
fprintf(fid,'%-8d',hdr.numSamp);
fprintf(fid,'%-32s',hdr.chanReserved{:});

%here's the part eeglab doesn't do... normalize our values inside our
%range
percission=repmat(hdr.digMax,[size(data,1) 1 size(data,3)]);
data=round(data./str2num(hdr.phMax{1}).*percission);

%writing the data is simple because .edf wants things written in time x
%channel x epoch, which is what we already have
fwrite(fid,data,'int16');

fclose(fid);










