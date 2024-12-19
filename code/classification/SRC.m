% This file is for the SRC of subsampeld tactile images and plotting some
% relavant figures.
close all;

% loading relevant data
load("..\..\data\archieveData\TSWMat.mat")
load("..\..\data\traningData\lib.mat")
lib=Psi;

% extract the names of data files
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject=length(dataNameList);
numM = 20;
numMode = 3;
numTestWindow = 3; %!!!
numSensor = 1024;
pressThreshold = 50;

SRCdata(numTestWindow,numM,numMode,numObject) = struct('data',[]);

tic
for dataNameIdx=1:numObject % !!!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the original data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(fullpath)
    disp('data loaded successfully!');

    for modeNum = [1,2,3] % !!!
        idxMode = find(samplingMode==modeNum);

        for msrNum = M % !!!
            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            sparsity = round(0.25*msrNum); % !!

            accuracy = 0;

            for idxWindow = 1:numTestWindow
                TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
                TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;

                SRCHis = zeros(TSWF-TSW0+1,1); % store the class for each frame where press is not zero in the current case
                kk=1; % idx of SRCHis
                for idxFrame=TSW0:TSWF
                    LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
                    y=data(2,LL,idxWindow,idxM,idxMode);
                    if all(y<=pressThreshold)
                        kk=kk+1;
                        continue;
                    end
                    y(y<=pressThreshold)=0;
                    pos=data(1,LL,idxWindow,idxM,idxMode); % 0-1023

                    % % arrange the measurement into a tactile image
                    % % equivalent full raster signal initialization
                    % img = zeros(32,32);
                    % for k = 1:msrNum
                    %     temp1 = pos(k); % 0-1023
                    %     x1 = floor(temp1/32)+1; % 1-32
                    %     x2 = mod(temp1,32)+1; % 1-32
                    %     img(x1,x2) = y(k);
                    % end

                    % SRC subsampling version
                    % sensing matrix
                    phi=zeros(msrNum,numSensor);
                    for k=1:msrNum
                        temp1 = pos(k); % 0-1023
                        phi(k,temp1+1)=1;
                    end

                    lib1=phi*lib;

                    % % visualization of extracted tactile data
                    % imagesc(img);
                    % title(sprintf('M = %d|modeNum = %d|Window %d|Frame %d',msrNum,modeNum,idxWindow,idxFrame));
                    % drawnow;

                    % % SRC process
                    % img = img';
                    % y1 = img(:);
                    % % OMP method
                    % s1 = FastOMP(lib,y1,50); % !!!

                    % SRC subsampling version
                    s1 = FastOMP(lib1,y',sparsity); % !!!

                    % L1-minimization using cvx package
                    % eps = 100; % !!!
                    % cvx_begin;
                    %     variable s1(libSize);
                    %     minimize(norm(s1,1));
                    %     subject to
                    %         norm(lib*s1 - y1,2) < eps;
                    % cvx_end;

                    binErr = zeros(numObject,1);
                    for idxObject=1:numObject
                        L=(idxObject-1)*numTrainObj+1:idxObject*numTrainObj;
                        % binErr(idxObject)=norm(y1-lib(:,L)*s1(L))/norm(y1);
                        % SRC subsampling version
                        binErr(idxObject)=norm(y'-lib1(:,L)*s1(L))/norm(y);
                    end

                    [~,class]=min(binErr);

                    SRCHis(kk)=class;
                    kk=kk+1;
                end

                SRCdata(idxWindow,idxM,idxMode,dataNameIdx).data=SRCHis;
            end

            fprintf('M=%d|mode=%d Finish!\n',msrNum,modeNum);
        end
    end
end
toc
save("SRCdata.mat","SRCdata","numTestWindow");
disp("can move the saved file to the folder ""..\archieveData""");

%% The 'Time Vs SRC-Accuracy' figure and confusion mat figure, frame-wise
% update: 9/19
% confusion mat is for the supplementary
load("..\..\data\archieveData\SRCdata.mat") % !!
load("..\..\data\archieveData\timePerFrameArr.mat")
load("..\..\data\archieveData\delayMat.mat")

% data post-processing
numM = 20;
numMode = 3;
timeResoln = 1e-3; % unit: s, !!, figure in paper use 1e-4
totalTime = 3e-1; % unit: s, !!, figure in paper use 1e-1
numTimePoint = floor(totalTime/timeResoln)+1;
accSRCTime = zeros(numTimePoint,numM,numMode);
%%%%%%%%%%%
timeArrConfMat = [0.025,0.05,0.1]; % write from small to large, unit: s, !!
nTimeConfMat = numel(timeArrConfMat);
iTimeConfMat = 1;
confMat = zeros(numObject,numObject,nTimeConfMat,numM,numMode);
isConfMat = false;
%%%%%%%%%%%
SRCTempArr(numTestWindow,numObject)=struct("SRCdata",[],"lastIndex",[]);
for i=1:numTestWindow
    for j=1:numObject
        SRCTempArr(i,j).lastIndex=0;
    end
end
myDelay=[timePerFrameArr(2:end,2)';timePerFrameArr(2:end,2)';timePerFrameArr2(15:end,2)']*1e-6; % delay for test, comment this line!!

for idxMode=1:numMode
    if idxMode==3
        tpfTable=timePerFrameArr2;
    else
        tpfTable=timePerFrameArr;
    end

    for msrNum = M
        idxM = find(M==msrNum);
        tpf=tpfTable(tpfTable(:,1)==msrNum,2); % unit: us

        for i1=1:numTestWindow
            for j1=1:numObject
                SRCTempArr(i1,j1).SRCdata=[];
                SRCTempArr(i1,j1).lastIndex=0;
            end
        end

        % set the ind for the time when handling confusion matrix to be 1
        iTimeConfMat=1;

        for i=1:numTimePoint
            numTrueFrame=0;
            numTotFrame=0;

            crtMaxTime=(i-1)*timeResoln; % unit: s

            % should we handle the confusion mat?
            isConfMat=false;
            if iTimeConfMat<=nTimeConfMat && crtMaxTime>=timeArrConfMat(iTimeConfMat)
                isConfMat=true;
                iTimeConfMat=iTimeConfMat+1;
            end

            for iObj=1:numObject % !!!
                for iWin=1:numTestWindow
                    % delay = delayMat(iWin,idxM,idxMode,iObj)+0.01; % delay for alignment, unit: s
                    delay = myDelay(idxMode,idxM)+0.000; % delay for test, comment this line!!
                    timePt = delay:-tpf*1e-6:0; % unit: s
                    timePt = flip(timePt(2:end));
                    nPt0 = numel(timePt); % num of time point before press
                    timePt = [timePt (0:tpf*1e-6:0.4)+delay]; % 0.4 is an approx. max val of duration of one TSW; unit: s
                    % find the last index of timePt (ii), s.t. timePt(ii)
                    % <= crtMaxTime.
                    for jj=1:numel(timePt)
                        if timePt(jj)>crtMaxTime
                            ii=jj-1;
                            break;
                        end
                    end

                    iip=SRCTempArr(iWin,iObj).lastIndex;
                    SRCTempArr(iWin,iObj).lastIndex=ii;
                    SRCHis=SRCTempArr(iWin,iObj).SRCdata;

                    if iip>=nPt0
                        SRCHis1=SRCdata(iWin,idxM,idxMode,iObj).data(iip+1-nPt0:ii-nPt0);
                    elseif ii<=nPt0
                        SRCHis1=zeros(ii-iip,1);
                    elseif iip<nPt0 && ii>nPt0
                        SRCHis1=[zeros(nPt0-iip,1);SRCdata(iWin,idxM,idxMode,iObj).data(1:ii-nPt0)];
                    end

                    for jj=1:numel(SRCHis1)
                        if SRCHis1(jj)==0
                            SRCHis1(jj)=randperm(numObject,1);
                        end
                    end
                    SRCHis=[SRCHis;SRCHis1];
                    SRCTempArr(iWin,iObj).SRCdata=SRCHis;

                    numTrueFrame=numTrueFrame+sum(SRCHis==iObj);
                    numTotFrame=numTotFrame+length(SRCHis);

                    % confusion mat
                    if isConfMat
                        for kk=SRCHis'
                            confMat(iObj,kk,iTimeConfMat-1,idxM,idxMode)=confMat(iObj,kk,iTimeConfMat-1,idxM,idxMode)+1;
                        end
                    end
                end
            end

            accSRCTime(i,idxM,idxMode)=numTrueFrame/numTotFrame;
        end
    end
end

%% plotting 'Time Vs SRC-Accuracy' figure
t=0:timeResoln:totalTime;
plotM = [64,112,192,256,512,1024]; % !!!
plotStyle = {'-ro','-yo','-go','-bo','-mo','-ko'}; % !!!
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"];
figure('Position', [400, 100, 1200, 800]);
for idxMode = 1:3
    subplot(1,3,idxMode)
    hold on;
    for i=1:numel(plotM)
        idxM = find(M==plotM(i));
        plot(t, accSRCTime(:,idxM,idxMode), char(plotStyle(i)), 'DisplayName', sprintf('Measurement Level: %d',plotM(i)));
    end
    xlabel('time (s)');
    ylabel('Accuracy');
    xlim([0,totalTime]);
    ylim([0,1]);
    % set(gca, 'XScale', 'log');
    % set(gca, 'YScale', 'log');
    legend('Location', 'southoutside');
    title(modeName(idxMode));
    hold off;
end
sgtitle('Time Vs SRC-Accuracy');

%% plotting the confusion mat (supplementary figure)
% update: 9/19
%confMat(iObj,kk,iTimeConfMat,idxM,idxMode)
modeName = ["Down_Sampling","Random_Sampling","Binary_Sampling"];
folder = '..\..\paperFig\figS_confusionMat_SRC\';
testM = [64,256,512,1024]; % !!
ntestM=numel(testM);
testMode=[1,2,3]; % !!

% legend text
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
numObject=length(dataNameList);
objLegend = cell(1,numObject);
for iObj=1:numObject
    objLegend{iObj}=sprintf(['%d - ',dataNameList(iObj).name],iObj);
end
dim=[0.9,0.5,0.3,0.3];

for iMode=testMode
    f1 = figure("Name",strcat("confusionMat_",modeName(iMode)),'Position', [100,50,1000,800]);
    iFig=1;
    for msrNum = testM
        idxM = find(M==msrNum);
        for i=1:nTimeConfMat
            subplot(ntestM,nTimeConfMat,iFig)
            iFig=iFig+1;
            imagesc(confMat(:,:,i,idxM,iMode));
            colorbar
            xlabel('classified objects');
            ylabel('real objects');
            title(sprintf('M=%d|%.3fs',msrNum,timeArrConfMat(i)))
        end
    end
    annotation('textbox',dim,'String',objLegend,'FitBoxToText','on');
    filePath = fullfile(folder, strcat("confusionMat_",modeName(iMode),".fig"));
    saveas(gcf, filePath);
end

%% The 'Measurement-Level Vs SRC-Accuracy' figure, frame-wise
close all;

load("..\..\data\archieveData\SRCdata.mat") % !!
load("..\..\data\archieveData\timePerFrameArr.mat")

% data post-processing
numM = 20;
numMode = 3;
% press buffer; unit: s
pressBuffer = 0.0; % !!! for the SRC-time figure, set 0
accSRCM=zeros(numM,numMode);
for idxMode=1:numMode
    if idxMode==3
        tpfTable=timePerFrameArr2;
    else
        tpfTable=timePerFrameArr;
    end

    for msrNum = M
        idxM = find(M==msrNum);
        tpf=tpfTable(tpfTable(:,1)==msrNum,2); % unit: us

        numTrueFrame=0;
        numTotFrame=0;

        for iObj=1:numObject % !!!
            for iWin=1:numTestWindow
                SRCHis=SRCdata(iWin,idxM,idxMode,iObj).data;
                TSW0=1;
                TSWF=length(SRCHis);
                TSW0=TSW0+round(pressBuffer/tpf*1e6);
                TSWF=TSWF-round(pressBuffer/tpf*1e6);
                SRCHis=SRCHis(TSW0:TSWF);

                numTrueFrame=numTrueFrame+sum(SRCHis==iObj);
                numTotFrame=numTotFrame+sum(SRCHis~=0);
            end
        end

        accSRCM(idxM,idxMode)=numTrueFrame/numTotFrame;
    end
end

% plotting
figure('Position', [100, 100, 800, 800]);

plot(M, accSRCM(:,1), '-ro', 'DisplayName', sprintf('Down Sampling'));
hold on;
plot(M, accSRCM(:,2), '-bo', 'DisplayName', sprintf('Random Sampling'));
plot(M, accSRCM(:,3), '-go', 'DisplayName', sprintf('Binary Sampling'));

xlabel('Measurement Level');
ylabel('Accuracy');
ylim([0,1]);
title('Measurement-Level Vs SRC-Accuracy');
legend('Location', 'southoutside');

hold off;
