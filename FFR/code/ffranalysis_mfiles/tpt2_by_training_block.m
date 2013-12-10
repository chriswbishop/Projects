function [s1,s2,s3,phase_results, k, b] = proj_m_tpt2(sx, sy, xtitle, ax, output, k, plot_width, x_position)
%function [p,pct2,pr,s1,s2,s3,phase_results] =%proj_m_tpt2(sx,sy,xtitle,ax,output)
% slightly revised Dec 2009 by Clinard.
% annotates figure with results; Modified for use with
% FFR_by_training_block.m
%
% revised version January 2008 by Picton.
% adds ax input (+ and - limits of polar plot)
% and makes figure have equal axes

% Terry Picton July 4 version 2000
% sx and sy are column vectors.  They are the real and imaginary output of
%        the FFT at a particular frequency bin, converted to polar form.
% xtitle is the title to use for the figure
% output to output figures and data within the program (1) or not (0).
%
% subroutine to look at the statistics for a set of 2D data
% t2, cicular t2, magnitude squared coherence, phase coherence 
% are calculated and 3 probabilities are returned (magnitude  
% squared coherence gives the same probability as circular T2).
%%
z = sx + i*sy;                             % set up to plot the data points; % Cartesian?
n = size(sx,1) * size(sx,2);               % the number of sweeps squared

%% ***** T2 (T-squared)calculations ******************************* 
% centre of the ellipse is mean
cx = mean(sx); 
cy = mean(sy);  %so, if this is circular phase data, is this a non-circular mean?

% calculate the variance covariance matrix and then T2
S = cov(sx,sy);                           % covariance matrix (2 x 2)
SX = inv(S);
cc = zeros(2,1);
cc(1,1) = cx; cc(2,1) = cy;               % assume that the real mean is 0
t2x = n * cc' * SX * cc;                               % T-squared value
f = t2x*(n-2)/(2*n-2);                                 % F-ratio
df1 = 2; df2 = n - 2;                                  % degrees of freedom
p = 1 - fcdf(f,df1,df2);                               % p-value



 s1 = sprintf('T2 = %.2f; F= %.2f; df = %.0f,%.0f; p= %.5f',t2x, f, df1, df2, p);
% if (output==1)
%  disp (s1);
% end
% a and b values 
t20 = ((2*n-2)/(n-2)) * finv(.95,df1,df2);   % basic t2 value for p = 0.05 
dum1 = 2 * SX(1,2);  
dum2 = SX(2,2) - SX(1,1);
phi = 0.5 * atan2(dum1,dum2); % "atan2(imag(z),real(z))" converts to polar, see help atan2.
e1 = t20/n;
e2 = cos(phi) * cos(phi);
e3 = cos(phi) * sin(phi);
e4 = sin(phi) * sin(phi);
a = sqrt(e1/(SX(1,1) * e2-2*SX(1,2) * e3+SX(2,2) * e4));
b = sqrt(e1/(SX(1,1) * e4+2*SX(1,2) * e3+SX(2,2) * e2));

% note that phi is in radians counter-clockwise from x axis

%% *****Ellipse for t squared ***************************************
% create ellipse with the necessary translation and rotation
% if (output == 1)
% NOTE: 4/9/2009 - Chris disabled this if loop so that
% the ellipse could be stored for later plotting, even when output ==0.

 R = zeros(3);
% rotation
 Q = zeros(3);
 Q(3,3) = 1;
 cc = cos(phi); ss = sin(phi);              % minus for counter-clockwise
 Q(1,1) = cc;
 Q(2,2) = cc;
 Q(1,2) = ss;
 Q(2,1) = -ss;
% translation
 P = zeros(3);                             
 P(1,1) = 1.0;
 P(2,2) = 1.0;
 P(3,3) = 1.0;
 P(1,3) = cx;           % cx and cy are means of input args sx and sy
 P(2,3) = cy;
% combine manipulation matrices
 R = P * Q;
% create ellipse 
 theta = 0:pi/50:2*pi;
 xx = a * cos(theta);
 yy = b * sin(theta);
% manipulate ellipse
 nn = 1:101;
 xxx(nn) = xx(nn) * R(1,1) + yy(nn) * R(1,2) + R(1,3); 
 yyy(nn) = xx(nn) * R(2,1) + yy(nn) * R(2,2) + R(2,3);

% make result complex for plotting
 zz = xxx + i*yyy;                  % in rectangular coordinate format
% end
% End of ellipse ***********************************

%% calculate the circular T2
sum = 0;
for j = 1:n;           % calculate sum of squared deviations from mean
   sum = sum + (sx(j)-cx)*(sx(j)-cx) + (sy(j)-cy)*(sy(j)-cy);
end  
ct2 = (n-1)*(cx*cx + cy*cy)/sum;    
fct2 = n * ct2;                                % F-ratio
df1 = 2; df2 = 2*n-2;                          % degrees of freedom
pct2 = 1 - fcdf(fct2,df1,df2);                 % p-value circular T-squared

 s2 = sprintf('CT2 = %.2f; F= %.2f; df = %.0f,%.0f; p= %.5f',...
     ct2,fct2,df1,df2,pct2);
