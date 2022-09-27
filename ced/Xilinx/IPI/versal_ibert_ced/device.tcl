# ########################################################################
# Copyright (C) 2021, Xilinx Inc - All rights reserved
# 
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################


proc get_GTY_width {linerate} {
    return 80
  }

proc get_GTM_width {linerate} {
  if {$linerate > 57.0} {
    return 320
  } else {
    return 160
  }
}

proc get_GTYP_width {linerate} {
  return 80
}

proc get_max_refclk_rate {speedgrade type} {
  return 820.0
}

proc get_max_refclk_sharing_linerate {type} {
  return 16.375
}

proc get_max_linerate {speedgrade type} {
  switch $type {
    GTY {
      switch $speedgrade {
        -3HP { 
          return 32.75
        }
        -2MP -
        -2HP -
        -2LP {
          return 28.21
        }
        -1MM -
        -1MP {
          return 26.5625
        }
        -1LP {
          return 25.78125
        }
        default {
          return 25.78125
        }
      }
    }
    GTYP {
      switch $speedgrade {
        -3HP { 
          return 32.75
        }
        -2MP -
        -2HP -
        -2LP {
          return 32.0
        }
        -1MM -
        -1MP {
          return 32.0
        }
        -1LP {
          return 25.78125
        }
        default {
          return 25.78125
        }
      }
    }
    GTM {
      switch $speedgrade {
        -2LP -
        -2MP {
          return 112.0
        }
        default {
          return 112.0
        }
      }
    }
  }
}

proc get_min_linerate {speedgrade type} {
  return 1.25
}


########################################################################################################################
#  V20
#
proc xcv20 {} {
  log "using xcv20 procs"

  proc get_gt_types {} {
    return [list "GTY"]
  }

  proc get_left {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list ]
      }
    }
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nbvb1024 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_103" "GTY_QUAD_104"] }
        }
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { GTY_QUAD_103 {GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1}
                      GTY_QUAD_104 {GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3}
                      GTY_QUAD_106 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
       }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y0
      GTY_QUAD_104 GTY_QUAD_X0Y1
      GTY_QUAD_106 GTY_QUAD_X0Y3
    }

    return [dict get $gt_dict $q]
  }


}

########################################################################################################################
#  V65
#
proc xcv65 {} {
  log "using xcv65 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
      GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
      GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
      GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}

    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvd1760 {
        switch $quad {
            GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
            GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] } 
            GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] } 
            GTY_QUAD_106 { return [list "GTY_QUAD_105"] } 
            GTY_QUAD_203 { return [list "GTY_QUAD_204"] } 
            GTY_QUAD_203 { return [list "GTY_QUAD_203"] } 
        }
      }
    }
  }

  proc get_gt_types {} {
    return [list "GTY"]
  }
}

########################################################################################################################
#  VC1502
#
proc xcvc1502 {} {
  log "using xcvc1502 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
    }

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      
      nsvg1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      
      nsvg1369 {
        return [list GTY_QUAD_202 GTY_QUAD_203]
      }
      vsva1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
      GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
      GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
      GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
      GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
      GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
      GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
      GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202"] }
        }
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204"] }
          GTY_QUAD_204 { return [list "GTY_QUAD_203" "GTY_QUAD_205"] }
          GTY_QUAD_205 { return [list "GTY_QUAD_204"] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_200 { return [list "GTY_QUAD_201"] }
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_201" "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204"] }
          GTY_QUAD_204 { return [list "GTY_QUAD_203" "GTY_QUAD_205"] }
          GTY_QUAD_205 { return [list "GTY_QUAD_204" "GTY_QUAD_206"] }
          GTY_QUAD_206 { return [list "GTY_QUAD_205"] }

        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTY"]
  }


}


########################################################################################################################
#  VC1702
#
proc xcvc1702 {} {
  log "using xcvc1702 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nsvg1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsvg1369 {
        return [list GTY_QUAD_202 GTY_QUAD_203]
      }
      vsva1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
      GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
      GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
      GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
      GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
      GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
      GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
      GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
      GTY_QUAD_206 {GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13}
    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_200 { return [list "GTY_QUAD_201"] }
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202"] }
        }
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204"] }
          GTY_QUAD_204 { return [list "GTY_QUAD_203" "GTY_QUAD_205"] }
          GTY_QUAD_205 { return [list "GTY_QUAD_204"] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_200 { return [list "GTY_QUAD_201"] }
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_201" "GTY_QUAD_203"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204"] }
          GTY_QUAD_204 { return [list "GTY_QUAD_203" "GTY_QUAD_205"] }
          GTY_QUAD_205 { return [list "GTY_QUAD_204" "GTY_QUAD_206"] }
          GTY_QUAD_206 { return [list "GTY_QUAD_205"] }

        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTY"]
  }


}

########################################################################################################################
#  VC1802
#
proc xcvc1802 {} { xcvc1902 }


########################################################################################################################
#  VC1902
#
proc xcvc1902 {} {
  log "using xcvc1902 procs"
  
  proc get_gt_types {} {
    return [list "GTY"]
  }
  
  
  proc get_left {pkg} {
    switch $pkg {
      vsva2197 -
      vsvd2197 -
      vfvc1760 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      vsva1760 -
      vsvd1760 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      viva1596 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      default {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2197 -
      vsvd2197 -
      vfvc1760 {
        return [list "GTY_QUAD_200" "GTY_QUAD_201" "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_205" "GTY_QUAD_206"]
      }
      vsva1760 -
      vsvd1760 {
        return [list "GTY_QUAD_203" "GTY_QUAD_204"]
      }
      viva1596
      {
        return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_205"]
      }
      default {
        return [list "GTY_QUAD_203" "GTY_QUAD_204"]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2197 -
      vsvd2197 -
      vfvc1760 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_200 { return [list "GTY_QUAD_201" "GTY_QUAD_202"] } 
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202" "GTY_QUAD_203"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_200" "GTY_QUAD_201" "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_201" "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205" "GTY_QUAD_206"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_206"] } 
          GTY_QUAD_206 { return [list "GTY_QUAD_204" "GTY_QUAD_205"] } 
        }  
      }
      vsva1760 -
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_204"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_203"] } 
        }  
      }
      viva1596
      {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
        }  
      }
      default {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
        }  
      }
    }
    
  }
  
  
  proc get_reflocs {q} {
    set refclk_dict { GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7} 
                    GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
                    GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
                    GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
                    GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
                    GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
                    GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
                    GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
                    GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
                    GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
                    GTY_QUAD_206 {GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13} }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { GTY_QUAD_103 GTY_QUAD_X0Y3
                GTY_QUAD_104 GTY_QUAD_X0Y4
                GTY_QUAD_105 GTY_QUAD_X0Y5
                GTY_QUAD_106 GTY_QUAD_X0Y6
                GTY_QUAD_200 GTY_QUAD_X1Y0
                GTY_QUAD_201 GTY_QUAD_X1Y1
                GTY_QUAD_202 GTY_QUAD_X1Y2
                GTY_QUAD_203 GTY_QUAD_X1Y3
                GTY_QUAD_204 GTY_QUAD_X1Y4
                GTY_QUAD_205 GTY_QUAD_X1Y5
                GTY_QUAD_206 GTY_QUAD_X1Y6}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VC2802
