#!/usr/bin/env bats

@test "celery defaults" {
  run test -f /etc/default/celeryd
}

@test "celeryd.service exists" {
  run test -f /etc/systemd/system/celeryd.service
}

@test "celeryd is running" {
  run systemctl status celeryd.service
  [ ${status} = 0 ]
}
