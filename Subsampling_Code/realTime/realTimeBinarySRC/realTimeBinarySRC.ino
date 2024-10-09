// This file is the arduino code for the real-time implementation of the binary subsampling method and the SRC algorithm.
// Notes:
// 1. Update the values of variables "M", "K", "nObj", "S" and "thr";
// 2. To implement the real-time implementation of the binary subsampling algorithm and display the class SRC algorithm
// recognizes, firstly, compile and upload this code. After that, upload the dictionary and some other auxiliary matrices
// by using the matlab file "dict2Arduino.m". Lastly, open the serial monitor of arduino software to see the printed class.
// 3. Comment the time printing line when not use it;
#include <math.h>

#define N 1024 // number of sensors
#define thr 180 // threshold for the initiation of neighborSampling, !!
#define M 500 // number of measurement for each frame, !!

static const int K = 60; // size of dictionary !!
static const int S = 10;  // Sparsity level, !!
float Psi[N][K]; // dictionary for the whole image
static const int nObj = 30; // num of objects !!
int kObj = K / nObj; // size of dictionary !!
const char* objName[] = {
  "AAABattery",
  "J",
  "battery",
  "brain",
  "charger",
  "circle",
  "eraser",
  "flower",
  "foldingHex",
  "garlicPaste",
  "glue",
  "line",
  "mouse",
  "perfume",
  "plier",
  "ring",
  "scissor",
  "screwNNut",
  "screwdriver",
  "smallBall",
  "spoon",
  "square",
  "tennisBall",
  "threeLines",
  "triangle",
  "tweezers",
  "twoPoles",
  "watch",
  "wrench",
  "x"
}; // name of each object
int RTclass; // index of class the real-time SRC recognizes
int msr_norm; // norm of the subsampled image
int ctrMsrArr[N][2]; // array for the points to be examined in the binary subsampling mode in order; 1st col is x axis (row num), 2nd col is y axis (col num)
int colOrd[3] = {0, -1, 1}; // the column order for checking neighborhood of binary sampling algorithm
int msrPosArr[M]; // storage array of positions for each frame
float msrValArr[M][1]; // storage array of measurements for each frame
int idx = 0; // set zero for every iteration
bool isSampled[N]; // The lookup table for checking whether the pos has been checked in the current itr
int lastmsrRow = 16; // last row turned on for measurment
int lastmsrCol = 16; // last column turned on for measurment
int msr; // temp var for storage of measure
int pos; // temp var for storage of position
unsigned long timer1; // variable for assessing consumed time
int dpins[32] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32}; // table for the connected digital pins
int muxtable[32][5] = {
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
int rowConv[32] = {31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0}; // convert matlab img (0-31) index to arduino index (0-31)

void FastOMP(float Dict[N][K], int posArr[M], float y[M][1]) {
  // this function implements the FastOMP algorithm for determining the corresponding sparse representation and calculating the class who gives minimal error (principle of the SRC algorithm).
  float r[M];
  float s[S];
  float Q[M][S];
  float R[S][S];

  // Additional arrays for calculations
  float w[M];
  float v[S];

  float xhat[K][1];

  // Initialize arrays
  for (int i = 0; i < K; i++) xhat[i][0] = 0;
  for (int i = 0; i < M; i++) r[i] = y[i][0];

  for (int i = 0; i < S; i++) {
    // Find the max index ([~, idx_max] = max(abs(r'*A)))
    int idx_max = 0;
    float max_val = 0;

    // Here we use loop unrolling for performance gains
    // 1. Reduces the loop control overhead
    // 2. Better ILP - (Teensy 4.0 can execute 2 instructions
    // simultaneously)
    for (int j = 0; j < K - 3; j += 4) {
      float corr = 0, corr_1 = 0, corr_2 = 0, corr_3 = 0;
      int k;

      for (k = 0; k < M - 3; k += 4) {
        float r_k = r[k];
        float r_k1 = r[k + 1];
        float r_k2 = r[k + 2];
        float r_k3 = r[k + 3];
        int temp1 = posArr[k];
        int temp2 = posArr[k + 1];
        int temp3 = posArr[k + 2];
        int temp4 = posArr[k + 3];
        corr += r_k * Dict[temp1][j] + r_k1 * Dict[temp2][j] +
                r_k2 * Dict[temp3][j] + r_k3 * Dict[temp4][j];
        corr_1 += r_k * Dict[temp1][j + 1] + r_k1 * Dict[temp2][j + 1] +
                  r_k2 * Dict[temp3][j + 1] + r_k3 * Dict[temp4][j + 1];
        corr_2 += r_k * Dict[temp1][j + 2] + r_k1 * Dict[temp2][j + 2] +
                  r_k2 * Dict[temp3][j + 2] + r_k3 * Dict[temp4][j + 2];
        corr_3 += r_k * Dict[temp1][j + 3] + r_k1 * Dict[temp2][j + 3] +
                  r_k2 * Dict[temp3][j + 3] + r_k3 * Dict[temp4][j + 3];
      }
      for (; k < M; k++) {
        corr += r[k] * Dict[posArr[k]][j];
        corr_1 += r[k] * ((j + 1 < N) ? Dict[posArr[k]][j + 1] : 0);
        corr_2 += r[k] * ((j + 2 < N) ? Dict[posArr[k]][j + 2] : 0);
        corr_3 += r[k] * ((j + 3 < N) ? Dict[posArr[k]][j + 3] : 0);
      }

      if (fabs(corr) > fabs(max_val)) {
        max_val = corr;
        idx_max = j;
      }
      if (fabs(corr_1) > fabs(max_val)) {
        max_val = corr_1;
        idx_max = j + 1;
      }
      if (fabs(corr_2) > fabs(max_val)) {
        max_val = corr_2;
        idx_max = j + 2;
      }
      if (fabs(corr_3) > fabs(max_val)) {
        max_val = corr_3;
        idx_max = j + 3;
      }
    }

    s[i] = idx_max;

    // Store row of A where col is max index (w = A(:, s(i)))
    for (int i = 0; i < M; i++) {
      w[i] = Dict[posArr[i]][idx_max];
    }

    // Gram-Schmidt Orthogonalization (for j = 1 : i-1...)
    for (int j = 0; j < i; j++) {
      float Rji = 0;

      // Get Q(:,j)'
      // Also use loop unrolling here
      int k;
      for (k = 0; k < M - 3; k += 4) {
        Rji += Q[k][j] * w[k];
        Rji += Q[k + 1][j] * w[k + 1];
        Rji += Q[k + 2][j] * w[k + 2];
        Rji += Q[k + 3][j] * w[k + 3];
      }
      for (; k < M; k++) {
        Rji += Q[k][j] * w[k];
      }
      R[j][i] = Rji;

      // Update W
      float factor = Rji / R[j][j];
      for (k = 0; k < M - 3; k += 4) {
        w[k] -= factor * Q[k][j];
        w[k + 1] -= factor * Q[k + 1][j];
        w[k + 2] -= factor * Q[k + 2][j];
        w[k + 3] -= factor * Q[k + 3][j];
      }
      for (; k < M; k++) {
        w[k] -= factor * Q[k][j];
      }
    }

    // Calculate squared norm
    R[i][i] = 0;
    for (int k = 0; k < M; k++) {
      R[i][i] += w[k] * w[k];
    }

    // Update Q with the new orthogonal vector
    for (int k = 0; k < M; k++) {
      Q[k][i] = w[k];
    }

    // Update r
    float rDotQi = 0;
    for (int k = 0; k < M; k++) {
      rDotQi += r[k] * Q[k][i];
    }
    float scaledRdotQi = rDotQi / R[i][i];
    for (int k = 0; k < M; k++) {
      r[k] -= scaledRdotQi * Q[k][i];
    }
  }

  // Compute v(Q' * y)
  for (int i = 0; i < S; i++) {
    v[i] = 0;
    for (int j = 0; j < M; j++) {
      v[i] += Q[j][i] * y[j][0];
    }
  }

  // Back-substitution
  for (int i = 0; i < S; i++) {
    float sum = 0;

    // R(S-i+1,:)*xhat(s)
    for (int j = 0; j < i; j++) {
      int xhat_ind = static_cast<int>(s[S - j - 1]);
      sum += R[S - i - 1][S - j - 1] * xhat[xhat_ind][0];
    }

    // Assign xhat
    int xhat_ind = static_cast<int>(s[S - i - 1]);
    float temp_xhat = (v[S - i - 1] - sum) / R[S - i - 1][S - i - 1];
    xhat[xhat_ind][0] = temp_xhat;
  }

  // adapt to real-time classification
  int yhat[M]; for (int iM = 0; iM < M; iM++) yhat[iM] = 0;
  float errp = 1e6;
  float err;
  for (int iK = 0; iK < K; iK++) {
    float temp_xhat = xhat[iK][0];
    if (temp_xhat != 0) {
      for (int iM = 0; iM < M; iM++) yhat[iM] += temp_xhat * Psi[posArr[iM]][iK];
    }
    if (((iK + 1) % kObj) == 0) {
      err = 0;
      for (int iM = 0; iM < M; iM++) {
        float temp = y[iM][0] - yhat[iM];
        err += temp * temp;
        yhat[iM] = 0;
      }
      if (err < errp) {
        errp = err;
        RTclass = iK / kObj;
      }
    }
  }
}

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


  // set all the output pins for the [lastmsrRow]th row
  for (int i = 0; i < 32; i++) {
    digitalWriteFast(dpins[i], LOW);
  }
  digitalWriteFast(dpins[rowConv[lastmsrRow]], HIGH);

  // set all the output pins for the [lastmsrCol]th col
  digitalWriteFast(37, muxtable[lastmsrCol][0]);
  digitalWriteFast(36, muxtable[lastmsrCol][1]);
  digitalWriteFast(35, muxtable[lastmsrCol][2]);
  digitalWriteFast(34, muxtable[lastmsrCol][3]);
  digitalWriteFast(33, muxtable[lastmsrCol][4]);

  // construct the array of centers we will go through
  buildCtrArr();

  // initialize the isSampled arr
  for (int i = 0; i < N; i++) {
    isSampled[i] = false;
  }
}

