# 
# $Id: x04_scope_mod_complete.tcl,v 1.1 2009/07/28 20:13:05 jrothwei Exp jrothwei $
# File originally created by ISE version 10.1, using the GUI sequence:
# "Project"->"Generate TCL Script"
# and select option: "Modified properties with complete script"
#
# Project automation script for x04_scope 
# 
# Created for ISE version 10.1
# 
# This file contains several Tcl procedures (procs) that you can use to automate
# your project by running from xtclsh or the Project Navigator Tcl console.
# If you load this file (using the Tcl command: source x04_scope_mod_complete.tcl,
# then you can
# run any of the procs included here.
# You may also edit any of these procs to customize them. See comments in each
# proc for more instructions.
# 
# This file contains the following procedures:
# 
# Top Level procs (meant to be called directly by the user):
#    run_process: you can use this top-level procedure to run any processes
#        that you choose to by adding and removing comments, or by
#        adding new entries.
#    rebuild_project: you can alternatively use this top-level procedure
#        to recreate your entire project, and the run selected processes.
# 
# Lower Level (helper) procs (called under in various cases by the top level procs):
#    show_help: print some basic information describing how this script works
#    add_source_files: adds the listed source files to your project.
#    set_project_props: sets the project properties that were in effect when this
#        script was generated.
#    create_libraries: creates and adds file to VHDL libraries that were defined when
#        this script was generated.
#    create_partitions: adds any partitions that were defined when this script was generated.
#    set_process_props: set the process properties as they were set for your project
#        when this script was generated.
# 

set myProject "x04_scope.ise"
set myScript "x04_scope_mod_complete.tcl"

# 
# Main (top-level) routines
# 

# 
# run_process
# This procedure is used to run processes on an existing project. You may comment or
# uncomment lines to control which processes are run. This routine is set up to run
# the Implement Design and Generate Programming File processes by default. This proc
# also sets process properties as specified in the "set_process_props" proc. Only
# those properties which have values different from their current settings in the project
# file will be modified in the project.
# 
proc run_process {} {

   global myScript
   global myProject

   ## put out a 'heartbeat' - so we know something's happening.
   puts "\n$myScript: running ($myProject)...\n"

   if { ! [ open_project ] } {
      return false
   }

   set_process_props
   #
   # Remove the comment characters (#'s) to enable the following commands 
   # process run "Synthesize"
   # process run "Translate"
   # process run "Map"
   # process run "Place & Route"
   #
   puts "Running 'Implement Design'"
   if { ! [ process run "Implement Design" ] } {
      puts "$myScript: Implementation run failed, check run output for details."
      project close
      return
   }
   puts "Running 'Generate Programming File'"
   if { ! [ process run "Generate Programming File" ] } {
      puts "$myScript: Generate Programming File run failed, check run output for details."
      project close
      return
   }

   puts "Run completed."
   project close

}

# 
# rebuild_project
# 
# This procedure renames the project file (if it exists) and recreates the project.
# It then sets project properties and adds project sources as specified by the
# set_project_props and add_source_files support procs. It recreates VHDL libraries
# and partitions as they existed at the time this script was generated.
# 
# It then calls run_process to set process properties and run selected processes.
# 
proc rebuild_project {} {

   global myScript
   global myProject

   ## put out a 'heartbeat' - so we know something's happening.
   puts "\n$myScript: rebuilding ($myProject)...\n"

   if { [ file exists $myProject ] } { 
      puts "$myScript: Removing existing project file."
      file delete $myProject
   }

   puts "$myScript: Rebuilding project $myProject"
   project new $myProject
   set_project_props
   add_source_files
   create_libraries
   create_partitions
   puts "$myScript: project rebuild completed."

   run_process

}

# 
# Support Routines
# 

# 
# show_help: print information to help users understand the options available when
#            running this script.
# 
proc show_help {} {

   global myScript

   puts ""
   puts "usage: xtclsh $myScript <options>"
   puts "       or you can run xtclsh and then enter 'source $myScript'."
   puts ""
   puts "options:"
   puts "   run_process       - set properties and run processes."
   puts "   rebuild_project   - rebuild the project from scratch and run processes."
   puts "   set_project_props - set project properties (device, speed, etc.)"
   puts "   add_source_files  - add source files"
   puts "   create_libraries  - create vhdl libraries"
   puts "   create_partitions - create partitions"
   puts "   set_process_props - set process property values"
   puts "   show_help         - print this message"
   puts ""
}

