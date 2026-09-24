# write_device_image.post hook
#
# Refreshes "boot.pdi" and "pld.pdi" symlinks in the project directory to
# point at the last generated PDIs. runme.tcl has already cd'd into the 
# firing run's own directory by the time this hook is sourced.
#
# Attach this to every run you care about, e.g.:
#   set hook_tcl [get_files -of_objects [get_filesets utils_1] "soft_link_pdis.tcl"]
#   foreach run [get_runs impl_*] {
#     set_property STEPS.WRITE_DEVICE_IMAGE.TCL.POST $hook_tcl $run
#   }
#
# With multiple runs generating bitstreams, hooks can fire out of order
# (a run started earlier may finish later). To make "last one wins" mean
# "most recently built PDI" rather than "most recently fired hook," each
# link is only updated if the new source PDI is newer than whatever the
# link currently points at.

set run_dir  [pwd]
set proj_dir [file dirname [file dirname $run_dir]]

puts "INFO: write_device_image.post: run_dir=$run_dir and proj_dir=$proj_dir"

foreach suffix {boot pld} {
  set pdi_matches [glob -nocomplain -directory $run_dir "*_${suffix}.pdi"]
  set pdi_link [file join $proj_dir "${suffix}.pdi"]

  if {[llength $pdi_matches] == 0} {
    puts "WARNING: write_device_image.post: no *_${suffix}.pdi found in: $run_dir"
    continue
  }

  # Normally there is exactly one match; if not, fall back to the newest.
  set pdi_src [lindex [lsort -command {apply {{a b} {expr {[file mtime $a] - [file mtime $b]}}}} $pdi_matches] end]
  if {[llength $pdi_matches] > 1} {
    puts "WARNING: write_device_image.post: multiple *_${suffix}.pdi found in $run_dir, using newest: $pdi_src"
  }

  set src_mtime [file mtime $pdi_src]

  set do_relink 1
  if {![catch {file mtime $pdi_link} link_mtime]} {
    if {$src_mtime <= $link_mtime} {
      set do_relink 0
    }
  }

  if {!$do_relink} {
    puts "INFO: write_device_image.post: ${suffix}.pdi left unchanged (current target is newer): $pdi_src"
    continue
  }

  file delete -force $pdi_link
  exec ln -sf $pdi_src $pdi_link

  puts "INFO: write_device_image.post: ${suffix}.pdi -> $pdi_src"
}
