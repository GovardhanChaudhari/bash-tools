#!/usr/bin/env bats

setup() {
  source ../git/gvc-git-functions.sh
  TEST_REPO="test_repo_$(date +%s)"
  git init "$TEST_REPO"
  cd "$TEST_REPO"
}

teardown() {
  cd ..
  rm -rf "$TEST_REPO"
}

@test "ggc (commit) command exists" {
  run type ggc
  [ "$status" -eq 0 ]
}

@test "ggcp (commit and push) command exists" {
  run type ggcp
  [ "$status" -eq 0 ]
}

@test "gad (git add) command exists" {
  run type gad
  [ "$status" -eq 0 ]
}

@test "gac (add and commit) command exists" {
  run type gac
  [ "$status" -eq 0 ]
}

@test "ggco (checkout) command exists" {
  run type ggco
  [ "$status" -eq 0 ]
}

@test "get_current_branch_name works" {
  touch testfile
  git add testfile
  git commit -m "Initial commit"
  run get_current_branch_name
  [ "$status" -eq 0 ]
  [ "$output" = "master" ]
}