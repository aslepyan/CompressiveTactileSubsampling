/*
  Given a number of sensors and a simple press image (where non-zero presses exist), this file is to simulate and determine the order of binary sampling.
  It assumes the tactile sensor is square, that is the number of sensors is a square number.
  Note: Before uploading the code, please adjust 'N' and 'nnzPosArr'.
*/

const int N = 225;
uint8_t nnzPosArr[N][2] = {
  {12, 4},
  {12, 5},
  {12, 6},
  {11, 5},
  {11, 6},
  {12, 14},
  {11, 14},
  {12, 13},
  {11, 13},
};

int find_nnzSz(uint8_t nnzPosArr[N][2]);
const int nnzSz = find_nnzSz(nnzPosArr);
const int nRow = sqrt(N), nCol = sqrt(N);
uint8_t ctrMsrArr[N][2]; // array for the points to be examined in the binary subsampling mode in order. 1st col is x axis (row num), 2nd col is y axis (col num).
int idx = 0; // index of measurement in each frame; set zero for every frame
int pos; // temp var for storage of position
uint8_t msrPosArr[N][2]; // real pos with consideration of neighbor sampling
bool isSampled[N]; // lookup table for checking whether the pos has been checked in the current iteration
int colOrd[3] = {0, -1, 1}; // column order for checking neighborhood of binary sampling mode

void setup() {
  // construct the array of centers we will go through
  buildCtrArr();
}

FASTRUN void loop() {
  // simulate bin sam for extracting the sampling order
  binarySampling();
  for (int i = 0; i < N; i++) {
    Serial.print(msrPosArr[i][0]);
    Serial.print(',');
    Serial.print(msrPosArr[i][1]);
    Serial.print(',');
  }
  Serial.println();
}

int find_nnzSz(uint8_t nnzPosArr[N][2]) {
  int result = N;
  for (int i = 1; i < N; i++) {
    if (nnzPosArr[i][0] == 0 && nnzPosArr[i][1] == 0 && nnzPosArr[i-1][0] == 0 && nnzPosArr[i-1][1] == 0) {
       result = i-1;
       break;
    }
  }
  return result;
}

