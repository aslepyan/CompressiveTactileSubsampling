function randomSampling1()
global M save_time data numWindow samplingMode numSensor numWindowTotal idxWindowTotal;save

port = serialportlist;
s = serialport(port(1),12E6);
flush(s);

identity = 'randomSampling';
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
    1024, 18078;
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

idxMode = find(samplingMode==2); % 2 means the mode is random sampling

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
    % contains all sensor index to be measured in all 2s-window(s).
    sensoridx=zeros(1,msrNum);
    sensoridx1=zeros(numWindow,total_num);

    for idxWindow = 1:numWindow
        for frame=1:num_frames
            % starting and ending idx for sensoridx1
            idxFrame0 = (frame-1)*msrNum+1;
            idxFrameF = frame*msrNum;

            % Extract sensor idx (w.r.t. matlab img) to be measured for
            % each frame randomly.
            sensoridxmat = randperm(numSensor,msrNum); % 1-1024

            for k=1:msrNum
                temp=sensoridxmat(k); % 1-1024
                i=ceil(temp/32); % 1-32; row idx w.r.t. matlab img
                j=mod(temp,32)+32*(mod(temp,32)==0); % 1-32; col idx w.r.t. matlab img
                reMsrRow=rowtable(i); % 1-32; row idx w.r.t. ard
                reMsrCol=coltable(j); % 1-32; col idx w.r.t. ard
                sensoridx(k)=(reMsrRow-1)*32+reMsrCol-1; % 0-1023; idx w.r.t. ard
            end

            % sort the sensoridx, which will be sent to Arduino.
            sensoridx1(idxWindow,idxFrame0:idxFrameF)=sort(sensoridx); % 0-1023

            % Put the corresponding pos into the stored array 'data'. Note that
            % for each window, the extracted pos are the same.
            for k=idxFrame0:idxFrameF
                IDXArd=sensoridx1(idxWindow,k); % 0-1023
                rowIDXArd = floor(IDXArd/32); % 0-31
                colIDXArd = mod(IDXArd,32); % 0-31

                matIDX = (rowRtable(rowIDXArd+1)-1)*32+colRtable(colIDXArd+1)-1; % 0-1023

                data(1,k,idxWindow,idxM,idxMode)=matIDX;
            end
        end
    end

    idxWindow = 1;
    isSend = 0;
    while idxWindow<=numWindow
        if isSend==0
            % give initiation signal to arduino
            % this time need to send 'sensoridx1' to arduino, which contain sorted
            % (for each frame) sensor index (w.r.t. arduino) to be measured.
            megary = [2 msrNum num_frames sensoridx1(idxWindow,:)]; % 2 means the mode is random sampling
            str = sprintf('%d,', megary);

            flush(s)
            writeline(s, str); % start the main program of Arduino

            isStart=input("press enter to start!","s");
            writeline(s, ['a',isStart]); % signal to start the window

            isSend=1;
        end

        try
            disp([identity, '|msrNum ',num2str(msrNum), '|Window ', num2str(idxWindow), '|', num2str(idxWindowTotal), '/', num2str(numWindowTotal)]);
            pause(30)
            input1 = split(readline(s),',');
        catch
            writeline(s, 'stop'); % stop the main program of Arduino

            clear s
            s = serialport(port(1),12E6);
            disp('re-connected')

            flush(s)
            writeline(s, str);

            continue;
        end

        if length(input1)~=(total_num+1+1)
            disp('read data error');
            
            flush(s)
            writeline(s, str); % start the main program of Arduino

            continue;
        end

        % extract the val
        data(2,1:(msrNum*num_frames),idxWindow,idxM,idxMode) = double(input1(1:end-2));

        disp(input1(end-1));

        idxWindow = idxWindow+1;
        isSend=0;
        idxWindowTotal = idxWindowTotal+1;

        writeline(s, 'z'); % stop the main program of Arduino; can be ignored
    end
end

clear s
