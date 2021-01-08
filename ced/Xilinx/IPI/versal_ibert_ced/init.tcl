
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
variable logStuff 0

source -notrace "$currentDir/gty_help.tcl"
source -notrace "$currentDir/device.tcl"

#
#  required for CED, return all versal parts
#
proc getSupportedParts {} {
  set mylist [get_parts -filter {DEVICE =~ xcvc* || DEVICE =~ xcvm* || DEVICE =~ xcvp*}]
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
  
  set max_lr [get_max_linerate ${PROJECT_PARAM.SPEEDGRADE}]
  set max_rr [get_max_refclk_rate ${PROJECT_PARAM.SPEEDGRADE}]
  
  set all_quads [get_all_quads ${PROJECT_PARAM.PACKAGE}]
  foreach v $all_quads {
    lappend x [dict create name ${v}_en type bool value false enabled true]
    lappend x [dict create name ${v}_lr type double value 10.3125 min_value 0 max_value $max_lr enabled false] 
    set refs [get_reflocs $v]
    lappend x [dict create name ${v}_ref type "string" value [lindex $refs 0] value_list $refs enabled false]
    lappend x [dict create name ${v}_rr type double value 156.25 min_value 0 max_value $max_rr enabled false]
  }
   
  return $x
}

#
#  Required by CED, create parameters, which are GUI controls to be displayed in the CED
#
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART PROJECT_PARAM.PACKAGE PROJECT_PARAM.SPEEDGRADE} {
  
  set max_lr [get_max_linerate ${PROJECT_PARAM.SPEEDGRADE}]
  set max_rr [get_max_refclk_rate ${PROJECT_PARAM.SPEEDGRADE}]
  
  set designObj $DESIGNOBJ
  set page_left [ced::add_page -name "Page1" -display_name "Left Side" -designObject $designObj -layout horizontal] 
  
  set left_quads [get_left ${PROJECT_PARAM.PACKAGE}]
  
  set rows [llength $left_quads]
  set table_l [ced::add_table $designObj  -name "Table" -rows [expr $rows+1] -columns "4" -parent ${page_left}]
  ced::add_text -name q_label_l -parent $table_l -designObject $designObj -tclproc "Quad Enable"
  set_property cell_location "0,0" [ced::get_text -name q_label_l -designObject $designObj]  
  ced::add_text -name r_label_l -parent $table_l -designObject $designObj -tclproc "Refclk Source"
  set_property cell_location "0,1" [ced::get_text -name r_label_l -designObject $designObj]  
  ced::add_text -name lr_label_l -parent $table_l -designObject $designObj -tclproc "Line Rate (max: $max_lr Gbps)"
  set_property cell_location "0,2" [ced::get_text -name lr_label_l -designObject $designObj]  
  ced::add_text -name rr_label_l -parent $table_l -designObject $designObj -tclproc "Refclk (max: $max_rr MHz)"
  set_property cell_location "0,3" [ced::get_text -name rr_label_l -designObject $designObj]  
  
   

  set i 1
  foreach v $left_quads {
     set name [replace $v "_" " "]
       
     ced::add_param -name ${v}_en -display_name $name -parent $table_l -designObject $designObj -layout horizontal -widget checkbox
     set_property cell_location "$i,0" [ced::get_param -name ${v}_en -designObject $designObj]        
     ced::add_param -name ${v}_ref -display_name " " -parent $table_l -designObject $designObj -layout horizontal -widget comboBox
     set_property cell_location "$i,1" [ced::get_param -name ${v}_ref -designObject $designObj]       
     ced::add_param -name ${v}_lr -display_name " " -parent $table_l -designObject $designObj -layout horizontal -widget textEdit
     set_property cell_location "$i,2" [ced::get_param -name ${v}_lr -designObject $designObj]
     ced::add_param -name ${v}_rr -display_name " " -parent $table_l -designObject $designObj  -layout horizontal -widget textEdit
     set_property cell_location "$i,3" [ced::get_param -name ${v}_rr -designObject $designObj]       
     incr i
  }

  #  
  #  These add auto-generated gui_updater calls, which provide the ability to have values of some gui controls affect others
  #
  gui_quad_enablement $left_quads
  for {set i 0} {$i < [llength $left_quads]} {incr i} {
    set obj_quad [lindex $left_quads $i]
    #  source quads can be up to two above and two below the object quad (lrange will property size results from list)
    set source_quads [concat [lrange $left_quads [expr $i-2] [expr $i-1]] [lrange $left_quads [expr $i+1] [expr $i+2]]]
    gui_refclk_choice_generation $obj_quad $source_quads
  }
  

  set page_right [ced::add_page -name "Page2" -display_name "Right Side" -designObject $designObj -layout horizontal]
  
  set right_quads [get_right ${PROJECT_PARAM.PACKAGE}]
  
  set rows [llength $right_quads]
  set table_r [ced::add_table $designObj  -name "Table2" -rows [expr $rows+1] -columns "4" -parent ${page_right}]
  ced::add_text -name q_label_r -parent $table_r -designObject $designObj -tclproc "Quad Enable"
  set_property cell_location "0,0" [ced::get_text -name q_label_r -designObject $designObj] 
  ced::add_text -name r_label_r -parent $table_r -designObject $designObj -tclproc "Refclk Source"
  set_property cell_location "0,1" [ced::get_text -name r_label_r -designObject $designObj]  
  ced::add_text -name lr_label_r -parent $table_r -designObject $designObj -tclproc "Line Rate (max: $max_lr Gbps)"
  set_property cell_location "0,2" [ced::get_text -name lr_label_r -designObject $designObj]  
  ced::add_text -name rr_label_r -parent $table_r -designObject $designObj -tclproc "Refclk (max: 820 MHz)"
  set_property cell_location "0,3" [ced::get_text -name rr_label_r -designObject $designObj]   
  
   

  set i 1
  puts $right_quads
  foreach v $right_quads { 
     set name [replace $v "_" " "]
       
     ced::add_param -name ${v}_en -display_name $name -parent $table_r -designObject $designObj -layout horizontal -widget checkbox
     set_property cell_location "$i,0" [ced::get_param -name ${v}_en -designObject $designObj]      
     ced::add_param -name ${v}_ref -display_name " " -parent $table_r -designObject $designObj -layout horizontal -widget comboBox
     set_property cell_location "$i,1" [ced::get_param -name ${v}_ref -designObject $designObj]   
     ced::add_param -name ${v}_lr -display_name " " -parent $table_r -designObject $designObj -layout horizontal -widget textEdit
     set_property cell_location "$i,2" [ced::get_param -name ${v}_lr -designObject $designObj]  
     ced::add_param -name ${v}_rr -display_name " " -parent $table_r -designObject $designObj  -layout horizontal -widget textEdit
     set_property cell_location "$i,3" [ced::get_param -name ${v}_rr -designObject $designObj]   
     incr i
  }
  
  #  
  #  These add auto-generated gui_updater calls, which provide the ability to have values of some gui controls affect others
  #
  gui_quad_enablement $right_quads
  for {set i 0} {$i < [llength $right_quads]} {incr i} {
    set obj_quad [lindex $right_quads $i]
    #  source quads can be up to two above and two below the object quad (lrange will property size results from list)
    set source_quads [concat [lrange $right_quads [expr $i-2] [expr $i-1]] [lrange $right_quads [expr $i+1] [expr $i+2]]]
    gui_refclk_choice_generation $obj_quad $source_quads
  }
  
  

}

