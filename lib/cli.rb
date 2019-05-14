require_relative 'credential'

class Cli
  attr_accessor :username, :password, :key_password, :nodes, :command, :block, :debug, :credential

  def initialize

    @options = {}
    opt_parse = OptionParser.new do |opt|
      opt.banner = 'Usage: multissh.rb --nodes "server1,server2" --command "echo \'hello\'"'
      opt.on('--nodes "NODES"', 'REQUIRED: "server1,server2,server3" OR "@nodes.txt"') { |o| @options[:nodes] = o }
      opt.on('--command "COMMAND"', 'REQUIRED: "echo \'hello\'" OR @command.txt') { |o| @options[:command] = o }
      opt.on('--username "USERNAME"', 'OPTIONAL: current user by default') { |o| @options[:username] = o }
      opt.on('--password "PASSWORD"', 'OPTIONAL: will prompt if needed') { |o| @options[:password] = o }
      opt.on('--pkey_password "PASSWORD"', 'OPTIONAL: will prompt if needed') { |o| @options[:pkey_password] = o }
      opt.on('--disable_sudo', 'OPTIONAL: disable_sudo requirement and run as current user') { @options[:disable_sudo] = true }
      opt.on('--block', 'OPTIONAL: block mode for command ouptut') { @options[:block] = true }
      opt.on('--regenerate_config', 'OPTIONAL: regenerate configuration file') { @options[:regenerate_config] = true }
      opt.on('--debug', 'OPTIONAL: debug mode') { @options[:debug] = true }
    end
    opt_parse.parse!

    begin
      valid_options_set = false
      valid_options_set = true if @options[:nodes] && @options[:command]
      valid_options_set = true if @options[:regenerate_config]

      raise OptionParser::MissingArgument unless valid_options_set
    rescue
      abort(opt_parse.help)
    end

    @username       = @options[:username]
    @password       = @options[:password]
    @pkey_password  = @options[:pkey_password]

    @debug          = true if @options[:debug]
    @util           = Util.new(@debug)
    @regenerate     = true if @options[:regenerate_config]
    @disable_sudo   = true if @options[:disable_sudo]

    credential      = Credential.new(
                      username      = @username, 
                      password      = @password, 
                      pkey_password = @pkey_password, 
                      regenerate    = @regenerate, 
                      debug         = @debug
                    )
    @username       = credential.username
    @password       = credential.password
    @pkey_password  = if credential.pkey_password == "" then nil else credential.pkey_password end

    abort() if @options[:regenerate_config]

    @nodes          = parse_nodes(@options[:nodes])
    @command        = parse_command(@options[:command])
    @block          = true if @options[:block]

  rescue Interrupt
    puts "\nCtrl+C Interrupt\n"
    exit 1

  end#initialize


  def parse_nodes(nodes)
    ##
    # If '@' is used, return a list of nodes from a file
    # Otherwise return a list of nodes parsed from comma-separated input from cli
    #
    @util.dbg("nodes: #{nodes}")
    if nodes.start_with?('@')
      node_list = []
      file_path = nodes[1..-1]
      expanded_file_path = File.expand_path(file_path)
      @util.dbg("nodes_file: #{expanded_file_path}")
      raise "File not found" unless File.exists?(expanded_file_path)

      File.open(expanded_file_path, 'r') do |f|
        f.each_line do |line|
          @util.dbg("line: #{line}")
          line.chomp!.strip!
          unless line.start_with?('#') || line.empty?
            node_list << line
          end
        end
      end

      return node_list
    else
      return nodes.split(',').map(&:strip)
    end#if
  end#parse_nodes


  def parse_command(command)
    ##
    # If '@' is used, return a command string from a file
    # Otherwise return specified command
    #
    @util.dbg("command: #{command}")
    if command.start_with?('@')
      command_list = []
      file_path = command[1..-1]
      expanded_file_path = File.expand_path(file_path)
      @util.dbg("command_file: #{expanded_file_path}")
      raise "File not found" unless File.exists?(expanded_file_path)

      File.open(expanded_file_path, 'r') do |f|
        f.each_line do |line|
          line.chomp!.strip!
          unless line.start_with?('#') || line.empty?
            command_list << line
          end
        end
      end

      command_list.map! do |command|
        command = format_command(command, @disable_sudo)
      end
      command = command_list.join('; ')
    else
      command = command.chomp
      command = format_command(command, @disable_sudo)
    end#if
  end#parse_command


  def format_command(command, disable_sudo=false)
    pre_command = ". ~/.bash_profile; "\
                  "export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin; "
    unless command[0..3] == 'sudo'
      unless disable_sudo
        command = 'sudo ' + command
      end
    end
    pre_command + command + ' 2>&1'
  end

end
