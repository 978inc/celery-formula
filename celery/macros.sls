{% macro displayer(name, thing) %}
{%- if thing is mapping -%}
{% for k,v in thing.items() -%}
{{ displayer('%s_%s'|format(name, k), v) }}
{% endfor -%}
{% elif thing is string -%}
{{ name|upper }}={{ thing }}
{% elif thing is sequence -%}
{{ name|upper }}={{ thing|json }}
{% elif thing == True or thing == False %}
{{ name|upper }}={{ thing|lower }}
{% elif thing != None  -%}
{{ name|upper }}={{ thing }}
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
