#!jinja|yaml
{% from "celery/map.jinja" import celery with context %}

/tmp/celery-formula.debug:
  file.managed:
    - template: jinja
    - contents: |
        #!jinja
        {% for k,v in celery.items() %}
        {{ k }} => {{ v |json }}
        {% endfor %}
