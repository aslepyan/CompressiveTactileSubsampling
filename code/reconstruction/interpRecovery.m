% This file is for recovering the sensing profile using interpolation
% recovery for each object, and for each case of designated msr num and
% subsampling mode. This is just for recovering only the designated frame
% used for MSE.
clear

% params
pressThreshold = 50;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);
load("..\..\data\archieveData\TSWMat.mat")

% extract the names of data files
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject=length(dataNameList);
numMode = 3;
numM = 20;
numTestWindow = 10;
numSensor = 1024;

% initialize array for storage of data after interpolation
recim=zeros(32);

% initialize the interpolation method
myInterp = scatteredInterpolant;
myInterp.Method = 'linear';
myInterp.ExtrapolationMethod = 'linear';

disp('Data recovery process initiated...');
for dataNameIdx=1:numObject
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the original data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(fullpath)
    disp('data loaded successfully!');

    % struct for saving the recovered signals and storage the indices of
    % frames for each window to be recovered
    savedRcvSg(numTestWindow,numM-1,numMode) = struct('data',[],'recFrameIdx',[]);
    tic
    for modeNum = [1,2,3]
        idxMode = find(samplingMode==modeNum);

        for msrNum = M
            if msrNum==numSensor
                continue;
            end

            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            % array for storage of coordinate of scattered data for
            % interpolation
            interpData = zeros(msrNum,2);

            for idxWindow = 1:numTestWindow
                TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
                TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;

                % extract the mid frame to be recovered for each window
                midFrame = round((TSW0+TSWF)/2);
                savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx = midFrame;

                LL=(midFrame-1)*msrNum+1:midFrame*msrNum;
                y=data(2,LL,idxWindow,idxM,idxMode)';
                y(y<=pressThreshold)=0;

                % postion vector (pos)
                pos=data(1,LL,idxWindow,idxM,idxMode); % 0-1023

                for k = 1:msrNum
                    temp = pos(k); % 0-1023
                    interpData(k,1) = floor(temp/32)+1; % 1-32
                    interpData(k,2) = mod(temp,32)+1; % 1-32
                end

                myInterp.Points=interpData;
                myInterp.Values=y;

                for i=1:32
                    for j=1:32
                        temp=myInterp(i,j);
                        if (temp<pressThreshold)
                            temp=0;
                        elseif (temp>1023)
                            temp=1023;
                        end
                        recim(j,i)=temp;
                    end
                end

                savedRcvSg(idxWindow,idxM,idxMode).data = recim(:);
            end
            fprintf('Mode %d|Msr Num %d Finish!\n',modeNum,msrNum);
        end
    end
    toc
    % save recovered signals
    recSignalFileName = ['interpRcv1_', dataFileName];
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
    disp('saving...');
    save(fullpath, "savedRcvSg");
    disp('The recovered signal file is saved!')
end
