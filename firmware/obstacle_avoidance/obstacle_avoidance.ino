// Reactive obstacle avoidance for a tracked rover.
// Arduino Uno + L293D shield (AFMotor), fixed forward-facing HC-SR04 (NewPing).

#include <AFMotor.h>
#include <NewPing.h>

#define TRIG_PIN A0
#define ECHO_PIN A1
#define MAX_DISTANCE 350    // [cm]
#define MAX_SPEED 100       // PWM, 0-255

NewPing sonar(TRIG_PIN, ECHO_PIN, MAX_DISTANCE);

// Left and right tracks on shield ports M1 and M4.
AF_DCMotor motor1(1, MOTOR12_1KHZ);
AF_DCMotor motor4(4, MOTOR34_1KHZ);

boolean goesForward = false;
int distance = 100;          // [cm]
int speedSet = 0;

void setup() {
  delay(2000);
  // Discard the first readings while the sensor settles.
  distance = readPing();
  delay(100);
  distance = readPing();
  delay(100);
  distance = readPing();
  delay(100);
  distance = readPing();
  delay(100);
}

// Obstacle within 15 cm: back off, take two readings, pivot, and let the next
// iteration re-check the path. The sonar has no servo, so both readings look
// ahead from the backed-off position and only pick the pivot direction.
void loop() {
  int distanceR = 0;
  int distanceL = 0;
  delay(40);

  if (distance <= 15) {
    moveStop();
    delay(100);
    moveBackward();
    delay(300);
    moveStop();
    delay(200);
    distanceR = lookRight();
    delay(200);
    distanceL = lookLeft();
    delay(200);

    // Ties go right.
    if (distanceR >= distanceL) {
      turnRight();
      moveStop();
    } else {
      turnLeft();
      moveStop();
    }
  } else {
    moveForward();
  }
  distance = readPing();
}

// No servo: lookRight and lookLeft both read straight ahead, 500 ms after stopping.
int lookRight() {
  delay(500);
  int distance = readPing();
  delay(100);
  return distance;
}

int lookLeft() {
  delay(500);
  int distance = readPing();
  delay(100);
  return distance;
}

// NewPing returns 0 for no echo (nothing in range): treat it as free space,
// not as an obstacle at 0 cm.
int readPing() {
  delay(70);  // let the previous echo die out
  int cm = sonar.ping_cm();
  if (cm == 0) {
    cm = 250;
  }
  return cm;
}

void moveStop() {
  motor1.run(RELEASE);
  motor4.run(RELEASE);
}

void moveForward() {
  if (!goesForward) {
    goesForward = true;
    motor1.run(FORWARD);
    motor4.run(FORWARD);
    // Ramp up to avoid current spikes on the batteries.
    for (speedSet = 0; speedSet < MAX_SPEED; speedSet += 2) {
      motor1.setSpeed(speedSet);
      motor4.setSpeed(speedSet);
      delay(5);
    }
  }
}

void moveBackward() {
  goesForward = false;
  motor1.run(BACKWARD);
  motor4.run(BACKWARD);
  for (speedSet = 0; speedSet < MAX_SPEED; speedSet += 2) {
    motor1.setSpeed(speedSet);
    motor4.setSpeed(speedSet);
    delay(5);
  }
}

// Counter-rotating tracks for 500 ms, then both forward.
void turnRight() {
  motor1.run(FORWARD);
  motor4.run(BACKWARD);
  delay(500);
  motor1.run(FORWARD);
  motor4.run(FORWARD);
}

void turnLeft() {
  motor1.run(BACKWARD);
  motor4.run(FORWARD);
  delay(500);
  motor1.run(FORWARD);
  motor4.run(FORWARD);
}
