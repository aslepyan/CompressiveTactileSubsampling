 // This is the code for real-time binary subsampling algorithms.
#include <math.h>

#define N 1024 // number of sensors; 32x32
#define M 128 // number of measurement, !!
#define mythreshold 180 // threshold for the initiation of neighborSampling, !!
#define nbSamLayer 1 // sampling layer in the neighborSampling

// 2d int array of center points to be examined (with order), later, if the points is checked by the neighborSampling, then the x axis will be marked as -1, which indicate that the corresponding points will be omitted. 1st col is x axis (row num), 2nd col is y axis (col num).
int ctrMsrArr[N][2];

// size of dict
static const int K=500; // !!

// dict
EXTMEM float Psi[N][K];
bool iniDict = false; // whether initialize the dict

// sensing matrix (Phi*Psi)
EXTMEM float Phi[M][K];

int msrPosArr[M]; // array of the position of sampled pixels
float msrValArr[M][1]; // array of the values of sampled pixels
float xs[K][1]; // array of sparse coding vector
float xvec[N][1];
int S;
float tempX=0; // temp var for storage of x

int idx = 0; // set zero for every frame

int lastmsrRow = 16;
int msr; // temp var for storage of measure
int pos; // temp var for storage of position

// what are the connected digital pins?
int dpins[32] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32};

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
};


// convert matlab img (0-31) index to arduino index (0-31)
int rowConv[32] = {31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0};

int coord2DTo1D(int x1, int x2){
  // convert coordinates from 2d (0-31,0-31)to 1d (0-1023)
  return 32*x1+x2;
}

bool notIn1d(int a[], int startIdx, int len, int x, int y){
  //this function judge the point (x,y) is not in the 1d array a, from the index of startIdx to startIdx+len
  bool judge=true;
  for (int i=startIdx; i<startIdx+len; i++){
    if (*(a+i)==coord2DTo1D(x,y)){
      judge=false;
      break;
    }
  }
  return judge;
}


bool notIn2d(int a[][2], int len, int x, int y){
  //this function judge the point (x,y) is not in the 2d array a, whose each row stores 2d coordinates.
  bool judge=true;
  for (int i=0; i<len; i++){
    if (*(*(a+i)+0)==x && *(*(a+i)+1)==y){
      judge=false;
      break;
    }
  }
  return judge;
}


