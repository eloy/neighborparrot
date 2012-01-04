# Neighborparrot server deploy
# Run with puppet apply -e "include neighborparrot"
#=======================================

class neighborparrot {
  
  # Setup app path
  $app_name = 'neighborparrot'
  $app_path = '/var/local/neighborparrot'
  $app_owner = 'neighborparrot'
  $app_group = 'neighborparrot'

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
  
}
