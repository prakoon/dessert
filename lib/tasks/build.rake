namespace :build do

  APP_PREFIX      = "ds"
  HEROKU_PREFIX   = "heroku"
  STACK           = "cedar"

  desc "Create a new test app"
  task :create_test_app => :environment do
    setup_environment
    check_environment
    input_new_app_name
    check_app_not_exists

    create_app

    turn_on_maintenance
    push_code
    turn_off_maintenance
  end

  desc "Push recent code to test app"
  task :push_test_app => :environment do
    setup_environment
    check_environment
    input_new_app_name
    check_app_exists

    turn_on_maintenance
    push_code
    turn_off_maintenance
  end

  def setup_environment
    @branch = `git symbolic-ref -q HEAD`.chomp
    @branch = @branch.gsub /^refs\/heads\//, ''
    if @branch.index("#{APP_PREFIX}-")
      @app_name = @branch.gsub(/[^-a-z0-9]/, '-')
    else
      @app_name = "#{APP_PREFIX}-#{@branch}".gsub(/[^-a-z0-9]/, '-')
    end
    @git_remote  = "#{HEROKU_PREFIX}-#{@app_name}"
  end

  def check_environment
    unless `git status --porcelain`.blank?
      $stderr.puts "\n*** WARNING: You have uncommitted change.  You might want to commit them first.\n\n"
    end
  end

  def input_new_app_name
    app_name = input <<-EOT
      --------------------------------------------------------
      About to PUSH an app based on branch #{@branch}
      with #{STACK} stack.

      Enter the app-name (or press return for #{@app_name},
      or Control-C to exit) :

    EOT
    @app_name = app_name unless app_name.blank?
  end

  def check_app_not_exists
    $stderr.puts "Check to make sure #{@app_name} does not exists ..."
    unless `heroku list`.split.grep(@app_name).empty?
      abort "Error: #{@app_name} already exists.  Please destroy existing app first"
    end
  end

  def check_app_exists
    $stderr.puts "Check to make sure #{@app_name} exists ..."
    if `heroku list`.split.grep(@app_name).empty?
      abort "Error: #{@app_name} does not exists. Use 'rake build:create_test_app' to create a new app"
    end
  end

  def create_app
    exec <<-EOF
      heroku apps:create "#{@app_name}" --remote "#{@git_remote}" --stack "#{STACK}" \
        --addons heroku-postgresql:dev,scheduler:standard,newrelic:standard,sendgrid:starter,pgbackups,redistogo:nano,zerigo_dns:basic
    EOF
  end

  def create_full_app
    exec <<-EOF
      # Here are all the add-ons we need to add
      #heroku addons:add airbrake:developer
      #heroku addons:add heroku-postgresql:kappa
      #heroku addons:add scheduler:standard
      #heroku addons:add newrelic:standard
      #heroku addons:add redistogo:mini
      #heroku addons:add stillalive:basic
      #heroku addons:add zerigo_dns:basic

      heroku apps:create "#{@app_name}" --remote "#{@git_remote}" --stack "#{STACK}" \
        --addons airbrake:developer,heroku-postgresql:kappa,scheduler:standard,newrelic:standard,sendgrid:starter,pgbackups,redistogo:mini,stillalive:basic,zerigo_dns:basic
    EOF
  end

  def push_code
      # This does not deal with branches.  For branch, you need to do:
      # git push {Heroku app name} +{branch}:master

    $stderr.puts "Pushing code to Heroku ..."

    if @branch == "master"
      exec %( git push "#{@git_remote}" master )
    else
      exec %( git push "#{@git_remote}" "+#{@branch}:master" )
    end
  end

  def turn_on_maintenance
    exec %( heroku maintenance:on --app #{@app_name} )
  end


  def turn_off_maintenance
    exec %( heroku maintenance:off --app #{@app_name} )
  end

  # Convenient methods

  def exec(command)
    command = command.strip
    system(command) || abort("\nError in executing system commands: #{command}\n")
  end

  def input(message)
    $stdout.print message.strip
    $stdout.flush
    $stdin.gets.chomp
  end

end