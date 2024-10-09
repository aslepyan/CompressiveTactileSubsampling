%% This code file is for accuracy-related plotting (generalization)
% This function calculates the accuracies (or errors) between recovered
% tactile images and their cooresponding GT images. The GT images are
% extracted under the assumption that TSW are the same for each object.
% The formula for calculating the accuracy (acc) is: acc=support+alpha/mae.
% close all
% clear
% clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

load ..\archieveData\GTImg.mat
addpath ..\Utilities\

numSensor = 1024;
pressThreshold = 50; % !!

dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
samplingMode = [1,2,3]; % !!
M = [42,48,49,56,64,66,77,88,96,112,121,128,160,176,192,224,256,352,512,1024,];
nObj=length(dataNameList);
nMode = length(samplingMode);
nM = length(M);
nWin = 10;
% recover mode: 1 is learned dict, 2 is linear interpolation
rcvMode = [1,]; % !!
nRecMode = length(rcvMode);
posArr = [1,2,3];
nPos = numel(posArr);
dataNameIdx=22; % !! 22 or 27
modeNum=2; % !! 2 or 3

% struct for saving the accuracies of interested frame(s) (e.g. mid frame
% of a TSW window) and the corresponding frames used for calculating the
% accuracy.
accStr(nWin,nM-1,nPos) = struct('acc',[],'img',[]);

% param(s) for accuracy
alpha = 0.1; % !!
k = 1; % !!

% main loop for calculating the accuracy

fprintf('Object No.%d/%d\n',dataNameIdx,nObj);

% loading the data
for ipos=posArr
    dataFolderName = dataNameList(dataNameIdx).name;
    recSignalFileName1 = ['RecSignal',num2str(posArr(ipos)),'_', dataFolderName, '.mat']; % recovered signal by learned dictionary
    recSignalFileName2 = ['interpRcv1_', dataFolderName, '.mat']; % recovered signal by linear interpolation

    recDatapath1 = fullfile(uupwd, dataStorageFolder, dataFolderName, recSignalFileName1);
    recDatapath2 = fullfile(uupwd, dataStorageFolder, dataFolderName, recSignalFileName2);
    disp('data loading...');
    load(recDatapath1)
    savedRcvSg1=savedRcvSg;
    load(recDatapath2)
    savedRcvSg2=savedRcvSg;
    disp('data loaded successfully!');

    GTxArr = GTImgArr(:,1,dataNameIdx);

    % change position or orientation
    img = reshape(GTxArr,[32,32])';
    img = circshift(img,newP)';
    GTxArr=img(:);

    % calculate the accuracy
    for rcvModeIdx=rcvMode
        if rcvModeIdx==1
            savedRcvSg=savedRcvSg1;
        elseif rcvModeIdx==2
            savedRcvSg=savedRcvSg2;
        end

        iMode = find(samplingMode==modeNum);

        for msrNum = M
            if msrNum==numSensor
                continue;
            end
            iM = find(M==msrNum);

            for iWin = 1:nWin
                % extract the recovered tactile image
                xArr = savedRcvSg(iWin,iM,iMode).data;

                nx = size(xArr,2);
                accArr = zeros(1,nx);

                % calculate the accuracy
                for kk=1:nx
                    x = xArr(:,kk);
                    GTx = GTxArr(:,kk);
                    supAcc = supportAcc(GTx,x,pressThreshold);
                    mae = immae(GTx,x);
                    mse = immse(GTx,x);
                    accArr(kk) = supAcc;%mse;%k*supAcc+alpha/mae; % !!
                end

                % store the data in the struct
                accStr(iWin,iM,ipos).acc=accArr;
                accStr(iWin,iM,ipos).img=xArr;
            end
        end
    end
end

% saved trained data
disp('saving the accuracy...');
save("accData.mat","accStr",'-v7.3');
disp("saved! Later, it can be moved to the ""archieveData"" file, if necessary.");

%% determine the 'sizeDataPlot' array
sizeDataPlot = zeros(nObj,1);

for dataNameIdx=1:nObj
    temp = GTImgArr(:,1,dataNameIdx);
    sizeDataPlot(dataNameIdx)=nnz(temp);
end

%% M-Accuracy plot over all objects for each subsampling and recovery method
% load ..\archieveData\accData.mat
load ..\garbage\accData.mat

% arr for ploting the M-Acc figure
accDataPlot = zeros(nM-1,nPos);

% processing the 'accDataPlot'
for msrNum = M
    if msrNum==numSensor
        continue;
    end
    iM = find(M==msrNum);
    for ipos=posArr
        temp=0;
        count=0;
        for iWin=1:nWin
            temp=temp+mean(accStr(iWin,iM,ipos).acc);
            count=count+1;
        end
        accDataPlot(iM,ipos)=temp/count;
    end
end

% plotting
figure('Position', [100, 100, 800, 600]);
plotSetting = ["-ro","-bo","-go"];
hold on;
for ipos=posArr
    plot(M(1:end-1), accDataPlot(:,ipos), plotSetting(ipos), 'DisplayName', sprintf('position %d',posArr(ipos)));
end
xlabel('Number of measurements (M)');
ylabel('Support Accuracy');
ylim([650,1024]);
legend;
% set(gca, 'YScale', 'log');
hold off;
