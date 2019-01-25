require 'net/ssh'
require 'parallel'
require 'optparse'
require 'io/console'
require 'colorize'
require 'yaml'

require_relative 'lib/cli'
require_relative 'lib/worker'
require_relative 'lib/util'


class Multissh < Cli

  def run
    puts "\n\n"
    tasks = []
    @nodes.each do |node|
      worker = Worker.new(
        hostname=node.chomp, 
        username=@username, 
        password=@password,
        pkey_password=@pkey_password,
        sudo_password=@sudo_password,
        command=@command, 
        block=@block, 
        debug=@debug,
      )
      tasks.append(worker)
    end

    results = Parallel.map(tasks) do |task|
      task.go
    end

    rescue Interrupt
      puts "\nCtrl+C Interrupt\n"
      exit 1

  end#run

end#class



mssh = Multissh.new
mssh.run

puts "\n"
