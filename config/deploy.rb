set :user, "deployer"
# ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "keypair")]
set :ssh_options, {:forward_agent => true}
ssh_options[:user] = "deployer"
default_run_options[:pty] = true

set :application, "neighborparrot"
set :repository,  "git@github.com:harlock/neighborparrot.git"
set :use_sudo, false
set :deploy_to, "/var/local/apps/neighborparrot"
set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

role :web, "neighborparrot.net"
role :app, "neighborparrot.net"
role :db,  "neighborparrot.net", :primary => true


namespace :deploy do

  # task :puppet, :roles => :app do
  #   run "sudo puppet agent -t"
  # end

  #----------------------------------------------------------------------
  # Server control
  #----------------------------------------------------------------------

  task :start, :roles => :app do
    run "sudo /etc/init.d/neighborparrot start"
  end

  task :stop, :roles => :app do
    run "sudo /etc/init.d/neighborparrot stop"
  end

  task :restart, :roles => :app do
    run "sudo /etc/init.d/neighborparrot restart"
  end

  #----------------------------------------------------------------------
  # db tasks
  #----------------------------------------------------------------------

  task :migrate, :roles => :app do
  end

  task :migrate_redo, :roles => :app do
  end

  task :disable do
  end

  task :enable do
  end

  task :prepare_app do
    # copy the configuration to the correct place
    run "cp /etc/capistrano/neighborparrot/broker.rb #{release_path}/config/broker.rb"
    run "cd #{release_path} && bundle install --without=test development --deployment"
    # Precompile assets
    run "mkdir #{release_path}/public/js"
    # run "cd #{release_path}; bundle exec rake precompile_assets"
  end

  after "deploy:update_code", "deploy:prepare_app"
end
