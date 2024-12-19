// 32x32 raster scan of TDMA sensor
// Compile for Teensy 4.1
// Digital pins are d0 through d13, and then d15 through d32
// Analog pin is a0
// Mux pins are d33 through d37 | mux0-4

const int N = 1024; //number of sensors; 32*32
int values[N]; //variable to save values of the array
int idx = 0;
unsigned long timer1;
int dpins[32] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32}; // what are the connected digital pins?
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
uint8_t rowConv[32] = {31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0}; // convert matlab img (0-31) index to arduino index (0-31)

void setup() {
  for (int i = 0; i < 32; i++) { //rows
    pinMode(dpins[i], OUTPUT);
  }

  //mux pins
  pinMode(33, OUTPUT);
  pinMode(34, OUTPUT);
  pinMode(35, OUTPUT);
  pinMode(36, OUTPUT);
  pinMode(37, OUTPUT);

  //set all the output pins to low
  for (int i = 0; i < 32; i++) {
    digitalWriteFast(dpins[i], LOW);
  }
}

FASTRUN void loop() {
  timer1 = micros();
  idx = 0;
  for (int i = 0; i < 32; i++) {
    digitalWriteFast(dpins[rowConv[i]], HIGH);
    for (int j = 0; j < 32; j++) { //loop through the output rows
      // multiplex the readout columns
      digitalWriteFast(37, muxtable[j][0]);
      digitalWriteFast(36, muxtable[j][1]);
      digitalWriteFast(35, muxtable[j][2]);
      digitalWriteFast(34, muxtable[j][3]);
      digitalWriteFast(33, muxtable[j][4]);
      //delayMicroseconds(5); //??
      values[idx] = analogRead(A0); // col-first order
      idx++;
    }
    digitalWriteFast(dpins[rowConv[i]], LOW); // turn that row back to low
  }
  timer1 = micros() - timer1;

  for (int q = 0; q < N; q++) { //print out the values to serial monitor
    Serial.print(values[q]);
    Serial.print(',');
    delayMicroseconds(5);
  }

  Serial.print(timer1);
  Serial.println();
}
