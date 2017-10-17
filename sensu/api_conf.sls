{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu

/etc/sensu/conf.d/api.json:
  file.serialize:
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - mode: 644
    - require:
      - pkg: sensu
    - dataset:
        api:
          host: {{ sensu.api.host }}
          password: {{ sensu.api.password }}
          port: {{ sensu.api.port }}
          user: {{ sensu.api.user }}

