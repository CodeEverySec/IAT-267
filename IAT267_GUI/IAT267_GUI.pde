import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import processing.serial.*;

import controlP5.*;

// I used the controlP5 library to build the gui
// learn how to implement the library from https://github.com/sojamo/controlp5

// log in page widgets
Textfield accountTextfiled;
Textfield passwordTextfiled;
Button loginButton;
Button logoutButton;

// username and password
final String rightAccount = "123";
final String rightPassword = "123";

String account;
String password;
boolean loginState = false;


// Serial port 
Serial port;
byte[] inBuffer = new byte[255];

ControlP5 cp5;

// Temp value chart
Knob myKnob;
float temp_value;

// Light vlaue chart 
Chart myChart;
Textlabel chartLabel;
float light_value;
float force_value;

// swtich - on/off for the power
RadioButton powerButton;
int powerStatue = 1;

// music play button
Button musicButton;
Minim minim;
AudioPlayer song;
boolean isPlaying = false;

// background image 
PImage backgroundImg;

void setup() {
  cp5 = new ControlP5(this);
  size(700, 400);
  smooth();
  noStroke();

  // set up the account Textfield
  accountTextfiled = cp5.addTextfield("account")
    .setPosition(260, 120)
    .setSize(200, 40)
    .setFocus(true)
    .setColorActive(color(255))
    .setColorForeground(color(255))
    .setColorBackground(color(0));

  // set up the password Textfield
  passwordTextfiled = cp5.addTextfield("password")
    .setPosition(260, 200)
    .setSize(200, 40)
    .setAutoClear(false)
    .setColorActive(color(255))
    .setColorForeground(color(255))
    .setColorBackground(color(0));

  // set up the login button
  loginButton = cp5.addButton("login Button")
    .setPosition(320, 280)
    .setColorActive(color(255)) 
    .setColorLabel(color(255))
    .setColorBackground(color(0))
    .setColorForeground(color(255));

  ////////////////////////////
  ////////////////////////////
  // Serial port 
  port = new Serial(this, Serial.list()[1], 9600);
  ////////////////////////////
  ////////////////////////////

  backgroundImg = loadImage("gui_background.jpg");

  imageMode(CENTER);
  image(backgroundImg, 350, 200, width, height);
  filter(BLUR, 6);

  // pie for temperature
  myKnob = cp5.addKnob("temp")
    .setRange(0, 50) 
    .setValue(0)
    .setPosition(420, 70)
    .setRadius(100)
    .lock()
    .setColorBackground(color(105, 105, 105))
    .setColorForeground(color(255))
    .setColorCaptionLabel(color(255))
    .setLabelVisible(true)
    .setFont(createFont("arial", 20))
    .setLabel("Temperature")
    .hide();

  // chart for light level
  myChart = cp5.addChart("lightLevel")
    .setPosition(70, 70)
    .setSize(200, 200)
    .setRange(0, 200)
    .setColorBackground(color(105, 105, 105))
    .setColorForeground(color(255))
    .setView(Chart.BAR) 
    .setStrokeWeight(1.5)
    .setLabelVisible(false)
    .hide();

  myChart.addDataSet("incomingLightLevel");
  myChart.setData("incomingLightLevel", color(169, 205, 195));

  // add light level chart label
  chartLabel = cp5.addTextlabel("chartLabel")
    .setFont(createFont("arial", 20))
    .setText("Light level")
    .setColorValue(255)
    .hide();

  // Radio button for powerStatue
  powerButton = cp5.addRadioButton("power")
    .setPosition(290, 300)
    .setSize(40, 20)
    .setColorBackground(color(0))
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setItemsPerRow(5)
    .setSpacingColumn(50) 
    .addItem("on", 1)
    .addItem("off", 2)
    .hide();

  // set the powerButton to off
  //powerButton.activate("off");

  // set two labels for the power button in a unique style  
  for (Toggle t : powerButton.getItems()) {
    t.getCaptionLabel().setColor(color(255));
    t.getCaptionLabel().getStyle().backgroundWidth = 45;
    t.getCaptionLabel().getStyle().backgroundHeight = 13;
  }

  // set music button
  musicButton = cp5.addButton("music Button")
    .setColorActive(color(255)) 
    .setColorLabel(color(255))
    .setColorBackground(color(0))
    .setColorForeground(color(255))
    .setPosition(70, 30)
    .hide();

  // Use Minim library
  minim = new Minim(this);
  song = minim.loadFile("song.mp3");

  // logout button
  logoutButton = cp5.addButton("logout Button")
    .setColorActive(color(255)) 
    .setColorLabel(color(255))
    .setColorBackground(color(0))
    .setColorForeground(color(255))
    .setPosition(290, 340)
    .setSize(130, 25)
    .hide();
}

