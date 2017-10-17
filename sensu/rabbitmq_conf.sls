{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu

/etc/sensu/conf.d/rabbitmq.json:
  file.serialize:
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - makedirs: True
    {%- if grains['os_family'] != 'Windows' %}
    - mode: 640
    {%- endif %}
    - dataset:
        rabbitmq:
          host: {{ sensu.rabbitmq.host }}
          port: {{ sensu.rabbitmq.port }}
          vhost: {{ sensu.rabbitmq.vhost }}
          user: {{ sensu.rabbitmq.user }}
          password: {{ sensu.rabbitmq.password }}
          {% if sensu.ssl.enable %}
          ssl:
            cert_chain_file: /etc/sensu/ssl/cert.pem
            private_key_file: /etc/sensu/ssl/key.pem
          {%- endif %}

{%- if salt['pillar.get']('sensu:ssl:enable', false) %}
/etc/sensu/ssl:
  file.directory:
    - user: sensu
    - group: sensu
    - require:
      - pkg: sensu

/etc/sensu/ssl/key.pem:
  file.managed:
    - contents_pillar: sensu:ssl:key_pem
    - require:
      - file: /etc/sensu/ssl

/etc/sensu/ssl/cert.pem:
  file.managed:
    - contents_pillar: sensu:ssl:cert_pem
    - require:
      - file: /etc/sensu/ssl
{%- endif %}
