%% The file is for locating the 1st or 2nd entire TSW for each window.
% Assumptions:
% 1. Each window contains at least one entire TSW;
% 2. For every two consecutive TSWs, one of them is entire;
% 3. For each object, all touches on the sensor are the same;
% 4. From (2) and (3), for every two consecutive TSWs, the longer one is
% entire;
% 5. For every two consecutive TSWs, the gap between them is at least 0.2s.

close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% extract the names of data files
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject = length(dataNameList);
numMode = 3;
numM = 20;
nWin = 10;

% threshold for sensing a touch
touchThreshold = 50; % !!
% threshold of duration between two consecutive TSWs; unit: s
interTSW = 0.2;

% struct for storage of the start and the end frame indices of the 1st or
% the 2nd entire TSW for each window
TSWMat(nWin,numM,numMode,numObject)=struct("TSW0",[],"TSWF",[]);

for dataNameIdx=1:numObject
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the original data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, 'data',dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(fullpath)
    disp('data loaded successfully!');

    for modeNum = [1,2,3]
        idxMode = find(samplingMode==modeNum);

        for msrNum = M
            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1:numWindow
                nTouch=0;
                for idxFrame=1:numFrame
                    LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
                    y=data(2,LL,idxWindow,idxM,idxMode);

                    if idxFrame==numFrame && nTouch==2 && all(y<=touchThreshold)
                        if (TSWF-TSW0)<(TSWFp-TSW0p)
                            TSW0=TSW0p;
                            TSWF=TSWFp;
                        end
                        break;
                    end

                    if all(y<=touchThreshold)
                        continue;
                    end

                    if nTouch==0
                        TSW0=idxFrame;
                        idxFrameHis = TSW0;
                        nTouch=1;
                    end

                    if (idxFrame-idxFrameHis)/fs>interTSW
                        TSWF=idxFrameHis;
                        if nTouch==2
                            if (TSWF-TSW0)<(TSWFp-TSW0p)
                                TSW0=TSW0p;
                                TSWF=TSWFp;
                            end
                            break;
                        elseif nTouch==1
                            TSW0p=TSW0;
                            TSWFp=TSWF;
                            TSW0=idxFrame;
                            nTouch=2;
                        end
                    end

                    idxFrameHis=idxFrame;
                    TSWF=idxFrame;

                    if idxFrame==numFrame && nTouch==2
                        if (TSWF-TSW0)<(TSWFp-TSW0p)
                            TSW0=TSW0p;
                            TSWF=TSWFp;
                        end
                    end
                end

                TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0=TSW0; % !!
                TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF=TSWF; % !!
            end
        end
    end
end

save("TSWMat.mat","TSWMat");
disp("TSWMat has been saved to data file ""TSWMat.mat""! Copy it to the folder ""archieveData"".");
