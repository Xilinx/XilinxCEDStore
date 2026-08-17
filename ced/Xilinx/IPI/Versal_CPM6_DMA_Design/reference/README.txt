This directory holds reference material that is NOT part of the active
simulation compile path (nothing here is referenced by any sim/*.f filelist).

bmd_test_example/
  The original BMD (Bus Master DMA) UVM verification package that this
  design's sim/ tree was originally bootstrapped from (scoreboards,
  sequences, tests, config/callback/interface classes -- all named
  "bmd_*"). It does not apply to HDMA's DMA-ring/descriptor protocol and
  was moved here (out of sim/test/) so it can no longer be accidentally
  compiled via +incdir+test, while still being available as a worked
  example of how to structure a project-specific UVM test package
  (see sim/tb/test/pkg.proj_test_pkg.sv for the empty placeholder it
  used to override, and sim/tb/test/test_pkg.svh for the generic
  framework base classes it built on top of).

  Writing real HDMA-specific verification content (descriptor rings, DMA
  read/write scoreboards, interrupt tests) is a separate task for the
  verification team; this example shows the structural pattern to follow.
