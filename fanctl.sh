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


# Constants.
readonly FAN_MODE_MANUAL="0"
readonly FAN_MODE_AUTO="1"

# Command line arguments.
readonly ARGS="$@"

# Parsed command line arguments.
FAN_MODE=""
FAN_SPEEDS=""
CPU_FREQS=""
TEMP_LIMITS=""
QUERY="false"
DEBUG="false"

# Temperature control related device node files.
readonly FAN_FOLDER_XU3="/sys/devices/odroid_fan.14"
readonly FAN_FOLDER_XU4="/sys/devices/odroid_fan.13"
FAN_FOLDER=""
CORETEMP_FILE=""
FAN_MODE_FILE=""
FAN_SPEEDS_FILE=""
TEMP_LIMITS_FILE=""


################################################################################


printf_err () {
    printf "ERROR: %-16s %s \n" "[${FUNCNAME[1]}]:" "$@" >&2
}


printf_dbg () {
    if [[ "$DEBUG" == "true" ]]; then
        printf "DEBUG: %-16s %s \n" "[${FUNCNAME[1]}]:" "$@"
    fi
}


################################################################################


cmdline () {
    while getopts ":m:s:f:t:qd" opt; do
        case $opt in
            m)
                FAN_MODE="$OPTARG"
                ;;
            s)
                FAN_SPEEDS="$OPTARG"
                ;;
            f)
                CPU_FREQS="$OPTARG"
                ;;
            t)
                TEMP_LIMITS="$OPTARG"
                ;;
            q)
                QUERY="true"
                ;;
            d)
                DEBUG="true"
                ;;
            \?)
                printf "invalid option: -%c \n" "$OPTARG" >&2
                exit 1
                ;;
            :)
                printf "option -%c requires an argument \n" "$OPTARG" >&2
                exit 1
                ;;
        esac
    done

    readonly FAN_MODE
    readonly FAN_SPEEDS
    readonly CPU_FREQS
    readonly TEMP_LIMITS
    readonly QUERY
    readonly DEBUG
}


################################################################################


check_board () {
    if [[ -d "$FAN_FOLDER_XU4" ]]; then
        FAN_FOLDER="$FAN_FOLDER_XU4"
        printf_dbg "odroid-xu4 board"
    elif [[ -d "$FAN_FOLDER_XU3" ]]; then
        FAN_FOLDER="$FAN_FOLDER_XU3"
        printf_dbg "odroid-xu3 board"
    else
        printf_err "unsupported board"
        exit 1
    fi

    CORETEMP_FILE="/sys/devices/virtual/thermal/thermal_zone0/temp"
    FAN_MODE_FILE="$FAN_FOLDER/fan_mode"
    FAN_SPEEDS_FILE="$FAN_FOLDER/fan_speeds"
    TEMP_LIMITS_FILE="$FAN_FOLDER/temp_levels"

    if [[ ! (  -e "$FAN_MODE_FILE"
            && -e "$FAN_SPEEDS_FILE"
            && -e "$TEMP_LIMITS_FILE"
            && -e "$CORETEMP_FILE" ) ]]
    then
        printf_err "device node files not present"
        exit 1
    fi

    readonly FAN_FOLDER
    readonly CORETEMP_FILE
    readonly FAN_MODE_FILE
    readonly FAN_SPEEDS_FILE
    readonly TEMP_LIMITS_FILE
}


################################################################################


check_cmdline () {
    if [[ -n "$FAN_MODE" ]]; then

        check_mode

        # In auto mode it is possible to to set either temperature limits, fan
        # speed states, both or none (meaning just switching to auto mode and
        # using whatever values are currently set).
        if [[ "$FAN_MODE" == "$FAN_MODE_AUTO" ]]; then
            if [[ -n "$CPU_FREQS" ]]; then
                printf_err "only control via fan speed is possible in auto mode"
                exit 1
            fi

            if [[ -n "$TEMP_LIMITS" ]]; then
                check_temps
            fi

            if [[ -n "$FAN_SPEEDS" ]]; then
                check_speeds
            fi
        fi

        # In manual mode (where this script runs the control loop) the
        # temperature limits and exactly one of either fan speed states or
        # cpu frequency limits have to be set.
        if [[ "$FAN_MODE" == "$FAN_MODE_MANUAL" ]]; then
            if [[ -z "$TEMP_LIMITS" ]]; then
                printf_err "temperature limits need to be specified in manual mode"
                exit 1
            fi

            check_temps

            if [[ ( -n "$FAN_SPEEDS" && -n "$CPU_FREQS" )
                    || ( -z "$FAN_SPEEDS" && -z "$CPU_FREQS" ) ]]
            then
                printf_err "exactly one control method has to be specified in manual mode"
                exit 1
            fi

            if [[ -n "$FAN_SPEEDS" ]]; then
                check_speeds
            fi

            if [[ -n "$CPU_FREQS" ]]; then
                check_freqs
            fi
        fi

    else
        if [[ -n "$TEMP_LIMITS" || -n "$FAN_SPEEDS" || -n "$CPU_FREQS" ]]; then
            printf_err "fan control mode needs to be specified"
            exit 1
        fi
    fi
}


