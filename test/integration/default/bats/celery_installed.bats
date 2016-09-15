#!/usr/bin/env bats

@test "celery binary is in our \$PATH" {
  command -v celery
}

@test "celery version is 3.1.23" {
  run celery --version
  [[ ${lines[0]} =~ "3.1.23" ]]
}

@test "verify debugging output is relevant and source_hash is a 'known known'" {
  run bash -c "grep source_hash /tmp/celery-formula.debug"
  [ ${status} = 0 ]
  [[ ${lines[0]} =~ "2c38b56599edb0a23725dc750d689100fba8519e4de2542146d351e346dfb5c3" ]]
}