#
proc xcvc2802 {} {
  log "using xcvc2802 procs"
  
  proc get_gt_types {} {
    return [list "GTYP"]
  }
  
  
  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTYP_QUAD_104 GTYP_QUAD_105 GTYP_QUAD_106]
      }
      vsvh1760 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTYP_QUAD_104 GTYP_QUAD_105 GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_204 GTYP_QUAD_205 GTYP_QUAD_206]
      }
      vsvh1760 {
        return [list GTYP_QUAD_204 GTYP_QUAD_205 GTYP_QUAD_206]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvh1369 -
      vsvh1760 {
        switch $quad {
          GTY_QUAD_106 { return [list ] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_205" "GTY_QUAD_206"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_204" "GTY_QUAD_206"] } 
          GTY_QUAD_206 { return [list "GTY_QUAD_204" "GTY_QUAD_205"] } 
        }  
      }
    }
  }
  
  
  proc get_reflocs {q} {
    set refclk_dict { GTYP_QUAD_102 {GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1}
            GTYP_QUAD_103 {GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3}
            GTYP_QUAD_104 {GTYP_REFCLK_X0Y4 GTYP_REFCLK_X0Y5}
            GTYP_QUAD_105 {GTYP_REFCLK_X0Y6 GTYP_REFCLK_X0Y7}
            GTYP_QUAD_106 {GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9}
            GTYP_QUAD_204 {GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5}
            GTYP_QUAD_205 {GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7}
            GTYP_QUAD_206 {GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9} }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { GTYP_QUAD_102 GTYP_QUAD_X0Y0
            GTYP_QUAD_103 GTYP_QUAD_X0Y1
            GTYP_QUAD_104 GTYP_QUAD_X0Y2
            GTYP_QUAD_105 GTYP_QUAD_X0Y3
            GTYP_QUAD_106 GTYP_QUAD_X0Y4
            GTYP_QUAD_204 GTYP_QUAD_X1Y2
            GTYP_QUAD_205 GTYP_QUAD_X1Y3
            GTYP_QUAD_206 GTYP_QUAD_X1Y4}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VE1752
#
proc xcve1752 {} {
  log "using xcve1752 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      nsvg1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsvg1369 {
        return [list GTY_QUAD_202 GTY_QUAD_203]
      }
      vsva1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
      GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
      GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
      GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
      GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
      GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
      GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
      GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
      GTY_QUAD_206 {GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13}
    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202"] } 
        }  
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
        }  
      }
      vsva2197 -
      vsvd2197 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_200 { return [list "GTY_QUAD_201" "GTY_QUAD_202"] } 
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202" "GTY_QUAD_203"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_200" "GTY_QUAD_201" "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_201" "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205" "GTY_QUAD_206"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_206"] } 
          GTY_QUAD_206 { return [list "GTY_QUAD_204" "GTY_QUAD_205"] } 
        }  
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTY"]
  }
}

########################################################################################################################
#  VE2302
#
proc xcve2302 {} {
  log "using xcve2302 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_103 GTYP_QUAD_X0Y0
      GTYP_QUAD_104 GTYP_QUAD_X0Y1
    }

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      sfva784 {
        return [list GTYP_QUAD_103 GTYP_QUAD_104]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      sfva784 {
        return [list ]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTYP_QUAD_103 {GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1}
      GTYP_QUAD_104 {GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3}
    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sfva784 {
        switch $quad {
          GTYP_QUAD_103 { return [list "GTY_QUAD_104"] } 
          GTYP_QUAD_104 { return [list "GTY_QUAD_103"] } 
        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTYP"]
  }
}

########################################################################################################################
#  VE2802
#
proc xcve2802 {} {
  log "using xcve2802 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 -
      vsvh1760 {
        return [list GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsvh1369 -
      vsvh1760 {
        return [list GTYP_QUAD_204 GTYP_QUAD_205 GTYP_QUAD_206]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTYP_QUAD_106 {GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9}
      GTYP_QUAD_204 {GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5}
      GTYP_QUAD_205 {GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7}
      GTYP_QUAD_206 {GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9}
    }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvh1369 -
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list] } 
          GTYP_QUAD_204 { return [list "GTY_QUAD_205" "GTY_QUAD_205"] } 
          GTYP_QUAD_205 { return [list "GTY_QUAD_204" "GTY_QUAD_206"] }
          GTYP_QUAD_206 { return [list "GTY_QUAD_204" "GTY_QUAD_205"] }
        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTYP"]
  }
}

########################################################################################################################
#  VH1522
#
proc xcvh1522 {} {
  log "using xcvh1522 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTYP_QUAD_109 GTYP_QUAD_X0Y9
      GTYP_QUAD_110 GTYP_QUAD_X0Y10
      GTYP_QUAD_111 GTYP_QUAD_X0Y11
      GTYP_QUAD_112 GTYP_QUAD_X0Y12
      GTYP_QUAD_200 GTYP_QUAD_X1Y0
      GTYP_QUAD_201 GTYP_QUAD_X1Y1
      GTM_QUAD_202 GTM_QUAD_X0Y0
      GTM_QUAD_203 GTM_QUAD_X0Y1
      GTM_QUAD_204 GTM_QUAD_X0Y2
      GTM_QUAD_205 GTM_QUAD_X0Y3
      GTM_QUAD_206 GTM_QUAD_X0Y4
      GTYP_QUAD_207 GTYP_QUAD_X1Y7
      GTYP_QUAD_208 GTYP_QUAD_X1Y8
      GTYP_QUAD_209 GTYP_QUAD_X1Y9
      GTYP_QUAD_210 GTYP_QUAD_X1Y10
      GTYP_QUAD_211 GTYP_QUAD_X1Y11
      GTYP_QUAD_212 GTYP_QUAD_X1Y12}

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      vsva3697 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva3697 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13}
      GTYP_QUAD_109 {GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19}
      GTYP_QUAD_110 {GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21}
      GTYP_QUAD_111 {GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23}
      GTYP_QUAD_112 {GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25}
      GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1}
      GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3}
      GTM_QUAD_202 {GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1}
      GTM_QUAD_203 {GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3}
      GTM_QUAD_204 {GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5}
      GTM_QUAD_205 {GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7}
      GTM_QUAD_206 {GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9}
      GTYP_QUAD_207 {GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15}
      GTYP_QUAD_208 {GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17}
      GTYP_QUAD_209 {GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19}
      GTYP_QUAD_210 {GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21}
      GTYP_QUAD_211 {GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23}
      GTYP_QUAD_212 {GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25} }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva3697 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTYP_QUAD_109 { return [list "GTYP_QUAD_110"]} 
          GTYP_QUAD_110 { return [list "GTYP_QUAD_109" "GTYP_QUAD_111"]} 
          GTYP_QUAD_111 { return [list "GTYP_QUAD_110" "GTYP_QUAD_112"]}
          GTYP_QUAD_112 { return [list "GTYP_QUAD_111"]} 
          GTYP_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTYP_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTYP_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTYP_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTYP_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTYP_QUAD_212 { return [list "GTM_QUAD_211"]} 
        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }


}

########################################################################################################################
#  VH1542
#
proc xcvh1542 {} {
  log "using xcvh1542 procs"
  xcvh1522
}

########################################################################################################################
#  VH1582
#
proc xcvh1582 {} {
  log "using xcvh1582 procs"
  xcvh1522
}

