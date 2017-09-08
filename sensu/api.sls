include:
  - sensu
  - sensu.api_conf
{% if salt['pillar.get']('sensu:server:configure_rabbitmq', True) %}
  - sensu.rabbitmq_conf
{% endif %}
  - sensu.redis_conf

sensu-api:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/api.json
{% if salt['pillar.get']('sensu:server:configure_rabbitmq', True) %}
      - file: /etc/sensu/conf.d/rabbitmq.json
{% endif %}
      - file: /etc/sensu/conf.d/redis.json
    - watch:
      - file: /etc/sensu/conf.d/api.json
{% if salt['pillar.get']('sensu:server:configure_rabbitmq', True) %}
      - file: /etc/sensu/conf.d/rabbitmq.json
{% endif %}
      - file: /etc/sensu/conf.d/redis.json
