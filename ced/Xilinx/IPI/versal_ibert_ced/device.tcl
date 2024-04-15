#######################################################################################################
# xcv70
#######################################################################################################
proc xcv70 {} {
  log "using xcv70 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvh1760 {
        return [list ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvh1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvh1760 {
        switch $quad {
        }
      }
    }
  }
}

#######################################################################################################
# xcv80
#######################################################################################################
proc xcv80 {} {
  log "using xcv80 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTYP_QUAD_200 GTYP_QUAD_X1Y0
      GTM_QUAD_209 GTM_QUAD_X1Y7
      GTM_QUAD_210 GTM_QUAD_X1Y8
      GTYP_QUAD_213 GTYP_QUAD_X1Y7
      GTYP_QUAD_214 GTYP_QUAD_X1Y8
      GTYP_QUAD_218 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTYP_QUAD_213 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_214 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_218 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTM_QUAD_111 GTM_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_200 GTM_QUAD_209 GTM_QUAD_210 GTYP_QUAD_213 GTYP_QUAD_214 GTYP_QUAD_218]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTM_QUAD_111 { return [list GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_111] }
          GTM_QUAD_209 { return [list GTM_QUAD_210] }
          GTM_QUAD_210 { return [list GTM_QUAD_209] }
          GTYP_QUAD_200 { return [list ] }
          GTYP_QUAD_213 { return [list GTYP_QUAD_214] }
          GTYP_QUAD_214 { return [list GTYP_QUAD_213] }
          GTYP_QUAD_218 { return [list ] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc1502
#######################################################################################################
proc xcvc1502 {} {
  log "using xcvc1502 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
    }
    return [dict get $refclk_dict $q]
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
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203] }
          GTY_QUAD_203 { return [list GTY_QUAD_202] }
        }
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc1502_SE
#######################################################################################################
proc xcvc1502_SE {} {
  log "using xcvc1502_SE procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2197 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc1702
#######################################################################################################
proc xcvc1702 {} {
  log "using xcvc1702 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203] }
          GTY_QUAD_203 { return [list GTY_QUAD_202] }
        }
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc1802
#######################################################################################################
proc xcvc1802 {} {
  log "using xcvc1802 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      viva1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      viva1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsvd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      viva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc1902
#######################################################################################################
proc xcvc1902 {} {
  log "using xcvc1902 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      viva1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      viva1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsvd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      viva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc2602
#######################################################################################################
proc xcvc2602 {} {
  log "using xcvc2602 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_106]
      }
      vsvh1760 {
        return [list GTYP_QUAD_106]
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
      nsvh1369 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvc2802
#######################################################################################################
proc xcvc2802 {} {
  log "using xcvc2802 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_106]
      }
      vsvh1760 {
        return [list GTYP_QUAD_106]
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
      nsvh1369 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve1752
#######################################################################################################
proc xcve1752 {} {
  log "using xcve1752 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203] }
          GTY_QUAD_203 { return [list GTY_QUAD_202] }
        }
      }
      vsva1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve2002
#######################################################################################################
proc xcve2002 {} {
  log "using xcve2002 procs"

  proc get_gt_types {} {
    return [list ]
  }

  proc get_gtloc {q} {
    set gt_dict {
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      sbva484 {
        return [list ]
      }
      sbva625 {
        return [list ]
      }
      sfva784 {
        return [list ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      sbva484 {
        return [list ]
      }
      sbva625 {
        return [list ]
      }
      sfva784 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sbva484 {
        switch $quad {
        }
      }
      sbva625 {
        switch $quad {
        }
      }
      sfva784 {
        switch $quad {
        }
      }
    }
  }
}

#######################################################################################################
# xcve2102
#######################################################################################################
proc xcve2102 {} {
  log "using xcve2102 procs"

  proc get_gt_types {} {
    return [list ]
  }

  proc get_gtloc {q} {
    set gt_dict {
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      sbva484 {
        return [list ]
      }
      sbva625 {
        return [list ]
      }
      sfva784 {
        return [list ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      sbva484 {
        return [list ]
      }
      sbva625 {
        return [list ]
      }
      sfva784 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sbva484 {
        switch $quad {
        }
      }
      sbva625 {
        switch $quad {
        }
      }
      sfva784 {
        switch $quad {
        }
      }
    }
  }
}

#######################################################################################################
# xcve2202
#######################################################################################################
proc xcve2202 {} {
  log "using xcve2202 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_103 GTYP_QUAD_X0Y0
      GTYP_QUAD_104 GTYP_QUAD_X0Y1
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_104 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sfva784 {
        switch $quad {
          GTYP_QUAD_103 { return [list GTYP_QUAD_104] }
          GTYP_QUAD_104 { return [list GTYP_QUAD_103] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve2302
#######################################################################################################
proc xcve2302 {} {
  log "using xcve2302 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_103 GTYP_QUAD_X0Y0
      GTYP_QUAD_104 GTYP_QUAD_X0Y1
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_104 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sfva784 {
        switch $quad {
          GTYP_QUAD_103 { return [list GTYP_QUAD_104] }
          GTYP_QUAD_104 { return [list GTYP_QUAD_103] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve2602
#######################################################################################################
proc xcve2602 {} {
  log "using xcve2602 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_106]
      }
      vsvh1760 {
        return [list GTYP_QUAD_106]
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
      nsvh1369 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve2602_SE
#######################################################################################################
proc xcve2602_SE {} {
  log "using xcve2602_SE procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvh1760 {
        return [list GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvh1760 {
        return [list GTYP_QUAD_204 GTYP_QUAD_205 GTYP_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcve2802
#######################################################################################################
proc xcve2802 {} {
  log "using xcve2802 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_106]
      }
      vsvh1760 {
        return [list GTYP_QUAD_106]
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
      nsvh1369 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
      vsvh1760 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvh1522
#######################################################################################################
proc xcvh1522 {} {
  log "using xcvh1522 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_212 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_109 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_110 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_111 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_112 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
      GTYP_QUAD_207 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_208 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_209 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_210 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_211 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_212 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva3697 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvh1542
#######################################################################################################
proc xcvh1542 {} {
  log "using xcvh1542 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_212 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_109 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_110 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_111 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_112 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
      GTYP_QUAD_207 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_208 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_209 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_210 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_211 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_212 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
      vsva3697 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
      vsva3697 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
      vsva3697 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvh1582
#######################################################################################################
proc xcvh1582 {} {
  log "using xcvh1582 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_212 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_109 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_110 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_111 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_112 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
      GTYP_QUAD_207 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_208 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_209 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_210 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_211 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_212 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
      vsva3697 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
      vsva3697 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
      vsva3697 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvh1742
#######################################################################################################
proc xcvh1742 {} {
  log "using xcvh1742 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_218 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_115 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_116 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_117 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_118 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTYP_QUAD_213 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_214 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_215 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_216 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_217 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_218 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTYP_QUAD_115 GTYP_QUAD_116 GTYP_QUAD_117 GTYP_QUAD_118]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_115 { return [list GTYP_QUAD_116 GTYP_QUAD_117] }
          GTYP_QUAD_116 { return [list GTYP_QUAD_115 GTYP_QUAD_117 GTYP_QUAD_118] }
          GTYP_QUAD_117 { return [list GTYP_QUAD_115 GTYP_QUAD_116 GTYP_QUAD_118] }
          GTYP_QUAD_118 { return [list GTYP_QUAD_116 GTYP_QUAD_117] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_213 { return [list GTYP_QUAD_214 GTYP_QUAD_215] }
          GTYP_QUAD_214 { return [list GTYP_QUAD_213 GTYP_QUAD_215 GTYP_QUAD_216] }
          GTYP_QUAD_215 { return [list GTYP_QUAD_213 GTYP_QUAD_214 GTYP_QUAD_216 GTYP_QUAD_217] }
          GTYP_QUAD_216 { return [list GTYP_QUAD_214 GTYP_QUAD_215 GTYP_QUAD_217 GTYP_QUAD_218] }
          GTYP_QUAD_217 { return [list GTYP_QUAD_215 GTYP_QUAD_216 GTYP_QUAD_218] }
          GTYP_QUAD_218 { return [list GTYP_QUAD_216 GTYP_QUAD_217] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvh1782
#######################################################################################################
proc xcvh1782 {} {
  log "using xcvh1782 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_218 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_115 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_116 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_117 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_118 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTYP_QUAD_213 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_214 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_215 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_216 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_217 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_218 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsva4737 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTYP_QUAD_115 GTYP_QUAD_116 GTYP_QUAD_117 GTYP_QUAD_118]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsva4737 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_115 { return [list GTYP_QUAD_116 GTYP_QUAD_117] }
          GTYP_QUAD_116 { return [list GTYP_QUAD_115 GTYP_QUAD_117 GTYP_QUAD_118] }
          GTYP_QUAD_117 { return [list GTYP_QUAD_115 GTYP_QUAD_116 GTYP_QUAD_118] }
          GTYP_QUAD_118 { return [list GTYP_QUAD_116 GTYP_QUAD_117] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_213 { return [list GTYP_QUAD_214 GTYP_QUAD_215] }
          GTYP_QUAD_214 { return [list GTYP_QUAD_213 GTYP_QUAD_215 GTYP_QUAD_216] }
          GTYP_QUAD_215 { return [list GTYP_QUAD_213 GTYP_QUAD_214 GTYP_QUAD_216 GTYP_QUAD_217] }
          GTYP_QUAD_216 { return [list GTYP_QUAD_214 GTYP_QUAD_215 GTYP_QUAD_217 GTYP_QUAD_218] }
          GTYP_QUAD_217 { return [list GTYP_QUAD_215 GTYP_QUAD_216 GTYP_QUAD_218] }
          GTYP_QUAD_218 { return [list GTYP_QUAD_216 GTYP_QUAD_217] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1102
#######################################################################################################
proc xcvm1102 {} {
  log "using xcvm1102 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_103 GTYP_QUAD_X0Y0
      GTYP_QUAD_104 GTYP_QUAD_X0Y1
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_104 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
    }
    return [dict get $refclk_dict $q]
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
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      sfva784 {
        switch $quad {
          GTYP_QUAD_103 { return [list GTYP_QUAD_104] }
          GTYP_QUAD_104 { return [list GTYP_QUAD_103] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1302
#######################################################################################################
proc xcvm1302 {} {
  log "using xcvm1302 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_108 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nsvf1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104]
      }
      vfvc1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTY_QUAD_108]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list ]
      }
      nsvf1369 {
        return [list ]
      }
      vfvc1596 {
        return [list ]
      }
      vsvd1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nbvb1024 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
      nsvf1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104] }
          GTY_QUAD_104 { return [list GTY_QUAD_103] }
        }
      }
      vfvc1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107 GTY_QUAD_108] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_108] }
          GTY_QUAD_108 { return [list GTY_QUAD_106 GTY_QUAD_107] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1402
#######################################################################################################
proc xcvm1402 {} {
  log "using xcvm1402 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_108 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      nsvf1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104]
      }
      vfvc1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTY_QUAD_108]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nbvb1024 {
        return [list ]
      }
      nsvf1369 {
        return [list ]
      }
      vfvc1596 {
        return [list ]
      }
      vsvd1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nbvb1024 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
      nsvf1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104] }
          GTY_QUAD_104 { return [list GTY_QUAD_103] }
        }
      }
      vfvc1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107 GTY_QUAD_108] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_108] }
          GTY_QUAD_108 { return [list GTY_QUAD_106 GTY_QUAD_107] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1402_SE
#######################################################################################################
proc xcvm1402_SE {} {
  log "using xcvm1402_SE procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_108 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvc1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTY_QUAD_108]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvc1596 {
        return [list ]
      }
      vsvd1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvc1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107 GTY_QUAD_108] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_108] }
          GTY_QUAD_108 { return [list GTY_QUAD_106 GTY_QUAD_107] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1502
#######################################################################################################
proc xcvm1502 {} {
  log "using xcvm1502 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nfvb1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vfvc1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nfvb1369 {
        return [list ]
      }
      vfvc1760 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nfvb1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
      vfvc1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1802
#######################################################################################################
proc xcvm1802 {} {
  log "using xcvm1802 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvc1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvc1760 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsvd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvc1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm1802_SE
#######################################################################################################
proc xcvm1802_SE {} {
  log "using xcvm1802_SE procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsvd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsvd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsvd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm2202
#######################################################################################################
proc xcvm2202 {} {
  log "using xcvm2202 procs"

  proc get_gt_types {} {
    return [list GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y4
      GTYP_QUAD_204 GTYP_QUAD_X1Y2
      GTYP_QUAD_205 GTYP_QUAD_X1Y3
      GTYP_QUAD_206 GTYP_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y8 GTYP_REFCLK_X0Y9 }
      GTYP_QUAD_204 { GTYP_REFCLK_X1Y4 GTYP_REFCLK_X1Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_X1Y6 GTYP_REFCLK_X1Y7 }
      GTYP_QUAD_206 { GTYP_REFCLK_X1Y8 GTYP_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsvh1369 {
        return [list GTYP_QUAD_204 GTYP_QUAD_205 GTYP_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsvh1369 {
        switch $quad {
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_205 GTYP_QUAD_206] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_204 GTYP_QUAD_206] }
          GTYP_QUAD_206 { return [list GTYP_QUAD_204 GTYP_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm2302
#######################################################################################################
proc xcvm2302 {} {
  log "using xcvm2302 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_102 GTYP_QUAD_X0Y0
      GTYP_QUAD_103 GTYP_QUAD_X0Y1
      GTM_QUAD_107 GTM_QUAD_X0Y7
      GTM_QUAD_108 GTM_QUAD_X0Y8
      GTM_QUAD_109 GTM_QUAD_X0Y9
      GTM_QUAD_202 GTM_QUAD_X1Y2
      GTM_QUAD_203 GTM_QUAD_X1Y3
      GTM_QUAD_204 GTM_QUAD_X1Y4
      GTM_QUAD_205 GTM_QUAD_X1Y5
      GTM_QUAD_206 GTM_QUAD_X1Y6
      GTM_QUAD_207 GTM_QUAD_X1Y7
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_102 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
      GTM_QUAD_107 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_108 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvf1760 {
        switch $quad {
          GTM_QUAD_107 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_107 GTM_QUAD_109] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvm2502
#######################################################################################################
proc xcvm2502 {} {
  log "using xcvm2502 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

  proc get_gtloc {q} {
    set gt_dict {
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvi1760 {
        return [list ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvi1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvi1760 {
        switch $quad {
        }
      }
    }
  }
}

#######################################################################################################
# xcvm2902
#######################################################################################################
proc xcvm2902 {} {
  log "using xcvm2902 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_102 GTYP_QUAD_X0Y0
      GTYP_QUAD_103 GTYP_QUAD_X0Y1
      GTM_QUAD_107 GTM_QUAD_X0Y7
      GTM_QUAD_108 GTM_QUAD_X0Y8
      GTM_QUAD_109 GTM_QUAD_X0Y9
      GTM_QUAD_202 GTM_QUAD_X1Y2
      GTM_QUAD_203 GTM_QUAD_X1Y3
      GTM_QUAD_204 GTM_QUAD_X1Y4
      GTM_QUAD_205 GTM_QUAD_X1Y5
      GTM_QUAD_206 GTM_QUAD_X1Y6
      GTM_QUAD_207 GTM_QUAD_X1Y7
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_102 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
      GTM_QUAD_107 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_108 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvf1760 {
        switch $quad {
          GTM_QUAD_107 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_107 GTM_QUAD_109] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvn3716
#######################################################################################################
proc xcvn3716 {} {
  log "using xcvn3716 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTM_QUAD_200 GTM_QUAD_X0Y0
      GTM_QUAD_201 GTM_QUAD_X0Y1
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTM_QUAD_200 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_201 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsvb2197 {
        return [list ]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsvb2197 {
        return [list GTM_QUAD_200 GTM_QUAD_201]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsvb2197 {
        switch $quad {
          GTM_QUAD_200 { return [list GTM_QUAD_201] }
          GTM_QUAD_201 { return [list GTM_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1002
#######################################################################################################
proc xcvp1002 {} {
  log "using xcvp1002 procs"

  proc get_gt_types {} {
    return [list GTY GTM]
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
      GTM_QUAD_207 GTM_QUAD_X1Y5
      GTY_QUAD_104 GTY_QUAD_X0Y1
      GTY_QUAD_106 GTY_QUAD_X0Y3
      GTY_QUAD_107 GTY_QUAD_X0Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTY_QUAD_103 GTY_QUAD_105]
      }
      vfvf1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104]
      }
      vsvc2021 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      vsvc2021 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nfvi1369 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTY_QUAD_103 { return [list GTY_QUAD_105] }
          GTY_QUAD_105 { return [list GTY_QUAD_103] }
        }
      }
      vfvf1760 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTY_QUAD_103 { return [list GTY_QUAD_104] }
          GTY_QUAD_104 { return [list GTY_QUAD_103] }
        }
      }
      vsvc2021 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1052
#######################################################################################################
proc xcvp1052 {} {
  log "using xcvp1052 procs"

  proc get_gt_types {} {
    return [list GTM GTY]
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
      GTM_QUAD_207 GTM_QUAD_X1Y5
      GTY_QUAD_104 GTY_QUAD_X0Y1
      GTY_QUAD_106 GTY_QUAD_X0Y3
      GTY_QUAD_107 GTY_QUAD_X0Y4
      GTM_QUAD_208 GTM_QUAD_X1Y6
      GTM_QUAD_209 GTM_QUAD_X1Y7
      GTM_QUAD_210 GTM_QUAD_X1Y8
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTM_QUAD_108 { GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTY_QUAD_103 GTY_QUAD_105 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110]
      }
      sbvj1369 {
        return [list GTY_QUAD_103 GTY_QUAD_105]
      }
      vfvf1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110]
      }
      vsvc2021 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nfvi1369 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      sbvj1369 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205]
      }
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      vsvc2021 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nfvi1369 {
        switch $quad {
          GTM_QUAD_108 { return [list GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_108 GTM_QUAD_110] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTY_QUAD_103 { return [list GTY_QUAD_105] }
          GTY_QUAD_105 { return [list GTY_QUAD_103] }
        }
      }
      sbvj1369 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTY_QUAD_103 { return [list GTY_QUAD_105] }
          GTY_QUAD_105 { return [list GTY_QUAD_103] }
        }
      }
      vfvf1760 {
        switch $quad {
          GTM_QUAD_108 { return [list GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_108 GTM_QUAD_110] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTY_QUAD_103 { return [list GTY_QUAD_104] }
          GTY_QUAD_104 { return [list GTY_QUAD_103] }
        }
      }
      vsvc2021 {
        switch $quad {
          GTM_QUAD_108 { return [list GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_108 GTM_QUAD_110] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1102
#######################################################################################################
proc xcvp1102 {} {
  log "using xcvp1102 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_102 GTYP_QUAD_X0Y0
      GTYP_QUAD_103 GTYP_QUAD_X0Y1
      GTM_QUAD_107 GTM_QUAD_X0Y7
      GTM_QUAD_108 GTM_QUAD_X0Y8
      GTM_QUAD_109 GTM_QUAD_X0Y9
      GTM_QUAD_202 GTM_QUAD_X1Y2
      GTM_QUAD_203 GTM_QUAD_X1Y3
      GTM_QUAD_204 GTM_QUAD_X1Y4
      GTM_QUAD_205 GTM_QUAD_X1Y5
      GTM_QUAD_206 GTM_QUAD_X1Y6
      GTM_QUAD_207 GTM_QUAD_X1Y7
      GTM_QUAD_104 GTM_QUAD_X0Y4
      GTM_QUAD_105 GTM_QUAD_X0Y5
      GTM_QUAD_106 GTM_QUAD_X0Y6
      GTM_QUAD_200 GTM_QUAD_X1Y0
      GTM_QUAD_201 GTM_QUAD_X1Y1
      GTM_QUAD_208 GTM_QUAD_X1Y8
      GTM_QUAD_209 GTM_QUAD_X1Y9
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_102 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
      GTM_QUAD_107 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_108 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_104 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
      GTM_QUAD_105 { GTM_REFCLK_X0Y10 GTM_REFCLK_X0Y11 }
      GTM_QUAD_106 { GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13 }
      GTM_QUAD_200 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_201 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
      vsva2785 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      vsva2785 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvf1760 {
        switch $quad {
          GTM_QUAD_107 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_107 GTM_QUAD_109] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
      vsva2785 {
        switch $quad {
          GTM_QUAD_104 { return [list GTM_QUAD_105 GTM_QUAD_106] }
          GTM_QUAD_105 { return [list GTM_QUAD_104 GTM_QUAD_106 GTM_QUAD_107] }
          GTM_QUAD_106 { return [list GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_107 { return [list GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_109] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_200 { return [list GTM_QUAD_201 GTM_QUAD_202] }
          GTM_QUAD_201 { return [list GTM_QUAD_200 GTM_QUAD_202 GTM_QUAD_203] }
          GTM_QUAD_202 { return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_209] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1202
#######################################################################################################
proc xcvp1202 {} {
  log "using xcvp1202 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
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
      GTM_QUAD_206 GTM_QUAD_X0Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1202_SE
#######################################################################################################
proc xcvp1202_SE {} {
  log "using xcvp1202_SE procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
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
      GTM_QUAD_206 GTM_QUAD_X0Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1402
#######################################################################################################
proc xcvp1402 {} {
  log "using xcvp1402 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_102 GTYP_QUAD_X0Y0
      GTYP_QUAD_103 GTYP_QUAD_X0Y1
      GTM_QUAD_107 GTM_QUAD_X0Y7
      GTM_QUAD_108 GTM_QUAD_X0Y8
      GTM_QUAD_109 GTM_QUAD_X0Y9
      GTM_QUAD_202 GTM_QUAD_X1Y2
      GTM_QUAD_203 GTM_QUAD_X1Y3
      GTM_QUAD_204 GTM_QUAD_X1Y4
      GTM_QUAD_205 GTM_QUAD_X1Y5
      GTM_QUAD_206 GTM_QUAD_X1Y6
      GTM_QUAD_207 GTM_QUAD_X1Y7
      GTM_QUAD_104 GTM_QUAD_X0Y4
      GTM_QUAD_105 GTM_QUAD_X0Y5
      GTM_QUAD_106 GTM_QUAD_X0Y6
      GTM_QUAD_110 GTM_QUAD_X0Y10
      GTM_QUAD_111 GTM_QUAD_X0Y11
      GTM_QUAD_200 GTM_QUAD_X1Y0
      GTM_QUAD_201 GTM_QUAD_X1Y1
      GTM_QUAD_208 GTM_QUAD_X1Y8
      GTM_QUAD_209 GTM_QUAD_X1Y9
      GTM_QUAD_210 GTM_QUAD_X1Y10
      GTM_QUAD_211 GTM_QUAD_X1Y11
      GTM_QUAD_112 GTM_QUAD_X0Y12
      GTM_QUAD_113 GTM_QUAD_X0Y13
      GTM_QUAD_212 GTM_QUAD_X1Y12
      GTM_QUAD_213 GTM_QUAD_X1Y13
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_102 { GTYP_REFCLK_X0Y0 GTYP_REFCLK_X0Y1 }
      GTYP_QUAD_103 { GTYP_REFCLK_X0Y2 GTYP_REFCLK_X0Y3 }
      GTM_QUAD_107 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_108 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_104 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
      GTM_QUAD_105 { GTM_REFCLK_X0Y10 GTM_REFCLK_X0Y11 }
      GTM_QUAD_106 { GTM_REFCLK_X0Y12 GTM_REFCLK_X0Y13 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y22 GTM_REFCLK_X0Y23 }
      GTM_QUAD_200 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_201 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y24 GTM_REFCLK_X0Y25 }
      GTM_QUAD_113 { GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25 }
      GTM_QUAD_213 { GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109]
      }
      vsva2785 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111]
      }
      vsva3340 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_113]
      }
      vsvd2197 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_113]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vfvf1760 {
        return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207]
      }
      vsva2785 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211]
      }
      vsva3340 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213]
      }
      vsvd2197 {
        return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vfvf1760 {
        switch $quad {
          GTM_QUAD_107 { return [list GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_107 GTM_QUAD_109] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
      vsva2785 {
        switch $quad {
          GTM_QUAD_104 { return [list GTM_QUAD_105 GTM_QUAD_106] }
          GTM_QUAD_105 { return [list GTM_QUAD_104 GTM_QUAD_106 GTM_QUAD_107] }
          GTM_QUAD_106 { return [list GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_107 { return [list GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_111] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_200 { return [list GTM_QUAD_201 GTM_QUAD_202] }
          GTM_QUAD_201 { return [list GTM_QUAD_200 GTM_QUAD_202 GTM_QUAD_203] }
          GTM_QUAD_202 { return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
      vsva3340 {
        switch $quad {
          GTM_QUAD_104 { return [list GTM_QUAD_105 GTM_QUAD_106] }
          GTM_QUAD_105 { return [list GTM_QUAD_104 GTM_QUAD_106 GTM_QUAD_107] }
          GTM_QUAD_106 { return [list GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_107 { return [list GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112 GTM_QUAD_113] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_113] }
          GTM_QUAD_113 { return [list GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_200 { return [list GTM_QUAD_201 GTM_QUAD_202] }
          GTM_QUAD_201 { return [list GTM_QUAD_200 GTM_QUAD_202 GTM_QUAD_203] }
          GTM_QUAD_202 { return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212 GTM_QUAD_213] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_213] }
          GTM_QUAD_213 { return [list GTM_QUAD_211 GTM_QUAD_212] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
      vsvd2197 {
        switch $quad {
          GTM_QUAD_104 { return [list GTM_QUAD_105 GTM_QUAD_106] }
          GTM_QUAD_105 { return [list GTM_QUAD_104 GTM_QUAD_106 GTM_QUAD_107] }
          GTM_QUAD_106 { return [list GTM_QUAD_104 GTM_QUAD_105 GTM_QUAD_107 GTM_QUAD_108] }
          GTM_QUAD_107 { return [list GTM_QUAD_105 GTM_QUAD_106 GTM_QUAD_108 GTM_QUAD_109] }
          GTM_QUAD_108 { return [list GTM_QUAD_106 GTM_QUAD_107 GTM_QUAD_109 GTM_QUAD_110] }
          GTM_QUAD_109 { return [list GTM_QUAD_107 GTM_QUAD_108 GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_108 GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112 GTM_QUAD_113] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_113] }
          GTM_QUAD_113 { return [list GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_200 { return [list GTM_QUAD_201 GTM_QUAD_202] }
          GTM_QUAD_201 { return [list GTM_QUAD_200 GTM_QUAD_202 GTM_QUAD_203] }
          GTM_QUAD_202 { return [list GTM_QUAD_200 GTM_QUAD_201 GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_201 GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206 GTM_QUAD_207] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_207 { return [list GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212 GTM_QUAD_213] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_213] }
          GTM_QUAD_213 { return [list GTM_QUAD_211 GTM_QUAD_212] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1502
#######################################################################################################
proc xcvp1502 {} {
  log "using xcvp1502 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
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
      GTM_QUAD_207 GTM_QUAD_X1Y5
      GTM_QUAD_208 GTM_QUAD_X1Y6
      GTM_QUAD_209 GTM_QUAD_X1Y7
      GTM_QUAD_210 GTM_QUAD_X1Y8
      GTM_QUAD_211 GTM_QUAD_X1Y9
      GTM_QUAD_212 GTM_QUAD_X1Y10
      GTM_QUAD_206 GTM_QUAD_X1Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
      vsva3340 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
      vsva3340 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
      vsva3340 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1502_SE
#######################################################################################################
proc xcvp1502_SE {} {
  log "using xcvp1502_SE procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
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
      GTM_QUAD_207 GTM_QUAD_X1Y5
      GTM_QUAD_208 GTM_QUAD_X1Y6
      GTM_QUAD_209 GTM_QUAD_X1Y7
      GTM_QUAD_210 GTM_QUAD_X1Y8
      GTM_QUAD_211 GTM_QUAD_X1Y9
      GTM_QUAD_212 GTM_QUAD_X1Y10
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1552
#######################################################################################################
proc xcvp1552 {} {
  log "using xcvp1552 procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_207 GTYP_QUAD_X1Y7
      GTYP_QUAD_208 GTYP_QUAD_X1Y8
      GTYP_QUAD_209 GTYP_QUAD_X1Y9
      GTYP_QUAD_210 GTYP_QUAD_X1Y10
      GTYP_QUAD_211 GTYP_QUAD_X1Y11
      GTYP_QUAD_212 GTYP_QUAD_X1Y12
      GTM_QUAD_206 GTM_QUAD_X0Y4
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_109 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_110 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_111 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_112 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTYP_QUAD_207 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_208 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_209 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_210 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_211 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_212 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
      GTM_QUAD_206 { GTM_REFCLK_X0Y8 GTM_REFCLK_X0Y9 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
      vsva3340 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
      vsva3340 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
      vsva3340 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1552_SE
#######################################################################################################
proc xcvp1552_SE {} {
  log "using xcvp1552_SE procs"

  proc get_gt_types {} {
    return [list GTYP GTM]
  }

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
      GTYP_QUAD_207 GTYP_QUAD_X1Y7
      GTYP_QUAD_208 GTYP_QUAD_X1Y8
      GTYP_QUAD_209 GTYP_QUAD_X1Y9
      GTYP_QUAD_210 GTYP_QUAD_X1Y10
      GTYP_QUAD_211 GTYP_QUAD_X1Y11
      GTYP_QUAD_212 GTYP_QUAD_X1Y12
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTYP_QUAD_109 { GTYP_REFCLK_X0Y18 GTYP_REFCLK_X0Y19 }
      GTYP_QUAD_110 { GTYP_REFCLK_X0Y20 GTYP_REFCLK_X0Y21 }
      GTYP_QUAD_111 { GTYP_REFCLK_X0Y22 GTYP_REFCLK_X0Y23 }
      GTYP_QUAD_112 { GTYP_REFCLK_X0Y24 GTYP_REFCLK_X0Y25 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X0Y0 GTM_REFCLK_X0Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X0Y2 GTM_REFCLK_X0Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X0Y4 GTM_REFCLK_X0Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X0Y6 GTM_REFCLK_X0Y7 }
      GTYP_QUAD_207 { GTYP_REFCLK_X1Y14 GTYP_REFCLK_X1Y15 }
      GTYP_QUAD_208 { GTYP_REFCLK_X1Y16 GTYP_REFCLK_X1Y17 }
      GTYP_QUAD_209 { GTYP_REFCLK_X1Y18 GTYP_REFCLK_X1Y19 }
      GTYP_QUAD_210 { GTYP_REFCLK_X1Y20 GTYP_REFCLK_X1Y21 }
      GTYP_QUAD_211 { GTYP_REFCLK_X1Y22 GTYP_REFCLK_X1Y23 }
      GTYP_QUAD_212 { GTYP_REFCLK_X1Y24 GTYP_REFCLK_X1Y25 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_106 GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_111 GTYP_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva2785 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_211 GTYP_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva2785 {
        switch $quad {
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_109 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_110 { return [list GTYP_QUAD_109 GTYP_QUAD_111 GTYP_QUAD_112] }
          GTYP_QUAD_111 { return [list GTYP_QUAD_109 GTYP_QUAD_110 GTYP_QUAD_112] }
          GTYP_QUAD_112 { return [list GTYP_QUAD_110 GTYP_QUAD_111] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
          GTYP_QUAD_207 { return [list GTYP_QUAD_208 GTYP_QUAD_209] }
          GTYP_QUAD_208 { return [list GTYP_QUAD_207 GTYP_QUAD_209 GTYP_QUAD_210] }
          GTYP_QUAD_209 { return [list GTYP_QUAD_207 GTYP_QUAD_208 GTYP_QUAD_210 GTYP_QUAD_211] }
          GTYP_QUAD_210 { return [list GTYP_QUAD_208 GTYP_QUAD_209 GTYP_QUAD_211 GTYP_QUAD_212] }
          GTYP_QUAD_211 { return [list GTYP_QUAD_209 GTYP_QUAD_210 GTYP_QUAD_212] }
          GTYP_QUAD_212 { return [list GTYP_QUAD_210 GTYP_QUAD_211] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1702
#######################################################################################################
proc xcvp1702 {} {
  log "using xcvp1702 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTM_QUAD_115 GTM_QUAD_X0Y13
      GTM_QUAD_116 GTM_QUAD_X0Y14
      GTM_QUAD_117 GTM_QUAD_X0Y15
      GTM_QUAD_118 GTM_QUAD_X0Y16
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
      GTM_QUAD_213 GTM_QUAD_X1Y11
      GTM_QUAD_214 GTM_QUAD_X1Y12
      GTM_QUAD_215 GTM_QUAD_X1Y13
      GTM_QUAD_216 GTM_QUAD_X1Y14
      GTM_QUAD_217 GTM_QUAD_X1Y15
      GTM_QUAD_218 GTM_QUAD_X1Y16
      GTM_QUAD_210 GTM_QUAD_X1Y8
      GTM_QUAD_211 GTM_QUAD_X1Y9
      GTM_QUAD_212 GTM_QUAD_X1Y10
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTM_QUAD_115 { GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27 }
      GTM_QUAD_116 { GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29 }
      GTM_QUAD_117 { GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31 }
      GTM_QUAD_118 { GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_213 { GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23 }
      GTM_QUAD_214 { GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25 }
      GTM_QUAD_215 { GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27 }
      GTM_QUAD_216 { GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29 }
      GTM_QUAD_217 { GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31 }
      GTM_QUAD_218 { GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva3340 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118]
      }
      vsva5601 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva3340 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218]
      }
      vsva5601 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva3340 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
      vsva5601 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1802
#######################################################################################################
proc xcvp1802 {} {
  log "using xcvp1802 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTM_QUAD_115 GTM_QUAD_X0Y13
      GTM_QUAD_116 GTM_QUAD_X0Y14
      GTM_QUAD_117 GTM_QUAD_X0Y15
      GTM_QUAD_118 GTM_QUAD_X0Y16
      GTM_QUAD_121 GTM_QUAD_X0Y19
      GTM_QUAD_122 GTM_QUAD_X0Y20
      GTM_QUAD_123 GTM_QUAD_X0Y21
      GTM_QUAD_124 GTM_QUAD_X0Y22
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
      GTM_QUAD_213 GTM_QUAD_X1Y11
      GTM_QUAD_214 GTM_QUAD_X1Y12
      GTM_QUAD_215 GTM_QUAD_X1Y13
      GTM_QUAD_216 GTM_QUAD_X1Y14
      GTM_QUAD_217 GTM_QUAD_X1Y15
      GTM_QUAD_218 GTM_QUAD_X1Y16
      GTM_QUAD_219 GTM_QUAD_X1Y17
      GTM_QUAD_220 GTM_QUAD_X1Y18
      GTM_QUAD_221 GTM_QUAD_X1Y19
      GTM_QUAD_222 GTM_QUAD_X1Y20
      GTM_QUAD_223 GTM_QUAD_X1Y21
      GTM_QUAD_224 GTM_QUAD_X1Y22
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTM_QUAD_115 { GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27 }
      GTM_QUAD_116 { GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29 }
      GTM_QUAD_117 { GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31 }
      GTM_QUAD_118 { GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33 }
      GTM_QUAD_121 { GTM_REFCLK_X0Y38 GTM_REFCLK_X0Y39 }
      GTM_QUAD_122 { GTM_REFCLK_X0Y40 GTM_REFCLK_X0Y41 }
      GTM_QUAD_123 { GTM_REFCLK_X0Y42 GTM_REFCLK_X0Y43 }
      GTM_QUAD_124 { GTM_REFCLK_X0Y44 GTM_REFCLK_X0Y45 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTM_QUAD_213 { GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23 }
      GTM_QUAD_214 { GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25 }
      GTM_QUAD_215 { GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27 }
      GTM_QUAD_216 { GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29 }
      GTM_QUAD_217 { GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31 }
      GTM_QUAD_218 { GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33 }
      GTM_QUAD_219 { GTM_REFCLK_X1Y34 GTM_REFCLK_X1Y35 }
      GTM_QUAD_220 { GTM_REFCLK_X1Y36 GTM_REFCLK_X1Y37 }
      GTM_QUAD_221 { GTM_REFCLK_X1Y38 GTM_REFCLK_X1Y39 }
      GTM_QUAD_222 { GTM_REFCLK_X1Y40 GTM_REFCLK_X1Y41 }
      GTM_QUAD_223 { GTM_REFCLK_X1Y42 GTM_REFCLK_X1Y43 }
      GTM_QUAD_224 { GTM_REFCLK_X1Y44 GTM_REFCLK_X1Y45 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsvc4072 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118 GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_123 GTM_QUAD_124]
      }
      vsva5601 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118 GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_123 GTM_QUAD_124]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsvc4072 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218 GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_223 GTM_QUAD_224]
      }
      vsva5601 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218 GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_223 GTM_QUAD_224]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsvc4072 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_121 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_122 { return [list GTM_QUAD_121 GTM_QUAD_123 GTM_QUAD_124] }
          GTM_QUAD_123 { return [list GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_124] }
          GTM_QUAD_124 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_219 { return [list GTM_QUAD_220 GTM_QUAD_221] }
          GTM_QUAD_220 { return [list GTM_QUAD_219 GTM_QUAD_221 GTM_QUAD_222] }
          GTM_QUAD_221 { return [list GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_222 GTM_QUAD_223] }
          GTM_QUAD_222 { return [list GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_223 GTM_QUAD_224] }
          GTM_QUAD_223 { return [list GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_224] }
          GTM_QUAD_224 { return [list GTM_QUAD_222 GTM_QUAD_223] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
      vsva5601 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_121 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_122 { return [list GTM_QUAD_121 GTM_QUAD_123 GTM_QUAD_124] }
          GTM_QUAD_123 { return [list GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_124] }
          GTM_QUAD_124 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_219 { return [list GTM_QUAD_220 GTM_QUAD_221] }
          GTM_QUAD_220 { return [list GTM_QUAD_219 GTM_QUAD_221 GTM_QUAD_222] }
          GTM_QUAD_221 { return [list GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_222 GTM_QUAD_223] }
          GTM_QUAD_222 { return [list GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_223 GTM_QUAD_224] }
          GTM_QUAD_223 { return [list GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_224] }
          GTM_QUAD_224 { return [list GTM_QUAD_222 GTM_QUAD_223] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1802_SE
#######################################################################################################
proc xcvp1802_SE {} {
  log "using xcvp1802_SE procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTM_QUAD_115 GTM_QUAD_X0Y13
      GTM_QUAD_116 GTM_QUAD_X0Y14
      GTM_QUAD_117 GTM_QUAD_X0Y15
      GTM_QUAD_118 GTM_QUAD_X0Y16
      GTM_QUAD_121 GTM_QUAD_X0Y19
      GTM_QUAD_122 GTM_QUAD_X0Y20
      GTM_QUAD_123 GTM_QUAD_X0Y21
      GTM_QUAD_124 GTM_QUAD_X0Y22
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
      GTM_QUAD_213 GTM_QUAD_X1Y11
      GTM_QUAD_214 GTM_QUAD_X1Y12
      GTM_QUAD_215 GTM_QUAD_X1Y13
      GTM_QUAD_216 GTM_QUAD_X1Y14
      GTM_QUAD_217 GTM_QUAD_X1Y15
      GTM_QUAD_218 GTM_QUAD_X1Y16
      GTM_QUAD_219 GTM_QUAD_X1Y17
      GTM_QUAD_220 GTM_QUAD_X1Y18
      GTM_QUAD_221 GTM_QUAD_X1Y19
      GTM_QUAD_222 GTM_QUAD_X1Y20
      GTM_QUAD_223 GTM_QUAD_X1Y21
      GTM_QUAD_224 GTM_QUAD_X1Y22
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTM_QUAD_115 { GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27 }
      GTM_QUAD_116 { GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29 }
      GTM_QUAD_117 { GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31 }
      GTM_QUAD_118 { GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33 }
      GTM_QUAD_121 { GTM_REFCLK_X0Y38 GTM_REFCLK_X0Y39 }
      GTM_QUAD_122 { GTM_REFCLK_X0Y40 GTM_REFCLK_X0Y41 }
      GTM_QUAD_123 { GTM_REFCLK_X0Y42 GTM_REFCLK_X0Y43 }
      GTM_QUAD_124 { GTM_REFCLK_X0Y44 GTM_REFCLK_X0Y45 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTM_QUAD_213 { GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23 }
      GTM_QUAD_214 { GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25 }
      GTM_QUAD_215 { GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27 }
      GTM_QUAD_216 { GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29 }
      GTM_QUAD_217 { GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31 }
      GTM_QUAD_218 { GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33 }
      GTM_QUAD_219 { GTM_REFCLK_X1Y34 GTM_REFCLK_X1Y35 }
      GTM_QUAD_220 { GTM_REFCLK_X1Y36 GTM_REFCLK_X1Y37 }
      GTM_QUAD_221 { GTM_REFCLK_X1Y38 GTM_REFCLK_X1Y39 }
      GTM_QUAD_222 { GTM_REFCLK_X1Y40 GTM_REFCLK_X1Y41 }
      GTM_QUAD_223 { GTM_REFCLK_X1Y42 GTM_REFCLK_X1Y43 }
      GTM_QUAD_224 { GTM_REFCLK_X1Y44 GTM_REFCLK_X1Y45 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      lsvc4072 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118 GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_123 GTM_QUAD_124]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      lsvc4072 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218 GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_223 GTM_QUAD_224]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      lsvc4072 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_121 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_122 { return [list GTM_QUAD_121 GTM_QUAD_123 GTM_QUAD_124] }
          GTM_QUAD_123 { return [list GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_124] }
          GTM_QUAD_124 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_219 { return [list GTM_QUAD_220 GTM_QUAD_221] }
          GTM_QUAD_220 { return [list GTM_QUAD_219 GTM_QUAD_221 GTM_QUAD_222] }
          GTM_QUAD_221 { return [list GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_222 GTM_QUAD_223] }
          GTM_QUAD_222 { return [list GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_223 GTM_QUAD_224] }
          GTM_QUAD_223 { return [list GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_224] }
          GTM_QUAD_224 { return [list GTM_QUAD_222 GTM_QUAD_223] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp1902
#######################################################################################################
proc xcvp1902 {} {
  log "using xcvp1902 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_102 GTYP_QUAD_S0X0Y0
      GTYP_QUAD_103 GTYP_QUAD_S0X0Y1
      GTYP_QUAD_104 GTYP_QUAD_S0X0Y2
      GTYP_QUAD_105 GTYP_QUAD_S0X0Y3
      GTM_QUAD_110 GTM_QUAD_S0X0Y0
      GTM_QUAD_111 GTM_QUAD_S0X0Y1
      GTM_QUAD_112 GTM_QUAD_S1X0Y0
      GTM_QUAD_113 GTM_QUAD_S1X0Y1
      GTYP_QUAD_118 GTYP_QUAD_S1X0Y3
      GTYP_QUAD_119 GTYP_QUAD_S1X0Y2
      GTYP_QUAD_120 GTYP_QUAD_S1X0Y1
      GTYP_QUAD_121 GTYP_QUAD_S1X0Y0
      GTYP_QUAD_202 GTYP_QUAD_S3X0Y0
      GTYP_QUAD_203 GTYP_QUAD_S3X0Y1
      GTYP_QUAD_204 GTYP_QUAD_S3X0Y2
      GTYP_QUAD_205 GTYP_QUAD_S3X0Y3
      GTM_QUAD_210 GTM_QUAD_S3X0Y0
      GTM_QUAD_211 GTM_QUAD_S3X0Y1
      GTM_QUAD_212 GTM_QUAD_S2X0Y0
      GTM_QUAD_213 GTM_QUAD_S2X0Y1
      GTYP_QUAD_218 GTYP_QUAD_S2X0Y3
      GTYP_QUAD_219 GTYP_QUAD_S2X0Y2
      GTYP_QUAD_220 GTYP_QUAD_S2X0Y1
      GTYP_QUAD_221 GTYP_QUAD_S2X0Y0
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_102 { GTYP_REFCLK_S0X0Y0 GTYP_REFCLK_S0X0Y1 }
      GTYP_QUAD_103 { GTYP_REFCLK_S0X0Y2 GTYP_REFCLK_S0X0Y3 }
      GTYP_QUAD_104 { GTYP_REFCLK_S0X0Y4 GTYP_REFCLK_S0X0Y5 }
      GTYP_QUAD_105 { GTYP_REFCLK_S0X0Y6 GTYP_REFCLK_S0X0Y7 }
      GTM_QUAD_110 { GTM_REFCLK_S0X0Y0 GTM_REFCLK_S0X0Y1 }
      GTM_QUAD_111 { GTM_REFCLK_S0X0Y2 GTM_REFCLK_S0X0Y3 }
      GTM_QUAD_112 { GTM_REFCLK_S1X0Y2 GTM_REFCLK_S1X0Y3 }
      GTM_QUAD_113 { GTM_REFCLK_S1X0Y0 GTM_REFCLK_S1X0Y1 }
      GTYP_QUAD_118 { GTYP_REFCLK_S1X0Y6 GTYP_REFCLK_S1X0Y7 }
      GTYP_QUAD_119 { GTYP_REFCLK_S1X0Y4 GTYP_REFCLK_S1X0Y5 }
      GTYP_QUAD_120 { GTYP_REFCLK_S1X0Y2 GTYP_REFCLK_S1X0Y3 }
      GTYP_QUAD_121 { GTYP_REFCLK_S1X0Y0 GTYP_REFCLK_S1X0Y1 }
      GTYP_QUAD_202 { GTYP_REFCLK_S3X0Y0 GTYP_REFCLK_S3X0Y1 }
      GTYP_QUAD_203 { GTYP_REFCLK_S3X0Y2 GTYP_REFCLK_S3X0Y3 }
      GTYP_QUAD_204 { GTYP_REFCLK_S3X0Y4 GTYP_REFCLK_S3X0Y5 }
      GTYP_QUAD_205 { GTYP_REFCLK_S3X0Y6 GTYP_REFCLK_S3X0Y7 }
      GTM_QUAD_210 { GTM_REFCLK_S3X0Y0 GTM_REFCLK_S3X0Y1 }
      GTM_QUAD_211 { GTM_REFCLK_S3X0Y2 GTM_REFCLK_S3X0Y3 }
      GTM_QUAD_212 { GTM_REFCLK_S2X0Y2 GTM_REFCLK_S2X0Y3 }
      GTM_QUAD_213 { GTM_REFCLK_S2X0Y0 GTM_REFCLK_S2X0Y1 }
      GTYP_QUAD_218 { GTYP_REFCLK_S2X0Y6 GTYP_REFCLK_S2X0Y7 }
      GTYP_QUAD_219 { GTYP_REFCLK_S2X0Y4 GTYP_REFCLK_S2X0Y5 }
      GTYP_QUAD_220 { GTYP_REFCLK_S2X0Y2 GTYP_REFCLK_S2X0Y3 }
      GTYP_QUAD_221 { GTYP_REFCLK_S2X0Y0 GTYP_REFCLK_S2X0Y1 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva6865 {
        return [list GTYP_QUAD_102 GTYP_QUAD_103 GTYP_QUAD_104 GTYP_QUAD_105 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_113 GTYP_QUAD_118 GTYP_QUAD_119 GTYP_QUAD_120 GTYP_QUAD_121]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva6865 {
        return [list GTYP_QUAD_202 GTYP_QUAD_203 GTYP_QUAD_204 GTYP_QUAD_205 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTYP_QUAD_218 GTYP_QUAD_219 GTYP_QUAD_220 GTYP_QUAD_221]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva6865 {
        switch $quad {
          GTM_QUAD_110 { return [list GTM_QUAD_111] }
          GTM_QUAD_111 { return [list GTM_QUAD_110] }
          GTM_QUAD_112 { return [list GTM_QUAD_113] }
          GTM_QUAD_113 { return [list GTM_QUAD_112] }
          GTM_QUAD_210 { return [list GTM_QUAD_211] }
          GTM_QUAD_211 { return [list GTM_QUAD_210] }
          GTM_QUAD_212 { return [list GTM_QUAD_213] }
          GTM_QUAD_213 { return [list GTM_QUAD_212] }
          GTYP_QUAD_102 { return [list GTYP_QUAD_103 GTYP_QUAD_104] }
          GTYP_QUAD_103 { return [list GTYP_QUAD_102 GTYP_QUAD_104 GTYP_QUAD_105] }
          GTYP_QUAD_104 { return [list GTYP_QUAD_102 GTYP_QUAD_103 GTYP_QUAD_105] }
          GTYP_QUAD_105 { return [list GTYP_QUAD_103 GTYP_QUAD_104] }
          GTYP_QUAD_118 { return [list GTYP_QUAD_119 GTYP_QUAD_120] }
          GTYP_QUAD_119 { return [list GTYP_QUAD_118 GTYP_QUAD_120 GTYP_QUAD_121] }
          GTYP_QUAD_120 { return [list GTYP_QUAD_118 GTYP_QUAD_119 GTYP_QUAD_121] }
          GTYP_QUAD_121 { return [list GTYP_QUAD_119 GTYP_QUAD_120] }
          GTYP_QUAD_202 { return [list GTYP_QUAD_203 GTYP_QUAD_204] }
          GTYP_QUAD_203 { return [list GTYP_QUAD_202 GTYP_QUAD_204 GTYP_QUAD_205] }
          GTYP_QUAD_204 { return [list GTYP_QUAD_202 GTYP_QUAD_203 GTYP_QUAD_205] }
          GTYP_QUAD_205 { return [list GTYP_QUAD_203 GTYP_QUAD_204] }
          GTYP_QUAD_218 { return [list GTYP_QUAD_219 GTYP_QUAD_220] }
          GTYP_QUAD_219 { return [list GTYP_QUAD_218 GTYP_QUAD_220 GTYP_QUAD_221] }
          GTYP_QUAD_220 { return [list GTYP_QUAD_218 GTYP_QUAD_219 GTYP_QUAD_221] }
          GTYP_QUAD_221 { return [list GTYP_QUAD_219 GTYP_QUAD_220] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp2502
#######################################################################################################
proc xcvp2502 {} {
  log "using xcvp2502 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
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
      GTM_QUAD_212 GTM_QUAD_X1Y10
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva5601 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
      vsvb3340 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva5601 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
      vsvb3340 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva5601 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
      vsvb3340 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xcvp2802
#######################################################################################################
proc xcvp2802 {} {
  log "using xcvp2802 procs"

  proc get_gt_types {} {
    return [list GTM GTYP]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTYP_QUAD_106 GTYP_QUAD_X0Y6
      GTM_QUAD_109 GTM_QUAD_X0Y7
      GTM_QUAD_110 GTM_QUAD_X0Y8
      GTM_QUAD_111 GTM_QUAD_X0Y9
      GTM_QUAD_112 GTM_QUAD_X0Y10
      GTM_QUAD_115 GTM_QUAD_X0Y13
      GTM_QUAD_116 GTM_QUAD_X0Y14
      GTM_QUAD_117 GTM_QUAD_X0Y15
      GTM_QUAD_118 GTM_QUAD_X0Y16
      GTM_QUAD_121 GTM_QUAD_X0Y19
      GTM_QUAD_122 GTM_QUAD_X0Y20
      GTM_QUAD_123 GTM_QUAD_X0Y21
      GTM_QUAD_124 GTM_QUAD_X0Y22
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
      GTM_QUAD_213 GTM_QUAD_X1Y11
      GTM_QUAD_214 GTM_QUAD_X1Y12
      GTM_QUAD_215 GTM_QUAD_X1Y13
      GTM_QUAD_216 GTM_QUAD_X1Y14
      GTM_QUAD_217 GTM_QUAD_X1Y15
      GTM_QUAD_218 GTM_QUAD_X1Y16
      GTM_QUAD_219 GTM_QUAD_X1Y17
      GTM_QUAD_220 GTM_QUAD_X1Y18
      GTM_QUAD_221 GTM_QUAD_X1Y19
      GTM_QUAD_222 GTM_QUAD_X1Y20
      GTM_QUAD_223 GTM_QUAD_X1Y21
      GTM_QUAD_224 GTM_QUAD_X1Y22
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTYP_QUAD_106 { GTYP_REFCLK_X0Y12 GTYP_REFCLK_X0Y13 }
      GTM_QUAD_109 { GTM_REFCLK_X0Y14 GTM_REFCLK_X0Y15 }
      GTM_QUAD_110 { GTM_REFCLK_X0Y16 GTM_REFCLK_X0Y17 }
      GTM_QUAD_111 { GTM_REFCLK_X0Y18 GTM_REFCLK_X0Y19 }
      GTM_QUAD_112 { GTM_REFCLK_X0Y20 GTM_REFCLK_X0Y21 }
      GTM_QUAD_115 { GTM_REFCLK_X0Y26 GTM_REFCLK_X0Y27 }
      GTM_QUAD_116 { GTM_REFCLK_X0Y28 GTM_REFCLK_X0Y29 }
      GTM_QUAD_117 { GTM_REFCLK_X0Y30 GTM_REFCLK_X0Y31 }
      GTM_QUAD_118 { GTM_REFCLK_X0Y32 GTM_REFCLK_X0Y33 }
      GTM_QUAD_121 { GTM_REFCLK_X0Y38 GTM_REFCLK_X0Y39 }
      GTM_QUAD_122 { GTM_REFCLK_X0Y40 GTM_REFCLK_X0Y41 }
      GTM_QUAD_123 { GTM_REFCLK_X0Y42 GTM_REFCLK_X0Y43 }
      GTM_QUAD_124 { GTM_REFCLK_X0Y44 GTM_REFCLK_X0Y45 }
      GTYP_QUAD_200 { GTYP_REFCLK_X1Y0 GTYP_REFCLK_X1Y1 }
      GTYP_QUAD_201 { GTYP_REFCLK_X1Y2 GTYP_REFCLK_X1Y3 }
      GTM_QUAD_202 { GTM_REFCLK_X1Y0 GTM_REFCLK_X1Y1 }
      GTM_QUAD_203 { GTM_REFCLK_X1Y2 GTM_REFCLK_X1Y3 }
      GTM_QUAD_204 { GTM_REFCLK_X1Y4 GTM_REFCLK_X1Y5 }
      GTM_QUAD_205 { GTM_REFCLK_X1Y6 GTM_REFCLK_X1Y7 }
      GTM_QUAD_206 { GTM_REFCLK_X1Y8 GTM_REFCLK_X1Y9 }
      GTM_QUAD_207 { GTM_REFCLK_X1Y10 GTM_REFCLK_X1Y11 }
      GTM_QUAD_208 { GTM_REFCLK_X1Y12 GTM_REFCLK_X1Y13 }
      GTM_QUAD_209 { GTM_REFCLK_X1Y14 GTM_REFCLK_X1Y15 }
      GTM_QUAD_210 { GTM_REFCLK_X1Y16 GTM_REFCLK_X1Y17 }
      GTM_QUAD_211 { GTM_REFCLK_X1Y18 GTM_REFCLK_X1Y19 }
      GTM_QUAD_212 { GTM_REFCLK_X1Y20 GTM_REFCLK_X1Y21 }
      GTM_QUAD_213 { GTM_REFCLK_X1Y22 GTM_REFCLK_X1Y23 }
      GTM_QUAD_214 { GTM_REFCLK_X1Y24 GTM_REFCLK_X1Y25 }
      GTM_QUAD_215 { GTM_REFCLK_X1Y26 GTM_REFCLK_X1Y27 }
      GTM_QUAD_216 { GTM_REFCLK_X1Y28 GTM_REFCLK_X1Y29 }
      GTM_QUAD_217 { GTM_REFCLK_X1Y30 GTM_REFCLK_X1Y31 }
      GTM_QUAD_218 { GTM_REFCLK_X1Y32 GTM_REFCLK_X1Y33 }
      GTM_QUAD_219 { GTM_REFCLK_X1Y34 GTM_REFCLK_X1Y35 }
      GTM_QUAD_220 { GTM_REFCLK_X1Y36 GTM_REFCLK_X1Y37 }
      GTM_QUAD_221 { GTM_REFCLK_X1Y38 GTM_REFCLK_X1Y39 }
      GTM_QUAD_222 { GTM_REFCLK_X1Y40 GTM_REFCLK_X1Y41 }
      GTM_QUAD_223 { GTM_REFCLK_X1Y42 GTM_REFCLK_X1Y43 }
      GTM_QUAD_224 { GTM_REFCLK_X1Y44 GTM_REFCLK_X1Y45 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsva5601 {
        return [list GTYP_QUAD_106 GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_111 GTM_QUAD_112 GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_117 GTM_QUAD_118 GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_123 GTM_QUAD_124]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsva5601 {
        return [list GTYP_QUAD_200 GTYP_QUAD_201 GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_205 GTM_QUAD_206 GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_211 GTM_QUAD_212 GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_217 GTM_QUAD_218 GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_223 GTM_QUAD_224]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsva5601 {
        switch $quad {
          GTM_QUAD_109 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_110 { return [list GTM_QUAD_109 GTM_QUAD_111 GTM_QUAD_112] }
          GTM_QUAD_111 { return [list GTM_QUAD_109 GTM_QUAD_110 GTM_QUAD_112] }
          GTM_QUAD_112 { return [list GTM_QUAD_110 GTM_QUAD_111] }
          GTM_QUAD_115 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_116 { return [list GTM_QUAD_115 GTM_QUAD_117 GTM_QUAD_118] }
          GTM_QUAD_117 { return [list GTM_QUAD_115 GTM_QUAD_116 GTM_QUAD_118] }
          GTM_QUAD_118 { return [list GTM_QUAD_116 GTM_QUAD_117] }
          GTM_QUAD_121 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_122 { return [list GTM_QUAD_121 GTM_QUAD_123 GTM_QUAD_124] }
          GTM_QUAD_123 { return [list GTM_QUAD_121 GTM_QUAD_122 GTM_QUAD_124] }
          GTM_QUAD_124 { return [list GTM_QUAD_122 GTM_QUAD_123] }
          GTM_QUAD_202 { return [list GTM_QUAD_203 GTM_QUAD_204] }
          GTM_QUAD_203 { return [list GTM_QUAD_202 GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_204 { return [list GTM_QUAD_202 GTM_QUAD_203 GTM_QUAD_205 GTM_QUAD_206] }
          GTM_QUAD_205 { return [list GTM_QUAD_203 GTM_QUAD_204 GTM_QUAD_206] }
          GTM_QUAD_206 { return [list GTM_QUAD_204 GTM_QUAD_205] }
          GTM_QUAD_207 { return [list GTM_QUAD_208 GTM_QUAD_209] }
          GTM_QUAD_208 { return [list GTM_QUAD_207 GTM_QUAD_209 GTM_QUAD_210] }
          GTM_QUAD_209 { return [list GTM_QUAD_207 GTM_QUAD_208 GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_210 { return [list GTM_QUAD_208 GTM_QUAD_209 GTM_QUAD_211 GTM_QUAD_212] }
          GTM_QUAD_211 { return [list GTM_QUAD_209 GTM_QUAD_210 GTM_QUAD_212] }
          GTM_QUAD_212 { return [list GTM_QUAD_210 GTM_QUAD_211] }
          GTM_QUAD_213 { return [list GTM_QUAD_214 GTM_QUAD_215] }
          GTM_QUAD_214 { return [list GTM_QUAD_213 GTM_QUAD_215 GTM_QUAD_216] }
          GTM_QUAD_215 { return [list GTM_QUAD_213 GTM_QUAD_214 GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_216 { return [list GTM_QUAD_214 GTM_QUAD_215 GTM_QUAD_217 GTM_QUAD_218] }
          GTM_QUAD_217 { return [list GTM_QUAD_215 GTM_QUAD_216 GTM_QUAD_218] }
          GTM_QUAD_218 { return [list GTM_QUAD_216 GTM_QUAD_217] }
          GTM_QUAD_219 { return [list GTM_QUAD_220 GTM_QUAD_221] }
          GTM_QUAD_220 { return [list GTM_QUAD_219 GTM_QUAD_221 GTM_QUAD_222] }
          GTM_QUAD_221 { return [list GTM_QUAD_219 GTM_QUAD_220 GTM_QUAD_222 GTM_QUAD_223] }
          GTM_QUAD_222 { return [list GTM_QUAD_220 GTM_QUAD_221 GTM_QUAD_223 GTM_QUAD_224] }
          GTM_QUAD_223 { return [list GTM_QUAD_221 GTM_QUAD_222 GTM_QUAD_224] }
          GTM_QUAD_224 { return [list GTM_QUAD_222 GTM_QUAD_223] }
          GTYP_QUAD_106 { return [list ] }
          GTYP_QUAD_200 { return [list GTYP_QUAD_201] }
          GTYP_QUAD_201 { return [list GTYP_QUAD_200] }
        }
      }
    }
  }
}

#######################################################################################################
# xqrvc1902
#######################################################################################################
proc xqrvc1902 {} {
  log "using xqrvc1902 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsra2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xqvc1702
#######################################################################################################
proc xqvc1702 {} {
  log "using xqvc1702 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      nsrg1369 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsra1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsra2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      nsrg1369 {
        return [list GTY_QUAD_202 GTY_QUAD_203]
      }
      vsra1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsra2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      nsrg1369 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203] }
          GTY_QUAD_203 { return [list GTY_QUAD_202] }
        }
      }
      vsra1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsra2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xqvc1902
#######################################################################################################
proc xqvc1902 {} {
  log "using xqvc1902 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

  proc get_gtloc {q} {
    set gt_dict {
      GTY_QUAD_103 GTY_QUAD_X0Y3
      GTY_QUAD_104 GTY_QUAD_X0Y4
      GTY_QUAD_105 GTY_QUAD_X0Y5
      GTY_QUAD_106 GTY_QUAD_X0Y6
      GTY_QUAD_202 GTY_QUAD_X1Y2
      GTY_QUAD_203 GTY_QUAD_X1Y3
      GTY_QUAD_204 GTY_QUAD_X1Y4
      GTY_QUAD_205 GTY_QUAD_X1Y5
      GTY_QUAD_200 GTY_QUAD_X1Y0
      GTY_QUAD_201 GTY_QUAD_X1Y1
      GTY_QUAD_206 GTY_QUAD_X1Y6
    }
    return [dict get $gt_dict $q]
  }

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vira1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsra2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsrd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vira1596 {
        return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205]
      }
      vsra2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsrd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vira1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_202 { return [list GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204] }
        }
      }
      vsra2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsrd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

#######################################################################################################
# xqvm1402
#######################################################################################################
proc xqvm1402 {} {
  log "using xqvm1402 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y0 GTY_REFCLK_X0Y1 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y2 GTY_REFCLK_X0Y3 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y4 GTY_REFCLK_X0Y5 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_107 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_108 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsrc1596 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_107 GTY_QUAD_108]
      }
      vsrd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsrc1596 {
        return [list ]
      }
      vsrd1760 {
        return [list ]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsrc1596 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106 GTY_QUAD_107] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_107 GTY_QUAD_108] }
          GTY_QUAD_107 { return [list GTY_QUAD_105 GTY_QUAD_106 GTY_QUAD_108] }
          GTY_QUAD_108 { return [list GTY_QUAD_106 GTY_QUAD_107] }
        }
      }
      vsrd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
        }
      }
    }
  }
}

#######################################################################################################
# xqvm1502
#######################################################################################################
proc xqvm1502 {} {
  log "using xqvm1502 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsra2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
    }
  }
}

#######################################################################################################
# xqvm1802
#######################################################################################################
proc xqvm1802 {} {
  log "using xqvm1802 procs"

  proc get_gt_types {} {
    return [list GTY]
  }

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

  proc get_reflocs {q} {
    set refclk_dict {
      GTY_QUAD_103 { GTY_REFCLK_X0Y6 GTY_REFCLK_X0Y7 }
      GTY_QUAD_104 { GTY_REFCLK_X0Y8 GTY_REFCLK_X0Y9 }
      GTY_QUAD_105 { GTY_REFCLK_X0Y10 GTY_REFCLK_X0Y11 }
      GTY_QUAD_106 { GTY_REFCLK_X0Y12 GTY_REFCLK_X0Y13 }
      GTY_QUAD_200 { GTY_REFCLK_X1Y0 GTY_REFCLK_X1Y1 }
      GTY_QUAD_201 { GTY_REFCLK_X1Y2 GTY_REFCLK_X1Y3 }
      GTY_QUAD_202 { GTY_REFCLK_X1Y4 GTY_REFCLK_X1Y5 }
      GTY_QUAD_203 { GTY_REFCLK_X1Y6 GTY_REFCLK_X1Y7 }
      GTY_QUAD_204 { GTY_REFCLK_X1Y8 GTY_REFCLK_X1Y9 }
      GTY_QUAD_205 { GTY_REFCLK_X1Y10 GTY_REFCLK_X1Y11 }
      GTY_QUAD_206 { GTY_REFCLK_X1Y12 GTY_REFCLK_X1Y13 }
    }
    return [dict get $refclk_dict $q]
  }

  proc get_left {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
      vsrd1760 {
        return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_105 GTY_QUAD_106]
      }
    }
  }

  proc get_right {pkg} {
    switch $pkg {
      vsra2197 {
        return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_205 GTY_QUAD_206]
      }
      vsrd1760 {
        return [list GTY_QUAD_203 GTY_QUAD_204]
      }
    }
  }
  proc get_refclk_neighbors {pkg quad} {
    switch $pkg {
      vsra2197 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_200 { return [list GTY_QUAD_201 GTY_QUAD_202] }
          GTY_QUAD_201 { return [list GTY_QUAD_200 GTY_QUAD_202 GTY_QUAD_203] }
          GTY_QUAD_202 { return [list GTY_QUAD_200 GTY_QUAD_201 GTY_QUAD_203 GTY_QUAD_204] }
          GTY_QUAD_203 { return [list GTY_QUAD_201 GTY_QUAD_202 GTY_QUAD_204 GTY_QUAD_205] }
          GTY_QUAD_204 { return [list GTY_QUAD_202 GTY_QUAD_203 GTY_QUAD_205 GTY_QUAD_206] }
          GTY_QUAD_205 { return [list GTY_QUAD_203 GTY_QUAD_204 GTY_QUAD_206] }
          GTY_QUAD_206 { return [list GTY_QUAD_204 GTY_QUAD_205] }
        }
      }
      vsrd1760 {
        switch $quad {
          GTY_QUAD_103 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_104 { return [list GTY_QUAD_103 GTY_QUAD_105 GTY_QUAD_106] }
          GTY_QUAD_105 { return [list GTY_QUAD_103 GTY_QUAD_104 GTY_QUAD_106] }
          GTY_QUAD_106 { return [list GTY_QUAD_104 GTY_QUAD_105] }
          GTY_QUAD_203 { return [list GTY_QUAD_204] }
          GTY_QUAD_204 { return [list GTY_QUAD_203] }
        }
      }
    }
  }
}

