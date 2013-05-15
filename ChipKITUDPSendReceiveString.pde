#include <chipKITEthernet.h>
#include <Wire.h>
#include <IOShieldOled.h>


// TODO: Change SPI display pins
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
char  ReplyBuffer[] = "ack";       // a string to send back

// A UDP instance to let us send and receive packets over UDP
UDP Udp;

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
  
  Ethernet.begin(mac,ip);
  Udp.begin(localPort);

  Serial.begin(9600); 
  Serial.println("Start");

  Wire.begin(); //Begin i2c communication

  //SETUP PORT EXPANDERS AS OUTPUT
  Wire.beginTransmission(0x20); //address of U501
  Wire.send(0x06); //  Access port direction register
  Wire.send(0x00); //  Set Port0 all output 
  Wire.send(0x00); //  Set Port1 all output
  Wire.endTransmission();

  Serial.println("Setup Done");  
}


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
    Serial.println(packetBuffer);


    if(strcmp(packetBuffer, "I1") == 0){
      setIn1();
    }

    if(strcmp(packetBuffer, "I2") == 0){
      setIn2();  
    }


    //Udp.sendPacket( ReplyBuffer, remoteIp, remotePort);   



  } 

  //#if 0   // this is throttled by the sending application  
  //  // wait 10 seconds.
  //  time = millis();
  //  while((millis() < time + 10000) )
  //  {
  //    Ethernet.PeriodicTasks();
  //  }  
  //#endif

}


void setIn1() {
  Wire.beginTransmission(0x20);  //i2c address of U501 on ST
  Wire.send(B00000000);  //access GP0       
  Wire.send(B00010001); //write input 1 output 1
  Wire.endTransmission();    // stop transmitting
  
  Serial.println("setIn1");
  digitalWrite(13, HIGH);
}

void setIn2() {
  Wire.beginTransmission(0x20);  //i2c address of U501 on ST
  Wire.send(B00000000);  //access GP0       
  Wire.send(B00010100); //write in 2 out 1          
  Wire.endTransmission();    // stop transmitting
  
  Serial.println("setIn2");
  digitalWrite(13, LOW);
}