#
#  gui_quad_enablement
#
#  Will generate gui_updater tcl code based on an incoming list of quads
#  For each quad, code will check to see if the refclk location starts with an "X", meaning it's a local
#  buffer. If so, code will enable the line rate and refclk rate choice controls.  Otherwise, the line
#  rate and refclk rate controls are disabled
#
proc gui_quad_enablement {quad_list} {
  
  set watch_params ""
  set change_params ""
  set code ""
  
  foreach quad $quad_list {
    lappend watch_params ${quad}_en.VALUE ${quad}_ref.VALUE ${quad}_lr.VALUE ${quad}_rr.VALUE
    lappend change_params ${quad}_lr.ENABLEMENT ${quad}_ref.ENABLEMENT ${quad}_rr.ENABLEMENT
    set quad_code [list \
      "if \{\$\{${quad}_en.VALUE\} == true \} \{" \
      "  set ${quad}_ref.ENABLEMENT true" \
      "  if \{\[string first X \$\{${quad}_ref.VALUE\}\] == 0\} \{" \
      "    set ${quad}_lr.ENABLEMENT true" \
      "    set ${quad}_rr.ENABLEMENT true" \
      "  \} else \{" \
      "    set ${quad}_lr.ENABLEMENT false" \
      "    set ${quad}_rr.ENABLEMENT false" \
      "  \}" \
      "\} else \{" \
      "  set ${quad}_lr.ENABLEMENT false" \
      "  set ${quad}_ref.ENABLEMENT false" \
      "  set ${quad}_rr.ENABLEMENT false" \
      "\} \n" \
    ]
    set quad_code [join $quad_code "\n"]
    set code "$code$quad_code"
  }
  log "------ gui_quad_enablement $quad_list START ------"
  log "gui_updater \{${watch_params}\} \{$change_params\} \{\n${code}\n\}"
  
  gui_updater $watch_params $change_params $code
  log "------ gui_quad_enablement END ------\n"
}

