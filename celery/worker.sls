{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config, create_file %}

include:
  - celery.env
  
{% set svc_file = "/etc/systemd/system/%s.service"|format(celery.service) %}
{% set def_file = "/etc/default/%s"|format(celery.service) %}
{% set cfg_file = "%s/%s.py"|format(celery.working_dir, celery.config_module) %}
# svc_file => {{ svc_file }}

# assert user {{ celery.user }} exists
celery-user-{{ celery.user }}:
  group.present:
    - name: {{ celery.user }}
    - unless:
        - getent passwd {{ celery.user }}
  user.present:
    - name: {{ celery.user }}
    - fullname: "Celery Service"
    - createhome: true
    - shell: /bin/bash
    - gid_from_name: true
    - groups:
        - {{ celery.user }}
    - unless:
        - getent passwd {{ celery.user }}
    - require:
        - group: celery-user-{{ celery.user }}

# Creating celery related dirs
worker-bootstrap:
  file.directory:
    - names:
        - {{ celery.run_dir }}
        - {{ celery.working_dir }}
        - {{ celery.log_dir }}
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - makedirs: true
    - require:
        - user: celery-user-{{ celery.user }}


## Generate the file.managed states using the macros.create_file
{{ create_file(cfg_file, "celery-config", celery.user) }}
{{ create_file(def_file, "celery-defaults", celery.user) }}
{{ create_file(svc_file, "celery-service", celery.user) }}


# activating service =>  {{ celery.service }}
{{ celery.service }}:
  service.running:
    - enable: true
    - init_delay: 3
    - sig: celery
    - unmask: true
    - unmask_runtime: true
    - watch:
        - file: {{ cfg_file }}
        - file: {{ def_file }}
        - file: {{ svc_file }}

