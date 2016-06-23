# config valid only for current version of Capistrano
lock "3.5.0"
require 'active_support/core_ext/string'

set :application, ENV["REPO_URL"].split("/").last.gsub(".git","").underscore.camelize
set :repo_url, ENV["REPO_URL"]
set :assets_roles, [:app]
set :deploy_ref, ENV["DEPLOY_REF"]
set :bundle_binstubs, ->{shared_path.join("bin")}

if fetch(:deploy_ref)
  set :branch, fetch(:deploy_ref)
else
  raise "Please set $DEPLOY_REF"
end

set :rvm_ruby_version, "2.3.1"
set :deploy_to, "/usr/local/rails_apps/#{fetch :application}"
set :passenger_roles, :app
set :passenger_restart_runner, :sequence
set :passenger_restart_wait, 5
set :passenger_restart_limit, 2
set :passenger_restart_with_sudo, false
set :passenger_environment_variables, {}
set :passenger_restart_command, "passenger-config restart-app"
set :passenger_restart_options, -> { "#{deploy_to} --ignore-app-not-running" }

# Default value for linked_dirs is []
# NOTE: public/uploads IS USED ONLY FOR THE STAGING ENVIRONMENT
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads)

# Default value for default_env is {}
set :default_env, {
  rails_env: ENV["RAILS_ENV"],
  repo_url: ENV["REPO_URL"],
  deploy_ref: ENV["DEPLOY_REF"],
  deploy_ref_type: ENV["DEPLOY_REF_TYPE"],
  aws_region: ENV["AWS_REGION"],
  aws_elb_name: ENV["AWS_ELB_NAME"],
  aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  s3_bucket_name: ENV["S3_BUCKET_NAME"],
  cloudfront_domain_name: ENV["CLOUDFRONT_DOMAIN_NAME"],
  devise_secret_key: ENV["DEVISE_SECRET_KEY"],
  secret_key_base: ENV["SECRET_KEY_BASE"],
  database_name: ENV["DATABASE_NAME"],
  database_hostname: ENV["DATABASE_HOSTNAME"],
  database_username: ENV["DATABASE_USERNAME"],
  database_password: ENV["DATABASE_PASSWORD"],
  redis_hostname: ENV["REDIS_HOSTNAME"],
  host: ENV["HOST"],
  email_username: ENV["EMAIL_USERNAME"],
  email_password: ENV["EMAIL_PASSWORD"]
}

namespace :deploy do
  desc "create database"
  task :create_database do
    on roles(:db) do |host|
      within "#{release_path}" do
        with rails_env: ENV["RAILS_ENV"] do
          execute :rake, "db:create"
        end
      end
    end
  end
  before :migrate, :create_database

  desc "link dotenv"
  task :link_dotenv do
    on roles(:app) do
      execute "ln -s /home/deploy/.env #{release_path}/.env"
    end
  end
  before :restart, :link_dotenv

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "passenger:restart"
    end
  end
  after :publishing, :restart
end
