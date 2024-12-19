% This is function for determining the coordinates of points of region of
% objects. The sensor is assumed to be size of 32x32.
% Input: an array of coordinates (1d, 0-1023) and an array of values of
% sampled points
% Output: an array of coordinates of region points (2d, (1-32)x(1-32))
function regionArr = regionFind(x,y,opt)

if (isfield(opt,'touchThreshold'))
    touchThreshold=opt.touchThreshold;
else
    touchThreshold=0;
end
msrNum=length(x);

% initialize the 2d array for storage of contour coordinate points
regionArr=[];

for i=1:msrNum
    temp=x(i);
    x1=floor(temp/32)+1; % 1-32
    x2=mod(temp,32)+1; % 1-32

    if y(i)>touchThreshold
        regionArr=[regionArr;x1,x2];
    end
end
