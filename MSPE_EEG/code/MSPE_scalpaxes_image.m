function MSPE_scalpaxes_image(data,args)
%% DESCRIPTION:
%
% INPUT:
%
%   args.   
%       title
%       freqs
%       times
%       chanlocs
%
% OUTPUT:
%
%

%set up the axes and get the handles
H=scalpaxes(args.chanlocs,args.title);

%normalize data to give maximum contrast
% nval=max(max(max(abs(data))));
% ndata=(data./nval+1).*(length(colormap)/2); %this ensures that a 0 value is always the middle of the colormap

for c=1:length(H)
    h=imagesc(args.times,args.freqs,data(:,:,c),'parent',H(c));
    set(H(c),'ydir','norm')
    set(h,'ButtonDownFcn',@solo_image);
    title(H(c),args.chanlocs(c).labels);
    
    %might want to control these from args...
    xlabel(H(c),'Time (msec)')
    ylabel(H(c),'Frequency (Hz)')
    
    set(H(c),'Visible','off');
end

function solo_image(h,callback)

times=get(h,'xdata');
freqs=get(h,'ydata');
data=get(h,'cdata');
titletxt=get(get(get(h,'parent'),'title'),'string');
xtxt=get(get(get(h,'parent'),'xlabel'),'string');
ytxt=get(get(get(h,'parent'),'ylabel'),'string');
name=get(ancestor(h,'figure'),'name');

figure,imagesc(times,freqs,data);
set(gca,'ydir','norm')
title(titletxt);
xlabel(xtxt);
ylabel(ytxt);
set(gcf,'name',name);
colorbar