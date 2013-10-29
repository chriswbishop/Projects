function arw=PEEndA_arrow(SESS, n)
%Takes condition of current experiment and spits out appropriate arrow
%indicator.
%INPUTS
%SESS - Trial value matrix
%n - Current trial number
%OUTPUTS
%arw - Arrow indicator /0 = NULL/1 = LEFT/2 = RIGHT/

arwL = [4 5 9 12];
arwR = [3 6 10 11];
arw = 0;

cond = SESS(5, n);
if ~isempty(find(arwL == cond)) %#ok<EFIND>
    arw = 1;
end
if ~isempty(find(arwR == cond)) %#ok<EFIND>
    arw = 2;
end
