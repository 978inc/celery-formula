redis:
  pkg.installed:
    - pkgs:
        - redis-server
        - python-hiredis

/etc/hosts:
  file.append:
    - text: 
        - 127.0.0.1 salt
    - template: jinja

