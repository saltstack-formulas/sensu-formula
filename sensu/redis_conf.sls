{% from "sensu/pillar_map.jinja" import sensu with context -%}

/etc/sensu/conf.d/redis.json:
  file.serialize:
    - formatter: json
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu
    - dataset:
        redis:
          host: {{ sensu.redis.host }}
          {% if sensu.redis.password is defined and sensu.redis.password is not none %}password: {{ sensu.redis.password }}{% endif %}
          port: {{ sensu.redis.port }}
          {% if sensu.redis.sentinels is defined and sensu.redis.sentinels is not none %}sentinels: {{ sensu.redis.sentinels }}{% endif %}
