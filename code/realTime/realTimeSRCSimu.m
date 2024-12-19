% This file is for the simulation of real-time recon.
% load the pre-collected full raster tactile images data
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
addpath("..\utils\")
load(fullfile('..\..\data\traningData','traningData.mat'))

% basic params
pressThreshold = 50; % !!
ncol=32;
nrow=32;
classAcc = 0;
nTestWin = 10;
nObj = 30;
count = 0;

% connect the serial port
clear s
port = serialportlist;
s = serialport(port(1),12E6);

% loop for calculate the support acc
for iobj = 1:30%nObj %!!
    savedFullRasterData = savedTrainData(iobj).data;
    for iwin = 1:nTestWin %!!
        img0 = savedFullRasterData(:,iwin);
        img0 = reshape(img0,[ncol,nrow])';

        flush(s);
        % upload the image to arduino for simulated sub-sampling
        write(s, reshape(img0', 1, []), 'uint16');

        while(1)
            try
                input = split(readline(s),',');
            catch
                clear s
                s = serialport(port(1),12E6);
                disp('re-connected')
                flush(s)
                write(s, reshape(img0', 1, []), 'uint16');
            end

            if length(input)<1+1
                continue;
            end

            vals = double(input(1));

            % calculate the support acc
            classAcc = classAcc+(vals==iobj);
            count=count+1;
            break;
        end
    end
end

disp(classAcc/count);
clear s
