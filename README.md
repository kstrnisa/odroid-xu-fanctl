# odroid-xu-fanctl

Fan control helper scripts for Odroid XU3/XU4 board.

## fanctl

[fanctl.sh](https://github.com/kstrnisa/odroid-xu-fanctl/blob/master/fanctl.sh) is a convenience script that sets or queries fan related settings on the board:
 * fan control operating mode
 * fan speed
 * fan states/speeds in auto mode
 * temperature limits in auto mode

The fan control on the board has two operating modes, manual and automatic.

In manual mode the fan spins at constant speed. When switching from auto to manual mode the fan speed defaults to 100% regardless of previous settings.

In auto mode the fan is in one of the four states (S1, S2, S3, S4) depending on the current temperature and temperature limits (T1, T2, T3). The relationship between fan speed (S) and temperature (T) in auto mode is:

Temperature|Fan speed
:-:|:-:
T < T1|S => S1  
T1 < T < T2|S => S2
T2 < T < T3|S => S3
T3 < T|S => S4

Although the fan speed can be set directly to a fixed value in auto mode it will immediately be overridden by auto control.

Settings made this way are not persistent across reboots.

The reason I wrote this is that by default my Odroid XU4 board has fairly conservative temperature limits for automatic fan control (57,63,68) and the fan starts/stops spinning every couple of seconds (irritating). My current temperature limits (75,83,90) are such that the fan actually spins only when there is significant load. I've been running this configuration for a month or so without problems but obviously there are no guarantees.

## fanmon

[fanmon.sh](https://github.com/kstrnisa/odroid-xu-fanctl/blob/master/fanmon.sh) periodically displays the current fan speed, temperature and cpu frequency.

## install

These are shell scripts, so just drop it somewhere and make sure it's added to your $PATH. Or you can use the following one-liners:

```sh
sudo sh -c "curl https://raw.githubusercontent.com/kstrnisa/odroid-xu-fanctl/master/fanctl.sh -o /usr/local/bin/fanctl.sh && chmod +x /usr/local/bin/fanctl.sh"
```

```sh
sudo sh -c "curl https://raw.githubusercontent.com/kstrnisa/odroid-xu-fanctl/master/fanmon.sh -o /usr/local/bin/fanmon.sh && chmod +x /usr/local/bin/fanmon.sh"
```

## usage

```
fanctl.sh [-v] [-q] [-m mode] [-f fan speed] [-s fan states] [-l fan limits]
        
        -v Verbose output.
        -q Query current fan related settings.
        -m Set fan control mode (0 - manual, 1 - automatic).
        -f Set fan speed in % of maximum (0 - 100). Only relevant in manual mode.
        -s Set fan speed states in % of maximum (0 - 100). Format is "S1,S2,S3,S4". Only relevant in auto mode.
        -l Set fan temperature limits in degrees C. Fromat is "T1,T2,T3". Only relevant in auto mode.
```

```
fanmon.sh [-c] [-p update period]

        -c Clear previos info on each output.
        -p Update period in seconds.
```
