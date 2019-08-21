{% from "fluentd/map.jinja" import fluentd_agent with context %}
{%- do salt.log.error(fluentd_agent) -%}
{%- if fluentd_agent.get('enabled', False) %}

fluentd_apt_repository:
  cmd.run:
    - name: curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh
    - unless: dpkg-query -W -f='${Status}' td-agent 2>/dev/null | grep "ok installed"

loggly_gem:
  cmd.run:
    - name: td-agent-gem install fluent-plugin-loggly

fluentd_packages_agent:
  pkg.installed:
    - names: {{ fluentd_agent.pkgs }}

fluentd_config_d_dir:
  file.directory:
    - name: {{ fluentd_agent.dir.config }}/config.d
    - makedirs: True
    - mode: 755
    - require:
      - pkg: fluentd_packages_agent

fluentd_config_d_dir_clean:
  file.directory:
    - name: {{ fluentd_agent.dir.config }}/config.d
    - clean: True
    - watch_in:
      - service: fluentd_service_agent

fluentd_positiondb_dir:
  file.directory:
    - name: {{ fluentd_agent.dir.positiondb }}
    - user: {{ fluentd_agent.user }}
    - group: {{ fluentd_agent.group }}
    - makedirs: True
    - mode: 755
    - require:
      - pkg: fluentd_packages_agent

{%- if grains.get('init') == 'systemd' %}

fluentd_config_service:
  file.managed:
    - name: /etc/systemd/system/td-agent.service.d/override.conf
    - source: salt://fluentd/files/override.conf
    - makedirs: true
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      fluentd_agent: {{ fluentd_agent }}

{%- else %}

fluentd_config_service:
  file.managed:
    - name: /etc/default/td-agent
    - source: salt://fluentd/files/default-td-agent
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      fluentd_agent: {{ fluentd_agent }}

{%- endif %}

fluentd_config_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/td-agent.conf
    - source: salt://fluentd/files/td-agent.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      fluentd_agent: {{ fluentd_agent }}

fluentd_grok_pattern_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/config.d/global.grok
    - source: salt://fluentd/files/global.grok
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - require_in:
      - file: fluentd_config_d_dir_clean
    - context:
      fluentd_agent: {{ fluentd_agent }}

{%- set fluentd_config = fluentd_agent.get('config', {}) %}
{%- for name,values in fluentd_config.get('input', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}
input_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/config.d/input-{{ name }}.conf
    - source:
      - salt://fluentd/files/input/_generate.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - require_in:
      - file: fluentd_config_d_dir_clean
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
  {%- if values is mapping %}
        values: {{ values | yaml }}
  {%- else %}
        values: {}
  {%- endif %}
{%- endif %}

{%- endfor %}

{%- for name,values in fluentd_config.get('filter', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}
filter_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/config.d/filter-{{ name }}.conf
    - source:
      - salt://fluentd/files/filter/_generate.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - require_in:
      - file: fluentd_config_d_dir_clean
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
  {%- if values is mapping %}
        values: {{ values | yaml }}
  {%- else %}
        values: {}
  {%- endif %}
{%- endif %}
{%- endfor %}

{%- for name,values in fluentd_config.get('match', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}
match_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/config.d/match-{{ name }}.conf
    - source:
      - salt://fluentd/files/match/_generate.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - require_in:
      - file: fluentd_config_d_dir_clean
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
  {%- if values is mapping %}
        values: {{ values | yaml }}
  {%- else %}
        values: {}
  {%- endif %}
{%- endif %}
{%- endfor %}

{%- for label_name,values in fluentd_config.get('label', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}
label_{{ label_name }}_agent:
  file.managed:
    - name: {{ fluentd_agent.dir.config }}/config.d/label-{{ label_name }}.conf
    - source:
      - salt://fluentd/files/label.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - require_in:
      - file: fluentd_config_d_dir_clean
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        label_name: {{ label_name }}
  {%- if values is mapping %}
        values: {{ values | yaml }}
  {%- else %}
        values: {}
  {%- endif %}
{%- endif %}
{%- endfor %}

fluentd_service_agent:
  service.running:
    - name: {{ fluentd_agent.service_name }}
    - enable: True
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: fluentd_config_agent
      - file: fluentd_config_service
    - require:
      - file: fluentd_positiondb_dir

{%- endif %}
