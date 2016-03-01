{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu

/etc/sensu/conf.d/api.json:
  file.serialize:
    - formatter: json
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu
    - dataset:
        api:
          host: {{ sensu.api.host }}
          port: {{ sensu.api.port }}
          {% if sensu.api.password is defined and sensu.api.password is not none %}password: {{ sensu.api.password }}{% endif %}
          {% if sensu.api.user is defined and sensu.api.user is not none %}user: {{ sensu.api.user }}{% endif %}

