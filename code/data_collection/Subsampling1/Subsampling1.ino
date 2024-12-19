// This arduino file is for the collection of tactile data within a designated duration by using three subsampling modes.
// Notes:
// 1. Each time change code, need measure the fs and update it;
// 2. Update "mythreshold".
#define N 1024 // number of sensors
#define mythreshold 700 // threshold for the initiation of neighborSampling
#define LEDpin 40 // pin number for LED
#define maxNumMsr 200000 // max num of measurement for each window

uint8_t ctrMsrArr[N][2]; // array for the points to be examined in the binary subsampling mode in order. 1st col is x axis (row num), 2nd col is y axis (col num).
uint16_t msrPosArr[maxNumMsr]; // storage array of measurement for each window
uint16_t* msrValArr = new uint16_t[maxNumMsr]; // storage of position for each window
int idx = 0; // index of measurement in each frame; set zero for every frame
int mode; // mode for subsampling
int M; // number of measurement within each frame
int numFrame; // number of frames for each window
int lastmsrRow; // last row turned on for measurment
int lastmsrCol; // last column turned on for measurment
int msr; // temp var for storage of measure
int pos; // temp var for storage of position
bool isSampled[N]; // lookup table for checking whether the pos has been checked in the current iteration
int colOrd[3] = {0, -1, 1}; // column order for checking neighborhood of binary sampling mode
unsigned long timer1; // variable for assessing consumed time
uint8_t dpins[32] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32}; // table for the connected digital pins
bool muxtable[32][5] = {
  {0, 0, 0, 0, 0},
  {0, 0, 0, 0, 1},
  {0, 0, 0, 1, 0},
  {0, 0, 0, 1, 1},
  {0, 0, 1, 0, 0},
  {0, 0, 1, 0, 1},
  {0, 0, 1, 1, 0},
  {0, 0, 1, 1, 1},
  {0, 1, 0, 0, 0},
  {0, 1, 0, 0, 1},
  {0, 1, 0, 1, 0},
  {0, 1, 0, 1, 1},
  {0, 1, 1, 0, 0},
  {0, 1, 1, 0, 1},
  {0, 1, 1, 1, 0},
  {0, 1, 1, 1, 1},
  {1, 0, 0, 0, 0},
  {1, 0, 0, 0, 1},
  {1, 0, 0, 1, 0},
  {1, 0, 0, 1, 1},
  {1, 0, 1, 0, 0},
  {1, 0, 1, 0, 1},
  {1, 0, 1, 1, 0},
  {1, 0, 1, 1, 1},
  {1, 1, 0, 0, 0},
  {1, 1, 0, 0, 1},
  {1, 1, 0, 1, 0},
  {1, 1, 0, 1, 1},
  {1, 1, 1, 0, 0},
  {1, 1, 1, 0, 1},
  {1, 1, 1, 1, 0},
  {1, 1, 1, 1, 1},
}; // conversion table for the multiplexer
uint8_t rowConv[32] = {31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0}; // convert matlab img (0-31) index to arduino index (0-31)
bool ini2 = false; // var for judging whether initialize subsampling
bool ini = false; // var for judging whether initialize the process of subsampling; turn on/off by matlab command via the serial port.

void setup() {
  // rows
  for (int i = 0; i < 32; i++) {
    pinMode(dpins[i], OUTPUT);
  }

  // mux pins
  pinMode(33, OUTPUT);
  pinMode(34, OUTPUT);
  pinMode(35, OUTPUT);
  pinMode(36, OUTPUT);
  pinMode(37, OUTPUT);

  // set the LED pin
  pinMode(LEDpin, OUTPUT);

  // set all the output pins to low
  for (int i = 0; i < 32; i++) {
    digitalWriteFast(dpins[i], LOW);
  }

  // construct the array of centers we will go through
  buildCtrArr();

  // initialize the isSampled arr
  for (int i = 0; i < N; i++) {
    isSampled[i] = false;
  }
}

