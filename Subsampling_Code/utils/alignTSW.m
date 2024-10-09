%% The file is for aligning the signals and calculating the delay.
close all
clear
clc

load ..\archieveData\TSWMat.mat

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% extract the names of data files
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject = length(dataNameList);
numMode = 3;
numM = 20;
nWin = 10;

% matrix for storage of delay for each entire touch/TSW
delayMat(nWin,numM,numMode,numObject) = 0;
maxTouchTime = 0.6; % unit: s
fineTimeRes = 1e-4;
fineTimeArr = 0:fineTimeRes:maxTouchTime;

for dataNameIdx=1:numObject
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the original data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(fullpath)
    disp('data loaded successfully!');

    for modeNum = [1,2,3]
        idxMode = find(samplingMode==modeNum);

        for msrNum = M
            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1%1:numWindow % !!
                % extract the location of each TSW
                TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
                TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;

                % extract force and time data
                forceArr = zeros(TSWF-TSW0+1,1);
                kk=1;
                timeArr = 0:1/fs:(TSWF-TSW0)/fs;
                for idxFrame=TSW0:TSWF
                    LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
                    y=data(2,LL,idxWindow,idxM,idxMode);
                    y(y<=50)=0;

                    forceArr(kk)=sum(y);
                    kk=kk+1;
                end

                % interp
                fineForceArr = interp1(timeArr,forceArr,fineTimeArr);
                fineForceArr(isnan(fineForceArr)) = 0; % make the force outside timeArr to be zero

                % ref force array for each object
                if idxWindow==1 && idxM==1 && idxMode==1
                    refFineForceArr = fineForceArr;
                end

                % alignment
                [~,~,D] = alignsignals(refFineForceArr,fineForceArr,Method="xcorr");
                delay=-D*fineTimeRes; % unit: s

                % uncomment it to see some info; !!
                % disp(msrNum);
                % plot(refFineForceArr,'-k.');
                % hold on
                % plot(fineForceArr,'-r.');
                % hold off
                % 
                % drawnow
                % Fidx1 = find(refFineForceArr>0);
                % disp(max(Fidx1));
                % Fidx1 = find(fineForceArr>0);
                % disp(max(Fidx1));

                % storage
                delayMat(idxWindow,idxM,idxMode,dataNameIdx)=delay;
            end
        end
    end
end

% set the min val of delay for each object to be 0
for iObj=1:numObject
    delayMat(:,:,:,iObj)=delayMat(:,:,:,iObj)-min(delayMat(:,:,:,iObj),[],'all');
end

save("delayMat.mat","delayMat");
disp("The data ""delayMat"" has been saved to data file ""delayMat.mat""! Copy it to the folder ""archieveData"".");
