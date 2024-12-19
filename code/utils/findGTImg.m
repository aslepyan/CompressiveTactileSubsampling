function findGTImg(params)
% This function finds the gound truth (GT) image for each case, and save them.
% Note: the saved GT img is flattened.
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

load ..\archieveData\TSWMat.mat

dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
numObject=length(dataNameList);
nWin = params.nWin;
numSensor = 1024;
pressThreshold = params.pressThreshold;

% store ground truth frame (full raster) for each window.
GTImgArr = zeros(numSensor,nWin,numObject);

for dataNameIdx=1:numObject
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    datapath = fullfile(uupwd, 'data',dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(datapath)
    disp('data loaded successfully!');

    modeNum = 3;
    msrNum = numSensor;

    idxMode = find(samplingMode==modeNum);
    idxM = find(M==msrNum);

    for idxWindow = 1:numWindow
        TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
        TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;

        % extract the middle frame for each ground truth window
        midpt = round((TSW0+TSWF)/2);

        % store the value of middle frame
        GTImg = zeros(32);

        for msr = 1:msrNum
            temp=data(2,((midpt-1)*msrNum)+msr,idxWindow,idxM,idxMode);
            temp1=data(1,((midpt-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
            x1=floor(temp1/32)+1; % 1-32
            x2=mod(temp1,32)+1; % 1-32
            GTImg(x1,x2)=temp*(temp>pressThreshold);
        end

        GTImg=GTImg';
        GTImgArr(:,idxWindow,dataNameIdx)=GTImg(:);
    end
end

% saved the ground truth data
save('GTImg.mat', "GTImgArr");
disp("The data ""GTImgArr"" has been saved to data file ""GTImg.mat""! Copy it to the folder ""archieveData"".");
