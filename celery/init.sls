{% from "celery/map.jinja" import celery with context %}

celery-deps:
  pkg.installed:
    - pkgs:
        - python-pip
        - python-setuptools

celery-fetch-tarball:
  archive.extracted:
    - name: {{ celery.build_dir }}
    - source: {{ 'https://github.com/celery/celery/archive/v%s.tar.gz'|format(celery.version) }}
    - source_hash: {{ celery.source_hash }}
    - archive_format: tar
    - user: root
    - group: root
    - if_missing: {{ celery.build_dir }}/celery-{{ celery.version }}

celery-install:
  cmd.run:
    - runas: root
    - name: |
        cd {{ '%s/celery-%s'|format(celery.build_dir, celery.version) }}
        python setup.py install -q
    - shell: /bin/bash
    - unless:
        - /usr/local/bin/celery --version | grep {{ celery.version }}
    - requires:
        - archive: celery-fetch-tarball
        - pkg: celery-deps
          
