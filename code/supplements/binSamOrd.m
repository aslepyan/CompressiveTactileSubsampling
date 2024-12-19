% This file is for determining the order of binary sampling pattern.
% First, upload "binSamOrd.ino", where the function for creating the
% pattern was written.
clear;

% param
N = 225;
visNPixel = 55;

% acquire the binary postion pattern from the sensor
port = serialportlist;
s = serialport(port(1),12E6);
flush(s);
while(1)
    try
        input = split(readline(s),',');
    catch
        s = serialport(port,12E6);
        disp('re-connected')
        flush(s)
    end
    if length(input)<2*N+1
        continue
    end
    break;
end

% data processing
temp = double(input(1:2*N));
temp = temp+1;

ncol = sqrt(N);
nrow = sqrt(N);
binSamOrdMat = 0*ones(nrow,ncol);
i=1;
k=1;
while (k<=visNPixel)
    binSamOrdMat(temp(i),temp(i+1))=k;
    i=i+2;
    k=k+1;
end

% visualization
f1 = figure("Name",sprintf("sam order for bin sam"),'Position', [0,0,800,1000]);
imagesc(binSamOrdMat)
colorbar;
clim([1 visNPixel]);
axis equal;
colormap gray;

% save fig
folder = '..\..\paperFig\figS_samOrd\';
filePath = fullfile(folder, 'binSamOrd.fig');
saveas(gcf, filePath);
