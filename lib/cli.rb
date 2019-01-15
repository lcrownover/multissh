class Cli
  attr_accessor :username, :password, :key_password, :nodes, :command, :stream, :debug

  def initialize

    set_options

    @credential_file_path = "#{%x{echo ~}.chomp}/.ssh/multissh.yaml"
    
    @username = check_username(@options[:username])

    if @options[:generate_credentials]
      generate_credentials
    end

    @credentials = load_credentials

    @password = check_password(@options[:password])

    @key_password = check_private_key(@options[:key_password])

    @nodes = parse_nodes(@options[:nodes])
    @command = parse_command(@options[:command])
    @stream = set_stream(@options[:stream])

    @debug = set_debug(@options[:debug])

  end#initialize


  # Do the stuff
  def set_options
    @options = {}
    opt_parse = OptionParser.new do |opt|
      opt.banner = 'Usage: multissh.rb --username \'USERNAME\' --nodes "server1,server2" --command "echo \'hello\'"'
      opt.on('--username \'USERNAME\'', 'OPTIONAL: current user by default') { |o| @options[:username] = o }
      opt.on('--password \'PASSWORD\'', 'OPTIONAL: will prompt if needed') { |o| @options[:password] = o }
      opt.on('--key_password \'KEYPASSWORD\'', 'OPTIONAL: private key password, will prompt if not using ssh-agent provided') { |o| @options[:key_password] = o }
      opt.on('--nodes NODES', 'REQUIRED: "server1,server2,server3" OR "@nodes.txt"') { |o| @options[:nodes] = o }
      opt.on('--command COMMAND', 'REQUIRED: "echo \'hello\'" OR @command.txt') { |o| @options[:command] = o }
      opt.on('--stream', 'OPTIONAL: stream mode for command ouptut, default true') { |o| @options[:stream] = o }
      opt.on('--generate_credentials', 'OPTIONAL: regenerate credentials file') { |o| @options[:generate_credentials] = o }
      opt.on('--debug', 'OPTIONAL: debug mode') { |o| @options[:debug] = o }
    end
    opt_parse.parse!



    # Abort the program if required arguments aren't given
    if (@options[:nodes].nil? || @options[:command].nil?)
      abort(opt_parse.help)
    end

  end#set_options



  def check_username(username)
    if username.nil?
      username = %x{whoami}.chomp.to_s
    end
    username
  end


  def check_password(password)
    if password.nil?
      if @credentials.nil?
        print "Enter System Password: "
        password = STDIN.noecho(&:gets).chomp
        puts "\n"
      else
        password = @credentials['global']['ldap']
      end
    end
    password
  end

  def check_private_key(password)
    if ssh_agent_loaded?
      pw = ''
    elsif @credentials['global']['pkey']
      pw = @credentials['global']['pkey']
    elsif password.nil?
      print "Enter Private Key Password: "
      pw = STDIN.noecho(&:gets).chomp
      puts "\n"
    else
      pw = password
    end
    pw
  end

  def ssh_agent_loaded?
    begin
      Net::SSH::Authentication::Agent.new.connect!
      true
    rescue Net::SSH::Authentication::AgentNotAvailable
      false
    end
  end

  def load_credentials
    begin
      YAML.load_file(@credential_file_path)
    rescue
      puts "\nNo credential file found at #{@credential_file_path}"
      puts "File will be created with user \"#{@username}\" and mode \"600\"\n\n"
      generate_credentials
      YAML.load_file(@credential_file_path)
    end
  end

  def generate_credentials
    print "LDAP Password: "
    ldap_password = STDIN.noecho(&:gets).chomp
    puts "\n"

    print "SUDO Password: "
    sudo_password = STDIN.noecho(&:gets).chomp
    puts "\n"

    print "Private Key Password: "
    pkey_password = STDIN.noecho(&:gets).chomp
    puts "\n"

    yaml = {"global"=>{"sudo"=>sudo_password, "ldap"=>ldap_password, "pkey"=>pkey_password}}
    File.open(@credential_file_path, 'w') { |f| f.write yaml.to_yaml }
    %x{chown #{@username} #{@credential_file_path}; chmod 600 #{@credential_file_path} }
    puts "credentials saved to #{@credential_file_path}"
  end


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