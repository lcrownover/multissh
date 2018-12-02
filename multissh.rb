require 'net/ssh'
require 'parallel'

require_relative 'lib/cli'
require_relative 'lib/worker'


class Multissh

  def initialize
    cli = Cli.new
    @username = cli.username
    @password = cli.password
    @nodes = cli.nodes
    @command = cli.command
    @stream = cli.stream
    @debug = cli.debug
  end


  def run
    tasks = []
    @nodes.each do |node|
      worker = Worker.new(hostname=node, username=@username, password=@password, command=@command, stream=@stream, debug=@debug)
      tasks.append(worker)
    end
    results = Parallel.map(tasks) do |task|
      task.go
    end
  end
end

mssh = Multissh.new
mssh.run
