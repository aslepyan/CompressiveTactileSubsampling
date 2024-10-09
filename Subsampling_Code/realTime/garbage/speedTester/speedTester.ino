#include <math.h>

int a[2] = {1, 2};
int b[2] = {3, 4};
int out[4-1];

void setup() {}

void loop() {
  unsigned long timer1 = micros();
  test1();
  timer1 = micros() - timer1;
  Serial.print("Time: ");
  Serial.println(timer1);
}

void test1() {
  for (int i = 0; i < 49 * 512; i++) {
    int temp = a[i % 2];
    int temp1 = b[i % 2];
    out[0] = temp;
    out[1] = temp1;
    out[2] = temp1;
  }
  float s= out[2];
  bool ff=isinf(s/0);
  Serial.println(ff);
}
