require 'rake'

namespace :build do

  desc "Pushing code to heroku"
  task :push => :environment do
    push_code
  end

  def push_code
      # This does not deal with branches.  For branch, you need to do:
      # git push {Heroku app name} +{branch}:master

    $stderr.puts "Pushing code to Heroku ..."
    exec %( git push heroku master )
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