from builders.builder_asm import BuilderAsm
from builders.builder_c import BuilderC
from builders.builder_compliance import BuilderCompliance
from builders.builder_zephyr import BuilderZephyr

def build_c():
  return BuilderC()
def build_asm():
  return BuilderAsm()
def build_compliance():
  return BuilderCompliance()
def build_zephyr():
  return BuilderZephyr()
def not_found():
  return None

builders = {}
builders["c"]          = build_c
builders["benchmarks"] = build_c
builders["asm"]        = build_asm
builders["debugger"]   = build_asm
builders["compliance"] = build_compliance
builders["zephyr"]     = build_zephyr

def build(test_category):
  img = builders.get(test_category, not_found)()

  if img == None:
    raise Exception("unknown test type {}".format(test_type))

  print 'build is complete'
  return img.find_driver()
