% This file is for the simulation of real-time recon.
% load the pre-collected full raster tactile images data
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
addpath("..\utils\")
load(fullfile('..\..\data\traningData', 'traningData.mat'))

% basic params
pressThreshold = 50; % !!
N = 1024;
supAcc = 0;
nTestWin = 10;
nObj = 10;

% connect the serial port
clear s
port = serialportlist;
s = serialport(port,12E6);

% loop for calculate the support acc
for iobj = 1:nObj %!!
    savedFullRasterData = savedTrainData(iobj).data;
    for iwin = 1:nTestWin %!!
        img0 = savedFullRasterData(:,iwin);
        img0 = reshape(img0,[32,32])';

        flush(s);
        % upload the image to arduino for simulated sub-sampling
        write(s, reshape(img0', 1, []), 'uint16');

        while(1)
            try
                input = split(readline(s),',');
            catch
                clear s
                s = serialport(port,12E6);
                disp('re-connected')
                flush(s)
                write(s, reshape(img0', 1, []), 'uint16');
            end

            if length(input)<N+2
                continue;
            end

            vals = double(input(1:N));
            img1 = reshape(vals,[32,32]);
            img1 = img1';
            img1(img1<=pressThreshold)=0;
            img1(img1>1023)=1023;

            % calculate the support acc
            supAcc = supAcc+supportAcc(img0,img1,pressThreshold);

            % % check the image visually
            % figure;
            % subplot(1,2,1)
            % imagesc(img0);
            % subplot(1,2,2)
            % imagesc(img1);

            break;
        end
    end
end

disp(supAcc/(nObj*nTestWin));
