{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config %}

include:
  - celery.env
  
{% with worker_queues = salt['pillar.get']('celery:worker_queues', []) %}
{% set config = celery.get('config', {}) %}
{% set default_queue_cfg = config['worker'] %}

{% set svc_file = "/etc/systemd/system/%s.service"|format(celery.service) %}
{% set def_file = "/etc/default/%s"|format(celery.service) %}
{% set cfg_file = "%s/%s.py"|format(celery.working_dir, celery.config_module) %}
# svc_file => {{ svc_file }}

# build up a map of dicts, each representing a celery worker queue
{% set queue_config = {} %}

# build up a list of options to pass the celery daemon
{% set celeryd_opts = ['-c 1'] %}

{% for qdata in worker_queues  %}
# start with defaults
{% set tmp = default_queue_cfg %}
# now apply the overrides
{% do tmp.update(qdata.get('opts', {})) %}
# now update the `qdata` map with the extended options
{% do qdata.update({'opts': tmp}) %}
{% set qname = qdata.get('name', 'default') %}
{% do queue_config.update({qname: qdata})%}

{% set cc = qdata.get('concurrency', 0) %}
{% if cc > 0 %}
# append concurrency settings to the command list
{% do celeryd_opts.append('-c:%d %d'|format(loop.index, cc)) -%}
{% endif %}

{% endfor %}
# EOF worker_queues
# queue_config => {{ queue_config }}

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
    - mode: 775
    - makedirs: true
    - require:
        - user: celery-user-{{ celery.user }}
    - recurse:
        - user
        - mode
        - group

# creating {{ cfg_file }} from templates in salt://files/celery or salt://celery/files 
{{ cfg_file }}:
  file.managed:
    - source:
        - salt://files/celery/celery-config.jinja
        - salt://celery/files/celery-config.jinja
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - mode: 644
    - template: jinja
    - context:
        queue_config: {{ queue_config }}

# creating {{ def_file }} from templates in salt://files/celery or salt://celery/files
{{ def_file }}:  
  file.managed:
    - source:
        - salt://files/celery/celery-defaults.jinja
        - salt://celery/files/celery-defaults.jinja
    - template: jinja
    - user: root
    - mode: 644
    - context:
        log_level: {{ celery.get('log_level', 'WARNING') }}
        run_dir: {{ celery.run_dir }}
        log_dir: {{ celery.log_dir }}
        service_name: {{ celery.service }}
        config: {{ config }}
        working_dir: {{ celery.working_dir }}
        celeryd_opts: {{ celeryd_opts|join(' ') }}
        queue_config: {{ queue_config }}

# creating {{ svc_file }} from templates in salt://files/celery or salt://celery/files
{{ svc_file }}:
  file.managed:
    - source:
        - salt://files/celery/celery-service.jinja        
        - salt://celery/files/celery-service.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
        - user: celery-user-{{ celery.user }}
        - file: worker-bootstrap
    - context:
        user: {{ celery.user }}
        working_dir: {{ celery.working_dir }}
        service_name: {{ celery.service  }}
        queue_config: {{ queue_config }}
        total_workers: {{ worker_queues|length }}
        celeryd_opts: {{ celeryd_opts|join(' ') }}

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
{% endwith %}
