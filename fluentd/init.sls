{%- if pillar.fluentd %}
{%- do salt.log.error('testing jinja logging') -%}
include:
  {%- if pillar.fluentd is defined %}
  - fluentd.agent
  {%- endif %}
{%- endif %}
