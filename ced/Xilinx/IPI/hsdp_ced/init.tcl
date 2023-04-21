
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
variable logStuff 1

source -notrace "$currentDir/hsdp_help.tcl"
source -notrace "$currentDir/device.tcl"

#
#  required for CED, return all versal parts
#
proc getSupportedParts {} {
  set mylist [get_parts -quiet -filter {C_FAMILY =~ versal}]
  set newlist [list]
  foreach item $mylist {
    set newitem versal{$item}
    lappend newlist $newitem
  }
  return $newlist
   
   #return [list versal]
   
   #return [get_parts -regexp {xcvc1902.*}]
}

#
#  required for CED, don't allow any board because they pre-empt part selection 
#
proc getSupportedBoards {} {
  return ""
  #return [get_boards  {*tenzing*} ]
}

#
#  Helper function to get  
#  
proc range {from to} {
   if {$to>$from} {concat [range $from [incr to -1]] $to}
}

#
#  Conditional puts
#
proc log {args} {
  variable logStuff
  if {$logStuff == 1} {
    puts [join $args " "]
  }
}


#
# Required by CED, will create dict of all the options needed to configure the CED, will be tied to 
# gui controls in addGUILayout
#
proc addOptions {DESIGNOBJ PROJECT_PARAM.PART PROJECT_PARAM.PACKAGE PROJECT_PARAM.SPEEDGRADE} {
  variable currentDir 
  
  set systemTime [clock seconds]
  log "addOptions:: [clock format $systemTime -format %H:%M:%S]"
  log "$DESIGNOBJ ${PROJECT_PARAM.PART} ${PROJECT_PARAM.PACKAGE} ${PROJECT_PARAM.SPEEDGRADE}"
  
  # load part/pkg stuff here
  set toks [split ${PROJECT_PARAM.PART} "-"]
  set part [lindex $toks 0]
  log "part : $part $currentDir"
  # run factory proc to create proper get_all_quads and other device-specific procs
  $part
  
  
  set all_quads [get_all_quads ${PROJECT_PARAM.PACKAGE}]
  log "quads: $all_quads"
  
  lappend x [dict create name "Quad" type "string" value [lindex $all_quads 0] value_list $all_quads enabled true]
  lappend x [dict create name "Clk" type "string" value "REFCLK0" value_list {"REFCLK0" "REFCLK1"} enabled true]
  
  return $x
}

#
#  Required by CED, create parameters, which are GUI controls to be displayed in the CED
#
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART PROJECT_PARAM.PACKAGE} {
  
  set designObj $DESIGNOBJ
  set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]
  ced::add_param -name Quad -parent $page -designObject $designObj -layout horizontal -widget comboBox
  ced::add_param -name Clk -display_name "GT Reference Clock" -parent $page -designObject $designObj -layout horizontal -widget comboBox

  

}

proc old_gui_updater {PROJECT_PARAM.PACKAGE Type.VALUE Quad.RANGE} {
  

  set all_quads [get_all_quads ${PROJECT_PARAM.PACKAGE}]
  log "gui_updater: quads: $all_quads"
  log "type.value = ${Type.VALUE}"
  
  if { ${Type.VALUE} == {Soft_Aurora}} {
    foreach q $all_quads {
      lappend l "$q $q"
    }
    log "l: $l"
    set Quad.RANGE $l
       
  } elseif { ${Type.VALUE} == {Hard_Aurora} } {
    set Quad.RANGE {"HSDP0 HSDP0" "HSDP1 HSDP1"} 
  } 
}



