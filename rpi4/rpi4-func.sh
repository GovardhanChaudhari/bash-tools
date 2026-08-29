#!/bin/zsh

rpimt(){ sudo vcgencmd measure_temp };

wrpimt(){
	while true; do
	 rpimt
	 sleep 1
  	done	  
};
