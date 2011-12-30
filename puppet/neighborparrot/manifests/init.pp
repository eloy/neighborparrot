# Neighborparrot server deploy
#=======================================
class neighborparrot {
  
  # Setup app path
  $app_name = 'neighborparrot'
  $app_path = '/var/local/neighborparrot'
  $app_owner = 'neighborparrot'
  $app_group = 'neighborparrot'

  Exec { path => ['/bin', '/usr/bin', '/usr/sbin'] }

  # Rabbit MQ config
  $rabbit_vhost = 'neighborparrot'
  $rabbit_user = 'theparrot'
  $rabbit_password = 'changeit'

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

  # Setup application
  file { 'broker.rb':
    path    => "${app_path}/lib/config/broker.rb",
    ensure  => file,
    require => Package['rabbitmq-server'],
    content  => template("neighborparrot/broker.config.erb"),
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
  }

  # Create rabbit vhost
  exec { "rabbitmqctl add_vhost /${rabbit_vhost}":
    unless => "rabbitmqctl list_vhosts  | grep ${rabbit_vhost} -q"
  }

  # Create user
  exec { "rabbitmqctl add_user ${rabbit_user} ${rabbit_password}":
    unless => "rabbitmqctl list_users  | grep ${rabbit_user} -q"
  }

  # Create user
  exec { "rabbitmqctl set_permissions -p /${rabbit_vhost} ${rabbit_user} \"^${rabbit_user}-.*\" \".*\" \".*\"":
    unless => "rabbitmqctl list_permissions -p /${rabbit_vhost} | grep ${rabbit_user} -q"
  }

  
}