check_mode () {
    if [[ "$FAN_MODE" != "$FAN_MODE_AUTO"
            && "$FAN_MODE" != "$FAN_MODE_MANUAL" ]];
    then
        printf_err "invalid control mode: $FAN_MODE"
        exit 1
    fi

    printf_dbg "control mode valid"
}


check_temps () {
    if [[ ! "$TEMP_LIMITS" =~ ^[0-9]+,[0-9]+,[0-9]+$ ]]; then
        printf_err "invalid temperature limits: $TEMP_LIMITS"
        exit 1
    fi

    printf_dbg "temperature limits valid"
}


check_speeds () {
    if [[ ! "$FAN_SPEEDS" =~ ^[0-9]+,[0-9]+,[0-9]+,[0-9]+$ ]]; then
        printf_err "invalid fan speeds: $FAN_SPEEDS"
        exit 1
    fi

    local fan_speeds_array=(${FAN_SPEEDS//,/ })
    local fan_speed=""

    for i in ${!fan_speeds_array[@]}; do
        fan_speed=${fan_speeds_array[i]}
        if (( fan_speed > 255 )); then
            printf_err "invalid fan speed: $fan_speed"
            exit 1
        fi
    done

    printf_dbg "fan speed states valid"
}


check_freqs () {
    printf_dbg "${FUNCNAME[0]}"
}


################################################################################


config_mode () {
    printf_dbg "setting fan control mode: $FAN_MODE"
    printf "$FAN_MODE" > "$FAN_MODE_FILE"
}


config_temps () {
    local temp_limits="${TEMP_LIMITS//,/ }"
    printf_dbg "setting auto mode temperature limits: $temp_limits"
    printf "$temp_limits" > "$TEMP_LIMITS_FILE"
}


config_speeds () {
    local fan_speeds="${FAN_SPEEDS//,/ }"
    printf_dbg "setting auto mode fan speed states: $fan_speeds"
    printf "$fan_speeds" > "$FAN_SPEEDS_FILE"
}


control_fan () {
    printf_dbg "${FUNCNAME[0]}"
}


control_freq () {
    printf_dbg "${FUNCNAME[0]}"
}


query_config () {
    local coretemp="$(cat $CORETEMP_FILE | sed -r "s:[0-9]{3}$::")"
    local fan_mode="$(cat $FAN_MODE_FILE | sed "s:fan_mode ::")"
    local fan_speeds="$(cat $FAN_SPEEDS_FILE)"
    local temp_limits="$(cat $TEMP_LIMITS_FILE)"

    printf "Current temperature [C]       %d \n" "$coretemp"
    printf "Fan control mode:             %s \n" "$fan_mode"
    printf "Auto speed settings [%%]:      %s \n" "$fan_speeds"
    printf "Auto temperature limits [C]:  %s \n" "$temp_limits"
}


################################################################################


main () {
    check_board
    cmdline $ARGS
    check_cmdline

    if [[ "$FAN_MODE" == "$FAN_MODE_AUTO" ]]; then
        config_mode

        if [[ -n "$TEMP_LIMITS" ]]; then
            config_temps
        fi

        if [[ -n "$FAN_SPEEDS" ]]; then
            config_speeds
        fi
    fi

    if [[ "$FAN_MODE" == "$FAN_MODE_MANUAL" ]]; then
        config_mode

        if [[ -n "$FAN_SPEEDS" ]]; then
            control_fan
        fi

        if [[ -n "$CPU_FREQS" ]]; then
            control_freq
        fi
    fi

    if [[ "$QUERY" == "true" ]]; then
        query_config
    fi
}


main
