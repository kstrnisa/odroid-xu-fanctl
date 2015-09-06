#!/bin/bash


#
# Helper script to configure fan related settings on odroid xu3/xu4 board.
#
# Usage: fanctl.sh [-v] [-q] [-m mode] [-f fan speed] [-s fan states] [-l fan limits]
#
#        -v Verbose output.
#        -q Query current fan related settings.
#        -m Set fan control mode (0 - manual, 1 - automatic).
#        -f Set fan speed in % of maximum (0 - 100). Only relevant in manual mode.
#        -s Set fan speed states in % of maximum (0 - 100). Format is "S1,S2,S3,S4".
#           Only relevant in auto mode.
#        -l Set fan temperature limits in degrees C. Fromat is "T1,T2,T3".
#           Only relevant in auto mode.
#
#
# The fan on the board has two operating modes, manual and automatic.
#
# In manual mode the fan spins at a constant speed. When switching from
# auto to manual mode the fan speed defaults to 100% regardless of previous
# settings.
#
# In auto mode the fan is in one of the four states (S1, S2, S3, S4) 
# depending on the current temperature and temperature limits (T1, T2, T3).
# The relationship between fan speed (S) and temperature (T) in auto mode is:
# 
# T < T1        S => S1  
# T1 < T < T2   S => S2
# T2 < T < T3   S => S3
# T3 < T        S => S4
#
# Although the fan speed can be set directly to a fixed value in auto mode 
# it will immediately be overridden by auto control.
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
FAN_AUTO_SPEEDS_FILE=$FAN_FOLDER/fan_speeds
FAN_AUTO_TEMPS_FILE=$FAN_FOLDER/temp_levels


if [[ ! ( -e $FAN_MODE_FILE && \
        -e $FAN_PWM_FILE && \
        -e $FAN_AUTO_SPEEDS_FILE && \
        -e $FAN_AUTO_TEMPS_FILE && \
        -e $CORETEMP_FILE ) ]]
then
    printf "unsupported board \n"
    exit 1
fi


while getopts ":m:f:s:l:vq" opt
do
    case $opt in
        m)
            FAN_MODE=$OPTARG
            ;;
        f)
            FAN_SPEED=$OPTARG
            ;;
        s)
            FAN_AUTO_SPEEDS=$OPTARG
            ;;
        l)
            FAN_AUTO_TEMPS=$OPTARG
            ;;
        v)
            VERBOSE=1
            ;;
        q)
            QUERY=1
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


if [[ $FAN_MODE ]]
then
    if [[ $FAN_MODE -eq 0 ]]
    then
        FAN_MODE_STRING=manual
    elif [[ $FAN_MODE -eq 1 ]]
    then
        FAN_MODE_STRING=auto
    else
        printf "invalid fan mode: %d \n" $FAN_MODE >&2
        exit 1
    fi
    
    if [[ $VERBOSE ]]
    then
        printf "setting FAN_MODE = %s \n" $FAN_MODE_STRING
    fi
    
    echo $FAN_MODE > $FAN_MODE_FILE
fi


if [[ $FAN_SPEED ]]
then
    if [[ $FAN_SPEED -lt 0 || $FAN_SPEED -gt 255 ]]
    then
        printf "invalid fan speed: %d \n" $FAN_SPEED >&2
        exit 1
    fi
    
    FAN_PWM=$(( $FAN_SPEED * 255 / 100 ))
    
    if [[ $VERBOSE ]]
    then
        printf "setting FAN_SPEED (FAN_PWM) = %d (%d) \n" $FAN_SPEED $FAN_PWM
    fi
    
    echo $FAN_PWM > $FAN_PWM_FILE
fi


if [[ $FAN_AUTO_SPEEDS ]]
then
    FAN_AUTO_SPEEDS=${FAN_AUTO_SPEEDS//,/ }
    FAN_AUTO_SPEEDS_ARRAY=($FAN_AUTO_SPEEDS)
    
    if [[ ${#FAN_AUTO_SPEEDS_ARRAY[@]} -ne 4 ]]
    then
        printf "invalid fan speeds argument: %s \n" "$FAN_AUTO_SPEEDS" >&2
    fi
    
    for i in ${!FAN_AUTO_SPEEDS_ARRAY[@]}
    do
        FAN_SPEED=${FAN_AUTO_SPEEDS_ARRAY[i]}
        if [[ $FAN_SPEED -lt 0 || $FAN_SPEED -gt 255 ]]
        then
            printf "invalid fan speed: %s \n" $FAN_SPEED >&2
            exit 1
        fi
    done
    
    if [[ $VERBOSE ]]
    then
        printf "setting FAN_AUTO_SPEEDS = %s \n" "$FAN_AUTO_SPEEDS"
    fi
    
    echo $FAN_AUTO_SPEEDS > $FAN_AUTO_SPEEDS_FILE
fi


if [[ $FAN_AUTO_TEMPS ]]
then
    FAN_AUTO_TEMPS=${FAN_AUTO_TEMPS//,/ }
    FAN_AUTO_TEMPS_ARRAY=($FAN_AUTO_TEMPS)
    
    if [[ ${#FAN_AUTO_TEMPS_ARRAY[@]} -ne 3 ]]
    then
        printf "invalid temperature limits argument: %s " "$FAN_AUTO_TEMPS" >&2
    fi
    
    if [[ $VERBOSE ]]
    then
        printf "setting FAN_AUTO_TEMPS = %s \n" "$FAN_AUTO_TEMPS"
    fi
    
    echo $FAN_AUTO_TEMPS > $FAN_AUTO_TEMPS_FILE
fi


if [[ $QUERY ]]
then
    CORETEMP=$(cat $CORETEMP_FILE | sed -r 's:[0-9]{3}$::')
    FAN_MODE=$(cat $FAN_MODE_FILE | sed 's:fan_mode ::')
    FAN_PWM=$(cat $FAN_PWM_FILE)
    FAN_SPEED=$(( $FAN_PWM * 100 / 255 ))
    FAN_AUTO_SPEEDS=$(cat $FAN_AUTO_SPEEDS_FILE)
    FAN_AUTO_TEMPS=$(cat $FAN_AUTO_TEMPS_FILE)

    if [[ $VERBOSE ]]
    then
        printf "\n"
    fi
    
    printf "Fan control mode:             %s \n" $FAN_MODE
    printf "Current temperature [C]       %d \n" $CORETEMP
    printf "Current fan speed [%%]:        %d \n" $FAN_SPEED
    printf "Auto speed settings [%%]:      %s \n" "$FAN_AUTO_SPEEDS"
    printf "Auto temperature limits [C]:  %s \n" "$FAN_AUTO_TEMPS"
fi




