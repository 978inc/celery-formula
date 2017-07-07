#!/usr/bin/env bats

@test "celery binary is in our \$PATH" {
  command -v celery
}

@test "celery version is 4.0.2" {
  run celery --version
  [[ ${lines[0]} =~ "4.0.2" ]]
}

@test "verify debugging output is relevant and source_hash is a 'known known'" {
  run bash -c "grep source_hash /tmp/celery-formula.debug"
  [ ${status} = 0 ]
  [[ ${lines[0]} =~ "ca95d6f80ffd83817ff8368310b191b2198beeeb3bc6202c0ddf0ded566391cc" ]]
}