########################################################################################################################
#  VH1742
#
proc xcvh1742 {} {
  log "using xcvh1742 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTYP_QUAD_115 GTYP_QUAD_X0Y9
      GTYP_QUAD_116 GTYP_QUAD_X0Y10
      GTYP_QUAD_117 GTYP_QUAD_X0Y11
      GTYP_QUAD_118 GTYP_QUAD_X0Y12
      GTYP_QUAD_200 GTYP_QUAD_X1Y0
      GTYP_QUAD_201 GTYP_QUAD_X1Y1
      GTM_QUAD_202 GTM_QUAD_X1Y0
      GTM_QUAD_203 GTM_QUAD_X1Y1
      GTM_QUAD_204 GTM_QUAD_X1Y2
      GTM_QUAD_205 GTM_QUAD_X1Y3
      GTM_QUAD_206 GTM_QUAD_X1Y4
      GTM_QUAD_207 GTM_QUAD_X1Y5
      GTM_QUAD_208 GTM_QUAD_X1Y6
      GTM_QUAD_209 GTM_QUAD_X1Y7
      GTM_QUAD_210 GTM_QUAD_X1Y8
      GTM_QUAD_211 GTM_QUAD_X1Y9
      GTM_QUAD_212 GTM_QUAD_X1Y10
      GTYP_QUAD_213 GTYP_QUAD_X1Y7
      GTYP_QUAD_214 GTYP_QUAD_X1Y8
      GTYP_QUAD_215 GTYP_QUAD_X1Y9
      GTYP_QUAD_216 GTYP_QUAD_X1Y10
      GTYP_QUAD_217 GTYP_QUAD_X1Y11
      GTYP_QUAD_218 GTYP_QUAD_X1Y12}

    return [dict get $gt_dict $q]
  }


  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTYP_QUAD_104 GTYP_QUAD_105 GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTYP_QUAD_115 GTYP_QUAD_116 GTYP_QUAD_117 GTYP_QUAD_118]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTYP_QUAD_213 GTYP_QUAD_214 GTYP_QUAD_215 GTYP_QUAD_216 GTYP_QUAD_217 GTYP_QUAD_218]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13}
      GTM_QUAD_109 {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
      GTM_QUAD_110 {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
      GTM_QUAD_111 {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
      GTM_QUAD_112 {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
      GTYP_QUAD_115 {GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19}
      GTYP_QUAD_116 {GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21}
      GTYP_QUAD_117 {GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23}
      GTYP_QUAD_118 {GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25}
      GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1}
      GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3}
      GTM_QUAD_202 {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
      GTM_QUAD_203 {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
      GTM_QUAD_204 {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
      GTM_QUAD_205 {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
      GTM_QUAD_206 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
      GTM_QUAD_207 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
      GTM_QUAD_208 {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
      GTM_QUAD_209 {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
      GTM_QUAD_210 {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
      GTM_QUAD_211 {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}
      GTM_QUAD_212 {GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21}
      GTYP_QUAD_213 {GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15}
      GTYP_QUAD_214 {GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17}
      GTYP_QUAD_215 {GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19}
      GTYP_QUAD_216 {GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21}
      GTYP_QUAD_217 {GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23}
      GTYP_QUAD_218 {GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25} }
    return [dict get $refclk_dict $q]
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTYP_QUAD_109 { return [list "GTYP_QUAD_110"]} 
          GTYP_QUAD_110 { return [list "GTYP_QUAD_109" "GTYP_QUAD_111"]} 
          GTYP_QUAD_111 { return [list "GTYP_QUAD_110" "GTYP_QUAD_112"]}
          GTYP_QUAD_112 { return [list "GTYP_QUAD_111"]} 
          GTYP_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTYP_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTYP_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTYP_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTYP_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTYP_QUAD_212 { return [list "GTM_QUAD_211"]} 
          GTYP_QUAD_115 { return [list "GTYP_QUAD_116"]} 
          GTYP_QUAD_116 { return [list "GTYP_QUAD_115" "GTYP_QUAD_117"]} 
          GTYP_QUAD_117 { return [list "GTYP_QUAD_116" "GTYP_QUAD_118"]}
          GTYP_QUAD_118 { return [list "GTYP_QUAD_117"]} 
          GTYP_QUAD_213 { return [list "GTM_QUAD_214"]} 
          GTYP_QUAD_214 { return [list "GTM_QUAD_213" "GTM_QUAD_215"]} 
          GTYP_QUAD_215 { return [list "GTM_QUAD_214" "GTM_QUAD_216"]} 
          GTYP_QUAD_216 { return [list "GTM_QUAD_215" "GTM_QUAD_217"]} 
          GTYP_QUAD_217 { return [list "GTM_QUAD_216" "GTM_QUAD_218"]} 
          GTYP_QUAD_218 { return [list "GTM_QUAD_217"]} 
        }
      }

    }
  }

  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }


}

########################################################################################################################
#  VH1782
#
proc xcvh1782 {} {
  log "using xcvh1782 procs"
  xcvh1742
}

########################################################################################################################
#  VM1102
#
proc xcvm1102 {} {
  log "using xcvm1102 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_103 GTYP_QUAD_X0Y0
      GTYP_QUAD_104 GTYP_QUAD_X0Y1
    }

    return [dict get $gt_dict $q]
  }


  proc get_gt_types {} {
    return [list "GTYP"]
  }

  proc get_left {pkg} {
    switch $pkg {
      sfva784 {
        return [list GTYP_QUAD_103 GTYP_QUAD_104 ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      sfva784 {
        return [list ]
      }
    }
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sfva784 {
        switch $quad {
          GTYP_QUAD_103 { return [list "GTYP_QUAD_104"] }
          GTYP_QUAD_104 { return [list "GTYP_QUAD_103"] }
        }
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_103 {GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1}
      GTYP_QUAD_104 {GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3}
    }
    return [dict get $refclk_dict $q]
  }
}




########################################################################################################################
#  VM1302
#
proc xcvm1302 {} {
  log "using xcvm1302 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y0
      GTY_QUAD_104 GTY_QUAD_X0Y1
      GTY_QUAD_105 GTY_QUAD_X0Y2
      GTY_QUAD_106 GTY_QUAD_X0Y3
      GTY_QUAD_107 GTY_QUAD_X0Y4
      GTY_QUAD_108 GTY_QUAD_X0Y5
    }

    return [dict get $gt_dict $q]
  }


  proc get_gt_types {} {
    return [list "GTY"]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nbvb1024 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nsvf1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104]
      }
      vfvc1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTY_QUAD_108]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvd1760 - 
      nbvn1024 -
      nsvf1369 -
      vfvc1596 {
        return [list ]
      }
    }
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvf1369 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103"] }
        }
      }
      vsvd1760 -
      nbvb1024 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
        }
      }
      vfvc1596 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105" "GTY_QUAD_107"] }
          GTY_QUAD_107 { return [list "GTY_QUAD_106" "GTY_QUAD_108"] }
          GTY_QUAD_108 { return [list "GTY_QUAD_107"] }
        }
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 {GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1}
      GTY_QUAD_104 {GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3}
      GTY_QUAD_105 {GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5}
      GTY_QUAD_106 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_107 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_108 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
    }
    return [dict get $refclk_dict $q]
  }
}

########################################################################################################################
#  VM1402
#
proc xcvm1402 {} {
  log "using xcvm1402 procs"
  xcvm1302
}

########################################################################################################################
#  VM1502
#
proc xcvm1502 {} {
  log "using xcvm1502 procs"

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }

    return [dict get $gt_dict $q]
  }


  proc get_gt_types {} {
    return [list "GTY"]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvc1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nfvb1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvc1760 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      nfvb1369 {
        return [list ]
      }
    }
  }

  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvc1760 -
      nfvb1369 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104"] }
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105"] }
          GTY_QUAD_105 { return [list "GTY_QUAD_104" "GTY_QUAD_106"] }
          GTY_QUAD_106 { return [list "GTY_QUAD_105"] }
          GTY_QUAD_200 { return [list "GTY_QUAD_201"] }
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202"] }
          GTY_QUAD_202 { return [list "GTY_QUAD_201" "GTY_QUAD_103"] }
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204"] }
          GTY_QUAD_204 { return [list "GTY_QUAD_203" "GTY_QUAD_205"] }
          GTY_QUAD_205 { return [list "GTY_QUAD_204" "GTY_QUAD_206"] }
          GTY_QUAD_206 { return [list "GTY_QUAD_205"] }
        }
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
      GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7}
      GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
      GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
      GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
      GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
      GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
      GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
      GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
      GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
      GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
      GTY_QUAD_206 {GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13}
    }
    return [dict get $refclk_dict $q]
  }
}

########################################################################################################################
#  VM1802
#
proc xcvm1802 {} { 
  log "using xcvm1802 procs"
  xcvc1902 
}

