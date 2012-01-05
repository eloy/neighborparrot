# Neighborparrot server deploy
# Run with puppet apply -e "include neighborparrot"
#=======================================

class neighborparrot {
  
  # Capistrano
  $cap_deployer = "deployer"
  $cap_deploy_to = '/var/local/apps'
  $cap_path = '/etc/capistrano'

    # Setup app path
  $app_name = 'neighborparrot'
  $app_path = "${cap_deploy_to}/${app_name}/current"
  $app_owner = 'neighborparrot'
  $app_group = 'neighborparrot'
  $cap_app_path = "${cap_path}/${app_name}"


   # Rabbit MQ config for public broadcast channel
  $rabbit_vhost = '/pub'
  $rabbit_user = 'theparrot'
  $rabbit_password = 'changeit'

  
  Exec { path => ['/bin', '/usr/bin', '/usr/sbin'] }

  # Create user and group for the app
  group { $app_group:
    ensure => present,
  }
  user { $app_owner:
    ensure => present,
    gid => $app_group,
    home => $app_path,
    managehome => false,
    shell => '/bin/false'
  }

  # Init script
  file { 'init script':
    path    => "/etc/init.d/${app_name}",
    ensure  => file,
    mode => 0755,
    content  => template("neighborparrot/init-script.erb"),
  }

  # Rabbit MQ
  package { 'rabbitmq-server':
    ensure => installed,
  }
  
  service { 'rabbitmq-server':
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
    require => Package['rabbitmq-server']
  }

  # Create rabbit vhost
  exec { 'rabbit-vhost':
    command => "rabbitmqctl add_vhost ${rabbit_vhost}",
    unless => "rabbitmqctl list_vhosts  | grep ${rabbit_vhost} -q",
    require => Service['rabbitmq-server'],
  }

  # Create user
  exec { 'rabbit-user':
    command => "rabbitmqctl add_user ${rabbit_user} ${rabbit_password}", 
    unless => "rabbitmqctl list_users  | grep ${rabbit_user} -q",
    require => Exec['rabbit-vhost']
  }

  # Create ACL
  exec { 'rabbit-acl': 
    command => "rabbitmqctl set_permissions -p ${rabbit_vhost} ${rabbit_user} \".*\" \".*\" \".*\"",
    unless => "rabbitmqctl list_permissions -p ${rabbit_vhost} | grep ${rabbit_user} -q",
    require => Exec['rabbit-user']
  }

  # HA Proxy
  package {'haproxy':
    ensure => installed,
    require => File['haproxy-config'],
  }

  service { 'haproxy':
    ensure => running,
    enable => true,
    hasstatus => false,
    hasrestart => true,
    require => File['haproxy-defaults']
  }
  
  # Override defaults
  file { 'haproxy-defaults':
    path    => "/etc/default/haproxy",
    ensure  => file,
    mode => 0755,
    source   => "puppet:///modules/neighborparrot/haproxy.defaults",
  }
  
  # Config
  file { 'haproxy-config':
    path    => "/etc/haproxy/haproxy.cfg",
    ensure  => file,
    mode => 0644,
    content  => template("neighborparrot/haproxy.cfg.erb"),
  }
  
  # Capistrano
  # Site file for capistrano files
  file { 'capistrano_app_repository' :
    path => $cap_app_path,
    ensure => directory,
    recurse => true,
  }

  # create rabbitmq config
  file { 'broker.rb':
    path    => "${cap_app_path}/broker.rb",
    ensure  => file,
    require => Package['rabbitmq-server'],
    content  => template("neighborparrot/broker.config.erb"),
  }

  
}
