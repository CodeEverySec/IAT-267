// val for temp sensor 
float voltage_for_temp;
float val_temp;
int val_light;

// val for force sensor 
int val_force;
int force_sensor_state = 0;

// val for distance sensor
int val_distance;

// intout pin
int inputPin0 = 0; // Analog pin 0 - for temp sensor
int inputPin1 = 1; // Analog pin 1 - for light sensor
int inputPin2 = 2; // Analog pin 2 - for force sensor
int inputPin3 = 6; // Digital pin 3 - for distance sensor

// output pin
int outputPin1 = 3; // Digital pin 11 - for heating pad
int outputPin2 = 9; // Digital pin 9 - for LED red
int outputPin3 = 10; // Digital pin 10 - for buzzer


void setup() {
  Serial.begin(9600);
  // input
  pinMode(inputPin0, INPUT);
  pinMode(inputPin1, INPUT);
  pinMode(inputPin2, INPUT);
  pinMode(inputPin3, INPUT);
  // output
  pinMode(outputPin1, OUTPUT);
  pinMode(outputPin2, OUTPUT);
  pinMode(outputPin3, OUTPUT);
}


void loop() {
  // calculate the temp value based on the inputPin0 voltage value
  voltage_for_temp = getVoltage(inputPin0);
  val_temp = (voltage_for_temp - 0.5) * 100.0;

  // read values for light and force  
  val_light = analogRead(inputPin1) / 4;
  val_force = analogRead(inputPin2) / 4;
  
  // distance sensor value is either '1' or '0'
  // '0' means be activated
  // '1' means not be activated
  val_distance = digitalRead(inputPin3);

  // if distance sensor is being touched and the room is not too light
  // start the heating pad and light up the LED
  // also beep once
  // else close the buzzer
  if (val_distance == 0 && val_light < 60) {
    force_sensor_state = 0;
    digitalWrite(outputPin1, HIGH);
    digitalWrite(outputPin2, HIGH);
    tone(outputPin3, 1000);
  }
  else {
    noTone(outputPin3);
  }

  // if the room is too light
  // close the LED
  if (val_light > 60) {
    digitalWrite(outputPin2, LOW);
  }

  // if the user press the force sensor
  // turns off the heating pad and LED
  if (val_force > 200) {
    force_sensor_state = 1;
    digitalWrite(outputPin1, LOW);
    digitalWrite(outputPin2, LOW);
  }

  // send the data to processing
  //'a' packet starts
  Serial.print("a");
  Serial.print(val_temp);
  Serial.print("a");
  Serial.println();
  //'a' packet ends

  //'b' packet starts
  Serial.print("b");
  Serial.print(val_light);
  Serial.print("b");
  Serial.println();
  //'b' packet ends

  //'c' packet starts
  Serial.print("c");
  Serial.print(val_distance);
  Serial.print("c");
  Serial.println();
  //'c' packet ends

  //'d' packet starts
  Serial.print("d");
  Serial.print(force_sensor_state);
  Serial.print("d");
  Serial.println();
  //'d' packet ends

  Serial.print("&"); //denotes end of readings from both sensors

  //print carriage return and newline
  Serial.println();
}

// calculate the voltage for temp sensor 
float getVoltage(int pin)
{
  return (analogRead(pin) * 0.004882814);
}
