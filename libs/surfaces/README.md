wscript:

in def build(bld):

if bld.is_defined ('HAVE_LO'):
  bld.recurse('cso')
