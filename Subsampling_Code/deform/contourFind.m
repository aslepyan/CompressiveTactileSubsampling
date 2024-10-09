% This is function for determining the coordinates of points of contour of
% objects. The sensor is assumed to be size of 32x32.
% Input: an array of coordinates (1d, 0-1023) and an array of values of
% sampled points
% Output: an array of coordinates of contour points (2d, (1-32)x(1-32))
function contourArr = contourFind(x,y,opt)

if (isfield(opt,'touchThreshold'))
    touchThreshold=opt.touchThreshold;
else
    touchThreshold=0;
end
msrNum=length(x);

% initialize the 2d array for storage of contour coordinate points
contourArr=[];

% initialize the 2d array for storage binary image of the raw data
BW=false(32,32);

for i=1:msrNum
    temp=x(i);
    x1=floor(temp/32)+1; % 1-32
    x2=mod(temp,32)+1; % 1-32

    if y(i)>touchThreshold
        BW(x1,x2)=true;
    end
end

for r1=1:size(BW,1)
    for c1=1:size(BW,2)
        if BW(r1,c1)==0
            continue;
        end
        contour = bwtraceboundary(BW,[r1 c1],'NW',8,20,'clockwise');
        contourArr = [contourArr;contour];
    end
end
