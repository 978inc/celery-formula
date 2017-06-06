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

@test "celery config file" {
  run test -f /etc/celery/celeryd_configfile.py
}

@test "celery config file length" {
  cat /etc/celery/celeryd_configfile.py | {
	  run wc -l
	[ "$output" -eq "46" ]	
  }
}
