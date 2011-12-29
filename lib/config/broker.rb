require 'amqp'

amqp_config = {
  :host => '10.254.0.88',
  :user => 'guest',
  :pass => 'guest'
}

config['connection'] = AMQP.connect(amqp_config)