proc open_project {} {

   global myScript
   global myProject

   if { ! [ file exists $myProject ] } { 
      ## project file isn't there, rebuild it.
      puts "Project $myProject not found. Use project_rebuild to recreate it."
      return false
   }

   project open $myProject

   return true

}
# 
# set_project_props
# 
# This procedure sets the project properties as they were set in the project
# at the time this script was generated.
# 
proc set_project_props {} {

   global myScript

   if { ! [ open_project ] } {
      return false
   }

   puts "$myScript: Setting project properties..."

   project set family "Spartan3E"
   project set device "xc3s500e"
   project set package "fg320"
   project set speed "-5"
   project set top_level_module_type "HDL"
   project set synthesis_tool "XST (VHDL/Verilog)"
   project set simulator "ISE Simulator (VHDL/Verilog)"
   project set "Preferred Language" "Verilog"
   project set "Enable Message Filtering" "false"
   project set "Display Incremental Messages" "false"

}


# 
# add_source_files
# 
# This procedure add the source files that were known to the project at the
# time this script was generated.
# 
proc add_source_files {} {

   global myScript

   if { ! [ open_project ] } {
      return false
   }

   puts "$myScript: Adding sources to project..."

   xfile add "../src/bytecmd.vhd"
   xfile add "../src/dcm_wrap.vhd"
   xfile add "../lib/adc_ads7822.vhd"
   xfile add "../lib/cic3_down.vhd"
   xfile add "../lib/dac_mcp492x.vhd"
   xfile add "../lib/debounce.vhd"
   xfile add "../lib/edgetrig.vhd"
   xfile add "../lib/ex8from32.vhd"
   xfile add "../lib/fx2usb_async8b.vhd"
   xfile add "../lib/p_func.vhd"
   xfile add "../lib/seg7x4.vhd"
   xfile add "../lib/xilinx_2kx9_3e.vhd"
   xfile add "../src/scope_nexys2_xc3s500e.ucf"
   xfile add "../src/scope_top.vhd"

   # Set the Top Module as well...
   project set top "rtl" "scope_top"

   puts "$myScript: project sources reloaded."

} ; # end add_source_files

# 
# create_libraries
# 
# This procedure defines VHDL libraries and associates files with those libraries.
# It is expected to be used when recreating the project. Any libraries defined
# when this script was generated are recreated by this procedure.
# 
proc create_libraries {} {

   global myScript

   if { ! [ open_project ] } {
      return false
   }

   puts "$myScript: Creating libraries..."
   # note: if you have multiple files with the same name at different paths,
   # you may have problems with the lib_vhdl command.


   # must close the project or library definitions aren't saved, then reopen it for further use.
   project close
   open_project

} ; # end create_libraries

#
# create_partitions
#
# This procedure creates partitions on instances in your project.
# It is expected to be used when recreating the project. Any partitions
# defined when this script was generated are recreated by this procedure.
# 
proc create_partitions {} {

   global myScript

   if { ! [ open_project ] } {
      return false
   }

   puts "$myScript: Creating Partitions..."


   # must close the project or partition definitions aren't saved, then reopen it for further use.
   project close
   open_project

} ; # end create_partitions

# 
# set_process_props
# 
# This procedure sets properties as requested during script generation (either
# all of the properties, or only those modified from their defaults).
# 
proc set_process_props {} {

   global myScript

   if { ! [ open_project ] } {
      return false
   }

   puts "$myScript: setting process properties..."

   project set "Pack I/O Registers/Latches into IOBs" "For Inputs and Outputs" -process "Map"

   puts "$myScript: project property values set."

} ; # end set_process_props

proc main {} {

   if { [llength $::argv] == 0 } {
      show_help
      return true
   }

   foreach option $::argv {
      switch $option {
         "show_help"           { show_help }
         "run_process"         { run_process }
         "rebuild_project"     { rebuild_project }
         "set_project_props"   { set_project_props }
         "add_source_files"    { add_source_files }
         "create_libraries"    { create_libraries }
         "create_partitions"   { create_partitions }
         "set_process_props"   { set_process_props }
         default               { puts "unrecognized option: $option"; show_help }
      }
   }
}

if { $tcl_interactive } {
   show_help
} else {
   if {[catch {main} result]} {
      puts "$myScript failed: $result."
   }
}