void draw() {
  // if user is not log in
  // show the login page widgets 
  // hide the control panel widgets
  if (!loginState) {
    background(255);
    image(backgroundImg, 350, 200, width, height);
    accountTextfiled.show();
    passwordTextfiled.show();
    loginButton.show();

    if (loginButton.isMouseOver()) {
      loginButton.setColorLabel(color(0));
    } else {
      loginButton.setColorLabel(color(255));
    }

    myKnob.hide();
    myChart.hide();
    chartLabel.hide();
    powerButton.hide();
    musicButton.hide();
    logoutButton.hide();

    if (port.available() > 0) {
      println(" ");
      port.readBytesUntil('&', inBuffer);

      if (inBuffer != null) {
        // convert bytes to string
        String myString = new String(inBuffer);
        // get the sensor data by using splitTokens
        String[] sensorDataList = splitTokens(myString, "&");

        // get packet 'a' data - temp value
        String[] temp_sensor = splitTokens(sensorDataList[0], "a");
        if (temp_sensor.length != 3) {
          return;
        }
        temp_value = float(temp_sensor[1]);

        // get packet 'b' data - light value
        String[] light_sensor = splitTokens(sensorDataList[0], "b");
        if (light_sensor.length != 3) {
          return;
        }
        light_value = float(light_sensor[1]);

        // get packet 'c' data - distance value
        String[] distance_sensor = splitTokens(sensorDataList[0], "c");
        if (distance_sensor.length != 3) {
          return;
        }
        powerStatue = int(distance_sensor[1]);

        // get packet 'd' data - force value 
        String[] force_sensor = splitTokens(sensorDataList[0], "d");
        if (force_sensor.length != 3) {
          return;
        }
        force_value = int(force_sensor[1]);
      }
    }

    // use distance sensor to turn the power on
    // 0 means distance sensor be activated
    if (powerStatue == 0) {
      powerButton.activate("on");
    }
    // use force sensor to trun the power off
    // 1 means the force sensor be activated
    if (force_value == 1) {
      powerButton.activate("off");
    }
  }

  // if user is log in
  // show the control panel widgets 
  // hide the login widgets 
  if (loginState) {
    background(255);
    image(backgroundImg, 350, 200, width, height);
    accountTextfiled.hide();
    passwordTextfiled.hide();
    loginButton.hide();

    myKnob.show();
    myChart.show();
    chartLabel.show();
    powerButton.show();
    musicButton.show();
    logoutButton.show();

    if (logoutButton.isMouseOver()) {
      logoutButton.setColorLabel(color(0));
    } else {
      logoutButton.setColorLabel(color(255));
    }

    if (musicButton.isMouseOver()) {
      musicButton.setColorLabel(color(0));
    } else {
      musicButton.setColorLabel(color(255));
    }

    // if the port receive the data from Arudino through the Serial port 
    if (port.available() > 0) {
      println(" ");
      port.readBytesUntil('&', inBuffer);

      if (inBuffer != null) {
        // convert bytes to string
        String myString = new String(inBuffer);
        // get the sensor data by using splitTokens
        String[] sensorDataList = splitTokens(myString, "&");

        // get packet 'a' data - temp value
        String[] temp_sensor = splitTokens(sensorDataList[0], "a");
        if (temp_sensor.length != 3) {
          return;
        }
        temp_value = float(temp_sensor[1]);

        // get packet 'b' data - light value
        String[] light_sensor = splitTokens(sensorDataList[0], "b");
        if (light_sensor.length != 3) {
          return;
        }
        light_value = float(light_sensor[1]);

        // get packet 'c' data - distance value
        String[] distance_sensor = splitTokens(sensorDataList[0], "c");
        if (distance_sensor.length != 3) {
          return;
        }
        powerStatue = int(distance_sensor[1]);

        // get packet 'd' data - force value 
        String[] force_sensor = splitTokens(sensorDataList[0], "d");
        if (force_sensor.length != 3) {
          return;
        }
        force_value = int(force_sensor[1]);
      }
    }

    // set the temp pie value
    myKnob.setValue(temp_value);

    // set the lightness value to the rect chart 
    myChart.push("incomingLightLevel", light_value);
    myChart.setColors("incomingLightLevel", color(255));

    // set the TextLabel for lighness
    Textlabel textLabel = cp5.get(Textlabel.class, "chartLabel");
    textLabel.setText("Light level")
      .setPosition(120, 280);

    // use distance sensor to turn the power on
    // 0 means distance sensor be activated
    if (powerStatue == 0) {
      powerButton.activate("on");
    }
    // use force sensor to trun the power off
    // 1 means the force sensor be activated
    if (force_value == 1) {
      powerButton.activate("off");
    }
  }
}

// callback function from ControlP5 library
// it triggers whenever there is a CallbackEvent is happening
void controlEvent(CallbackEvent event) {
  // if the there is click event for the ControlP5 widgets 
  if (event.getAction() == ControlP5.ACTION_CLICK) {
    // switch the Controller name based on their adress in the memory
    switch(event.getController().getAddress()) {

      // If the login button is pressed
      // then check the user input
      // if the user input is matched with the right user info
      // then login statue equals to true
    case "/login Button":
      String a = cp5.get(Textfield.class, "account").getText().replaceAll("\\s", "");
      String p = cp5.get(Textfield.class, "password").getText().replaceAll("\\s", "");
      if (a.equals(rightAccount) && p.equals(rightPassword)) {
        accountTextfiled.clear();
        passwordTextfiled.clear();
        loginState = true;
      }
      break;

      // If the log out button is pressed
      // then set the login statue to false 
    case "/logout Button":
      loginState = false;
      break;

      // if the music button is pressed
      // it will play the music
      // if the music button is pressed again
      // stop the music
      // the button will loop the conditions I describe above 
    case "/music Button":
      if (!isPlaying) {
        song.rewind();
        song.play();
        isPlaying = true;
      } else {
        song.pause();
        isPlaying = false;
      }
      break;
    }
  }
}
