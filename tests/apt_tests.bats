#!/usr/bin/env bats

setup() {
  source ../apt/apt.sh
}

@test "aptcmd exists" {
  run type aptcmd
  [ "$status" -eq 0 ]
}

@test "gi (install) command exists" {
  run type gi
  [ "$status" -eq 0 ]
}

@test "gu (update) command exists" {
  run type gu
  [ "$status" -eq 0 ]
}

@test "ggup (upgrade) command exists" {
  run type ggup
  [ "$status" -eq 0 ]
}

@test "glu (list upgradable) command exists" {
  run type glu
  [ "$status" -eq 0 ]
}

@test "gli (list installed) command exists" {
  run type gli
  [ "$status" -eq 0 ]
}