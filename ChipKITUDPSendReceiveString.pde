//************************************************************
//**                                                        **
//**             ST REMOTE TEST PROGRAM                     **
//**                RAD NYC 5/15/13                         **
//**                                                        **
//************************************************************

#include <chipKITEthernet.h>
#include <Wire.h>
#include <IOShieldOled.h>


//************************************************************
//**                  - GLOBAL VARS -                       **
//************************************************************

bool debug = true;
bool packetDebug = false;

byte mac[] = {  
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };          // A zero MAC address means that the chipKIT MAC is to be used
byte ip[] = { 
  192,168,000,250 };                               //default ip
unsigned short localPort = 8888;  
// default local port to listen on
byte remoteIp[4];                                // holds received packet's originating IP
unsigned short remotePort;                       // holds received packet's originating port

#define UDP_TX_PACKET_MAX_SIZE 1024
char packetBuffer[UDP_TX_PACKET_MAX_SIZE];       //buffer to hold incoming packet,
char ReplyBuffer[] = "ack";       

UDP Udp;                                         // A UDP instance to let us send and receive packets over UDP

//Relay State Vars
int input  = 1;
int output = 1;
int vol = 0;
int encoderTestInt = 0;

byte inputByte = 0;
byte outputByte = 0;
byte ioByte = 0;                                 //the byte to send

int lButtonPin = A0;
int uButtonPin = A1;
int rButtonPin = A2;
int dButtonPin = A3;
int encoderPinA = 9;
int encoderPinB = 8;
int encoderPinALast = LOW;
int n = LOW;
bool encoderUp = false;
bool encoderDn = false;

char displayCharBuffer[12];

int menuIndex = 0;                               //keep track of menus
int editIndex = 0;                               //which parameter to edit

int debounceDelay = 250;    // the debounce time; increase if the output flickers

int q=0;


//************************************************************
//**                      - SETUP -                         **
//************************************************************
void setup() {
  IOShieldOled.begin();
  IOShieldOled.clearBuffer();
  IOShieldOled.setCursor(0, 0);
  IOShieldOled.putString("R.A.D. NYC");

  setupPins();

  Ethernet.begin(mac,ip);
  Udp.begin(localPort);
  

  Serial.begin(9600); 

  Wire.begin(); //Begin i2c communication

    //ST INIT: Sets registers as outputs
  Wire.beginTransmission(0x20); //address of U501
  Wire.send(0x06); //  Access port direction register
  Wire.send(0x00); //  Set Port0 all output 
  Wire.send(0x00); //  Set Port1 all output
  Wire.endTransmission();

  Wire.beginTransmission(0x21); //address of U502
  Wire.send(0x06); //  Access port direction register
  Wire.send(0x00); //  Set Port0 all output 
  Wire.send(0x00); //  Set Port1 all output
  Wire.endTransmission();

  Serial.println("Setup Done");  
}





