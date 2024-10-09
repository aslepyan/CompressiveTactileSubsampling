#include <math.h>

// Constants
static const int N = 1024;
static const int K = 100; // !!
static const int M = 128; // !!
static const int S = 5;  // Sparsity level

/**
   Description: FastOMP Arduino Implementation
   Author: Aidan Aug

   HOW TO USE:
   1. Set dimension values (M, K) and sparsity level (S)
   2. Adjust setup and loop functions to read from sensors
   3. Perform FastOMP and compare results (and speed)!
*/

EXTMEM float Psi[N][K];
float y[M];
float xhat[K][1];
float x[K][1];
uint16_t dummyPos[M][1];
int xhat_indArr[S];

// =================== FAST OMP =============== */
void FastOMP(float A[N][K], uint16_t pos[M][1], float y[M], float xhat[K][1]) {
  float r[M];
  int s[S];
  float Q[M][S];
  float R[S][S];

  // Additional arrays for calculations
  float w[M];
  float v[S];

  float xhat1[S];

  // Initialize arrays
  for (int i = 0; i < K; i++) xhat[i][0] = 0;
  for (int i = 0; i < M; i++) r[i] = y[i];

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
        int temp1 = pos[k][0];
        int temp2 = pos[k + 1][0];
        int temp3 = pos[k + 2][0];
        int temp4 = pos[k + 3][0];
        corr += r_k * A[temp1][j] + r_k1 * A[temp2][j] +
                r_k2 * A[temp3][j] + r_k3 * A[temp4][j];
        corr_1 += r_k * A[temp1][j + 1] + r_k1 * A[temp2][j + 1] +
                  r_k2 * A[temp3][j + 1] + r_k3 * A[temp4][j + 1];
        corr_2 += r_k * A[temp1][j + 2] + r_k1 * A[temp2][j + 2] +
                  r_k2 * A[temp3][j + 2] + r_k3 * A[temp4][j + 2];
        corr_3 += r_k * A[temp1][j + 3] + r_k1 * A[temp2][j + 3] +
                  r_k2 * A[temp3][j + 3] + r_k3 * A[temp4][j + 3];
      }
      for (; k < M; k++) {
        corr += r[k] * A[pos[k][0]][j];
        corr_1 += r[k] * A[pos[k + 1][0]][j];
        corr_2 += r[k] * A[pos[k + 2][0]][j];
        corr_3 += r[k] * A[pos[k + 3][0]][j];
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
      w[i] = A[pos[i][0]][idx_max];
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
      v[i] += Q[j][i] * y[j];
    }
  }

  // Back-substitution
  for (int i = 0; i < S; i++) {
    float sum = 0;

    // R(S-i+1,:)*xhat(s)
    for (int j = 0; j < i; j++) {
      sum += R[S - i - 1][S - j - 1] * xhat1[j];
    }

    // Assign xhat
    int xhat_ind = s[S - i - 1];
    float temp_xhat = (v[S - i - 1] - sum) / R[S - i - 1][S - i - 1];
    xhat1[i] = temp_xhat;

    xhat[xhat_ind][0] = temp_xhat;
  }
}

void setup() {
  Serial.begin(12000000);
  Serial.println("Fast OMP");
}

void loop() {
  // Listen for the first signal to get matrix dimensions
  if ((unsigned)Serial.available() >= sizeof(uint16_t) * 3) {
    // Get matrix dimensions
    uint16_t m, n, s;
    Serial.readBytes((char*)&m, sizeof(uint16_t));
    Serial.readBytes((char*)&n, sizeof(uint16_t));
    Serial.readBytes((char*)&s, sizeof(uint16_t));

    if (m == M && n == K && s == S) {
      // Note: Read the entire chunks of data being sent over at once
      // 1. Efficiency: Reduces number of read operations and processing
      // overhead
      // 2. Less error prone: Minimizes chances of data corruption or
      // misalignment

      // Get sensing matrix from MATLAB
      Serial.readBytes((char*)Psi, N * K * sizeof(float));

      // Get measurements from MATLAB
      Serial.readBytes((char*)y, M * sizeof(float));

      // Perform Fast OMP
      Serial.readBytes((char*)dummyPos, M * sizeof(uint16_t));
      unsigned long startTime = micros();
      FastOMP(Psi, dummyPos, y, xhat);
      unsigned long elapsedTime = micros() - startTime;

      // Send results back to MATLAB
      Serial.write((const char*)&elapsedTime, sizeof(unsigned long));
      Serial.write((const char*)xhat, K * sizeof(float));  // Send xhat
    }

    // Clear the input buffer
    while (Serial.available() > 0) {
      Serial.read();
    }
  }
}