#
#  gui_refclk_choice_generation
#
#  Will generate gui_updater tcl code based on an incoming list of quads
#  The first arg is the quad to generate choices.  The entries in the source_quads list 
#  are the possible forwarding sources.  The code that is generated will check to see
#  if the possible sources each start with an X (meaning a local refclk source), and if
#  so, will add that Quad to the refclk source combo box. 
#
#  This proc needs to be called with each quad as the first argument, because a different
#  gui_updater call is needed for each. Dependencies will change based on the 
#  part and package combination.
#
proc gui_refclk_choice_generation {object_quad source_quads} {
  
  set watch_params ""
  set change_params ""
  set code ""
  set object_quad_num [lindex [split $object_quad "_"] 1]
  log "object_quad_num $object_quad_num"
  
  log "------ gui_refclk_choice_generation $object_quad $source_quads START ------"
  
  set change_params ${object_quad}_ref.RANGE
  lappend watch_params ${object_quad}_en.VALUE
  set c [list \
    "if \{\$\{${object_quad}_en.VALUE\} == true\} \{" \
    "  set l \[get_refclk_range $object_quad\]\n" \
  ]
  set code [join $c "\n"]
  
  set max_ref [get_max_refclk_sharing_linerate]
  
  foreach quad $source_quads {
    set source_quad_num [lindex [split $quad "_"] 1]
    # see if quads are next to each other, can't have a gap in forwarding
    set extra_term ""
    if {[expr abs($source_quad_num-$object_quad_num)] != 1} {
      set middle_quad "Quad_[expr ($source_quad_num+$object_quad_num)/2]"
      set extra_term "\$\{${middle_quad}_en.VALUE\} == true &&"
    }
    lappend watch_params ${quad}_en.VALUE ${quad}_ref.VALUE ${quad}_lr.VALUE
    set quad_code [list \
      "  if \{\$\{${quad}_en.VALUE\} == true && \[string first X \$\{${quad}_ref.VALUE\}\] == 0 && ${extra_term} \$\{${quad}_lr.VALUE\} < $max_ref\} \{" \
      "    lappend l \{$quad $quad\}" \
      "  \}\n" \
    ]
    set quad_code [join $quad_code "\n"]
    set code "$code$quad_code"
  }
  set c "\n  set ${object_quad}_ref.RANGE \$l\n\}"
  set code "$code$c"
 
  log "gui_updater \{$watch_params\} \{$change_params\} \{\n${code}\n\}"
  gui_updater $watch_params $change_params $code
  log "------ gui_refclk_choice_generation END ------\n"
}

