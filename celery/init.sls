{% from "celery/map.jinja" import celery with context %}

celery-deps:
  pkg.installed:
    - pkgs:
        - python-pip
        - python-setuptools

{% if celery.from_source %}
celery-worker-bootstrap:
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

{% if celery.bin_env != '/usr' %}
{% set prefix = celery.bin_env %}
{% else %}
{% set prefix = celery.prefix %}
{% endif %}

# install using pip in {{ prefix }} 
celery-install:
  pip.installed:
    - name: celery == {{ celery.version }}
    - bin_env: {{ prefix }}
    - require:
        - pkg: celery-deps

