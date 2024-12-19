% This file is to visualize real-time full raster scan. First, upload the arduino code.
clear all
close all
clc

addpath("..\utils\")

port = serialportlist;
N = 1024;
s1 = serialport(port(1),12E6);
flush(s1);

f = figure;
f.Position = [00 00 1000 2000];
while(1)
    try
        input1 = split(readline(s1),',');
    catch
        s1 = serialport(port,12E6);
        disp('re-connected')
        flush(s1)
    end
    if length(input1)<1025
        continue
    end
    vals1 = double(input1(1:N));
    t = double(input1(end)) / 1e6;
    fs = 1/t;

    img1 = reshape(vals1,[32,32]);
    img1 = img1';
    img1(img1<0)=0;
    img1 = insoleConv(img1);
    imagesc(img1);
    axis equal;
    colorbar;
    clim([0 1023]);
    disp(t);
    drawnow
    flush(s1)
end
