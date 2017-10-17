{% from "sensu/pillar_map.jinja" import sensu with context -%}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu

uchiwa:
  pkg.installed:
    - require:
      - pkgrepo: sensu
  file.serialize:
    - name: /etc/sensu/uchiwa.json
    - formatter: json
    - user: {{ files.files.user }}
    - group: {{ files.files.group }}
    - mode: 640
    - require:
      - pkg: uchiwa
    - dataset:
        sensu:
          {{ sensu.sites }}
        uchiwa:
          {{ sensu.uchiwa }}

  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/uchiwa.json
    - watch:
      - file: /etc/sensu/uchiwa.json
