function hrtf2wav(HDS, OUTDIR)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

hrir=HDS.hrir;
for i=1:size(hrir,3)
    wavwrite(hrir(:,:,i), HDS.fs,fullfile(OUTDIR, [HDS.sub '_' num2str(HDS.thetaVec(i)) '.wav']));
end % i