FASTRUN void loop() {
  if (!ini && Serial.available() > 0) {
    ini = true;

    // get the information of subsampling mode, measurement level and num of frame from matlab via the serial port
    mode = Serial.parseInt();
    M = Serial.parseInt();
    numFrame = Serial.parseInt();

    // For down- and random sampling, the sensors to be extracted has been directly sent from matlab.
    if (mode == 1 || mode == 2) {
      for (int frame = 0; frame < numFrame; frame++) {
        for (int pnt = 0; pnt < M; pnt++) {
          msrPosArr[frame * M + pnt] = Serial.parseInt();
        }
      }
    }

    if (mode == 0) ini = false;

    Serial.readString(); // clear seiral port
  }

  if (ini) {
    // judge whether initialize the sampling process
    if (Serial.available() > 0) {
      char isStart = Serial.read();
      Serial.readString(); // clear seiral port
      if (isStart == 'a') {
        ini2 = true;
      }
      if (isStart == 'z') {
        ini = false;
      }
    }

    if (ini2) {
      digitalWrite(LEDpin, HIGH); //turn on the LED

      timer1 = micros();

      // subsampling process
      if (mode == 1 || mode == 2) mySubsampling(); // down- or random sampling
      if (mode == 3) binarySampling(); // binary sampling

      // determine the time per frame.
      timer1 = micros() - timer1;

      digitalWrite(LEDpin, LOW); // turn off LED

      // send value back to matlab
      bool isSendPos = false; // when down or random sampling, pos will not be sent back.
      if (mode == 3) isSendPos = true; // binary sampling
      sendData1(numFrame, M, isSendPos); // send measured data (and corresponding position) back to matlab

      Serial.print(timer1);
      Serial.print(',');
      delayMicroseconds(5);
      Serial.println();

      ini2 = false;
    }
  }
}

void mySubsampling() {
  // storage the row and col indices and previous one
  int msrIDX;
  int rowIDX = 31;
  int colIDX;
  int rowIDXp;

  digitalWriteFast(dpins[rowIDX], HIGH);

  for (int frame = 0; frame < numFrame; frame++) {
    for (int i = 0; i < M; i++) {
      msrIDX = msrPosArr[frame * M + i]; // 0-1023
      rowIDXp = rowIDX;
      rowIDX = floor(msrIDX / 32); // 0-31
      colIDX = msrIDX - floor(msrIDX / 32) * 32; //0-31

      if ((rowIDX - rowIDXp) != 0) {
        digitalWriteFast(dpins[rowIDXp], LOW); //turn the previous row low
        digitalWriteFast(dpins[rowIDX], HIGH); // turn the current row high
      }

      digitalWriteFast(37, muxtable[colIDX][0]);
      digitalWriteFast(36, muxtable[colIDX][1]);
      digitalWriteFast(35, muxtable[colIDX][2]);
      digitalWriteFast(34, muxtable[colIDX][3]);
      digitalWriteFast(33, muxtable[colIDX][4]);

      msrValArr[frame * M + i] = analogRead(A0);
    }
  }

  digitalWriteFast(dpins[rowIDX], LOW);
}

void sendData1(int numFrame, int M, bool isSendPos) {
  // this function prints the pos coordinates and values out and send to serial monitor for one window
  for (int frame = 0; frame < numFrame; frame++) {
    for (int pnt = 0; pnt < M; pnt++) {
      if (isSendPos) {
        Serial.print(msrPosArr[frame * M + pnt]);
        Serial.print(',');
        delayMicroseconds(5);
      }

      Serial.print(msrValArr[frame * M + pnt]);
      Serial.print(',');
      delayMicroseconds(5);
    }
  }
}

int findMax() {
  // this function find the max value of sensor by the raster scanning method
  int sensorMax = 0;
  int temp;

  for (int i = 0; i < 32; i++) { //16
    digitalWriteFast(dpins[i], HIGH);
    for (int j = 0; j < 32; j++) { // 16
      digitalWriteFast(37, muxtable[j][0]);
      digitalWriteFast(36, muxtable[j][1]);
      digitalWriteFast(35, muxtable[j][2]);
      digitalWriteFast(34, muxtable[j][3]);
      digitalWriteFast(33, muxtable[j][4]);

      temp = analogRead(A0);
      if (temp > sensorMax) sensorMax = temp;

    }
    digitalWriteFast(dpins[i], LOW);
  }
  return sensorMax;
}

