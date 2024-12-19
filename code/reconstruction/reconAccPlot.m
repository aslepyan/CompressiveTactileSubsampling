%% This code file is for accuracy-related plotting
% This function calculates the accuracies (or errors) between recovered
% tactile images and their cooresponding GT images. The GT images are
% extracted under the assumption that TSW are the same for each object.
clear

% params
pressThreshold = 50;
recModeArr = [1,2]; % 1-ksvd; 2-interp; 3-DCT; 4-Haar

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);
load("..\..\data\archieveData\GTImg.mat")
addpath("..\utils\")

dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
samplingMode = [1,2,3];
numSensor = 1024;
M = [42,48,49,56,64,66,77,88,96,112,121,128,160,176,192,224,256,352,512,1024,];
nObj=length(dataNameList);
nMode = length(samplingMode);
nM = length(M);
nWin = 10;
nRecMode = length(recModeArr);
recFileNameArr = ["RecSignal1_","interpRcv1_","RecSignal_dct_","RecSignal_haar_"];
savedRcvSgList{4}=[];

% struct for saving the accuracies of interested frame(s) (e.g. mid frame
% of a TSW window) and the corresponding frames used for calculating the
% accuracy.
accStr(nWin,nM-1,nMode,nRecMode,nObj) = struct('acc',[],'img',[]);

% main loop for calculating the accuracy
for dataNameIdx=8%1:nObj
    fprintf('Object No.%d/%d\n',dataNameIdx,nObj);

    % loading the data
    dataFolderName = dataNameList(dataNameIdx).name;
    for recMode=recModeArr
        recSignalFileName=[char(recFileNameArr(recMode)), dataFolderName, '.mat'];
        recDatapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
        disp('data loading...');
        load(recDatapath)
        disp('data loaded successfully!');
        savedRcvSgList{recMode}=savedRcvSg;
    end

    GTxArr = GTImgArr(:,1,dataNameIdx);

    % calculate the accuracy
    for recMode=recModeArr
        rcvModeIdx=find(recModeArr==recMode);
        savedRcvSg=savedRcvSgList{recMode};

        for modeNum = samplingMode
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
                        accArr(kk) = supAcc;
                    end

                    % store the data in the struct
                    accStr(iWin,iM,iMode,rcvModeIdx,dataNameIdx).acc=accArr;
                    accStr(iWin,iM,iMode,rcvModeIdx,dataNameIdx).img=xArr;
                end
            end
        end
    end
end

% saved trained data
disp('saving the accuracy...');
save("accData_sup.mat","accStr",'-v7.3');
disp("saved! Later, it can be moved to the ""..\..\data\archieveData"" file, if necessary.");

%% M-Accuracy plot over all objects for each subsampling and recovery method
load("..\..\data\archieveData\accData_sup.mat")

% arr for ploting the M-Acc figure
accDataPlot = zeros(nM-1,nMode,nRecMode);

% processing the 'accDataPlot'
for msrNum = M
    if msrNum==numSensor
        continue;
    end
    iM = find(M==msrNum);
    for recMode=recModeArr
        rcvModeIdx=find(recModeArr==recMode);
        for iMode = samplingMode
            temp=0;
            count=0;
            for dataNameIdx=[1,2,4,8,9]%1:10%1:numObject % !!
                for iWin=1:nWin
                    temp=temp+mean(accStr(iWin,iM,iMode,rcvModeIdx,dataNameIdx).acc);
                    count=count+1;
                end
            end
            accDataPlot(iM,iMode,rcvModeIdx)=temp/count;
        end
    end
end

% plotting
figure('Position', [100, 100, 800, 600]);
plot(M(1:end-1), accDataPlot(:,1,1), "-ro", 'DisplayName', sprintf('Down Sampling + Learned Dictionary'));
hold on;
plot(M(1:end-1), accDataPlot(:,2,1), "-bo", 'DisplayName', sprintf('Random Sampling + Learned Dictionary'));
plot(M(1:end-1), accDataPlot(:,3,1), "-go", 'DisplayName', sprintf('Binary Sampling + Learned Dictionary'));
plot(M(1:end-1), accDataPlot(:,1,2), "-r*", 'DisplayName', sprintf('Down Sampling + DCT Dictionary'));
plot(M(1:end-1), accDataPlot(:,2,2), "-b*", 'DisplayName', sprintf('Random Sampling + DCT Dictionary'));
plot(M(1:end-1), accDataPlot(:,3,2), "-g*", 'DisplayName', sprintf('Binary Sampling + DCT Dictionary'));
plot(M(1:end-1), accDataPlot(:,1,3), "-rsquare", 'DisplayName', sprintf('Down Sampling + Haar Dictionary'));
plot(M(1:end-1), accDataPlot(:,2,3), "-bsquare", 'DisplayName', sprintf('Random Sampling + Haar Dictionary'));
plot(M(1:end-1), accDataPlot(:,3,3), "-gsquare", 'DisplayName', sprintf('Binary Sampling + Haar Dictionary'));
xlabel('Number of measurements (M)');
ylabel('Accuracy');
title('M-Accuracy');
legend('Location', 'southoutside');
% set(gca, 'YScale', 'log');
hold off;

%% obj size vs. accuracy plot (for both low and high M cases)
% Here, for each object, the object size is defined to be the number of
% active pixels of the middle frames of a TSW in the full raster senario.
load("..\..\data\archieveData\GTImg.mat")

% myM=[64,]; % low M, !!
myM=[512,]; % high M, !!
myNM=numel(myM);
rcvModeIdx=2; % Note: here, only consider the dictionary learning case.
nObj=30; % !!

% arrays for ploting the size-Acc figure
sizeDataPlot = zeros(nObj,1);
accDataPlot = zeros(myNM,nMode,nObj);

% determine the 'sizeDataPlot' array
for dataNameIdx=1:nObj
    temp = GTImgArr(:,1,dataNameIdx);
    sizeDataPlot(dataNameIdx)=nnz(temp);
end

% sort with respect to the size of object
[sizeDataPlot,ind]=sort(sizeDataPlot);
minSize = min(sizeDataPlot);
maxSize = max(sizeDataPlot);

% determine the 'accDataPlot' array
for msrNum = myM
    iM = find(M==msrNum);
    myIM = find(myM==msrNum);
    for iMode = samplingMode
        for dataNameIdx=1:nObj
            temp=0;
            count=0;
            for iWin=1:nWin
                temp=temp+mean(accStr(iWin,iM,iMode,rcvModeIdx,dataNameIdx).acc);
                count=count+1;
            end
            accDataPlot(myIM,iMode,dataNameIdx)=temp/count;
        end
        % re-order according to the order of size of object
        temp2=reshape(accDataPlot(myIM,iMode,:),[],1);
        accDataPlot(myIM,iMode,:)=temp2(ind);
        % accDataPlot(myIM,iMode,:)=temp2(ind)./sizeDataPlot;  % normalize over size ?? !!
    end
end

% plotting
figure('Position', [100, 100, 800, 600]);
ptPlotSetting = ["or","squarer","+r","xr";"ob","squareb","+b","xb";"og","squareg","+g","xg"];
lnPlotSetting = ["-r","--r",":r","-.r";"-b","--b",":b","-.b";"-g","--g",":g","-.g"];
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"];
hold on;
for myIM=1:myNM
    for modeNum=samplingMode
        iMode = find(samplingMode==modeNum);
        xplot=sizeDataPlot;
        yplot=reshape(accDataPlot(myIM,iMode,:),[],1);
        p = polyfit(xplot,yplot,1);
        xplot1 = linspace(minSize,maxSize);
        yplot1 = polyval(p,xplot1);
        plot(xplot, yplot, ptPlotSetting(iMode,myIM), 'DisplayName', sprintf(strcat(modeName(modeNum))));
        plot(xplot1, yplot1, lnPlotSetting(iMode,myIM), 'DisplayName', sprintf(""));
    end
end
title(sprintf("size-acc|M=%d",myM(1)));
% for myIM=1:myNM
%     for modeNum=[1,2]
%         iMode = find(samplingMode==modeNum);
%         temp1=reshape(accDataPlot(myIM,iMode,:),[],1);
%         temp2=reshape(accDataPlot(myIM,3,:),[],1);
%         plot(sizeDataPlot, temp2-temp1, plotSetting(iMode,myIM), 'DisplayName', sprintf(strcat(modeName(modeNum),'|M=%d'),myM(myIM)));
%     end
% end
xlabel('Size of Object');
ylabel('Support Accuracy');
legend('Location', 'southoutside');
% set(gca, 'YScale', 'log');
hold off;

%% visulization of comparison of frames to be used in MSE
% load("..\..\data\archieveData\accData.mat")
load("..\..\data\archieveData\GTImg.mat")

figure('Position', [0, 300, 1920, 500]);

% plot settings
figure;
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -20; % negative value assigned to the unsampled pixels
valMax = 1024; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

for dataNameIdx=8%1:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,nObj);
    for modeNum = 3%samplingMode % !!
        iMode = find(samplingMode==modeNum);
        for msrNum = M
            if msrNum==numSensor
                continue;
            end
            iM = find(M==msrNum);
            for iWin = 1:2%1:nWin % !!
                GTImg=GTImgArr(:,1,dataNameIdx);
                img1=accStr(iWin,iM,iMode,1,dataNameIdx).img;
                img2=accStr(iWin,iM,iMode,2,dataNameIdx).img;
                acc1=accStr(iWin,iM,iMode,1,dataNameIdx).acc;
                acc2=accStr(iWin,iM,iMode,2,dataNameIdx).acc;

                GTImg = reshape(GTImg,[32,32])';
                img1 = reshape(img1,[32,32])';
                img2 = reshape(img2,[32,32])';

                % plot the ground truth (full raster) data
                subplot(1,3,1);
                imagesc(GTImg)
                colormap(new_cmap);
                colorbar;
                clim([valMin valMax]);
                title('GT');
                axis equal;

                % plot recovered data
                subplot(1,3,2);
                imagesc(img1)
                colormap(new_cmap);
                colorbar;
                clim([valMin valMax]);
                title(sprintf('Learned Dictionary|acc: %d',acc1));
                axis equal;

                subplot(1,3,3);
                imagesc(img2)
                colormap(new_cmap);
                colorbar;
                clim([valMin valMax]);
                title(sprintf('Linear Interpolation|acc: %d',acc2));
                axis equal;

                sgtitle(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d"),msrNum,iWin))

                pause(0.5);
            end
        end
    end
end
