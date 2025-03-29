#!/usr/bin/env bats

setup() {
  source ../sys-utils/sys.sh
}

@test "gpoff (poweroff) command exists" {
  run type gpoff
  [ "$status" -eq 0 ]
}

@test "grbt (reboot) command exists" {
  run type grbt
  [ "$status" -eq 0 ]
}