void buildCtrArr() {
  // function for pre-determination of search order array of centers
  int maxNumItr = 10; // formula: 2*(log2(32*2/4)+1), need to change if sensor size change

  bool hrzDiv = false; // division style is horizontal or verticle, the first one should be verticle

  int ctrDev = 16 * 2; // distance of next center to the division line, multiply by 2 since will devide by 2 once enter the loop
  int myidx = 0; // index of ctrMsrArr

  int ctrCrtArr[N][2]; // center positions in the current iteration
  int ctrHisArr[N / 2][2]; // center positions in the previous iteration

  int tempx = 32; // temp var for storage of x pos from previous pos
  int tempy = 32; // temp var for storage of y pos from previous pos
  int tempx1; // temp var for storage of new x pos
  int tempy1; // temp var for storage of new y pos

  ctrMsrArr[myidx][0] = tempx / 2;
  ctrMsrArr[myidx][1] = tempy / 2;
  myidx++;

  ctrHisArr[0][0] = tempx;
  ctrHisArr[0][1] = tempy;

  for (int i = 1; i <= maxNumItr; i++) {
    if (hrzDiv) {
      for (int j = 0; j < pow(2, i - 1); j++) {

        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];

        tempx1 = tempx - ctrDev;
        ctrCrtArr[2 * j][0] = tempx1;
        ctrCrtArr[2 * j][1] = tempy;

        if (notIn2d(ctrMsrArr, myidx, tempx1 / 2, tempy / 2)) {
          ctrMsrArr[myidx][0] = tempx1 / 2;
          ctrMsrArr[myidx][1] = tempy / 2;
          myidx++;
        }

        tempx1 = tempx + ctrDev;
        ctrCrtArr[2 * j + 1][0] = tempx1;
        ctrCrtArr[2 * j + 1][1] = tempy;

        if (notIn2d(ctrMsrArr, myidx, tempx1 / 2, tempy / 2)) {
          ctrMsrArr[myidx][0] = tempx1 / 2;
          ctrMsrArr[myidx][1] = tempy / 2;
          myidx++;
        }
      }
    }

    else {
      ctrDev /= 2;

      for (int j = 0; j < pow(2, i - 1); j++) {

        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];

        tempy1 = tempy - ctrDev;
        ctrCrtArr[2 * j][0] = tempx;
        ctrCrtArr[2 * j][1] = tempy1;

        if (notIn2d(ctrMsrArr, myidx, tempx / 2, tempy1 / 2)) {
          ctrMsrArr[myidx][0] = tempx / 2;
          ctrMsrArr[myidx][1] = tempy1 / 2;
          myidx++;
        }

        tempy1 = tempy + ctrDev;
        ctrCrtArr[2 * j + 1][0] = tempx;
        ctrCrtArr[2 * j + 1][1] = tempy1;

        if (notIn2d(ctrMsrArr, myidx, tempx / 2, tempy1 / 2)) {
          ctrMsrArr[myidx][0] = tempx / 2;
          ctrMsrArr[myidx][1] = tempy1 / 2;
          myidx++;
        }
      }
    }

    // store current results into the 'ctrHisArr' array
    if (i != maxNumItr) {
      for (int j = 0; j < pow(2, i); j++) {
        ctrHisArr[j][0] = ctrCrtArr[j][0];
        ctrHisArr[j][1] = ctrCrtArr[j][1];
      }
    }

    hrzDiv = (hrzDiv == false);
  }
}

bool notIn2d(uint8_t a[][2], int len, int x, int y) {
  // this function judge the point (x,y) is not in the 2d array a, whose each row stores 2d coordinates.
  bool judge = true;
  for (int i = 0; i < len; i++) {
    if (*(*(a + i) + 0) == x && *(*(a + i) + 1) == y) {
      judge = false;
      break;
    }
  }
  return judge;
}