//************************************************************
//**                     - MAIN LOOP -                      **
//************************************************************
void loop() {  

  readEncoder();

  if (digitalRead(uButtonPin) == LOW){
    delay(debounceDelay);
    if (digitalRead(uButtonPin) == LOW && menuIndex < 2){
      menuIndex++;
      IOShieldOled.clearBuffer();
      IOShieldOled.updateDisplay();
    }
  }

  if (digitalRead(dButtonPin) == LOW){
    delay(debounceDelay);
    if (digitalRead(dButtonPin) == LOW && menuIndex > 0){
      menuIndex--;
      IOShieldOled.clearBuffer();
      IOShieldOled.updateDisplay();      
    }
  }

  if (digitalRead(rButtonPin) == LOW){
    delay(debounceDelay);
    if (digitalRead(rButtonPin) == LOW && editIndex < 5){
      editIndex++;
      IOShieldOled.clearBuffer();
      IOShieldOled.updateDisplay();
      
    }
  }

  if (digitalRead(lButtonPin) == LOW){
    delay(debounceDelay);
    if (digitalRead(lButtonPin) == LOW && editIndex > 0){
      editIndex--;
      IOShieldOled.clearBuffer();
      IOShieldOled.updateDisplay();
    }
  }
  
  if (digitalRead(lButtonPin) == LOW && digitalRead(rButtonPin) == LOW) {
    delay(debounceDelay);
    if (digitalRead(lButtonPin) == LOW && digitalRead(rButtonPin) == LOW){
    Udp.stop();
    Ethernet.begin(mac,ip);
    Udp.begin(localPort);
    Serial.println(localPort);
    }
  }



  switch (menuIndex) {
  case 0:
    networkMenu();
    break;
  case 1:
    currentDisplayMenu();
    break;
  case 2:
    debugMenu();
    break;
  }

  unsigned int time = 0;
  int packetSize = Udp.available();                                               // note that this includes the UDP header
  if(packetSize)
  {  
    packetSize = packetSize - 8;                                                  // subtract the 8 byte header
    //Serial.print("Received packet of size ");
    //Serial.println(packetSize);

    Udp.readPacket(packetBuffer,UDP_TX_PACKET_MAX_SIZE, remoteIp, remotePort);          // read the packet into packetBufffer and get the senders IP addr and port number

    if (packetDebug == true){
      Serial.println(packetBuffer);
    }

    if(strcmp(packetBuffer, "I1") == 0){
      inputByte = B00000001;
    }

    else if(strcmp(packetBuffer, "I2") == 0){
      inputByte = B00000010;
    }

    else if(strcmp(packetBuffer, "I3") == 0){
      inputByte = B00000100;
    }

    else if(strcmp(packetBuffer, "I4") == 0){
      inputByte = B00001000;
    }

    else if(strcmp(packetBuffer, "O1") == 0){
      outputByte = B00010000;
    }

    else if(strcmp(packetBuffer, "O2") == 0){
      outputByte = B00100010;
    }

    else if(strcmp(packetBuffer, "O3") == 0){
      outputByte = B01000100;
    }

    else if(strcmp(packetBuffer, "O4") == 0){
      outputByte = B10000100;
    }

    else {
      int i = atoi(packetBuffer);
      //prevent values over 24
      if (i < 25){
        vol = i;
      }
    }

    updateState();
    Udp.sendPacket(ReplyBuffer, remoteIp, remotePort);  
  } 

}


//************************************************************
//**                 - USER FUNCTIONS -                     **
//************************************************************
void setupPins() {
  //pins
  pinMode(lButtonPin, INPUT);
  digitalWrite(lButtonPin, HIGH);
  pinMode(uButtonPin, INPUT);
  digitalWrite(uButtonPin, HIGH);    
  pinMode(rButtonPin, INPUT);
  digitalWrite(rButtonPin, HIGH);    
  pinMode(dButtonPin, INPUT);
  digitalWrite(dButtonPin, HIGH);   
  pinMode(encoderPinA, INPUT);
  digitalWrite(encoderPinA, HIGH);
  pinMode(encoderPinB, INPUT);
  digitalWrite(encoderPinB, HIGH);  
}


void readEncoder(){
  
   n = digitalRead(encoderPinA);
   if ((encoderPinALast == LOW) && (n == HIGH)) {
     if (digitalRead(encoderPinB) == LOW) {
       encoderUp = true;
     } else {
       encoderDn = true;
     }
   } 
   encoderPinALast = n;
} 




void networkMenu(){  
  
  itoa(localPort, displayCharBuffer, 10);  //base 10!
  IOShieldOled.setCursor(0, 0);
  IOShieldOled.putString("PORT: ");
  IOShieldOled.putString(displayCharBuffer);
  IOShieldOled.setCursor(0, 2);
  for (int i=0; i<4; i++) {
    sprintf(displayCharBuffer, "%d", ip[i]);              
    IOShieldOled.putString(displayCharBuffer); 
    if(i < 3){        
      IOShieldOled.putString("."); 
    }
  }
  
  
  switch(editIndex){
    case 0:
      break;
    case 1:
      IOShieldOled.moveTo(47, 10);
      IOShieldOled.drawLine(80, 10);                //draw line under port
      if (encoderUp == true) {
        localPort++;
      }
      if (encoderDn == true) {
        localPort--;
      }
      encoderUp = false;
      encoderDn = false;
      break;
      
     case 2:
      IOShieldOled.moveTo(0, 29);
      IOShieldOled.drawLine(24, 29);  
      if (encoderUp == true) {
        ip[0]++;
      }
      if (encoderDn == true) {
        ip[0]--;
      }
      encoderUp = false;
      encoderDn = false;
      break;
      
     case 3:
      IOShieldOled.moveTo(32, 29);
      IOShieldOled.drawLine(55, 29);  
        if (encoderUp == true) {
        ip[1]++;
      }
      if (encoderDn == true) {
        ip[1]--;
      }
      encoderUp = false;
      encoderDn = false;      
      break;
      
     case 4:
      IOShieldOled.moveTo(64, 29);
      IOShieldOled.drawLine(72, 29);
      if (encoderUp == true) {
        ip[2]++;
      }
      if (encoderDn == true) {
        ip[2]--;
      }
      encoderUp = false;
      encoderDn = false;      
      break;
      
     case 5:
      IOShieldOled.moveTo(79, 29);
      IOShieldOled.drawLine(104, 29);
      if (encoderUp == true) {
        ip[3]++;
      }
      if (encoderDn == true) {
        ip[3]--;
      }
      encoderUp = false;
      encoderDn = false;      
      break;
  }
}