########################################################################################################################
#  VP1002
#
proc xcvp1002 {} {
  log "using xcvp1002 procs"
  
  proc get_gt_types {} {
    return [list "GTY" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTY_QUAD_103 GTY_QUAD_105]
      } 
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nfvi1369 {
        switch $quad {
          GTY_QUAD_103 { return [list]} 
          GTY_QUAD_105 { return [list]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205" "GTM_QUAD_207"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_206"]} 
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
          GTY_QUAD_103 {GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1}
          GTY_QUAD_105 {GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5}
          GTM_QUAD_202 {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
          GTM_QUAD_203 {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
          GTM_QUAD_204 {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
          GTM_QUAD_205 {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
          GTM_QUAD_206 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
          GTM_QUAD_207 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}}
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
        GTY_QUAD_103 GTY_QUAD_X0Y0
        GTY_QUAD_105 GTY_QUAD_X0Y2
        GTM_QUAD_202 GTM_QUAD_X1Y0
        GTM_QUAD_203 GTM_QUAD_X1Y1
        GTM_QUAD_204 GTM_QUAD_X1Y2
        GTM_QUAD_205 GTM_QUAD_X1Y3
        GTM_QUAD_206 GTM_QUAD_X1Y4
        GTM_QUAD_207 GTM_QUAD_X1Y5}

    return [dict get $gt_dict $q]
  }  

}

########################################################################################################################
#  VP1052
#
proc xcvp1052 {} {
  log "using xcvp1052 procs"
  
  proc get_gt_types {} {
    return [list "GTY" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTY_QUAD_103 GTY_QUAD_105 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nfvi1369 {
        switch $quad {
          GTY_QUAD_103 { return [list]} 
          GTY_QUAD_105 { return [list]} 
          GTY_QUAD_108 { return [list "GTY_QUAD_109"]} 
          GTY_QUAD_109 { return [list "GTY_QUAD_108" "GTY_QUAD_110"]} 
          GTY_QUAD_110 { return [list "GTY_QUAD_109"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205" "GTM_QUAD_207"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_206"]} 
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
        GTY_QUAD_103 {GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1}
        GTY_QUAD_105 {GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5}
        GTM_QUAD_108 {GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13}
        GTM_QUAD_109 {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
        GTM_QUAD_110 {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
        GTM_QUAD_202 {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
        GTM_QUAD_203 {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
        GTM_QUAD_204 {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
        GTM_QUAD_205 {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
        GTM_QUAD_206 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
        GTM_QUAD_207 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}}
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
      GTY_QUAD_103 GTY_QUAD_X0Y0
      GTY_QUAD_105 GTY_QUAD_X0Y2
      GTM_QUAD_108 GTM_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_202 GTM_QUAD_X1Y0
      GTM_QUAD_203 GTM_QUAD_X1Y1
      GTM_QUAD_204 GTM_QUAD_X1Y2
      GTM_QUAD_205 GTM_QUAD_X1Y3
      GTM_QUAD_206 GTM_QUAD_X1Y4
      GTM_QUAD_207 GTM_QUAD_X1Y5}

    return [dict get $gt_dict $q]
  }  

}

########################################################################################################################
#  VP1052
#
proc xcvp1102 {} {
  log "using xcvp1102 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTYP_QUAD_102 { return [list "GTYP_QUAD_103"]} 
          GTYP_QUAD_103 { return [list "GTYP_QUAD_102"]} 
          GTM_QUAD_104 { return [list "GTM_QUAD_105"]} 
          GTM_QUAD_105 { return [list "GTM_QUAD_104" "GTM_QUAD_106"]} 
          GTM_QUAD_106 { return [list "GTM_QUAD_105" "GTM_QUAD_107"]} 
          GTM_QUAD_107 { return [list "GTM_QUAD_106" "GTM_QUAD_108"]} 
          GTM_QUAD_108 { return [list "GTM_QUAD_107" "GTM_QUAD_109"]} 
          GTM_QUAD_109 { return [list "GTM_QUAD_108"]} 
          GTM_QUAD_200 { return [list "GTM_QUAD_201"]} 
          GTM_QUAD_201 { return [list "GTM_QUAD_200" "GTM_QUAD_202"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_201" "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_207"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204"]} 
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
        GTYP_QUAD_102 {GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1}
        GTYP_QUAD_103 {GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3}
        GTM_QUAD_104 {GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9}
        GTM_QUAD_105 {GTM_REFCLK_X0Y10 GTM_REFCLK_X0Y11}
        GTM_QUAD_106 {GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13}
        GTM_QUAD_107 {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
        GTM_QUAD_108 {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
        GTM_QUAD_109 {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
        GTM_QUAD_200 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
        GTM_QUAD_201 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
        GTM_QUAD_202 {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
        GTM_QUAD_203 {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
        GTM_QUAD_204 {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
        GTM_QUAD_205 {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}}
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
      GTYP_QUAD_102 GTYP_QUAD_X0Y0
      GTYP_QUAD_103 GTYP_QUAD_X0Y1
      GTM_QUAD_104 GTM_QUAD_X0Y4
      GTM_QUAD_105 GTM_QUAD_X0Y5
      GTM_QUAD_106 GTM_QUAD_X0Y6
      GTM_QUAD_107 GTM_QUAD_X0Y7
      GTM_QUAD_108 GTM_QUAD_X0Y8
      GTM_QUAD_109 GTM_QUAD_X0Y9
      GTM_QUAD_200 GTM_QUAD_X1Y4
      GTM_QUAD_201 GTM_QUAD_X1Y5
      GTM_QUAD_202 GTM_QUAD_X1Y6
      GTM_QUAD_203 GTM_QUAD_X1Y7
      GTM_QUAD_204 GTM_QUAD_X1Y8
      GTM_QUAD_205 GTM_QUAD_X1Y9}

    return [dict get $gt_dict $q]
  }  

}


########################################################################################################################
#  VP1202
#
proc xcvp1202 {} {
  log "using xcvp1202 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list "GTYP_QUAD_106"] 
      }
      default {
        return [list]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list "GTYP_QUAD_200" "GTYP_QUAD_201" "GTM_QUAD_202" "GTM_QUAD_203" "GTM_QUAD_204" "GTM_QUAD_205" "GTM_QUAD_206"]
      }
      default {
        return [list]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
                    GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13}
                    GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1}
                    GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3}
                    GTM_QUAD_202 {GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1}
                    GTM_QUAD_203 {GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3}
                    GTM_QUAD_204 {GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5}
                    GTM_QUAD_205 {GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7}
                    GTM_QUAD_206 {GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9} }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
                GTYP_QUAD_106 GTYP_QUAD_X0Y6
                GTYP_QUAD_200 GTYP_QUAD_X1Y0
                GTYP_QUAD_201 GTYP_QUAD_X1Y1
                GTM_QUAD_202 GTM_QUAD_X0Y0
                GTM_QUAD_203 GTM_QUAD_X0Y1
                GTM_QUAD_204 GTM_QUAD_X0Y2
                GTM_QUAD_205 GTM_QUAD_X0Y3
                GTM_QUAD_206 GTM_QUAD_X0Y4}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VP1402
#
proc xcvp1402 {} {
  log "using xcvp1402 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      vsvd2197 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_113]
      }
      vsva2785 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111]
      }
      vsva3340 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_113]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvd2197 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213]
      }
      vsva2785 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211]
      }
      vsva3340 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTYP_QUAD_102 { return [list "GTYP_QUAD_102"]} 
          GTYP_QUAD_103 { return [list "GTYP_QUAD_103"]}
          GTM_QUAD_104 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_105 { return [list "GTM_QUAD_104" "GTM_QUAD_106"]}
          GTM_QUAD_106 { return [list "GTM_QUAD_105" "GTM_QUAD_107"]}
          GTM_QUAD_107 { return [list "GTM_QUAD_106" "GTM_QUAD_108"]}
          GTM_QUAD_108 { return [list "GTM_QUAD_107" "GTM_QUAD_109"]}
          GTM_QUAD_109 { return [list "GTM_QUAD_108" "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_200 { return [list "GTM_QUAD_201"]} 
          GTM_QUAD_201 { return [list "GTM_QUAD_200" "GTM_QUAD_202"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203" "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205" "GTM_QUAD_207"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_206" "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTM_QUAD_211 { return [list "GTM_QUAD_210"]}         
        }  
      }
      vsvd2197 -
      vsva3340 {
        switch $quad {
          GTYP_QUAD_102 { return [list "GTYP_QUAD_102"]} 
          GTYP_QUAD_103 { return [list "GTYP_QUAD_103"]}
          GTM_QUAD_104 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_105 { return [list "GTM_QUAD_104" "GTM_QUAD_106"]}
          GTM_QUAD_106 { return [list "GTM_QUAD_105" "GTM_QUAD_107"]}
          GTM_QUAD_107 { return [list "GTM_QUAD_106" "GTM_QUAD_108"]}
          GTM_QUAD_108 { return [list "GTM_QUAD_107" "GTM_QUAD_109"]}
          GTM_QUAD_109 { return [list "GTM_QUAD_108" "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110" "GTM_QUAD_112"]}
          GTM_QUAD_112 { return [list "GTM_QUAD_111" "GTM_QUAD_113"]}
          GTM_QUAD_113 { return [list "GTM_QUAD_112"]}
          GTM_QUAD_200 { return [list "GTM_QUAD_201"]} 
          GTM_QUAD_201 { return [list "GTM_QUAD_200" "GTM_QUAD_202"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203" "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205" "GTM_QUAD_207"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_206" "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTM_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTM_QUAD_212 { return [list "GTM_QUAD_211" "GTM_QUAD_213"]}   
          GTM_QUAD_213 { return [list "GTM_QUAD_212"]}           
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
          GTYP_QUAD_102 {GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1}
          GTYP_QUAD_103 {GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3}
          GTM_QUAD_104 {GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9}
          GTM_QUAD_105 {GTM_REFCLK_X0Y10 GTM_REFCLK_X0Y11}
          GTM_QUAD_106 {GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13}
          GTM_QUAD_107 {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
          GTM_QUAD_108 {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
          GTM_QUAD_109 {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
          GTM_QUAD_110 {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
          GTM_QUAD_111 {GTM_REFCLK_X0Y22 GTM_REFCLK_X0Y23}
          GTM_QUAD_200 {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
          GTM_QUAD_201 {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
          GTM_QUAD_202 {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
          GTM_QUAD_203 {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
          GTM_QUAD_204 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
          GTM_QUAD_205 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
          GTM_QUAD_206 {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
          GTM_QUAD_207 {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
          GTM_QUAD_208 {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
          GTM_QUAD_209 {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}
          GTM_QUAD_210 {GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21}
          GTM_QUAD_211 {GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23}
                    }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
          GTYP_QUAD_102 GTYP_QUAD_X0Y0
          GTYP_QUAD_103 GTYP_QUAD_X0Y1
          GTM_QUAD_104 GTM_QUAD_X0Y4
          GTM_QUAD_105 GTM_QUAD_X0Y5
          GTM_QUAD_106 GTM_QUAD_X0Y6
          GTM_QUAD_107 GTM_QUAD_X0Y7
          GTM_QUAD_108 GTM_QUAD_X0Y8
          GTM_QUAD_109 GTM_QUAD_X0Y9
          GTM_QUAD_110 GTM_QUAD_X0Y10
          GTM_QUAD_111 GTM_QUAD_X0Y11
          GTM_QUAD_200 GTM_QUAD_X1Y0
          GTM_QUAD_201 GTM_QUAD_X1Y1
          GTM_QUAD_202 GTM_QUAD_X1Y2
          GTM_QUAD_203 GTM_QUAD_X1Y3
          GTM_QUAD_204 GTM_QUAD_X1Y4
          GTM_QUAD_205 GTM_QUAD_X1Y5
          GTM_QUAD_206 GTM_QUAD_X1Y6
          GTM_QUAD_207 GTM_QUAD_X1Y7
          GTM_QUAD_208 GTM_QUAD_X1Y8
          GTM_QUAD_209 GTM_QUAD_X1Y9
          GTM_QUAD_210 GTM_QUAD_X1Y10
          GTM_QUAD_211 GTM_QUAD_X1Y11}

    return [dict get $gt_dict $q]
  }

}


########################################################################################################################
#  VP1502
#
proc xcvp1502 {} {
  log "using xcvp1502 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      vsva2785 -
      vsva3340 {
        return [list "GTYP_QUAD_106" "GTM_QUAD_109" "GTM_QUAD_110" "GTM_QUAD_111" "GTM_QUAD_112"] 
      }
      default {
        return [list]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 -
      vsva3340 {
        return [list "GTYP_QUAD_200" "GTYP_QUAD_201" "GTM_QUAD_202" "GTM_QUAD_203" "GTM_QUAD_204" "GTM_QUAD_205" "GTM_QUAD_206" "GTM_QUAD_207" "GTM_QUAD_208" "GTM_QUAD_209" "GTM_QUAD_210" "GTM_QUAD_211" "GTM_QUAD_212"]
      }
      default {
        return [list]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 -
      vsva3340 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTM_QUAD_109 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110" "GTM_QUAD_112"]}
          GTM_QUAD_112 { return [list "GTM_QUAD_111"]}
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTM_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTM_QUAD_212 { return [list "GTM_QUAD_211"]}          
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
          GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13} 
          GTM_QUAD_109  {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
          GTM_QUAD_110  {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
          GTM_QUAD_111  {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
          GTM_QUAD_112  {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
          GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1} 
          GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3} 
          GTM_QUAD_202  {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
          GTM_QUAD_203  {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
          GTM_QUAD_204  {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
          GTM_QUAD_205  {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
          GTM_QUAD_206  {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
          GTM_QUAD_207  {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
          GTM_QUAD_208  {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
          GTM_QUAD_209  {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
          GTM_QUAD_210  {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
          GTM_QUAD_211  {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}
          GTM_QUAD_212  {GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21}
                    }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
          GTYP_QUAD_106 GTYP_QUAD_X0Y6 
          GTM_QUAD_109  GTM_QUAD_X0Y7
          GTM_QUAD_110  GTM_QUAD_X0Y8
          GTM_QUAD_111  GTM_QUAD_X0Y9
          GTM_QUAD_112  GTM_QUAD_X0Y10
          GTYP_QUAD_200 GTYP_QUAD_X1Y0 
          GTYP_QUAD_201 GTYP_QUAD_X1Y1 
          GTM_QUAD_202  GTM_QUAD_X1Y0
          GTM_QUAD_203  GTM_QUAD_X1Y1
          GTM_QUAD_204  GTM_QUAD_X1Y2
          GTM_QUAD_205  GTM_QUAD_X1Y3
          GTM_QUAD_206  GTM_QUAD_X1Y4
          GTM_QUAD_207  GTM_QUAD_X1Y5
          GTM_QUAD_208  GTM_QUAD_X1Y6
          GTM_QUAD_209  GTM_QUAD_X1Y7
          GTM_QUAD_210  GTM_QUAD_X1Y8
          GTM_QUAD_211  GTM_QUAD_X1Y9
          GTM_QUAD_212  GTM_QUAD_X1Y10}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VP1552
#
proc xcvp1552 {} {
  log "using xcvp1552 procs"
  xcvp1502
  
}

########################################################################################################################
#  VP1702
#
proc xcvp1702 {} {
  log "using xcvp1702 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  proc get_left {pkg} {
    switch $pkg {
      vsva3340 -
      vsva5601 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118]

      }
      default {
        return [list]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva3340 -
      vsva5601 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218]
      }
      default {
        return [list]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva3340 -
      vsva5601 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_109 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110" "GTM_QUAD_112"]}
          GTM_QUAD_112 { return [list "GTM_QUAD_111"]}
          GTM_QUAD_115 { return [list "GTM_QUAD_116"]}
          GTM_QUAD_116 { return [list "GTM_QUAD_105" "GTM_QUAD_117"]}
          GTM_QUAD_117 { return [list "GTM_QUAD_116" "GTM_QUAD_118"]}
          GTM_QUAD_118 { return [list "GTM_QUAD_117"]}
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_213 { return [list "GTM_QUAD_214"]} 
          GTM_QUAD_214 { return [list "GTM_QUAD_213" "GTM_QUAD_215"]} 
          GTM_QUAD_215 { return [list "GTM_QUAD_214" "GTM_QUAD_216"]} 
          GTM_QUAD_216 { return [list "GTM_QUAD_215" "GTM_QUAD_217"]}
          GTM_QUAD_217 { return [list "GTM_QUAD_216" "GTM_QUAD_218"]}
          GTM_QUAD_218 { return [list "GTM_QUAD_208"]} 
               
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
        GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13}
        GTM_QUAD_109 {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
        GTM_QUAD_110 {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
        GTM_QUAD_111 {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
        GTM_QUAD_112 {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
        GTM_QUAD_115 {GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27}
        GTM_QUAD_116 {GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29}
        GTM_QUAD_117 {GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31}
        GTM_QUAD_118 {GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33}
        GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1}
        GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3}
        GTM_QUAD_202 {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
        GTM_QUAD_203 {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
        GTM_QUAD_204 {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
        GTM_QUAD_205 {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
        GTM_QUAD_206 {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
        GTM_QUAD_207 {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
        GTM_QUAD_208 {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
        GTM_QUAD_209 {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
        GTM_QUAD_213 {GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23}
        GTM_QUAD_214 {GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25}
        GTM_QUAD_215 {GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27}
        GTM_QUAD_216 {GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29}
        GTM_QUAD_217 {GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31}
        GTM_QUAD_218 {GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33} 
    }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
          GTYP_QUAD_106 GTYP_QUAD_X0Y6
          GTYP_QUAD_200 GTYP_QUAD_X1Y0
          GTYP_QUAD_201 GTYP_QUAD_X1Y1
          GTM_QUAD_109 GTM_QUAD_X0Y7
          GTM_QUAD_110 GTM_QUAD_X0Y8
          GTM_QUAD_111 GTM_QUAD_X0Y9
          GTM_QUAD_112 GTM_QUAD_X0Y10
          GTM_QUAD_115 GTM_QUAD_X0Y13
          GTM_QUAD_116 GTM_QUAD_X0Y14
          GTM_QUAD_117 GTM_QUAD_X0Y15
          GTM_QUAD_118 GTM_QUAD_X0Y16
          GTM_QUAD_202 GTM_QUAD_X1Y0
          GTM_QUAD_203 GTM_QUAD_X1Y1
          GTM_QUAD_204 GTM_QUAD_X1Y2
          GTM_QUAD_205 GTM_QUAD_X1Y3
          GTM_QUAD_206 GTM_QUAD_X1Y4
          GTM_QUAD_207 GTM_QUAD_X1Y5
          GTM_QUAD_208 GTM_QUAD_X1Y6
          GTM_QUAD_209 GTM_QUAD_X1Y7
          GTM_QUAD_213 GTM_QUAD_X1Y11
          GTM_QUAD_214 GTM_QUAD_X1Y12
          GTM_QUAD_215 GTM_QUAD_X1Y13
          GTM_QUAD_216 GTM_QUAD_X1Y14
          GTM_QUAD_217 GTM_QUAD_X1Y15
          GTM_QUAD_218 GTM_QUAD_X1Y16}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VP1802
#
proc xcvp1802 {} {
  log "using xcvp1802 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  
  proc get_left {pkg} {
    switch $pkg {
      lsvc4072 -
      vsva5601 {
        return [list "GTYP_QUAD_106" "GTM_QUAD_109" "GTM_QUAD_110" "GTM_QUAD_111" "GTM_QUAD_112" "GTM_QUAD_115" "GTM_QUAD_116" "GTM_QUAD_117" "GTM_QUAD_118" "GTM_QUAD_121" "GTM_QUAD_122" "GTM_QUAD_123" "GTM_QUAD_124"] 
      }
      default {
        return [list]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsvc4072 -
      vsva5601 {
        return [list "GTYP_QUAD_200" "GTYP_QUAD_201" "GTM_QUAD_202" "GTM_QUAD_203" "GTM_QUAD_204" "GTM_QUAD_205" "GTM_QUAD_206" "GTM_QUAD_207" "GTM_QUAD_208" "GTM_QUAD_209" "GTM_QUAD_210" "GTM_QUAD_211" "GTM_QUAD_212" "GTM_QUAD_213" "GTM_QUAD_214" "GTM_QUAD_215" "GTM_QUAD_216" "GTM_QUAD_217" "GTM_QUAD_218" "GTM_QUAD_219" "GTM_QUAD_220" "GTM_QUAD_221" "GTM_QUAD_222" "GTM_QUAD_223" "GTM_QUAD_224"]
      }
      default {
        return [list]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsvc4072 -
      vsva5601 {
        switch $quad {
          GTYP_QUAD_105 { return [list "GTYP_QUAD_106"]}
          GTYP_QUAD_106 { return [list "GTYP_QUAD_105"]} 
          GTM_QUAD_109 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110" "GTM_QUAD_112"]}
          GTM_QUAD_112 { return [list "GTM_QUAD_111"]}
          GTM_QUAD_115 { return [list "GTM_QUAD_116"]}
          GTM_QUAD_116 { return [list "GTM_QUAD_115" "GTM_QUAD_117"]}
          GTM_QUAD_117 { return [list "GTM_QUAD_116" "GTM_QUAD_118"]}
          GTM_QUAD_118 { return [list "GTM_QUAD_117"]}
          GTM_QUAD_121 { return [list "GTM_QUAD_122"]}
          GTM_QUAD_122 { return [list "GTM_QUAD_123" "GTM_QUAD_124"]}
          GTM_QUAD_123 { return [list "GTM_QUAD_122" "GTM_QUAD_124"]}
          GTM_QUAD_124 { return [list "GTM_QUAD_123"]}
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTM_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTM_QUAD_212 { return [list "GTM_QUAD_211"]}
          GTM_QUAD_213 { return [list "GTM_QUAD_214"]} 
          GTM_QUAD_214 { return [list "GTM_QUAD_213" "GTM_QUAD_215"]} 
          GTM_QUAD_215 { return [list "GTM_QUAD_214" "GTM_QUAD_216"]} 
          GTM_QUAD_216 { return [list "GTM_QUAD_215" "GTM_QUAD_217"]} 
          GTM_QUAD_217 { return [list "GTM_QUAD_216" "GTM_QUAD_218"]} 
          GTM_QUAD_218 { return [list "GTM_QUAD_217"]} 
          GTM_QUAD_219 { return [list "GTM_QUAD_220"]} 
          GTM_QUAD_220 { return [list "GTM_QUAD_219" "GTM_QUAD_221"]} 
          GTM_QUAD_221 { return [list "GTM_QUAD_220" "GTM_QUAD_222"]} 
          GTM_QUAD_222 { return [list "GTM_QUAD_221" "GTM_QUAD_223"]} 
          GTM_QUAD_223 { return [list "GTM_QUAD_222" "GTM_QUAD_224"]} 
          GTM_QUAD_224 { return [list "GTM_QUAD_223"]}           
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
          GTYP_QUAD_105 {GTYP_REFCLK_X0Y10 GTYP_REFCLK_X0Y11}
          GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13} 
          GTM_QUAD_109  {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
          GTM_QUAD_110  {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
          GTM_QUAD_111  {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
          GTM_QUAD_112  {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
          GTM_QUAD_115  {GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27}
          GTM_QUAD_116  {GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29}
          GTM_QUAD_117  {GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31}
          GTM_QUAD_118  {GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33}
          GTM_QUAD_121  {GTM_REFCLK_X0Y38 GTM_REFCLK_X0Y39}
          GTM_QUAD_122  {GTM_REFCLK_X0Y40 GTM_REFCLK_X0Y41}
          GTM_QUAD_123  {GTM_REFCLK_X0Y42 GTM_REFCLK_X0Y43}
          GTM_QUAD_124  {GTM_REFCLK_X0Y44 GTM_REFCLK_X0Y45}
          GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1} 
          GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3} 
          GTM_QUAD_202  {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
          GTM_QUAD_203  {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
          GTM_QUAD_204  {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
          GTM_QUAD_205  {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
          GTM_QUAD_206  {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
          GTM_QUAD_207  {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
          GTM_QUAD_208  {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
          GTM_QUAD_209  {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
          GTM_QUAD_210  {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
          GTM_QUAD_211  {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}
          GTM_QUAD_212  {GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21}
          GTM_QUAD_213  {GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23}
          GTM_QUAD_214  {GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25}
          GTM_QUAD_215  {GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27}
          GTM_QUAD_216  {GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29}
          GTM_QUAD_217  {GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31}
          GTM_QUAD_218  {GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33}
          GTM_QUAD_219  {GTM_REFCLK_X1Y34 GTM_REFCLK_X1Y35}
          GTM_QUAD_220  {GTM_REFCLK_X1Y36 GTM_REFCLK_X1Y37}
          GTM_QUAD_221  {GTM_REFCLK_X1Y38 GTM_REFCLK_X1Y39}
          GTM_QUAD_222  {GTM_REFCLK_X1Y40 GTM_REFCLK_X1Y41}
          GTM_QUAD_223  {GTM_REFCLK_X1Y42 GTM_REFCLK_X1Y43}
          GTM_QUAD_224  {GTM_REFCLK_X1Y44 GTM_REFCLK_X1Y45}
                    }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
          GTYP_QUAD_105 GTYP_QUAD_X0Y5
          GTYP_QUAD_106 GTYP_QUAD_X0Y6 
          GTM_QUAD_109  GTM_QUAD_X0Y7
          GTM_QUAD_110  GTM_QUAD_X0Y8
          GTM_QUAD_111  GTM_QUAD_X0Y9
          GTM_QUAD_112  GTM_QUAD_X0Y10
          GTM_QUAD_115  GTM_QUAD_X0Y13                
          GTM_QUAD_116  GTM_QUAD_X0Y14
          GTM_QUAD_117  GTM_QUAD_X0Y15
          GTM_QUAD_118  GTM_QUAD_X0Y16
          GTM_QUAD_121  GTM_QUAD_X0Y19
          GTM_QUAD_122  GTM_QUAD_X0Y20
          GTM_QUAD_123  GTM_QUAD_X0Y21
          GTM_QUAD_124  GTM_QUAD_X0Y22
          GTYP_QUAD_200 GTYP_QUAD_X1Y0 
          GTYP_QUAD_201 GTYP_QUAD_X1Y1 
          GTM_QUAD_202  GTM_QUAD_X1Y0
          GTM_QUAD_203  GTM_QUAD_X1Y1
          GTM_QUAD_204  GTM_QUAD_X1Y2
          GTM_QUAD_205  GTM_QUAD_X1Y3
          GTM_QUAD_206  GTM_QUAD_X1Y4
          GTM_QUAD_207  GTM_QUAD_X1Y5
          GTM_QUAD_208  GTM_QUAD_X1Y6
          GTM_QUAD_209  GTM_QUAD_X1Y7
          GTM_QUAD_210  GTM_QUAD_X1Y8
          GTM_QUAD_211  GTM_QUAD_X1Y9
          GTM_QUAD_212  GTM_QUAD_X1Y10
          GTM_QUAD_213  GTM_QUAD_X1Y11
          GTM_QUAD_214  GTM_QUAD_X1Y12
          GTM_QUAD_215  GTM_QUAD_X1Y13
          GTM_QUAD_216  GTM_QUAD_X1Y14
          GTM_QUAD_217  GTM_QUAD_X1Y15
          GTM_QUAD_218  GTM_QUAD_X1Y16
          GTM_QUAD_219  GTM_QUAD_X1Y17
          GTM_QUAD_220  GTM_QUAD_X1Y18
          GTM_QUAD_221  GTM_QUAD_X1Y19
          GTM_QUAD_222  GTM_QUAD_X1Y20
          GTM_QUAD_223  GTM_QUAD_X1Y21
          GTM_QUAD_224  GTM_QUAD_X1Y22}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  VP1802
#
proc xcvp2502 {} {
  log "using xcvp2502 procs"
  
  proc get_gt_types {} {
    return [list "GTYP" "GTM"]
  }
  
  
  proc get_left {pkg} {
    switch $pkg {
      vsvb3340 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
      default {
        return [list]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvb3340 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
      default {
        return [list]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvb3340 {
        switch $quad {
          GTYP_QUAD_106 { return [list]} 
          GTM_QUAD_109 { return [list "GTM_QUAD_110"]}
          GTM_QUAD_110 { return [list "GTM_QUAD_109" "GTM_QUAD_111"]}
          GTM_QUAD_111 { return [list "GTM_QUAD_110" "GTM_QUAD_112"]}
          GTM_QUAD_112 { return [list "GTM_QUAD_111"]}
          GTYP_QUAD_200 { return [list "GTYP_QUAD_201"]} 
          GTYP_QUAD_201 { return [list "GTYP_QUAD_200"]} 
          GTM_QUAD_202 { return [list "GTM_QUAD_203"]} 
          GTM_QUAD_203 { return [list "GTM_QUAD_202" "GTM_QUAD_204"]} 
          GTM_QUAD_204 { return [list "GTM_QUAD_203" "GTM_QUAD_205"]} 
          GTM_QUAD_205 { return [list "GTM_QUAD_204" "GTM_QUAD_206"]} 
          GTM_QUAD_206 { return [list "GTM_QUAD_205"]} 
          GTM_QUAD_207 { return [list "GTM_QUAD_208"]} 
          GTM_QUAD_208 { return [list "GTM_QUAD_207" "GTM_QUAD_209"]} 
          GTM_QUAD_209 { return [list "GTM_QUAD_208" "GTM_QUAD_210"]} 
          GTM_QUAD_210 { return [list "GTM_QUAD_209" "GTM_QUAD_211"]} 
          GTM_QUAD_211 { return [list "GTM_QUAD_210" "GTM_QUAD_212"]} 
          GTM_QUAD_212 { return [list "GTM_QUAD_211"]}        
        }  
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { 
          GTYP_QUAD_106 {GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13} 
          GTM_QUAD_109  {GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15}
          GTM_QUAD_110  {GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17}
          GTM_QUAD_111  {GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19}
          GTM_QUAD_112  {GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21}
          GTYP_QUAD_200 {GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1} 
          GTYP_QUAD_201 {GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3} 
          GTM_QUAD_202  {GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1}
          GTM_QUAD_203  {GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3}
          GTM_QUAD_204  {GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5}
          GTM_QUAD_205  {GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7}
          GTM_QUAD_206  {GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9}
          GTM_QUAD_207  {GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11}
          GTM_QUAD_208  {GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13}
          GTM_QUAD_209  {GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15}
          GTM_QUAD_210  {GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17}
          GTM_QUAD_211  {GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19}
          GTM_QUAD_212  {GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21}
        }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { 
        GTYP_QUAD_106 GTYP_QUAD_X0Y6
        GTM_QUAD_109 GTM_QUAD_X0Y7
        GTM_QUAD_110 GTM_QUAD_X0Y8
        GTM_QUAD_111 GTM_QUAD_X0Y9
        GTM_QUAD_112 GTM_QUAD_X0Y10
        GTYP_QUAD_200 GTYP_QUAD_X1Y0
        GTYP_QUAD_201 GTYP_QUAD_X1Y1
        GTM_QUAD_202 GTM_QUAD_X1Y0
        GTM_QUAD_203 GTM_QUAD_X1Y1
        GTM_QUAD_204 GTM_QUAD_X1Y2
        GTM_QUAD_205 GTM_QUAD_X1Y3
        GTM_QUAD_206 GTM_QUAD_X1Y4
        GTM_QUAD_207 GTM_QUAD_X1Y5
        GTM_QUAD_208 GTM_QUAD_X1Y6
        GTM_QUAD_209 GTM_QUAD_X1Y7
        GTM_QUAD_210 GTM_QUAD_X1Y8
        GTM_QUAD_211 GTM_QUAD_X1Y9
        GTM_QUAD_212 GTM_QUAD_X1Y10}

    return [dict get $gt_dict $q]
  }

}

proc xcvp2802 {} {
  log "using xcvp2802 procs"
  xcvp1802
}

########################################################################################################################
#  XQVC1902
#
proc xqvc1902 {} {
  log "using xqvc1902 procs"
  
  proc get_gt_types {} {
    return [list "GTY"]
  }
  
  
  proc get_left {pkg} {
    switch $pkg {
      vsra2197 -
      vsvd2197 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      vsva1760 -
      vsrd1760 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      vira1596 {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      default {
        return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_105" "GTY_QUAD_106"]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsra2197 -
      vsvd2197 {
        return [list "GTY_QUAD_200" "GTY_QUAD_201" "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_205" "GTY_QUAD_206"]
      }
      vsva1760 -
      vsrd1760 {
        return [list "GTY_QUAD_203" "GTY_QUAD_204"]
      }
      vira1596
      {
        return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_205"]
      }
      default {
        return [list "GTY_QUAD_203" "GTY_QUAD_204"]
      }
    }
  }
  
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsra2197 -
      vsvd2197 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_200 { return [list "GTY_QUAD_201" "GTY_QUAD_202"] } 
          GTY_QUAD_201 { return [list "GTY_QUAD_200" "GTY_QUAD_202" "GTY_QUAD_203"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_200" "GTY_QUAD_201" "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_201" "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205" "GTY_QUAD_206"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204" "GTY_QUAD_206"] } 
          GTY_QUAD_206 { return [list "GTY_QUAD_204" "GTY_QUAD_205"] } 
        }  
      }
      vsva1760 -
      vsrd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_204"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_203"] } 
        }  
      }
      vira1596
      {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
        }  
      }
      default {
        switch $quad {
          GTY_QUAD_103 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_104 { return [list "GTY_QUAD_103" "GTY_QUAD_105" "GTY_QUAD_106"] } 
          GTY_QUAD_105 { return [list "GTY_QUAD_103" "GTY_QUAD_104" "GTY_QUAD_106"] } 
          GTY_QUAD_106 { return [list "GTY_QUAD_104" "GTY_QUAD_105"] } 
          GTY_QUAD_202 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
          GTY_QUAD_203 { return [list "GTY_QUAD_202" "GTY_QUAD_204" "GTY_QUAD_205"] } 
          GTY_QUAD_204 { return [list "GTY_QUAD_202" "GTY_QUAD_203" "GTY_QUAD_205"] } 
          GTY_QUAD_205 { return [list "GTY_QUAD_203" "GTY_QUAD_204"] } 
        }  
      }
    }
    
  }
  
  
  proc get_reflocs {q} {
    set refclk_dict { GTY_QUAD_103 {GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7} 
                    GTY_QUAD_104 {GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9}
                    GTY_QUAD_105 {GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11}
                    GTY_QUAD_106 {GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13}
                    GTY_QUAD_200 {GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1}
                    GTY_QUAD_201 {GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3}
                    GTY_QUAD_202 {GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5}
                    GTY_QUAD_203 {GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7}
                    GTY_QUAD_204 {GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9}
                    GTY_QUAD_205 {GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11}
                    GTY_QUAD_206 {GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13} }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { GTY_QUAD_103 GTY_QUAD_X0Y3
                GTY_QUAD_104 GTY_QUAD_X0Y4
                GTY_QUAD_105 GTY_QUAD_X0Y5
                GTY_QUAD_106 GTY_QUAD_X0Y6
                GTY_QUAD_200 GTY_QUAD_X1Y0
                GTY_QUAD_201 GTY_QUAD_X1Y1
                GTY_QUAD_202 GTY_QUAD_X1Y2
                GTY_QUAD_203 GTY_QUAD_X1Y3
                GTY_QUAD_204 GTY_QUAD_X1Y4
                GTY_QUAD_205 GTY_QUAD_X1Y5
                GTY_QUAD_206 GTY_QUAD_X1Y6}

    return [dict get $gt_dict $q]
  }

}

########################################################################################################################
#  XQRVC1802
#
proc xqrvc1902 {} {
  log "using xqrvc1902 procs"
  xqvc1902 
}

########################################################################################################################
#  XQVC1802
#
proc xqvm1802 {} {
  log "using xqvc1802 procs"
  xqvc1902 
}

# xcv65-vsvd1760-2MP-e-L xcv70-vsvh1760-2LHP-e-S-es1 xcvc1502-nsvg1369-1LHP-i-L xcvc1502-vsva1596-1LHP-i-L xcvc1502-vsva2197-1LHP-i-L xcvc1702-nsvg1369-1LHP-i-L xcvc1702-vsva1596-1LHP-i-L xcvc1702-vsva2197-1LHP-i-L xcvc1802-viva1596-1LHP-i-L xcvc1802-vsva2197-1LHP-i-L xcvc1802-vsvd1760-1LHP-i-L xcvc1902-viva1596-1LHP-i-L xcvc1902-vsva2197-1LHP-i-L xcvc1902-vsvd1760-1LHP-i-L xcvc2802-nsvh1369-1LHP-i-L-es1 xcvc2802-vsvh1760-1LHP-i-L-es1 xcve1752-nsvg1369-1LHP-i-L xcve1752-vsva1596-1LHP-i-L xcve1752-vsva2197-1LHP-i-L xcve2302-sfva784-1LHP-i-L-es1 xcve2802-nsvh1369-1LHP-i-L-es1 xcve2802-vsvh1760-1LHP-i-L-es1 xcvh1522-vsva3697-1LP-e-S-es1 xcvh1542-vsva3697-1LP-e-S-es1 xcvh1582-vsva3697-1LP-e-S-es1 xcvh1742-lsva4737-1LP-e-S-es1 xcvh1782-lsva4737-1LP-e-S-es1 xcvm1102-sfva784-1LHP-i-L-es1 xcvm1302-nbvb1024-1LHP-i-L xcvm1302-nsvf1369-1LHP-i-L xcvm1302-vfvc1596-1LHP-i-L xcvm1302-vsvd1760-1LHP-i-L xcvm1402-nbvb1024-1LHP-i-L xcvm1402-nsvf1369-1LHP-i-L xcvm1402-vfvc1596-1LHP-i-L xcvm1402-vsvd1760-1LHP-i-L xcvm1502-nfvb1369-1LHP-i-L xcvm1502-vfvc1760-1LHP-i-L xcvm1502-vsva2197-1LHP-i-L xcvm1802-vfvc1760-1LHP-i-L xcvm1802-vsva2197-1LHP-i-L xcvm1802-vsvd1760-1LHP-i-L xcvn3716-vsvb2197-1LHP-i-L-es1 xcvp1002-nfvi1369-1LHP-i-L xcvp1052-nfvi1369-1LHP-i-L xcvp1102-vsva2785-1LHP-i-L xcvp1202-vsva2785-1LHP-i-L-es1 xcvp1402-vsva2785-1LHP-i-L xcvp1402-vsva3340-1LHP-i-L xcvp1402-vsvd2197-1LHP-i-L xcvp1502-vsva2785-1LHP-i-L-es1 xcvp1502-vsva3340-1LHP-i-L-es1 xcvp1552-vsva2785-1LHP-i-L-es1 xcvp1702-vsva3340-1LHP-i-L-es1 xcvp1702-vsva5601-1LHP-i-L xcvp1802-lsvc4072-1LHP-i-L-es1 xcvp1802-vsva5601-1LHP-i-L xcvp2502-vsvb3340-1LHP-i-L xcvp2802-vsva5601-1LHP-i-L xqrvc1902-vsra2197-1MM-b-S xqvc1902-vira1596-1LHP-i-S xqvc1902-vsra2197-1LHP-i-S xqvc1902-vsrd1760-1LHP-i-S xqvm1802-vsra2197-1LHP-i-S xqvm1802-vsrd1760-1LHP-i-S



