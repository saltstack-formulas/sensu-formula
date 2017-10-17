{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu
  - sensu.api_conf # Some handlers need to access the API server
  - sensu.rabbitmq_conf
  - sensu.redis_conf

/etc/sensu/conf.d:
  file.recurse:
    - source: salt://{{ sensu.paths.conf_d }}
    - template: jinja
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{%- if salt['pillar.get']('sensu:checks') %}
sensu_subscription_checks_file:
  file.serialize:
    - name: {{ sensu.paths.checks_file }}
    - dataset:
        checks: {{ salt['pillar.get']('sensu:checks') }}
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server
{%- else %}
sensu_subscription_checks_file:
  file.absent:
    - name: {{ sensu.paths.checks_file }}
{%- endif %}

{%- if salt['pillar.get']('sensu:handlers') %}

sensu_handlers_file:
  file.serialize:
    - name: {{ sensu.paths.handlers_file }}
    - dataset_pillar: sensu:handlers
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{% endif %}

/etc/sensu/extensions:
  file.recurse:
    - source: salt://{{ sensu.paths.extensions }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

/etc/sensu/mutators:
  file.recurse:
    - source: salt://{{ sensu.paths.mutators }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

/etc/sensu/handlers:
  file.recurse:
    - source: salt://{{ sensu.paths.handlers }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-server
    - watch_in:
      - service: sensu-server

{% set gem_list = salt['pillar.get']('sensu:server:install_gems', []) %}
{% for gem in gem_list %}
{% if gem is mapping %}
{% set gem_name = gem.name %}
{% else %}
{% set gem_name = gem %}
{% endif %}
install_{{ gem_name }}:
  gem.installed:
    - name: {{ gem_name }}
    {% if sensu.server.embedded_ruby %}
    - gem_bin: /opt/sensu/embedded/bin/gem
    {% endif %}
    {% if gem.version is defined %}
    - version: {{ gem.version }}
    {% endif %}
    - rdoc: False
    - ri: False
    - proxy: {{ salt['pillar.get']('sensu:server:gem_proxy') }}
    - source: {{ salt['pillar.get']('sensu:server:gem_source') }}
{% endfor %}

sensu-server:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/redis.json
      - file: /etc/sensu/conf.d/rabbitmq.json