void currentDisplayMenu(){
  IOShieldOled.clearBuffer();
  sprintf(displayCharBuffer, "Volume: %d", vol);         
  IOShieldOled.setCursor(0, 0);
  IOShieldOled.putString(displayCharBuffer); 
}


void debugMenu(){
  IOShieldOled.setCursor(0, 0);
  IOShieldOled.putString("Debug:"); 
  if (debug == true){
    IOShieldOled.putString("ON");
  } 
  else {
    IOShieldOled.putString("OFF");
  }
  IOShieldOled.setCursor(0, 2);
  IOShieldOled.putString("PacketDebug:");
  if (packetDebug == true){
    IOShieldOled.putString("ON");
  } 
  else {
    IOShieldOled.putString("OFF");
  }
}


void updateState() {
  //Set I/O
  ioByte = inputByte | outputByte; //bitwise OR to combine into one byte
  Wire.beginTransmission(0x20);  //i2c address of U501 on ST
  Wire.send(0x00);  //access GP0       
  Wire.send(ioByte);  //write input 1 output 1
  Wire.endTransmission();    // stop transmitting

  //Set Volume
  byte volByte = vol; //convert the vol int to byte
  Wire.beginTransmission(0x21);  //i2c address of U502 on ST
  Wire.send(0x00);  //access GP0       
  Wire.send(volByte);  //write input 1 output 1
  Wire.endTransmission();    // stop transmitting
  // (other relays on this expander are not implemented yet and will remain off)

  if (debug == true){
    Serial.println(ioByte, BIN);
    Serial.println(volByte, BIN);
  } 
}


















//************************************************************
//**                      - NOTES -                         **
//************************************************************

/* MCP23016 GP Pin functions
 -----(U501 addr 0x20)-----
 GP#          FUNC         HW PIN
 0.0          IN1          21
 0.1          IN2          22
 0.2          IN3          23
 0.3          IN4          24
 0.4          OP1          25
 0.5          OP2          26
 0.6          OP3          27
 0.7          SUB          28
 1.0                       2
 1.1                       3
 1.2                       4
 1.3                       5
 1.4                       7    
 1.5                       11
 1.6           DIM         12
 1.7           T/B         13
 
 -----(U502 addr 0x21)-----
 GP#          FUNC          HW PIN
 0.0          V0            21
 0.1          V1            22
 0.2          V2            23
 0.3          V3            24
 0.4          V4            25
 0.5                        26
 0.6                        27
 0.7          LPF           28
 1.0          SL0           2
 1.1          SL1           3
 1.2          OL0           4
 1.3          OL1           5
 1.4          IGC           7    
 1.5          MNO           11
 1.6                        12
 1.7                        13
 */

/*OLED HOOOKUP
 CS   GND
 RST  13
 DC   12
 CLK  11
 DATA 10
 */





















//tests/concepts

//void setIn1() {
//  Wire.beginTransmission(0x20);  //i2c address of U501 on ST
//  Wire.send(0x00);  //access GP0       
//  Wire.send(B00010001); //write input 1 output 1
//  Wire.endTransmission();    // stop transmitting
//  
//  Serial.println("setIn1");
//  digitalWrite(13, HIGH);
//}
//
//void setIn2() {
//  Wire.beginTransmission(0x20);  //i2c address of U501 on ST
//  Wire.send(0x00);  //access GP0       
//  Wire.send(B00010100); //write in 3 out 1          
//  Wire.endTransmission();
//  
//  Serial.println("setIn2");
//  digitalWrite(13, LOW);
//}

//    if(strncmp (packetBuffer, "Vxx", 1) == 0){//check for "V"
//      vol[0] = packetBuffer[1];//this works
//      vol[1] = packetBuffer[2];//this does not?
//      Serial.println(vol[1]);
//    }












