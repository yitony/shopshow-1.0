# Set your full path to application.
application = "shopshow"
app_path = "/home/shopshow/www/#{application}"
shared_path = "#{app_path}/shared"
current_path = "#{app_path}/current"

# Set unicorn options
worker_processes 8
preload_app true   # Preload our app for more speed
timeout 180

# 可同时监听 Unix 本地 socket 或 TCP 端口
listen 9001, :tcp_nopush => true
listen "/tmp/unicorn.#{application}.sock", :backlog => 64

# Fill path to your app
working_directory current_path

# Should be 'production' by default, otherwise use other env 
rails_env = ENV['RAILS_ENV'] || 'production'

# Log everything to one file
stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"

# Set master PID location
pid "#{current_path}/tmp/pids/unicorn.pid"

if GC.respond_to?(:copy_on_write_friendly=)
    GC.copy_on_write_friendly = true
end

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end

# 修正无缝重启unicorn后更新的Gem未生效的问题，原因是config/boot.rb会优先从ENV中获取BUNDLE_GEMFILE，
# 而无缝重启时ENV['BUNDLE_GEMFILE']的值并>未被清除，仍指向旧目录的Gemfile
before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{current_path}/Gemfile"
end