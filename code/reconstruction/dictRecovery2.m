% This file is for the reconstruction of the subsampled tactile images
% using various dictionaries. Image is recovered as a whole by the
% dictionary.
close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% load dictionary
fullpath = fullfile(upperpwd, 'traningData', 'dictionary1.mat'); % !! use the correct file storing the dict
disp('dictionary loading...');
load(fullpath)
disp('dictionary loaded successfully!');

% extract the names of data files
dataStorageFolder= ''; % !!
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject=length(dataNameList);
numMode = 3;
numM = 20;
numTestWindow = 1; % !!
numSensor = 1024;
pressThreshold = 180; % !!
sparRat = 0.25; % !!

disp('Data recovery process initiated...');
for dataNameIdx=1:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the original data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(fullpath)
    disp('data loaded successfully!');

    % struct for saving the recovered signals and storage the indices of
    % frames for each window to be recovered. Note: full raster data do not
    % need to be recovered
    savedRcvSg(numTestWindow,numM-1,numMode) = struct('data',[],'recFrameIdx',[]);
    tic
    for modeNum = [2] %!!
        idxMode = find(samplingMode==modeNum);

        for msrNum = M % !!
            if msrNum==numSensor
                continue;
            end
            idxM = find(M==msrNum);

            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1:numTestWindow
                xHis = zeros(numSensor,numFrame);
                iHis = zeros(1,numFrame);
                xHisInd=1;
                for iFr=floor(numFrame/2)%1:numFrame
                    LL=(iFr-1)*msrNum+1:iFr*msrNum;
                    y=data(2,LL,idxWindow,idxM,idxMode)';

                    if all(y<=pressThreshold)
                        continue;
                    end

                    y(y<=pressThreshold)=0;

                    % calculate Phi, !!
                    Phi=zeros(msrNum,numSensor);
                    for posInd=1:msrNum
                        ind=posInd+(iFr-1)*msrNum;
                        if mod(ind,32)==1 || posInd==1
                            LL=(ceil(ind/32)-1)*32+1:ceil(ind/32)*32;
                            rolArr=data(1,LL,idxWindow,idxM,idxMode);
                            rolArr=rolArr.*(1:32);
                            rolArr=rolArr(rolArr~=0);
                        end
                        iCol=mod(ind,32)+32*(mod(ind,32)==0);
                        pp=(iCol-1)*32+rolArr;
                        Phi(posInd,pp)=1;
                    end

                    sparsity = round(sparRat*msrNum);
                    xs = FastOMP(Phi*Psi,y,sparsity);
                    x = Psi*xs;
                    x(x<pressThreshold)=0; %!!
                    x(x>1023)=1023;
                    xHis(:,xHisInd) = x;
                    iHis(xHisInd) = iFr;
                    xHisInd = xHisInd+1;

                    if (any(isnan(x)))
                        error(sprintf('x in the Mode %d|Msr Num %d|Window %d has NaN value!',modeNum,msrNum,idxWindow));
                    end
                end
                savedRcvSg(idxWindow,idxM,idxMode).data = xHis(:,1:xHisInd-1);
                savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx = iHis(1:xHisInd-1);
            end
            fprintf('Mode %d|Msr Num %d Finish!\n',modeNum,msrNum);
        end
    end
    toc
    % save recovered signals
    recSignalFileName = ['RecSignal_dct_', dataFileName]; % !!
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
    disp('saving...');
    save(fullpath, "savedRcvSg");
    disp('The recovered signal file is saved!')
end

