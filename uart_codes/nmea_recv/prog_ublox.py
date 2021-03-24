import serial

"""
Example how to program the ublox to deliver the gpszda output
"""
ser = Serial.serial('dev/ttyUSB0')
msg = '\x24\x50\x55\x42\x58\x2c\x34\x30\x2c\x5a\x44\x41\x2c\x31\x2c\x31\x2c\x30\x2c\x31\x2c\x30\x2c\x30\x2a\x34\x35\x0d\x0a'
#$PUBX,40,ZDA,1,1,0,1,0,0*45\r\n 
ser.write(msg)
ser.close()
