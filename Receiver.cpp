// Do not remove the include below
#include "Receiver.h"

#include <RFM69.h>
#include <SPI.h>

#define NODEID        1    //unique for each node on same network
#define NETWORKID     100  //the same on all nodes that talk to each other
#define FREQUENCY     RF69_915MHZ
#define ENCRYPTKEY    "sampleEncryptKey" //exactly the same 16 characters/bytes on all nodes!
#define SERIAL_BAUD   115200

#define LED           9 // Moteinos have LEDs on D9
#define FLASH_SS      8 // and FLASH SS on D8

RFM69 radio;

void setup() {
        Serial.begin(SERIAL_BAUD);
        delay(10);
        radio.initialize(FREQUENCY, NODEID, NETWORKID);
        radio.encrypt(ENCRYPTKEY);
}

void Blink(byte PIN, int DELAY_MS) {
        pinMode(PIN, OUTPUT);
        digitalWrite(PIN, HIGH);
        delay(DELAY_MS);
        digitalWrite(PIN, LOW);
}

void loop() {

        if (radio.receiveDone()) {
                Serial.print(radio.SENDERID, DEC);
                Serial.print(",");

                for (byte i = 0; i < radio.DATALEN; i++)
                        Serial.print((char) radio.DATA[i]);

                if (radio.ACKRequested()) {
                        radio.sendACK();
                }

                Serial.println();
                Blink(LED, 3);
        }
}

