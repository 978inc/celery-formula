#!jinja
{% macro displayer(name, thing) %}
{%- if thing is mapping -%}
{% for k,v in thing.items() -%}
{{ displayer('%s_%s'|format(name, k), v) }}
{% endfor -%}
{% elif thing is string -%}
{{ name|lower }} = {{ thing|json }}
{% elif thing is sequence -%}
{{ name|lower }} = {{ thing|json }}
{% elif thing == True or thing == False %}
{{ name|lower }} = {{ thing|capitalize }}
{% elif thing != None  -%}
{{ name|lower }} = {{ thing|json }}
{% else -%}
## {{ name }} is UNDEFINED
{% endif -%}
{% endmacro %}

{% macro render_config(prefix, dat) %}
{%- if dat is mapping -%}
{% for k,v in dat.items()  -%}
{% set kname = '%s_%s'|format(prefix, k) -%}
{{ displayer(kname, v) }}
{%- endfor -%}
{%- else -%}
{{ displayer(prefix, dat) }}
{%- endif -%}
{% endmacro %}
