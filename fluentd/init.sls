{%- do salt.log.info('testing jinja logging') -%}
{%- if pillar.fluentd %}
include:
  {%- if pillar.fluentd is defined %}
  - fluentd.agent
  {%- endif %}
{%- endif %}
