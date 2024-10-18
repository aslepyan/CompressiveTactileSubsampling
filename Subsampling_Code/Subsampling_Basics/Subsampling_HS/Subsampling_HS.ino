// This arduino file is for the collection of tactile data within a designated duration by using three subsampling modes.
// Notes:
// 1. Each time change code, need measure the fs and update it;
// 2. Comment the time printing line when not use it;
// 3. Update the values of variables "mythreshold" and "initThres".
#define N 1024 // number of sensors
#define mythreshold 180 // threshold for the initiation of neighborSampling
#define initThres 180 // threshold for the initiation of a subsampling process
#define LEDpin 40 // pin number for LED
#define maxNumMsr 200000 // max num of measurement for each window

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
int old_max = 0; // last max measurement in full scan for judging whether initialize subsampling
int new_max = 0; // current max measurement in full scan for judging whether initialize subsampling
int start_save = 0; // var for judging whether initialize subsampling
int initializer = 0; // var for judging whether initialize the process of subsampling; turn on/off by matlab command via the serial port.

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

  // initialize the isSampled arr
  for (int i = 0; i < N; i++) {
    isSampled[i] = false;
  }

  // find the max value in full scan to judge whether initialize the subsampling process
  old_max = findMax();
}

FASTRUN void loop() {
  if (Serial.available() > 0) {
    initializer = 1;

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

    if (mode == 0) initializer = 0;

    Serial.readString(); // clear seiral port
  }

  if (initializer == 1) {
    // judge whether initialize the sampling process
    new_max = findMax();
    if ((old_max > initThres) && (new_max < initThres)) {
      start_save = 1;
    }
    old_max = new_max;

    if (start_save == 1) {
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

      start_save = 0;
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

void buildCtrArr(uint16_t ctrMsrArr[N]) {
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

  ctrMsrArr[myidx] = floor(tempx / 2) * 32 + floor(tempy / 2);
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
          ctrMsrArr[myidx] = floor(tempx1 / 2) * 32 + floor(tempy / 2);
          myidx++;
        }

        tempx1 = tempx + ctrDev;
        ctrCrtArr[2 * j + 1][0] = tempx1;
        ctrCrtArr[2 * j + 1][1] = tempy;

        if (notIn2d(ctrMsrArr, myidx, tempx1 / 2, tempy / 2)) {
          ctrMsrArr[myidx] = floor(tempx1 / 2) * 32 + floor(tempy / 2);
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
          ctrMsrArr[myidx] = floor(tempx / 2) * 32 + floor(tempy1 / 2);
          myidx++;
        }

        tempy1 = tempy + ctrDev;
        ctrCrtArr[2 * j + 1][0] = tempx;
        ctrCrtArr[2 * j + 1][1] = tempy1;

        if (notIn2d(ctrMsrArr, myidx, tempx / 2, tempy1 / 2)) {
          ctrMsrArr[myidx] = floor(tempx / 2) * 32 + floor(tempy1 / 2);
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

bool notIn2d(uint16_t a[], int len, int x, int y) {
  // this function judge the point (x,y) is not in the 2d array a, whose each row stores 2d coordinates.
  bool judge = true;
  for (int i = 0; i < len; i++) {
    if (*(a + i) == (32 * x + y)) {
      judge = false;
      break;
    }
  }
  return judge;
}

void binarySampling() {
  // this function is for the implementation of the binary subsampling method
  uint16_t ctrMsrArr[N]; // array for the points to be examined in the binary subsampling mode in order. 1st col is x axis (row num), 2nd col is y axis (col num).
  buildCtrArr(ctrMsrArr); // construct the array of centers we will go through

  uint16_t repMsrArr[N]; // array for binary for repeat points
  uint16_t ind2Max = 0;
  bool iniFr = false;
  int iniFrInd = -1;
  bool HS = false; // whether high speed projectile examination; !!

  bool isNB[N];
  for (int i = 0; i < N; i++) {
    isNB[i] = false;
  }
  uint16_t nbArr[N]; // arr for ind of neighboring sampling
  uint16_t ind3Max = 0; // for nbArr
  uint16_t pos1;
  int ir, ic; // row, col ind for neighboring sampling

  bool isSampled1[N]; // as local var
  for (int i = 0; i < N; i++) {
    isSampled1[i] = false;
  }

  uint8_t tempx, tempy;

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
    uint16_t ind1 = 0, ind2 = 0, ind3 = 0; // ind1 for binary pattern points; ind2 for rep msr point; ind3 for neighbor points arr.
    idx = 0; // current ind

    while (1) {
      // extract each pos of center
      if (iniFrInd < frameNum && iniFr && ind2 < ind2Max) {
        pos = repMsrArr[ind2];
        ind2++;
      }
      else if (ind3 < ind3Max) {
        pos = nbArr[ind3];
        ind3++;
      }
      else {
        pos = ctrMsrArr[ind1];
        ind1++;
      }
      tempx = pos / 32;
      tempy = pos % 32;

      // case when the center point has been examined
      if (isSampled1[pos]) continue;

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

      // extract the tactile image of 1st non0 press for high speed projectile examination
      if (HS) {
        if (msr > mythreshold && (!iniFr || iniFrInd == frameNum)) {
          repMsrArr[ind2Max] = pos;
          ind2Max++;
          if (!iniFr) {
            iniFrInd = frameNum;
            iniFr = true;
          }
        }
      }

      msrPosArr[frameNum * M + idx] = pos;
      isSampled1[pos] = true;

      msrValArr[frameNum * M + idx] = msr;

      idx++;
      if (idx >= M) break; // case when max msr num is reached

      // case when msr > threshold, do the neighborhood examination
      if (msr > mythreshold && ind3Max < M) {
        // Notice that w/o any loop (unrolling) for faster speed, there is 8 neighbors: N,S,W,E,NW,NE,SW,SE.
        // N
        ic = tempy;
        if (ic >= 0 && ic < 32) {
          ir = tempx - 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // S
        ic = tempy;
        if (ic >= 0 && ic < 32) {
          ir = tempx + 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // NW
        ic = tempy - 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx - 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // W
        ic = tempy - 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // SW
        ic = tempy - 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx + 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // NE
        ic = tempy + 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx - 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // E
        ic = tempy + 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }

        // SE
        ic = tempy + 1;
        if (ic >= 0 && ic < 32) {
          ir = tempx + 1;
          if (ir >= 0 && ir < 32) {
            pos1 = 32 * ir + ic;
            if (!(isNB[pos1] || isSampled1[pos1])) {
              nbArr[ind3Max] = pos1;
              ind3Max++;
              isNB[pos1] = true;
            }
          }
        }
        /********************************/
      }
    }
    // reset isSample arr
    for (int i = 0; i < M; i++) {
      isSampled1[msrPosArr[frameNum * M + i]] = false;
    }
    for (int i = 0; i < ind3Max; i++) {
      isNB[nbArr[i]] = false;
    }
    ind3Max = 0;
  }
  // turn the row of last measured sensor to low.
  digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW);
}