FASTRUN void loop() {
  // receive the dictionary from the matlab for the real-time classification
  if (Serial.available() > 0) {
    Serial.readBytes((char*)Psi, N * K * sizeof(float));
  }

  timer1 = micros();

  // subsampling
  unsigned long timer2 = micros();
  binarySampling();
  timer2 = micros() - timer2;
  Serial.print("bin dur: ");
  Serial.println(timer2);

  // sparse coding and SRC
  unsigned long timer3 = micros();
  FastOMP(Psi, msrPosArr, msrValArr);
  timer3 = micros() - timer3;
  Serial.print("Classification dur: ");
  Serial.println(timer3);

  timer1 = micros() - timer1;

  // display the name of the recognized class
  dataDisp();
  Serial.println(timer1 * 1e-3);
  Serial.println(); // cheack the time per frame.
}

void dataDisp() {
  // display the name of the recognized class
  Serial.print(objName[RTclass]);
  Serial.print(',');
  delayMicroseconds(5);
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

bool notIn2d(int a[][2], int len, int x, int y) {
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
  int tempx;
  int tempy;

  idx = 0;

  msr_norm = 0;

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

    msrPosArr[idx] = pos;
    isSampled[pos] = true;
    if (msr > thr) {
      msrValArr[idx][0] = msr;
      msr_norm += msr * msr;
    } else {
      msrValArr[idx][0] = 1e-4;
    }

    idx++;
    if (idx >= M) break; // case when max msr num is reached

    // case when msr > threshold, do the neighborhood examination
    if (msr > thr) {
      neighborSampling(tempx, tempy);
      if (idx >= M) break; // case when max msr num is reached
    }
  }

  // reset isSample arr
  for (int i = 0; i < M; i++) {
    isSampled[msrPosArr[i]] = false;
  }
}

void neighborSampling(int centerX, int centerY) {
  // neighbor sampling algorithm. It will recursively search the neighbors which greater than the thredhold value.
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

      msrPosArr[idx] = pos;
      isSampled[pos] = true;
      if (msr > thr) {
        msrValArr[idx][0] = msr;
        msr_norm += msr * msr;
      } else {
        msrValArr[idx][0] = 1e-4;
      }
      idx++;

      if (idx >= M) return; // case when max msr num is reached

      if (msr > thr) neighborSampling(i, j);

      if (idx >= M) return; // case when max msr num is reached
    }
  }
}
