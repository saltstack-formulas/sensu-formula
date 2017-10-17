{% from "sensu/pillar_map.jinja" import sensu with context -%}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu

/etc/sensu/conf.d/transport.json:
  file.serialize:
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    {%- if grains['os_family'] != 'Windows' %}
    - mode: 644
    {%- endif %}
    - require:
      - pkg: sensu
    - dataset:
        transport:
          name: {{ sensu.transport.name }}
          reconnect_on_error: {{ sensu.transport.reconnect_on_error }}
