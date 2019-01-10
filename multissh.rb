require 'net/ssh'
require 'parallel'
require 'optparse'
require 'io/console'
require 'colorize'

require_relative 'lib/cli'
require_relative 'lib/worker'
require_relative 'lib/util'


class Multissh < Cli

  def run
    tasks = []
    @nodes.each do |node|
      worker = Worker.new(
        hostname=node.chomp, 
        username=@username, 
        password=@password, 
        command=@command, 
        stream=@stream, 
        debug=@debug,
      )
      tasks.append(worker)
    end

    results = Parallel.map(tasks) do |task|
      task.go
    end

  end#run

end#class



mssh = Multissh.new
mssh.run

puts "\n"
