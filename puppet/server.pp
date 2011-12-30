group { 'puppet':
  ensure => present,
}

package { 'rabbitmq-server':
  ensure => installed,
}

service { 'rabbitmq-server':
  ensure => running,
  enable => true,
  hasstatus => true,
  hasrestart => true,
}
