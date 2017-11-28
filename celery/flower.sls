{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config %}

include:
  - celery.env

{% with prefix = celery.bin_env %}
{% if celery.prefix != '/usr/local' %}
{% set prefix = celery.celery_prefix %}
{% endif %}
  
{% set svc_name = "flower" %}

bootstrap-{{ svc_name }}:
  group.present:
    - name: {{ celery.user }}
    - unless: getent passwd {{ celery.user }}
  user.present:
    - name: {{ celery.user }}
    - fullname: "Celery Service"
    - createhome: true
    - shell: /bin/bash
    - gid_from_name: true
    - groups:
        - {{ celery.user }}
    - unless: getent passwd {{ celery.user }}
    - require:
        - group: bootstrap-{{ svc_name }}
  file.directory:
    - name: {{ celery.working_dir }}/flower
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - mode: 775
    - makedirs: true
    - require:
        - sls: celery.env
          
    - recurse:
        - user
        - mode
        - group
        
{{ svc_name }}:
  pip.installed:
    - name: flower
    - bin_env: {{ prefix }}
    - require:
        - file: bootstrap-{{ svc_name }}
          
  file.managed:
    - name: /etc/systemd/system/{{ svc_name }}.service
    - context:
        bin: {{ prefix }}/bin/flower
        work_dir: {{ celery.working_dir }}
    - source: salt://celery/files/flower-service.jinja
    - template: jinja
    - require:
        - pip: {{ svc_name }}
            
  service.running:
    - enable: true
    - name: {{ svc_name }}
    - watch:
        - file: {{ svc_name }}
      
{% endwith %}
