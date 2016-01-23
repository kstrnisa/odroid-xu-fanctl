# odroid-xu-fanctl


Utility script to configure or control the temperature on Odroid xu3/xu4 board.


## fanctl


[fanctl.sh](https://github.com/kstrnisa/odroid-xu-fanctl/blob/master/fanctl.sh) is a convenience script that sets or queries fan related settings on the board:
 * fan control operating mode
 * fan states/speeds in auto mode
 * temperature limits in auto mode

It can also run the control loop for temperature control when in manual mode.

Temperature control via fan control (in both manual and automatic mode) works by setting the fan speed to one of four states (S1, S2, S3, S4) depending on the current temperature and temperature limits (T1, T2, T3). The relationship between fan speed (S) and temperature (T) in auto mode is:

Temperature|Fan speed
:-:|:-:
T < T1|S => S1  
T1 < T < T2|S => S2
T2 < T < T3|S => S3
T3 < T|S => S4

The temperature control has two operating modes, manual and automatic.

In automatic mode the fan is controlled by the hardware and the user (with or without this script) only sets the temperature limits and fan speed states. If this mode is specified the script will apply the settings and exit immediately. Settings made this way are not persistent across reboots.

In manual mode the hardware will simply spin the fan with a constant speed. However the control loop is run by this script. The behavior is exactly the same as the behavior of hardware temperature control in automatic mode. After the script terminates it will always set the control mode to automatic to minimize the possibility of overheating. If this mode is specified the script will run the control loop indefinitely.

The reason I wrote this is that by default my Odroid xu4 board has fairly conservative temperature limits for automatic fan control (57,63,68) and the fan starts/stops spinning every couple of seconds (irritating). My current temperature limits (75,83,90) are such that the fan actually spins only when there is significant load. I've been running this configuration for months now without any problems but obviously there are no guarantees.


## fanmon


[fanmon.sh](https://github.com/kstrnisa/odroid-xu-fanctl/blob/master/fanmon.sh) periodically displays the current fan speed, temperature and cpu frequency.


## install

These are shell scripts, so just drop it somewhere and make sure it's added to your $PATH. Or you can use the following one-liners:

```sh
sudo sh -c "curl https://raw.githubusercontent.com/kstrnisa/odroid-xu-fanctl/master/fanctl.sh -o /usr/bin/fanctl.sh && chmod +x /usr/bin/fanctl.sh"
```

```sh
sudo sh -c "curl https://raw.githubusercontent.com/kstrnisa/odroid-xu-fanctl/master/fanmon.sh -o /usr/bin/fanmon.sh && chmod +x /usr/bin/fanmon.sh"
```

## usage


### fanctl

```
Usage: fanctl.sh [-d] [-q] [-m mode] [-s fan states] [-t temperature limits]

        -d Debug output.
        -q Query automatic mode temperature control and fan settings.
        -m Set fan control mode (0 - manual, 1 - automatic).
        -s Set fan speed states in % of maximum (0 - 100). Format is "S1,S2,S3,S4".
        -t Set fan temperature limits in degrees C. Format is "T1,T2,T3".
```

Example:

```
fanctl.sh -m 1 -t 75,83,90 -s 0,51,71,91
```

This will set the fan control to automatic mode with temperature limits (75,83,90) for switching between fan (1,51,71,91) states/speeds. This means that while the temperature is below 75C the fan will not spin, when it is between 75C and 83C it will spin at 51% of maximum speed and so on.


### fanmon
```
fanmon.sh [-c] [-p update period]

        -c Clear previos info on each output.
        -p Update period in seconds.
```
