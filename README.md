# MCDupeDetector1.16
The scripts contained in this repository are aimed to catch cheaters attempting known dupe methods by watching the latest.log
Running your minecraft server on a linux machine is required, the code may not work for all distros. (Tested on my Pi3B+ on Buster)

## Noteable Scripts
### [PlayerSaveFail.sh](https://github.com/Jakesta13/McDupeDetector1.16/blob/master/PlayerSaveFail/PlayerSaveFail.sh)
* Watches for playerdata saving errors (which is a side effect from the inventory overflow exploit, which also causes a disconnect) and counts to x detections, which is configrable.
* Ability to ban the player based on a counter which is configurable.
* Notifies each detection on discord, the more they do it .. the more you know.


## Upcoming
### [FireworkDupe.sh](https://github.com/Jakesta13/McDupeDetector1.16/blob/master/FireworkDupe/FireworkDupe.sh)
* Watches for firework related death messages (which there is only one, yay!) which occur right after logging out.
* Built from looking at console output from legit examples, and tested using a false console line after a legit log-out.
* Ability to notify the ban on discord, you will get their last login coordinates and their IP in the message in-case they were using an alt to run the dupe.

## Requirements
* Running the server and script on Linux (Debian/Ubuntu should be fine)
* Rcon is enabled on the server.
* [mcrcon](https://github.com/Tiiffi/mcrcon) - You may have to build this (On Raspberry Pi you do)