void buildCtrArr(){
  // function for pre-determination of search order array of centers

  int maxNumItr = 10; // formula: 2*(log2(32*2/4)+1), need to change if sensor size change
  
  bool hrzDiv = false; // division style is horizontal or verticle, the first one should be verticle
  
  int ctrDev = 16*2; // distance of next center to the division line, multiply by 2 since will devide by 2 once enter the loop
  int myidx = 0; // index of ctrMsrArr
  
  int ctrCrtArr[N][2]; // center positions in the current iteration
  int ctrHisArr[N/2][2]; // center positions in the previous iteration

  int tempx=32; // temp var for storage of x pos from previous pos
  int tempy=32; // temp var for storage of y pos from previous pos
  int tempx1; // temp var for storage of new x pos
  int tempy1; // temp var for storage of new y pos
  
  ctrMsrArr[myidx][0]=tempx/2;
  ctrMsrArr[myidx][1]=tempy/2;
  myidx++;
  
  ctrHisArr[0][0]=tempx;
  ctrHisArr[0][1]=tempy;
  
  for (int i=1; i<=maxNumItr; i++){
    if (hrzDiv){
      for (int j=0; j<pow(2,i-1); j++){
        
        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];
        
        tempx1 = tempx-ctrDev;
        ctrCrtArr[2*j][0]=tempx1;
        ctrCrtArr[2*j][1]=tempy;
        
        if (notIn2d(ctrMsrArr, myidx, tempx1/2, tempy/2)){
          ctrMsrArr[myidx][0]=tempx1/2;
          ctrMsrArr[myidx][1]=tempy/2;
          myidx++;
        }
        
        tempx1 = tempx+ctrDev;
        ctrCrtArr[2*j+1][0]=tempx1;
        ctrCrtArr[2*j+1][1]=tempy;
        
        if (notIn2d(ctrMsrArr, myidx, tempx1/2, tempy/2)){
          ctrMsrArr[myidx][0]=tempx1/2;
          ctrMsrArr[myidx][1]=tempy/2;
          myidx++;
        }
      }
    }
    
    else{
      ctrDev/=2;

      for (int j=0; j<pow(2,i-1); j++){
        
        tempx = ctrHisArr[j][0];
        tempy = ctrHisArr[j][1];
        
        tempy1 = tempy-ctrDev;
        ctrCrtArr[2*j][0]=tempx;
        ctrCrtArr[2*j][1]=tempy1;
        
        if (notIn2d(ctrMsrArr, myidx, tempx/2, tempy1/2)){
          ctrMsrArr[myidx][0]=tempx/2;
          ctrMsrArr[myidx][1]=tempy1/2;
          myidx++;
        }
        
        tempy1 = tempy+ctrDev;
        ctrCrtArr[2*j+1][0]=tempx;
        ctrCrtArr[2*j+1][1]=tempy1;
        
        if (notIn2d(ctrMsrArr, myidx, tempx/2, tempy1/2)){
          ctrMsrArr[myidx][0]=tempx/2;
          ctrMsrArr[myidx][1]=tempy1/2;
          myidx++;
        }
      }
    }
    
    // store current results into the 'ctrHisArr' array
    if (i!=maxNumItr){
      for (int j=0; j<pow(2,i); j++){
        ctrHisArr[j][0]=ctrCrtArr[j][0];
        ctrHisArr[j][1]=ctrCrtArr[j][1];
      }
    }
    
    hrzDiv=(hrzDiv==false);
  }
}


void neighborSamplingV2(int centerX, int centerY){
  // this is the version 2 of neighbor sampling algorithm.
  // It will recursively search the neighbors which greater than the thredhold value.
  
  for (int i=centerX-nbSamLayer; i<=centerX+nbSamLayer;i++){

    if (i<0 || i>=32) {continue;}

    if (lastmsrRow-i!=0){
      digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW); //turn the previous row low
      digitalWriteFast(dpins[rowConv[i]], HIGH); // turn the current row high
      lastmsrRow=i;
    }
    
    for (int j=centerY-nbSamLayer; j<=centerY+nbSamLayer;j++){
          // edge condition j<0 or j>33 ...
          if (j<0 || j>=32) continue;
          
          // condi when notIn2d
          if (!notIn1d(msrPosArr, 0, idx, i, j)) continue;

          digitalWriteFast(37, muxtable[j][0]);
          digitalWriteFast(36, muxtable[j][1]);
          digitalWriteFast(35, muxtable[j][2]);
          digitalWriteFast(34, muxtable[j][3]);
          digitalWriteFast(33, muxtable[j][4]);
          
        msr = analogRead(A0);
		pos = coord2DTo1D(i,j); // 0-1023

		for (int kk=0;kk<K;kk++){
			Phi[idx][kk]=Psi[pos][kk];
		}

		msrPosArr[idx]=pos;
        msrValArr[idx][0]=msr;

        idx++;
        if (idx>=N) return; // case when max msr num is reached

        if (msr>mythreshold) neighborSamplingV2(i,j);
        if (idx>=N) return; // case when max msr num is reached
    }
  }
}


