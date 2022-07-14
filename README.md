# mimon
A Wifi monitoring tool to discover devices joining your network. 

# Requirements

To run this script you will need a network card able to run in monitor mode to sniff the traffic. You will also need [MacChanger](https://github.com/alobbs/macchanger) as well as the [Aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) suite but the good news is that the script checks if you have them installed and install them automatically if not.


# Usage

Mimon is a very simple script. To use it you just need to follow this steps:
```
git clone https://github.com/BdeVallejo/mimon
cd mimon
sudo ./mimon.sh -n <yournetworcard> 
```
Mimon will start by scanning your Wifi logging all the devices currently connected. Once this process is done you can start a second scanning proccess looking for devices joining your network and alerting you when that happens.





