//************************************************************
//**                                                        **
//**                ST REMOTE TEST PROGRAM                  **
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


// A zero MAC address means that the chipKIT MAC is to be used
byte mac[] = {  
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

byte ip[] = { 
  192,168,2,250 };

unsigned short localPort = 6000;      // local port to listen on

// the next two variables are set when a packet is received
byte remoteIp[4];        // holds received packet's originating IP
unsigned short remotePort; // holds received packet's originating port

// buffers for receiving and sending data
#define UDP_TX_PACKET_MAX_SIZE 1024
char packetBuffer[UDP_TX_PACKET_MAX_SIZE]; //buffer to hold incoming packet,
char ReplyBuffer[] = "ack";       // a string to send back

// A UDP instance to let us send and receive packets over UDP
UDP Udp;


//Relay State Vars
int input  = 1;
int output = 1;
int vol = 0;

byte inputByte = 0;
byte outputByte = 0;
byte ioByte = 0; //the byte to send


//************************************************************
//**                      - SETUP -                         **
//************************************************************
void setup() {
  IOShieldOled.begin();
  IOShieldOled.clearBuffer();
  IOShieldOled.setCursor(0, 0);
  IOShieldOled.putString("R.A.D. NYC");
  IOShieldOled.setCursor(0, 2);
  IOShieldOled.putString("Dangerous");
  IOShieldOled.setCursor(0, 3);
  IOShieldOled.putString("MON ST Tester");

  pinMode(13, OUTPUT);//led connected to indicate T/B ON
  //TODO: CONFLICTS WITH SPI COMM

  Ethernet.begin(mac,ip);
  Udp.begin(localPort);

  Serial.begin(9600); 
  Serial.println("Start");

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

  unsigned int time = 0;

  // if there's data available, read a packet
  int packetSize = Udp.available(); // note that this includes the UDP header
  if(packetSize)
  {
    packetSize = packetSize - 8;      // subtract the 8 byte header
    //Serial.print("Received packet of size ");
    //Serial.println(packetSize);

    // read the packet into packetBufffer and get the senders IP addr and port number
    Udp.readPacket(packetBuffer,UDP_TX_PACKET_MAX_SIZE, remoteIp, remotePort);
    if (packetDebug == true){
      Serial.println(packetBuffer);
    }

    if(strcmp(packetBuffer, "I1") == 0){
      input = 0;
    }

    else if(strcmp(packetBuffer, "I2") == 0){
      input = 1;
    }

    else if(strcmp(packetBuffer, "I3") == 0){
      input = 2;
    }

    else if(strcmp(packetBuffer, "I4") == 0){
      input = 3;
    }

    else if(strcmp(packetBuffer, "O1") == 0){
      output = 0;
    }

    else if(strcmp(packetBuffer, "O2") == 0){
      output = 1;
    }

    else if(strcmp(packetBuffer, "O3") == 0){
      output = 2;
    }

    else {
      vol = atoi(packetBuffer);
    }

    updateState();
    Udp.sendPacket(ReplyBuffer, remoteIp, remotePort);  
  } 

}


//************************************************************
//**                 - USER FUNCTIONS -                     **
//************************************************************

void updateState() {
  //Set I/O
  inputByte = input; //corresponds directly to relay positions
  outputByte = output << 4; //left shift into correct bits
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
    Serial.print("IN: ");
    Serial.println(ioByte);
    Serial.print("VOL: ");
    Serial.println(volByte);
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