int coord2DTo1D(int x1, int x2) {
  // convert coordinates from 2d (0-31,0-31)to 1d (0-1023)
  return 32 * x1 + x2;
}

void binarySampling() {
  // this function is for the implementation of the binary subsampling method
  lastmsrRow = 16; // 16 is 1st detected row in this case, but can be others
  lastmsrCol = 16;

  // set all the output pins for the [lastmsrRow]th row
  digitalWriteFast(dpins[rowConv[lastmsrRow]], HIGH);

  // set all the output pins for the [lastmsrCol]th col
  digitalWriteFast(37, muxtable[lastmsrCol][0]);
  digitalWriteFast(36, muxtable[lastmsrCol][1]);
  digitalWriteFast(35, muxtable[lastmsrCol][2]);
  digitalWriteFast(34, muxtable[lastmsrCol][3]);
  digitalWriteFast(33, muxtable[lastmsrCol][4]);

  for (int frameNum = 0; frameNum < numFrame; frameNum++) {
    int tempx;
    int tempy;

    idx = 0;

    for (int i = 0; i < N; i++) {
      // extract each pos of center
      tempx = ctrMsrArr[i][0];
      tempy = ctrMsrArr[i][1];
      pos = coord2DTo1D(tempx, tempy);

      // case when the center point has been examined
      if (isSampled[pos]) continue;

      if (lastmsrRow != tempx) {
        digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW); //turn the previous row low
        digitalWriteFast(dpins[rowConv[tempx]], HIGH); // turn the current row high
        lastmsrRow = tempx;
      }

      if (lastmsrCol != tempy) {
        digitalWriteFast(37, muxtable[tempy][0]);
        digitalWriteFast(36, muxtable[tempy][1]);
        digitalWriteFast(35, muxtable[tempy][2]);
        digitalWriteFast(34, muxtable[tempy][3]);
        digitalWriteFast(33, muxtable[tempy][4]);
        lastmsrCol = tempy;
      }

      msr = analogRead(A0);

      msrPosArr[frameNum * M + idx] = pos;
      isSampled[pos] = true;

      msrValArr[frameNum * M + idx] = msr;

      idx++;
      if (idx >= M) break; // case when max msr num is reached

      // case when msr > threshold, do the neighborhood examination
      if (msr > mythreshold) {
        neighborSampling(tempx, tempy, frameNum);
        if (idx >= M) break; // case when max msr num is reached
      }
    }
    // reset isSample arr
    for (int i = 0; i < M; i++) {
      isSampled[msrPosArr[frameNum * M + i]] = false;
    }
  }
  // turn the row of last measured sensor to low.
  digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW);
}

void neighborSampling(int centerX, int centerY, int frameNum) {
  // This function is for the implementation of the neighbor sampling algorithm. It will recursively search the neighbors which greater than the threshold value.
  for (int jj = 0; jj < 3; jj++) {
    int j = centerY + colOrd[jj];
    if (j < 0 || j >= 32) continue;
    for (int i = centerX - 1; i <= centerX + 1; i++) {
      if (i < 0 || i >= 32) continue;
      pos = coord2DTo1D(i, j);

      if (isSampled[pos]) continue;

      if (lastmsrCol != j) {
        digitalWriteFast(37, muxtable[j][0]);
        digitalWriteFast(36, muxtable[j][1]);
        digitalWriteFast(35, muxtable[j][2]);
        digitalWriteFast(34, muxtable[j][3]);
        digitalWriteFast(33, muxtable[j][4]);
        lastmsrCol = j;
      }

      if (lastmsrRow != i) {
        digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW); //turn the previous row low
        digitalWriteFast(dpins[rowConv[i]], HIGH); // turn the current row high
        lastmsrRow = i;
      }

      msr = analogRead(A0);

      msrPosArr[frameNum * M + idx] = pos;
      isSampled[pos] = true;

      msrValArr[frameNum * M + idx] = msr;

      idx++;
      if (idx >= M) return; // case when max msr num is reached

      if (msr > mythreshold) neighborSampling(i, j, frameNum);
      if (idx >= M) return; // case when max msr num is reached
    }
  }
}
