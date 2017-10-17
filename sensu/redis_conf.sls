{% from "sensu/pillar_map.jinja" import sensu with context -%}

/etc/sensu/conf.d/redis.json:
  file.serialize:
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - mode: 644
    - require:
      - pkg: sensu
    - dataset:
        redis:
          host: {{ sensu.redis.host }}
          {% if sensu.redis.password is defined and sensu.redis.password is not none %}password: {{ sensu.redis.password }}{% endif %}
          port: {{ sensu.redis.port }}

