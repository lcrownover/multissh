require_relative 'credential'

class Cli
  attr_accessor :username, :password, :key_password, :nodes, :command, :stream, :debug, :credential

  def initialize

    set_options

    @debug = set_debug(@options[:debug])

    if @options[:generate_credentials]
      @regenerate = true
    end

    credential = Credential.new(username=@options[:username], password=@options[:password], pkey_password=@options[:pkey_password], regenerate=@regenerate, debug=@debug)
    @username = credential.username
    @password = credential.password
    @pkey_password = credential.pkey_password

    @nodes = parse_nodes(@options[:nodes])
    @command = parse_command(@options[:command])
    @stream = set_stream(@options[:stream])

  end#initialize


  # Do the stuff
  def set_options
    @options = {}
    opt_parse = OptionParser.new do |opt|
      opt.banner = 'Usage: multissh.rb --username \'USERNAME\' --nodes "server1,server2" --command "echo \'hello\'"'
      opt.on('--nodes NODES', 'REQUIRED: "server1,server2,server3" OR "@nodes.txt"') { |o| @options[:nodes] = o }
      opt.on('--command COMMAND', 'REQUIRED: "echo \'hello\'" OR @command.txt') { |o| @options[:command] = o }
      opt.on('--username \'USERNAME\'', 'OPTIONAL: current user by default') { |o| @options[:username] = o }
      opt.on('--password \'PASSWORD\'', 'OPTIONAL: will prompt if needed') { |o| @options[:password] = o }
      opt.on('--pkey_password \'PASSWORD\'', 'OPTIONAL: will prompt if needed') { |o| @options[:pkey_password] = o }
      opt.on('--stream \'BOOL\'', 'OPTIONAL: stream mode for command ouptut, default true') { |o| @options[:stream] = o }
      opt.on('--generate_credentials', 'OPTIONAL: regenerate credentials file') { |o| @options[:generate_credentials] = o }
      opt.on('--debug', 'OPTIONAL: debug mode') { |o| @options[:debug] = o }
    end
    opt_parse.parse!



    # Abort the program if required arguments aren't given
    if (@options[:nodes].nil? || @options[:command].nil?)
      abort(opt_parse.help)
    end

  end#set_options


  # If '@' is used, return a list of nodes from a file
  # Otherwise return a list of nodes parsed from comma-separated input from cli
  def parse_nodes(nodes)
    if nodes.start_with?('@')
      node_list = []
      file_path = nodes[1..-1]
      if File.exists? File.expand_path(file_path)
        File.open(nodes[1..-1], 'r') do |f|
          f.each_line do |line|
            unless line.start_with?('#')
              node_list.append(line)
            end#unless
          end#f.each_line
        end#File.open
      end#File.exists?
      node_list
    else
      nodes.split(',').map(&:chomp)
    end#if
  end#parse_nodes


  # If '@' is used, return a command string from a file
  # Otherwise return specified command
  def parse_command(command)
    if command.start_with?('@')
      command_list = []
      file_path = command[1..-1]
      if File.exists? File.expand_path(file_path)
        File.open(command[1..-1], 'r') do |f|
          f.each_line do |line|
            unless line.start_with?('#')
              command_list.append(line.chomp)
            end#unless
          end#f.each_line
        end#File.open
      end#File.exists?
      command_list.map! do |command|
        command = format_command(command)
      end
      command = command_list.join('; ')
    else
      command = command.chomp
      command = format_command(command)
    end#if
  end#parse_command

  def format_command(command)
    pre_command = ". ~/.bash_profile; "\
                  "export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin; "
    unless command[0..3] == 'sudo'
      command = 'sudo ' + command
    end
    pre_command + command + ' 2>&1'
  end

  def set_stream(stream)
    if stream.nil? || stream
      true
    else
      false
    end
  end

  def set_debug(debug)
    if debug.nil?
      false
    else
      true
    end
  end

end