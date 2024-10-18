%% This file is for making the force-time plot
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% load the data
dataStorageFolder= 'Deformation_Data'; % !!
dataFolderName = 'tape'; % !!
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
disp('data loading...');
load(fullpath)
disp('loaded successfully!');

% some basic params
thr = 180; % !!
numM = length(M);
numMode = length(samplingMode);
% 1st index is for time or force; 2nd is for the measurement level; 3rd is
% for the measurement mode; 4th is for the object.
forceStr = cell(2,numM,numMode);

for modeNum = samplingMode
    idxMode = find(samplingMode==modeNum);

    for msrNum = M
        idxM = find(M==msrNum);

        fs=data(1,end,1,idxM,idxMode);
        num_frames = floor(fs * save_time);

        forceHis=zeros(numWindow,num_frames);
        timeHis=repmat(0:1/fs:save_time-1/fs, numWindow, 1);

        for idxWindow=1:numWindow
            for i=1:num_frames
                LL=(i-1)*msrNum+1:i*msrNum;
                temp=data(2,LL,idxWindow,idxM,idxMode);
                temp=temp.*(temp>thr);

                forceHis(idxWindow,i)=max(temp);
            end
        end

        forceStr{1,idxM,idxMode}=timeHis;
        forceStr{2,idxM,idxMode}=forceHis;
    end
end

%% plotting
figure;
for iMode=[1] % !!
    for iM=1%[5,8,12,17,19] % !!
        timeHis=forceStr{1,iM,iMode};
        forceHis=forceStr{2,iM,iMode};
        for idxWindow=2%1:numWindow % !!
            force = forceHis(idxWindow,:);
            fprintf('The num of non-zero frames is %d.\n',sum(force~=0));
            plot(timeHis(idxWindow,:),force,'.-',MarkerSize=10,DisplayName=sprintf('Measurement Level: %d|Win: %d',M(iM),idxWindow));
            legend('Location', 'southoutside');
            xlabel('time (s)');
            ylabel('force (A.U.)');
            legend('Location', 'eastoutside');

            disp('');
        end
    end
end
