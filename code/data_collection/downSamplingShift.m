function downSamplingShift()
global M save_time data numWindow samplingMode numSensor numWindowTotal idxWindowTotal;

port = serialportlist;
s = serialport(port(1),12E6);
flush(s);

identity = 'downSamplingShift';
% conversion table for relation between num of measured sensors (per frame)
% and time per frame (us)
timePerFrameArr = [
    36, 634;
    42, 737;
    48, 846;
    49, 864;
    56, 987;
    64, 1127;
    66, 1163;
    77, 1357;
    88, 1547;
    96, 1689;
    112, 1971;
    121, 2131;
    128, 2255;
    160, 2820;
    176, 3098;
    192, 3380;
    224, 3941;
    256, 4508;
    352, 6197;
    512, 9019;
    1024, 17509;
    ];

% conversion table for relation between num of measured sensors (per frame)
% and col, row spacings during shifting down-sampling
msrSpacing = [
    1,1,1024;
    2,1,512;
    2,2,256;
    3,1,352;
    3,2,176;
    3,3,121;
    % 4,1,256; % repeat
    4,2,128;
    4,3,88;
    4,4,64;
    5,1,224;
    5,2,112;
    5,3,77;
    5,4,56;
    5,5,49;
    6,1,192;
    6,2,96;
    6,3,66;
    6,4,48;
    6,5,42;
    6,6,36;
    7,1,160;
    ];

% From the output image we see in the matlab to determine the image pixel
% position in the arduino.
coltable=1:32;
rowtable=32:-1:1;

% From the image pixel position in the arduino to determinethe output image
% we see in the matlab
colRtable = zeros(1,32);
rowRtable = zeros(1,32);
for i=1:32
    colRtable(i)=find(coltable==i);
    rowRtable(i)=find(rowtable==i);
end

idxMode = find(samplingMode==1); % 1 means the mode is downsampling with shift

for idxM = 1:length(M)
    msrNum = M(idxM);

    % calculation of params (fs (sampling rate), frame num) for each M
    fs = 1/timePerFrameArr(timePerFrameArr(:,1)==msrNum,2)*1e6; % s-1

    % calculation of num of frames per window
    num_frames = floor(fs * save_time);

    total_num = msrNum * num_frames; % num of msr sensor per 2s-window

    % store fs
    data(1,end,1,idxM,idxMode) = fs;

    % 'sensoridx' store the index (w.r.t. the arduino board) of sensor to
    % be measured in the Arduino board in one frame.
    % Note: it is not sorted. Before we sent this to arduino, we need to
    % sort it per frame, sensoridx1 is the sorted in each frame, and it
    % contains all sensor index to be measured in a 2s-window.
    sensoridx=zeros(1,msrNum);
    sensoridx1=zeros(1,total_num);

    % specify the index of row and column resprectively where measurement
    % is conducted, this is w.r.t. the output image we see in the matlab.
    RowSpacing=msrSpacing(msrSpacing(:,3)==msrNum,1);
    ColSpacing=msrSpacing(msrSpacing(:,3)==msrNum,2);
    msrRow=1:RowSpacing:32; % range: 1-32
    msrCol=1:ColSpacing:32; % range: 1-32

    for frame=1:num_frames
        % starting and ending idx for sensoridx1
        idxFrame0 = (frame-1)*msrNum+1;
        idxFrameF = frame*msrNum;

        myidx=1;
        for i=msrRow % range: 1-32
            reMsrRow=rowtable(i); % 1-32
            for j=msrCol % range: 1-32
                reMsrCol=coltable(j); % 1-32
                sensoridx(myidx)=(reMsrRow-1)*32+reMsrCol-1; % 0-1023
                myidx = myidx+1;
            end
        end

        % sort the sensoridx, which will be sent to Arduino.
        sensoridx1(idxFrame0:idxFrameF)=sort(sensoridx); % 0-1023

        % Put the corresponding pos into the stored array 'data'. Note that
        % for each window, the extracted pos are the same.
        for k=idxFrame0:idxFrameF
            IDXArd=sensoridx1(k); % 0-1023
            rowIDXArd = floor(IDXArd/32); % 0-31
            colIDXArd = mod(IDXArd,32); % 0-31

            matIDX = (rowRtable(rowIDXArd+1)-1)*32+colRtable(colIDXArd+1)-1; % 0-1023

            for i=1:numWindow
                data(1,k,i,idxM,idxMode)=matIDX;
            end
        end

        % update the imgidx
        msrCol=msrCol+1;

        if msrCol(end)>32
            msrCol(end)=32;
        end

        if msrCol(1)>=32 || msrCol(1)>ColSpacing
            msrCol=1:ColSpacing:32;
            msrRow=msrRow+1;
        end

        if msrRow(end)>32
            msrRow(end)=32;
        end

        if msrRow(1)>=32 || msrRow(1)>RowSpacing
            msrRow=1:RowSpacing:32; % range: 1-32
            msrCol=1:ColSpacing:32; % range: 1-32
        end
    end

    % give initiation signal to arduino
    % this time need to send 'sensoridx1' to arduino, which contain sorted
    % (for each frame) sensor index (w.r.t. arduino) to be measured.
    megary = [1 msrNum num_frames sensoridx1]; % 1 means the mode is downsampling with shift; !!!
    str = sprintf('%d,', megary);

    flush(s) % !!!
    writeline(s, str); % start the main program of Arduino

    idxWindow = 1;
    while idxWindow<=numWindow
        try
            disp([identity, '|msrNum ',num2str(msrNum), '|Window ', num2str(idxWindow), '|', num2str(idxWindowTotal), '/', num2str(numWindowTotal)]);
            input = split(readline(s),',');
        catch
            writeline(s, 'stop'); % stop the main program of Arduino

            clear s
            s = serialport(port,12E6);
            disp('re-connected')

            flush(s)
            writeline(s, str);

            continue;
        end

        if length(input)~=(total_num+2)
            disp('read data error');

            continue;
        end

        % extract the val
        data(2,1:(msrNum*num_frames),idxWindow,idxM,idxMode) = double(input(1:end-2));

        disp(input(end-1));

        idxWindow = idxWindow+1;
        idxWindowTotal = idxWindowTotal+1;
    end
end

writeline(s, 'stop'); % stop the main program of Arduino; can be ignored
clear s
