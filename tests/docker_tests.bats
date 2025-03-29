#!/usr/bin/env bats

setup() {
  source ../docker/docker.sh
}

@test "gdckr (base command) exists" {
  run type gdckr
  [ "$status" -eq 0 ]
}

@test "gdckri (images) command exists" {
  run type gdckri
  [ "$status" -eq 0 ]
}

@test "gdckrrit (run interactive) command exists" {
  run type gdckrrit
  [ "$status" -eq 0 ]
}

@test "gdckrps (ps) command exists" {
  run type gdckrps
  [ "$status" -eq 0 ]
}

@test "gdckrstp (stop) command exists" {
  run type gdckrstp
  [ "$status" -eq 0 ]
}