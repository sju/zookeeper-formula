{% set zookeeper_version   = salt['pillar.get']('zookeeper:version', '3.4.5') %}
{% set java_home           = salt['pillar.get']('java_home', '/usr/java/default') %}
{% set zookeeper_alt_home  = salt['pillar.get']('zookeeper:prefix', '/usr/lib/zookeeper') %}
{% set zookeeper_real_home = zookeeper_alt_home + '-' + zookeeper_version %}
{% set zookeeper_alt_conf  = '/etc/zookeeper/conf' %}
{% set zookeeper_real_conf = zookeeper_alt_conf + '-' + zookeeper_version %}
{% set zookeeper_port = salt['pillar.get']('zookeeper:uid', '2181') %}
{% set zookeeper_bind_address = salt['pillar.get']('zookeeper:bind_address', '0.0.0.0') %}
{% set zookeeper_data_dir  = salt['pillar.get']('zookeeper:data_dir', '/var/lib/zookeeper/data') %}

{% from "zookeeper/map.jinja" import zookeeper_map with context %}

include:
  - zookeeper

/etc/zookeeper:
  file.directory:
    - user: root
    - group: root

{{ zookeeper_data_dir }}:
  file.directory:
    - user: zookeeper
    - group: zookeeper
    - makedirs: True

move-zookeeper-dist-conf:
  cmd.run:
    - name: mv {{ zookeeper_real_home }}/conf {{ zookeeper_real_conf }}
    - unless: test -L {{ zookeeper_real_home }}/conf
    - require:
      - file.directory: {{ zookeeper_real_home }}
      - file.directory: /etc/zookeeper

zookeeper-config-link:
  alternatives.install:
    - link: {{ zookeeper_alt_conf }}
    - path: {{ zookeeper_real_conf }}
    - priority: 30

{{ zookeeper_real_home }}/conf:
  file.symlink:
    - target: {{ zookeeper_real_conf }}
    - require:
      - cmd: move-zookeeper-dist-conf

{{ zookeeper_real_conf }}/zoo.cfg:
  file.managed:
    - source: salt://zookeeper/zoo.cfg.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      - zookeeper_port: {{ zookeeper_port }}
      - zookeeper_bind_address: {{ zookeeper_bind_address }}
      - zookeeper_data_dir: {{ zookeeper_data_dir }}

{{ zookeeper_real_conf }}/zookeeper-env.sh:
  file.managed:
    - source: salt://zookeeper/zookeeper-env.sh.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - context:
      java_home: {{ java_home }}

{% if zookeeper_map.service_script %}

{{ zookeeper_map.service_script }}:
  file.managed:
    - source: salt://zookeeper/{{ zookeeper_map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ zookeeper_map.service_script_mode }}
    - template: jinja
    - context:
      zookeeper_alt_home: {{ zookeeper_alt_home }}

zookeeper-service:
  service.running:
    - name: zookeeper
    - enable: true
    - require:
      - file.directory: {{ zookeeper_data_dir }}

{% endif %}


