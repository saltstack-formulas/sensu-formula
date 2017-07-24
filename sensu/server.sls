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
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{%- if salt['pillar.get']('sensu:handlers') %}

sensu_handlers_file:
  file.serialize:
    - name: {{ sensu.paths.handlers_file }}
    - dataset_pillar: sensu:handlers
    - formatter: JSON
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
    {% if sensu.client.embedded_ruby %}
    - gem_bin: /opt/sensu/embedded/bin/gem
    {% else %}
    - gem_bin: None
    {% endif %}
    {% if gem.version is defined %}
    - version: {{ gem.version }}
    {% endif %}
    - rdoc: False
    - ri: False
    {% if salt['pillar.get']('sensu:client:gem_proxy') %}
    - proxy: {{ salt['pillar.get']('sensu:client:gem_proxy') }}
    {% endif %}
    {% if salt['pillar.get']('sensu:client:gem_source') %}
    - source: {{ salt['pillar.get']('sensu:client:gem_source') }}
    {% endif %}
{% endfor %}

sensu-server:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/redis.json
      - file: /etc/sensu/conf.d/rabbitmq.json
