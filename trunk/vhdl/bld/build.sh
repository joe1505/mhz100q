#!/bin/sh
# $Id: build.sh,v 1.1 2009/07/28 20:14:09 jrothwei Exp jrothwei $
TCLCMD=/opt/Xilinx/10.1/ISE/bin/lin/xtclsh
$TCLCMD x04_scope_mod_complete.tcl rebuild_project