void buildCtrArr() {
  // function for pre-determination of search order array of centers
  int maxNumItr = log(N) / log(2) + 2; // formula: 2*(log2(32*2/4)+1), need to change if sensor size change
  bool hrzDiv = false; // division style is horizontal or verticle, the first one should be verticle
  int ctrDev; // distance of next center to the division line
  uint8_t ctrCrtArr[N][2]; // center positions in the current iteration
  uint8_t ctrHisArr[N][2]; // center positions in the previous iteration
  int ind = 0; // index of ctrMsrArr
  int crtNCtr = 1; // num of center for the current iteration
  int nextNCtr = 0; // num of center for the next iteration
  int tempx = nRow; // temp var for storage of x pos from previous pos
  int tempy = nCol; // temp var for storage of y pos from previous pos
  int tempx1; // temp var for storage of new x pos
  int tempy1; // temp var for storage of new y pos

  ctrMsrArr[ind][0] = tempx / 2;
  ctrMsrArr[ind][1] = tempy / 2;
  ind++;
  ctrHisArr[0][0] = tempx / 2;
  ctrHisArr[0][1] = tempy / 2;

  for (int i = 1; i <= maxNumItr; i++) {
    if (hrzDiv) {
      for (int j = 0; j < crtNCtr; j++) {
        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];

        tempx1 = tempx - ctrDev;
        if (tempx1 >= 0) {
          if (notIn2d(ctrCrtArr, nextNCtr, tempx1, tempy)) {
            ctrCrtArr[nextNCtr][0] = tempx1;
            ctrCrtArr[nextNCtr][1] = tempy;
            nextNCtr++;
          }

          if (notIn2d(ctrMsrArr, ind, tempx1, tempy)) {
            ctrMsrArr[ind][0] = tempx1;
            ctrMsrArr[ind][1] = tempy;
            ind++;
          }
        }

        tempx1 = tempx + ctrDev;
        if (tempx1 < nRow) {
          if (notIn2d(ctrCrtArr, nextNCtr, tempx1, tempy)) {
            ctrCrtArr[nextNCtr][0] = tempx1;
            ctrCrtArr[nextNCtr][1] = tempy;
            nextNCtr++;
          }

          if (notIn2d(ctrMsrArr, ind, tempx1, tempy)) {
            ctrMsrArr[ind][0] = tempx1;
            ctrMsrArr[ind][1] = tempy;
            ind++;
          }
        }
      }
    }

    else {
      ctrDev = ctrHisArr[0][1] - (int)(ctrHisArr[0][1] / 2); // current distance to the center
      if (ctrDev == 0) ctrDev = 1;

      for (int j = 0; j < crtNCtr; j++) {
        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];

        tempy1 = tempy - ctrDev;
        if (tempy1 >= 0) {
          if (notIn2d(ctrCrtArr, nextNCtr, tempx, tempy1)) {
            ctrCrtArr[nextNCtr][0] = tempx;
            ctrCrtArr[nextNCtr][1] = tempy1;
            nextNCtr++;
          }

          if (notIn2d(ctrMsrArr, ind, tempx, tempy1)) {
            ctrMsrArr[ind][0] = tempx;
            ctrMsrArr[ind][1] = tempy1;
            ind++;
          }
        }

        tempy1 = tempy + ctrDev;
        if (tempy1 < nCol) {
          if (notIn2d(ctrCrtArr, nextNCtr, tempx, tempy1)) {
            ctrCrtArr[nextNCtr][0] = tempx;
            ctrCrtArr[nextNCtr][1] = tempy1;
            nextNCtr++;
          }

          if (notIn2d(ctrMsrArr, ind, tempx, tempy1)) {
            ctrMsrArr[ind][0] = tempx;
            ctrMsrArr[ind][1] = tempy1;
            ind++;
          }
        }
      }
    }

    // store current results into the 'ctrHisArr' array
    if (i != maxNumItr) {
      for (int j = 0; j < nextNCtr; j++) {
        ctrHisArr[j][0] = ctrCrtArr[j][0];
        ctrHisArr[j][1] = ctrCrtArr[j][1];
      }
      crtNCtr = nextNCtr;
      nextNCtr = 0;
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
  return nCol * x1 + x2;
}

void binarySampling() {
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

    msrPosArr[idx][0] = tempx;
    msrPosArr[idx][1] = tempy;
    isSampled[pos] = true;
    idx++;
    if (idx >= N) break; // case when max msr num is reached

    // case when msr > threshold, do the neighborhood examination
    if (!notIn2d(nnzPosArr, nnzSz, tempx, tempy)) {
      neighborSampling(tempx, tempy);
      if (idx >= N) break; // case when max msr num is reached
    }
  }
  // reset isSample arr
  for (int i = 0; i < N; i++) {
    isSampled[i] = false;
  }
}

void neighborSampling(int centerX, int centerY) {
  // This function is for the implementation of the neighbor sampling algorithm. It will recursively search the neighbors which greater than the threshold value.
  for (int jj = 0; jj < 3; jj++) {
    int j = centerY + colOrd[jj];
    if (j < 0 || j >= nCol) continue;
    for (int i = centerX - 1; i <= centerX + 1; i++) {
      if (i < 0 || i >= nRow) continue;
      pos = coord2DTo1D(i, j);

      if (isSampled[pos]) continue;

      msrPosArr[idx][0] = i;
      msrPosArr[idx][1] = j;
      isSampled[pos] = true;
      idx++;
      if (idx >= N) return; // case when max msr num is reached

      if (!notIn2d(nnzPosArr, nnzSz, i, j)) neighborSampling(i, j);
      if (idx >= N) return; // case when max msr num is reached
    }
  }
}
