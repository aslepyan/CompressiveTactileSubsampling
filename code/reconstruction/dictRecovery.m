% This file is for the reconstruction of the subsampled tactile images
% using various dictionaries. Image is recovered patch by patch by the
% patch dictionary.
clear

% params
pressThreshold = 60;
sensorType = 2; % 1-square; 2-insole; 3-glove
alphaArr = [0.5,0.3,0.4,0.8,0.9,0.9,0.9]; % low-pass filtering
dataStorageFolder= 'insole_data';
frRange = 1; % 1-whole fr; 2-mid frame only

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);
addpath("..\utils\")
if frRange==2
    load("..\..\data\archieveData\TSWMat.mat")
end

% load dictionary
fullpath = fullfile('..\..\data\traningData', 'dictionary.mat'); % !! use the correct dict
disp('dictionary loading...');
load(fullpath)
disp('dictionary loaded successfully!');

% extract the names of data files
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
numObject=length(dataNameList);
numMode = 3;
numM = 20;
numSensor = 1024;

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
    % frames for each window to be recovered. Note: full raster data do not
    % need to be recovered
    savedRcvSg(numWindow,numM-1,numMode) = struct('data',[],'recFrameIdx',[]);
    tic
    for modeNum = samplingMode
        idxMode = find(samplingMode==modeNum);

        for msrNum = M
            if msrNum==numSensor
                continue;
            end
            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1:numWindow
                if frRange==1
                    frSet=1:numFrame;
                elseif frRange==2
                    % extract the start and ending frame points of TSW
                    TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
                    TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;
                    % extract the mid frame to be recovered for each window
                    midFrame = round((TSW0+TSWF)/2);
                    frSet=midFrame;
                end

                % params for the low-pass filtering
                alpha = alphaArr(idxM);
                pimg = zeros(32); % last rec img
                if sensorType==2
                    pimg = zeros(64,16);
                end
                firstLPF=true; % is first img?

                recFrArr=zeros(numSensor,numFrame);
                recFrIndArr=zeros(numFrame,1);
                kkk=1;

                for iFr=frSet
                    LL=(iFr-1)*msrNum+1:iFr*msrNum;
                    y=data(2,LL,idxWindow,idxM,idxMode)';
                    if all(y<=pressThreshold)
                        continue;
                    end

                    y(y<=pressThreshold)=0;

                    % postion vector (pos)
                    pos=data(1,LL,idxWindow,idxM,idxMode); % 0-1023

                    % initialize the degraded tactile img
                    deim = -10*ones(32);
                    for ii=1:msrNum
                        temp=y(ii);
                        temp1=pos(ii);
                        x1=floor(temp1/32)+1; % row ind
                        x2=mod(temp1,32)+1; % col ind
                        deim(x1,x2)=temp;
                    end

                    % convert the image to match specific type of sensor
                    if sensorType==2
                        deim = insoleConv(deim);
                    end

                    %%%%%%recovery%%%%%%
                    % patch params
                    lenImg = size(deim);
                    patchLength = dictArr(2).patchDim; % !!
                    numElemPatch = prod(patchLength);
                    patchStepSize = [1,1]; % !!
                    patchULCoord = [1,1]; % patch upper left coordinate
                    idxHelper = reshape(1:numel(deim),size(deim));
                    Psi = dictArr(2).data; % !!
                    sparRat = 0.25; % !!
                    recim = 0*deim;
                    repeatCount = 0*deim;

                    while(patchULCoord(1)+patchLength(1)-1<=lenImg(1))
                        patchLRCoord = patchULCoord+patchLength-1;

                        % temp stores the corresponding indices of the current patch
                        temp = idxHelper(patchULCoord(1):patchLRCoord(1),patchULCoord(2):patchLRCoord(2));

                        for kk=1:numel(temp)
                            repeatCount(temp(kk))=repeatCount(temp(kk))+1;
                        end

                        patchImg=deim(temp);

                        yvec=patchImg(~(patchImg<0));
                        Amat=zeros(numel(yvec),numElemPatch);
                        ii=1;
                        for kk=1:numElemPatch
                            if patchImg(kk)<0
                                continue;
                            end
                            Amat(ii,kk)=1;
                            ii=ii+1;
                        end

                        sparsity = round(sparRat*ii);
                        xs=FastOMP(Amat*Psi,yvec,sparsity);

                        x=Psi*xs;

                        recim(temp)=recim(temp)+reshape(x,patchLength);

                        patchULCoord(2) = patchULCoord(2)+patchStepSize(2);
                        if (patchULCoord(2)+patchLength(2)-1>lenImg(2))
                            patchULCoord(2) = 1;
                            patchULCoord(1) = patchULCoord(1)+patchStepSize(1);
                        end
                    end
                    recim=recim./repeatCount;

                    % recim(recim<pressThreshold)=0;
                    recim(recim>1023)=1023;

                    % low-pass filter
                    if firstLPF
                        recim=alpha*recim;
                        firstLPF=false;
                    else
                        recim=pimg+alpha*(recim-pimg);
                    end
                    pimg=recim;

                    x=reshape(recim',[],1);

                    if (any(isnan(x)))
                        error(sprintf('x in the Mode %d|Msr Num %d|Window %d has NaN value!',modeNum,msrNum,idxWindow));
                    end

                    % str the recovered img and its corresponding index
                    recFrArr(:,kkk)=x;
                    recFrIndArr(kkk)=iFr;
                    kkk=kkk+1;
                end
                % str data
                savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx = recFrIndArr(1:kkk-1);
                savedRcvSg(idxWindow,idxM,idxMode).data = recFrArr(:,1:kkk-1);

                % print prompt text
                fprintf('Windom %d|Mode %d|Msr Num %d Finish!\n',idxWindow,modeNum,msrNum);
            end
        end
    end
    toc
    % save recovered signals
    recSignalFileName = ['RecSignal1_', dataFileName];
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
    disp('saving...');
    save(fullpath, "savedRcvSg");
    disp('The recovered signal file is saved!')
end
