% This file is for the visualization of real-time reconstruction.
clear; close all; clc;

N = 1024;
thr = 180; % !!

clear s
port = serialportlist;
s = serialport(port,12E6);
flush(s);

f = figure;
f.Position = [400 200 600 500];
while(1)
    try
        input = split(readline(s),',');
    catch
        s = serialport(port,12E6);
        disp('re-connected')
        flush(s)
    end

    if length(input)<N+2
        continue;
    end

    vals = double(input(1:N));

    img = reshape(vals,[32,32]);
    img = img';
    img(img<=thr)=0;

    imagesc(img);
    drawnow

    delta_t = double(input(end))/1e3; % ms
    disp("sam: ");
    disp(delta_t);
    delta_t1 = double(input(end-1))/1e3; % ms
    disp("total: ");
    disp(delta_t1);

    flush(s)
end
