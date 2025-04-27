# Firmware

Ez a kártyán található Z80 kód forrása. Ez a kód hívódik meg, amikor a BASIC -ből kiadod a CALL $D000 vagy a CALL $D003 parancsok egyikét vagy
amikor a LOAD/SAVE API -t használod. Az ARM forrása az MCU -nak nem publikus, az általam készített kártyákon az ARM chipek le vannak zárva.
Ha mindezek ellenére ki tudod nyerni belőlük az ARM kódot, akkor
 - ügyes vagy és
 - akaratom ellenére cselekszel.

This is the source of the Z80 firmware that can be found on the cart. This is the code that is executed when you execute CALL $D000 or $D003.
The ARM MCU on the cart is locked on purpose.
