#
#  This file contains factory procs to create the correct location finders for the different devices
#  proc's inside proc's are not actually nested- they are created in the general namespace
#
proc xcvc1802 {} { xcvc1902 }
proc xcvm1802 {} { xcvc1902 }

proc xcvc1902 {} {
  log "using xcvc1902 procs"
  
  proc get_left {pkg} {
    switch $pkg {
      vsva2197 -
      vsvd2197 {
        return [list "Quad_103" "Quad_104" "Quad_105" "Quad_106"]
      }
      vsva1760 -
      vsvd1760 {
        return [list "Quad_103" "Quad_104" "Quad_105" "Quad_106"]
      }
      default {
        return [list "Quad_103" "Quad_104" "Quad_105" "Quad_106"]
      }
      
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2197 -
      vsvd2197 {
        return [list "Quad_200" "Quad_201" "Quad_202" "Quad_203" "Quad_204" "Quad_205" "Quad_206"]
      }
      vsva1760 -
      vsvd1760 {
        return [list "Quad_203" "Quad_204"]
      }
      viva1596
      {
        return [list "Quad_202" "Quad_203" "Quad_204" "Quad_205"]
      }
      default {
        return [list "Quad_203" "Quad_204"]
      }
    }
  }

  proc get_reflocs {q} {
    set refclk_dict { Quad_103 {X0Y6 X0Y7} 
                    Quad_104 {X0Y8 X0Y9}
                    Quad_105 {X0Y10 X0Y11}
                    Quad_106 {X0Y12 X0Y13}
                    Quad_200 {X1Y0 X1Y1}
                    Quad_201 {X1Y2 X1Y3}
                    Quad_202 {X1Y4 X1Y5}
                    Quad_203 {X1Y6 X1Y7}
                    Quad_204 {X1Y8 X1Y9}
                    Quad_205 {X1Y10 X1Y11}
                    Quad_206 {X1Y12 X1Y13} }
    return [dict get $refclk_dict $q]
  }

  proc get_gtloc {q} {
    set gt_dict { Quad_103 X0Y3
                Quad_104 X0Y4
                Quad_105 X0Y5
                Quad_106 X0Y6
                Quad_200 X1Y0
                Quad_201 X1Y1
                Quad_202 X1Y2
                Quad_203 X1Y3
                Quad_204 X1Y4
                Quad_205 X1Y5
                Quad_206 X1Y6}

    return [dict get $gt_dict $q]
  }

}

