# SPDX-License-Identifier: Apache-2.0

#NOTE: it seems that -Os causes some RIPE tests to fail perfoming attack
#zephyr_compile_options(-march=rv32imc -Os)
zephyr_compile_options(-march=rv32imc)

zephyr_sources()
zephyr_sources(beehive_clock.c mte_init.c)
