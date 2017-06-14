#!/bin/bash
#
# (c) by H. Schulz 2013-16
# This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.
# You may use and modify it as long as you state the above copyright.

#
# Stops all stations started by startStations.sh
# 

########################################################################################################
# TODO: Enter your station's start command or the significant part thereof.
#
# Example: stationCmd="java aufgabe4.MyStation"
########################################################################################################
stationCmd="erl"

########################################################################################################
# TODO: Enter data source programme with full path, but WITHOUT parameters 
#
# Example:    dataSource="~/somewhere/Vessel3"
#         or  dataSource="java -cp . vessel3.Vessel"
########################################################################################################
dataSource="Vessel"


if [ "$1" = "--help" ]; then
	echo "Script that terminates datasources and stations."
	echo "The following commands will be issued:"
	echo 
	echo "pkill -f \"$dataSource\""
	echo "pkill -f \"$stationCmd\""
else
	if [ "$dataSource" = "" -o "$stationCmd" = "" ]; then
		echo "One of the variables has not been set."
		exit 1
	else
		pkill -f "$dataSource"
		pkill -f "$stationCmd"
	fi
fi