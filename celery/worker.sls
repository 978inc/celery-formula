{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config %}

{% with worker_queues = salt['pillar.get']('celery:worker_queues',[]) %}
{% set config = celery.get('config', {}) %}
{% set default_queue_cfg = config['worker'] %}

{% set queue_config = [] %}

{% for qdata in worker_queues  %}
# start with defaults
{% set tmp = default_queue_cfg %}
# now apply the overrides
{% do tmp.update(qdata.get('opts', {})) %}
# now update the `qdata` map with the extended options
{% do qdata.update({'opts': tmp}) %}
{% do queue_config.append(qdata) %}
{% endfor %}

worker-bootstrap:
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
        - group: celery-bootstrap
  file.directory:
    - names:
        - {{ celery.run_dir }}
        - {{ celery.working_dir }}
        - {{ celery.log_dir }}
        - {{ celery.config_dir }}
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - mode: 775
    - makedirs: true
    - require:
        - user: worker-bootstrap
    - recurse:
        - user
        - mode
        - group
#
{{ celery.service }}-configfile:
  file.managed:
    - name: {{ celery.config_dir }}/configfile.py
    - contents: |
        #!/usr/bin/env python
        # This file is managed by Saltstack, any changes will be overwritten

        {% for section, data in celery.config.iteritems() %}
        # {{ section.capitalize() }}
        {{ render_config(section, data )}}
        # EOF {{ section.capitalize() }}
        {% endfor %}
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - mode: 644
      
#
{{ celery.service }}-defaults:
  file.managed:
    - name: /etc/default/{{ celery.service }}
    - source: salt://celery/files/celery-defaults.jinja
    - template: jinja
    - user: root
    - mode: 644
    - context:
        pid_file: {{ celery.run_dir }}/%N.pid
        log_dir: {{ celery.log_dir }}
        service_name: {{ celery.service }}
        config: {{ config }}

# 
{{ celery.service }}-service:
  file.managed:
    - name: /lib/systemd/system/{{ celery.service }}.service
    - source: salt://celery/files/celery-service.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
        - user: worker-bootstrap
        - file: worker-bootstrap
    - context:
        user: {{ celery.user }}
        working_dir: {{ celery.working_dir }}
        service_name: {{ celery.service  }}
        queue_config: {{ queue_config }}

#
{{ celery.service }}:
  file.symlink:
    - name: /etc/systemd/system/{{ celery.service }}.service
    - target: /lib/systemd/system/{{ celery.service }}.service
    - force: true
    - require:
        - file: {{ celery.service }}-service
  service.running:
    - init_delay: 10
    - watch:
        - file: {{ celery.service }}-service
        - file: {{ celery.service }}-defaults
#
{% endwith %}
