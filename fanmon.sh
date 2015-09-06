#!/bin/bash


#
# Helper script to monitor fan/temperature related info on odroid xu3/xu4 board.
#
# Usage: fanmon.sh [-c] [-p update period]
#
#        -c Clear previos info on each output.
#        -p Update period in seconds.
#


if [[ -d /sys/devices/odroid_fan.13 ]]
then
    # odroid-xu4
    FAN_FOLDER=/sys/devices/odroid_fan.13
elif [[ -d /sys/devices/odroid_fan.14 ]]
then
    # odroid-xu3
    FAN_FOLDER=/sys/devices/odroid_fan.14
else
    printf "unsupported board \n"
    exit 1
fi


CORETEMP_FILE=/sys/devices/virtual/thermal/thermal_zone0/temp
FAN_MODE_FILE=$FAN_FOLDER/fan_mode
FAN_PWM_FILE=$FAN_FOLDER/pwm_duty


if [[ ! ( -e $FAN_MODE_FILE && \
        -e $FAN_PWM_FILE && \
        -e $CORETEMP_FILE ) ]]
then
    printf "unsupported board \n"
    exit 1
fi


PERIOD=1


while getopts ":p:c" opt
do
    case $opt in
        p)
            PERIOD=$OPTARG
            ;;
        c)
            CLEAR=1
            ;;
        \?)
            printf "invalid option: -%c \n" $OPTARG >&2
            exit 1
            ;;
        :)
            printf "option -%c requires an argument \n" $OPTARG >&2
            exit 1
            ;;
    esac
done
    

printf " A15       A7      TEMP   FAN \n"
printf "******************************\n"


while [ true ]
do
    CORETEMP=$(cat $CORETEMP_FILE | sed -r 's:[0-9]{3}$::')
    FAN_PWM=$(cat $FAN_PWM_FILE)
    FAN_SPEED=$(( $FAN_PWM * 100 / 255 ))
    CPU_FREQ_A7=$(cpupower -c 0 frequency-info -f | tail -n 1 | sed -r 's:[0-9]{3}$::')
    CPU_FREQ_A15=$(cpupower -c 4 frequency-info -f | tail -n 1 | sed -r 's:[0-9]{3}$::')
    
    printf "%4d MHz " $CPU_FREQ_A15
    printf "%4d MHz " $CPU_FREQ_A7
    printf "%3d C " $CORETEMP
    printf "%3d %% " $FAN_SPEED
    
    if [[ $CLEAR ]]
    then
        printf "\r"
    else
        printf "\n"
    fi
    
    sleep $PERIOD
done