void FastOMP(float A[M][K], float y[M][1], float xhat[K][1]) {
	for (int i=0;i<M;i++){if (y[i][0]<1e-4) y[i][0]=1e-4;}
    
    float r[M];
    float s[S];
    float Q[M][S];
    float R[S][S];

    // Additional arrays for calculations
    float w[M];
    float v[S];

    // Initialize arrays
    int i;
    for (i = 0; i < K; i++) xhat[i][0] = 0;
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
                corr += r_k * A[k][j] + r_k1 * A[k + 1][j] +
                        r_k2 * A[k + 2][j] + r_k3 * A[k + 3][j];
                corr_1 += r_k * A[k][j + 1] + r_k1 * A[k + 1][j + 1] +
                          r_k2 * A[k + 2][j + 1] + r_k3 * A[k + 3][j + 1];
                corr_2 += r_k * A[k][j + 2] + r_k1 * A[k + 1][j + 2] +
                          r_k2 * A[k + 2][j + 2] + r_k3 * A[k + 3][j + 2];
                corr_3 += r_k * A[k][j + 3] + r_k1 * A[k + 1][j + 3] +
                          r_k2 * A[k + 2][j + 3] + r_k3 * A[k + 3][j + 3];
            }
            for (; k < M; k++) {
                corr += r[k] * A[k][j];
                corr_1 += r[k] * A[k + 1][j];
                corr_2 += r[k] * A[k + 2][j];
                corr_3 += r[k] * A[k + 3][j];
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
            w[i] = A[i][idx_max];
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
        xhat[xhat_ind][0] = (v[S - i - 1] - sum) / R[S - i - 1][S - i - 1];
    }
}


void binarySampling(){  
  int tempx;
  int tempy;
  
  idx = 0;

  for (int i=0; i<N; i++){
    // extract each pos of center
    tempx = ctrMsrArr[i][0];
    tempy = ctrMsrArr[i][1];
    
    // case when the center point has been examined
  if (!notIn1d(msrPosArr, 0, idx, tempx, tempy)) continue;
  
    if (lastmsrRow-tempx!=0){
      digitalWriteFast(dpins[rowConv[lastmsrRow]], LOW); //turn the previous row low
      digitalWriteFast(dpins[rowConv[tempx]], HIGH); // turn the current row high
      lastmsrRow = tempx;
    }
    
    digitalWriteFast(37, muxtable[tempy][0]);
    digitalWriteFast(36, muxtable[tempy][1]);
    digitalWriteFast(35, muxtable[tempy][2]);
    digitalWriteFast(34, muxtable[tempy][3]);
    digitalWriteFast(33, muxtable[tempy][4]);
    
    msr= analogRead(A0);
  pos = coord2DTo1D(tempx,tempy); // 0-1023

  for (int kk=0;kk<K;kk++){
    Phi[idx][kk]=Psi[pos][kk];
  }

    msrPosArr[idx]=pos;
    msrValArr[idx][0]=msr;

    idx++;
    if (idx>=N) break; // case when max msr num is reached

    // case when msr > threshold, do the neighborhood examination
    if (msr>mythreshold) {
      neighborSamplingV2(tempx,tempy);
      if (idx>=N) break; // case when max msr num is reached
    }
  }
}


void siganlRcv(){  
  FastOMP(Phi,msrValArr,xs);
  for (int i=0;i<N;i++){
    tempX=0;
    for (int j=0;j<K;j++){
      tempX+=Psi[i][j]*xs[j][0];
    }
    xvec[i][0]=tempX;
  }
}


void sendData1(){
	// print out the 2s pos coordinates and values to serial monitor
    for (int pnt = 0; pnt < N; pnt++) {
		Serial.print(xvec[pnt][0]);
		Serial.print(',');
		delayMicroseconds(5);
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
  
  // set all the output pins to low
  for (int i = 0; i < 32; i++) {
    digitalWriteFast(dpins[i], LOW);
  }
  
  // construct the array of centers we will go through
  buildCtrArr();
  
  S = round(0.25*M);  // Sparsity level, !!
}


FASTRUN void loop() {
	if (Serial.available() > 0) {
		iniDict=true;
		// transfer the dictionary from matlab to here
		Serial.readBytes((char*)Psi, N * K * sizeof(float));
	}

	if (iniDict){
		unsigned long startTime = micros();
	  
		binarySampling(); // binary sampling

		siganlRcv(); // signal recovery
		
		unsigned long elapsedTime = micros() - startTime;

		// Send results back to MATLAB
		sendData1();
		Serial.print(elapsedTime);
		Serial.println(); // cheack the time per frame.
	}
}
