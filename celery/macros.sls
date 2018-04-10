#!jinja
{% from "celery/map.jinja" import celery with context %}

## BEGIN config rendering - i.e. worker_queues
{% set worker_queues = salt['pillar.get']('celery:worker_queues', []) %}
{% set config = celery.get('config', {}) %}
{% set default_queue_cfg = config['worker'] %}

# build up a map of dicts, each representing a celery worker queue
{% set queue_config = {} %}

# build up a list of options to pass the celery daemon
{% set celeryd_opts = [] %}

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


{% macro displayer(name, thing) -%}
{%- if thing is mapping -%}
{% for k,v in thing.items() -%}
{{ displayer('%s_%s'|format(name, k), v) }}
{%- endfor -%}
{% elif thing is string and thing|string != 'None' -%}
{{ name|lower }} = {{ thing|json }}
{% elif thing is sequence and thing|string != 'None' -%}
{{ name|lower }} = {{ thing|json }}
{% elif thing == True or thing == False -%}
{{ name|lower }} = {{ thing|capitalize }}
{% elif thing != None and thing|string != 'None'  -%}
{{ name|lower }} = {{ thing|json }}
{% endif -%}
{%- endmacro %}

{% macro render_config(prefix, dat) -%}
{%- if dat is mapping -%}
{% for k,v in dat.items()  -%}
{%- set kname = '%s_%s'|format(prefix, k) -%}
{{ displayer(kname, v) }}
{%- endfor -%}
{%- else -%}
{{ displayer(prefix, dat) }}
{%- endif -%}
{% endmacro %}

{% macro create_file(filename, template_name, user) %}
{% set fn = filename %}
{% set tpl = template_name %}
{{ fn }}:
  file.managed:
    - source:
        - salt://files/celery/{{ tpl }}.jinja
        - salt://celery/files/{{ tpl }}.jinja
    - template: jinja
    - keep_source: true
    - user: {{ celery.user }}
    - group: {{ celery.user }}
    - require:
        - user: celery-user-{{ celery.user }}
        - file: worker-bootstrap
    - context:
        user: {{ user }}
        working_dir: {{ celery.working_dir }}
        run_dir: {{ celery.run_dir }}
        log_dir: {{ celery.log_dir }}
        log_level: {{ celery.get('log_level', 'WARNING') }}
        service_name: {{ celery.service  }}
        queue_names: {{ queue_config.keys() }}
        queue_config: {{ queue_config  }}
        total_workers: {{ worker_queues|length }}
        celeryd_opts: {{ celeryd_opts|join(' ') }}
        config_module: {{ celery.config_module }}
        config: {{ celery.config | json }}
        prefix: {{ celery.prefix }}
{% endmacro %}

