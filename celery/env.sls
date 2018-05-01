#!jinja|yaml
{% from "celery/map.jinja" import celery with context %}
{% from 'celery/macros.sls' import render_config %}

{% set config = celery.get('config', {}) %}
{% set default_queue_cfg = config['worker'] %}


celery-deps:
  pkg.installed:
    - pkgs:
        - python-pip
        - python-setuptools
    - unless:
        - test -x pip

{% if celery.from_source %}
celery-bootstrap:
  archive.extracted:
    - name: {{ celery.prefix }}/src
    - source: {{ 'https://github.com/celery/celery/archive/v%s.tar.gz'|format(celery.version) }}
    - source_hash: {{ celery.source_hash }}
    - archive_format: tar
    - user: root
    - group: root

celery-install:
  cmd.run:
    - runas: root
    - name: |
        cd {{ '%s/src/celery-%s'|format(celery.prefix, celery.version) }}
        {{ celery.bin_env  }}/bin/python setup.py install -q
    - shell: /bin/bash
    - unless:
        - {{ celery.prefix }}/bin/celery --version | grep {{ celery.version }}
    - requires:
        - archive: celery-worker-bootstrap
        - pkg: celery-deps
          
{% else %}

{% with prefix = celery.bin_env %}
{% if celery.prefix != '/usr/local' %}
{% set prefix = celery.prefix %}
{% endif %}

# install using pip in {{ prefix }} 
celery-install:
  cmd.run:
    - name: |
        {{ prefix }}/bin/pip install celery=={{ celery.version }}
    - require:
        - pkg: celery-deps
{% endwith %}
{% endif %}
