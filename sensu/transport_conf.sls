{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu

/etc/sensu/conf.d/transport.json:
  file.serialize:
    - formatter: json
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu
    - dataset:
        transport:
          name: {{ sensu.transport.name }}
          reconnect_on_error: {{ sensu.transport.reconnect_on_error }}