% if (output==1)
%  disp (s2);
% end
% plot circle
% if (output == 1)
%  NOTE: 4/9/2009 - Chris disabled this if loop so that
% the ellipse could be stored for later plotting, even when output ==0.
 ct20 = (finv(.95,df1,df2)/n)*sum/(n-1);     % 95% confidence interval
 r = sqrt(ct20);
 theta = 0:pi/50:2*pi;
 xct = r * cos(theta);
 yct = r * sin(theta);
 zct = xct + cx + i*yct + i*cy;
% end
%% magnitude squared coherence (MSC)
sum = 0;
for j = 1:n;
   sum = sum + sx(j)*sx(j) + sy(j)*sy(j);
end  
gamma = n * (cx*cx + cy*cy)/sum;                            % gamma = MSC

%% calculate the phase coherence;  Converts from Cartesian to Polar.
sumc = 0;
sums = 0;
for j = 1:n % atan2(imag(z),real(z)) converts angle/phase from cartesian to polar
   theta = atan2(sy(j),sx(j));      % where sy is imaginary and sx is real
   sumc = sumc + cos(theta);        % Polar phase
   sums = sums + sin(theta);        % Polar phase
end
r = (sqrt(sumc*sumc + sums*sums))/n;            % r = phase coherence

% calculate the phase coherence probability according to Fisher p 70
zr = n * r*r;
pr = exp(-zr)*(1+(2*zr-zr*zr)/...
    (4*n)-(24*zr-132*zr*zr+76*zr*zr*zr-9*zr*zr*zr*zr)/(288*n*n));


   s3 = sprintf('MSC = %.4f;    PC = %.4f, p = %.5f',gamma,r,pr);
% if (output == 1)
%    disp(s3);
% end

%% Plot results
% axes
xa = zeros(1,101);
ya = zeros(1,101);
% line to the mean
ccx = [0,cx]; ccy = [0,cy];
ccx = ccx'; ccy = ccy';
ccc = ccx + i*ccy;

if (output == 1)
 b(k) = axes('Units', 'inches', ...
     'Position', [k*plot_width*1.1 1.5 plot_width plot_width],...
     'TickLength', [0.02 0.02], 'Box', 'On');
 %modify axes location for use with FFR_by_training_block60single.m
 if nargin > 7; set(b(k), 'Position', [x_position 1.5 plot_width plot_width]);
     
 hold on;
 axis equal;
 plot(z,'o'),       % z = sx + i*sy, make an Argand plot of all data points
%  ax = max(abs(sy))* 1.3;                   % pad axes by 30% 
 axis([-ax +ax -ax +ax]);
 plot(zz,'r','LineWidth',2);                 % ellipse from t-squared;  
 plot(zct,'g','LineWidth',2);                % circular t-squared's circle
 plot(ccc,'k', 'LineWidth', 2);              % line from (0,0) to mean
 plot(-1:.02:1,xa);  plot(ya,-1:.02:1);      % plot quadrant divisions
%  plot(zz,'r','LineWidth',2);                 % ellipse from t-squared;  
%  plot(zct,'g','LineWidth',2);                % circular t-squared's circle
 hold off;      
 if k > 1;  set(b(k), 'YTickLabel', '');      end
    %  set(b(k), 'XLabel', 'real (\muV)', 'YLabel', 'imaginary')
else
end 

 
 % re: Units for Argand Plot:
 % * Double tick label values for units to be in microvolts (as done in
 %    amplitude calculations of FFT data).  Not necessary for now.
 % * simply doubling the tick labels doesn't allow for adjustments when zoomed.
 % * a better alternative may just be multiplying all data by 2 when
 %    plotting?
% %  tick_labels = str2num(char(cellstr(get(h4,'XTickLabel')))) * 2; % get the tick labels
% %  tick_labels = num2str(tick_labels); % convert back to strings
% %  set(h4,'XTickLabel', tick_labels, 'YTickLabel', tick_labels);
 
 % add T-squared, circular T-squared, & MSC results:
 % tb1 = annotation('textbox','String',{'    Phase Analyses:', s1, s2, s3},...            
 %     'Position',[0.00 0.95 0.9 0.05]);
 % set(tb1, 'FitHeightToText','off','LineStyle','none');

%% Make a structure to sent to The calling function FFR_by_training_block.m
phase_results = struct('mean_real', cx, 'mean_imag', cy, ...
    'ellipse_t2', t2x, 'ellipse_t2_f', f, 'ellipse_t2_pval', p, ...
    'msc', gamma, 'phase_coherence', r, 'phase_coherence_pval', pr, ...
    'ellipse_t2_plot', zz, 'circle_t2_plot', zct, 'line_0_to_mean_plot', ccc);
end