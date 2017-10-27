{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config %}

{% with worker_queues = salt['pillar.get']('celery:worker_queues',[{'name': 'default'}]) %}
{% set config = celery.get('config', {}) %}
{% set default_queue_cfg = config['worker'] %}

# build up a list of dicts, each representing a celery worker queue
{% set queue_config = [] %}
# build up a list of options to pass the celery daemon
{% set celeryd_opts = [] %}

{% for qdata in worker_queues  %}
# start with defaults
{% set tmp = default_queue_cfg %}
# now apply the overrides
{% do tmp.update(qdata.get('opts', {})) %}
# now update the `qdata` map with the extended options
{% do qdata.update({'opts': tmp}) %}
# append to our list of que dicts
{% do queue_config.append(qdata) %}
# append to the celeryd options list
{% do celeryd_opts.append(' -Q:%d %s -c:%d %d '|format(loop.index, qdata.get('name', 'default'), loop.index, qdata.get('concurrency', config['total_workers']))) -%}
{% endfor %}
# EOF worker_queues

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
        - group: worker-bootstrap
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
        - user: worker-bootstrap
    - recurse:
        - user
        - mode
        - group

#
{{ celery.service }}-configfile:
  file.managed:
    - name: {{ celery.working_dir }}/{{ celery.config_module }}.py
    - source: salt://celery/files/celery-config.jinja
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - mode: 644
    - template: jinja


#
{{ celery.service }}-defaults:
  file.managed:
    - name: /etc/default/{{ celery.service }}
    - source: salt://celery/files/celery-defaults.jinja
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
        - file: {{ celery.service }}-configfile
  service.running:
    - init_delay: 10
    - watch:
        - file: {{ celery.service }}-service
        - file: {{ celery.service }}-defaults
        - file: {{ celery.service }}-configfile
#
{% endwith %}
