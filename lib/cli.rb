class Cli
  attr_accessor :username, :password, :nodes, :command, :stream, :debug

  def initialize

    set_options
    
    @username = @options[:username]
    @password = check_password(@options[:password])

    @nodes = parse_nodes(@options[:nodes])
    @command = parse_command(@options[:command])
    @stream = set_stream(@options[:stream])

    @debug = set_debug(@options[:debug])

  end#initialize


  # Do the stuff
  def set_options
    @options = {}
    opt_parse = OptionParser.new do |opt|
      opt.banner = 'Usage: multissh.rb --username lcrown --nodes "server1,server2" --command "echo \'hello\'"'
      opt.on('--username USERNAME', 'REQUIRED: your LDAP username') { |o| @options[:username] = o }
      opt.on('--password PASSWORD', 'OPTIONAL: your LDAP password') { |o| @options[:password] = o }
      opt.on('--nodes NODES', 'REQUIRED: "server1,server2,server3" OR "@nodes.txt"') { |o| @options[:nodes] = o }
      opt.on('--command COMMAND', 'REQUIRED: "echo \'hello\'" OR @command.txt') { |o| @options[:command] = o }
      opt.on('--stream', 'OPTIONAL: stream mode for command ouptut') { |o| @options[:stream] = o }
      opt.on('--debug', 'OPTIONAL: debug mode') { |o| @options[:debug] = o }
    end
    opt_parse.parse!

    # Abort the program if required arguments aren't given
    if (@options[:username].nil? || @options[:nodes].nil? || @options[:command].nil?)
      abort(opt_parse.help)
    end

  end#set_options


  def check_password(password)
    if password.nil?
      print 'Enter LDAP Password: '
      pw = STDIN.noecho(&:gets).chomp
      puts "\n\n"
    else
      pw = @options[:password]
    end
    pw
  end#check_password


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
    if stream.nil?
      false
    else
      true
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