{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/service_map.jinja" import services with context %}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu
{% if salt['pillar.get']('sensu:server:configure_rabbitmq', True) %}
  - sensu.rabbitmq_conf
{% endif %}
{% if salt['pillar.get']('sensu:transport:name') %}
  - sensu.transport_conf
{% endif %}
{% if salt['pillar.get']('sensu:transport:name') == 'redis' %}
  - sensu.redis_conf
{% endif %}

{% if grains['os_family'] == 'Windows' %}
/opt/sensu/bin/sensu-client.xml:
  file.managed:
    - source: salt://sensu/files/windows/sensu-client.xml
    - template: jinja
    - require:
      - pkg: sensu
sensu_install_dotnet35:
  cmd.run:
    - name: 'powershell.exe "Import-Module ServerManager;Add-WindowsFeature Net-Framework-Core"'
sensu_enable_windows_service:
  cmd.run:
    - name: 'sc create sensu-client start= delayed-auto binPath= c:\opt\sensu\bin\sensu-client.exe DisplayName= "Sensu Client"'
    - unless: 'sc query sensu-client'
{% endif %}

{%- if salt['pillar.get']('sensu:standalone_checks') %}
sensu_standalone_checks_file:
  file.serialize:
    - name: {{ sensu.paths.standalone_checks_file }}
    - dataset:
        checks: {{ salt['pillar.get']('sensu:standalone_checks') }}
    - formatter: json
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-client
{%- else %}
sensu_standalone_checks_file:
  file.absent:
    - name: {{ sensu.paths.standalone_checks_file }}
{%- endif %}

/etc/sensu/conf.d/client.json:
  file.serialize:
    - formatter: json
    - user: {{files.files.user}}
    - group: {{files.files.group}}
    {% if grains['os_family'] != 'Windows' %}
    - mode: 644
    {% endif %}
    - makedirs: True
    - dataset:
        client:
          name: {{ sensu.client.name }}
          address: {{ sensu.client.address }}
          subscriptions: {{ sensu.client.subscriptions + pillar.get('role', []) }}
          safe_mode: {{ sensu.client.safe_mode }}
          {% if sensu.client.get('keepalive') %}
          keepalive: {{ sensu.client.keepalive }}
          {% endif %}
          {% if sensu.client.get("command_tokens") %}
          command_tokens: {{ sensu.client.command_tokens }}
          {% endif %}
          {% if sensu.client.get("redact") %}
          redact: {{ sensu.client.redact }}
          {% endif %}
          {% if sensu.client.get("override_attributes") %}
          {% for attribute, values in sensu.client.override_attributes.items() %}
          {{ attribute }}: {{ values|json }}
          {% endfor %}
          {% endif %}
    - require:
      - pkg: sensu

/etc/sensu/plugins:
  file.recurse:
    - source: salt://{{ sensu.paths.plugins }}
    {% if grains['os_family'] != 'Windows' %}
    - file_mode: 555
    {% endif %}
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-client
    - watch_in:
      - service: sensu-client

{% if grains['os_family'] != 'Windows' %}
/etc/default/sensu:
  file.replace:
{%- if sensu.client.embedded_ruby %}
    - pattern: 'EMBEDDED_RUBY=false'
    - repl: 'EMBEDDED_RUBY=true'
{%- else %}
    - pattern: 'EMBEDDED_RUBY=true'
    - repl: 'EMBEDDED_RUBY=false'
{%- endif %}
    - watch_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.nagios_plugins %}
{{ services.nagios_plugins }}:
  pkg:
    - installed
    - require_in:
      - service: sensu-client
{% endif %}

{% set gem_list = salt['pillar.get']('sensu:client:install_gems', []) %}
{% for gem in gem_list %}
{% if gem is mapping %}
{% set gem_name = gem.name %}
{% else %}
{% set gem_name = gem %}
{% endif %}
install_{{ gem_name }}:
  gem.installed:
    - name: {{ gem_name }}
    {% if sensu.client.embedded_ruby %}
    - gem_bin: /opt/sensu/embedded/bin/gem
    {% endif %}
    {% if gem.version is defined %}
    - version: {{ gem.version }}
    {% endif %}
    - rdoc: False
    - ri: False
    - proxy: {{ salt['pillar.get']('sensu:client:gem_proxy') }}
    - source: {{ salt['pillar.get']('sensu:client:gem_source') }}
{% endfor %}

sensu-client:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/client.json
{% if salt['pillar.get']('sensu:server:configure_rabbitmq', True) %}
      - file: /etc/sensu/conf.d/rabbitmq.json
{% endif %}
{% if salt['pillar.get']('sensu:transport:name') %}
      - file: /etc/sensu/conf.d/transport.json
{% endif %}
    - watch:
      - file: /etc/sensu/conf.d/*
