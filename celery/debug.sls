{% from "celery/map.jinja" import celery with context %}

/tmp/celery-formula.debug:
  file.managed:
    - contents: |
        {% for k,v in celery.items() %}
        {{ k }} => {{ v }}
        {% endfor %}
