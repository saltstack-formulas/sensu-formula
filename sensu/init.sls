{% from "sensu/repos_map.jinja" import repos with context -%}

{% if grains['os_family'] == 'Debian' %}
sensu-extra-packages:
  pkg.installed:
    - names:
      - python-apt
      {% if repos.get('enabled') and repos.get('name').startswith("https") %}
      - apt-transport-https
      {% endif %}
    - require_in:
      - pkgrepo: sensu
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
/etc/yum/vars/osmajorrelease:
  file.managed:
    - source: salt://sensu/files/yum/osmajorrelease.template
    - template: jinja
{% endif %}

sensu:
  {% if repos.get('enabled') %}
  pkgrepo.managed:
    - humanname: Sensu Repository
    {% if grains['os_family'] == 'Debian' %}
    - name: {{ repos.get('name') }}
    - file: /etc/apt/sources.list.d/sensu.list
    {%- if repos.get('key_url') %}
    - key_url: {{ repos.get('key_url') }}
    {%- endif %}
    {%- elif grains['os_family'] == 'RedHat' %}
    - baseurl: {{ repos.get('baseurl') }}
    - gpgcheck: {{ repos.get('gpgcheck') }}
    - enabled: 1
    {% endif %}
    - require_in:
      - pkg: sensu
  {%- if repos.get('pkg_version') %}
  pkg.installed:
    - version: {{ repos.get('pkg_version') }}
  {%- else %}
  pkg:
    - latest
  {%- endif %}
  {% endif %}
  {% else %}
  pkg:
    - installed
  {% endif %}

{% if grains['os_family'] != 'Windows' %}
old sensu repository:
  pkgrepo.absent:
    {% if grains['os_family'] == 'Debian' %}
    - name: deb http://repos.sensuapp.org/apt sensu main
    - keyid: 18609E3D7580C77F # key from http://repos.sensuapp.org/apt/pubkey.gpg
    {% elif grains['os_family'] == 'RedHat' %}
    - name: http://repos.sensuapp.org/yum/el/$releasever/$basearch/
    {% endif %}
    - require_in:
      - pkg: sensu
{% endif %}
