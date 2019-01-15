class Credential
  attr_accessor :credential_file_path, :username, :password, :pkey_password, :sudo_password, :snowflakes

  def initialize(username, password, regenerate, debug)
    @debug = debug
    @util = Util.new(@debug)

    @credential_file_path = "#{%x{echo ~}.chomp}/.ssh/multissh.yaml"
    @username = set_username(username)
    @password = password
    @pkey_password = nil
    @sudo_password = nil
    @snowflakes = nil

    if regenerate
      @regenerate = true
      generate_credentials
    end

    load_credentials
  end


  def load_credentials
    if File.exist? @credential_file_path
      @util.dbg('credential file exists')
      begin
        yaml = YAML.load_file(@credential_file_path)
      rescue
        raise 'Credential file detected but unable to properly load. Please regenerate using "multissh.rb --generate_credentials"'
      end
    else
      @util.dbg('couldnt find credential file')
      generate_credentials
      begin
        yaml = YAML.load_file(@credential_file_path)
      rescue
        raise 'Credential file detected but unable to properly load. Please regenerate using "multissh.rb --generate_credentials"'
      end
    end

    if yaml['enabled']
      @util.dbg('credential enabled')
      unless @password 
        @password = yaml['global']['password']
      end
      @pkey_password = yaml['global']['pkey_password']
      @sudo_password = yaml['global']['sudo_password']

      @snowflakes = yaml['snowflakes']

    else
      @util.dbg('credential disabled')
      unless @password
        printf "Enter System Password: "
        @password = STDIN.noecho(&:gets).chomp
        puts "\n"
      end

      unless ssh_agent_loaded?
        puts "ssh-agent is not in use, falling back to manual entry"
        printf "Enter Private Key Password: "
        @pkey_password = STDIN.noecho(&:gets).chomp
        puts "\n"
      end
    end
  end


  def set_username(username)
    unless username.nil? or username == ''
      @username = username
    else
      @username = %x{whoami}.chomp.to_s
    end
  end


  def generate_credentials
    @util.dbg('starting generation process')
    unless @regenerate
      printf "No credential file found at #{@credential_file_path}, would you like to generate one? (y/n): "
      ans = gets.chomp.downcase
      while ['y','n'].include? ans
        printf "Please answer only with 'y' or 'n'"
        ans = gets.chomp.downcase
      end
      if ans == 'y'
        generate = true
      else
        generate = false
      end
    else
      generate = true
      puts 'multissh.rb called with "--generate_credentials", generating new credential file'
    end

    if generate
      print "Password: "
      password = STDIN.noecho(&:gets).chomp
      puts "\n"

      unless ssh_agent_loaded?
        print "Private Key Password: "
        pkey_password = STDIN.noecho(&:gets).chomp
        puts "\n"
      else
        pkey_password = nil
      end
      yaml = {"enabled"=>true,"global"=>{"password"=>password, "pkey"=>pkey_password}}

    else
      yaml = {"enabled"=>false}

    end

    File.open(@credential_file_path, 'w') { |f| f.write yaml.to_yaml }
    %x{chown #{@username} #{@credential_file_path}; chmod 600 #{@credential_file_path} }
    puts "credentials saved to #{@credential_file_path}"
    @util.dbg('end generation process')
  end


  def ssh_agent_loaded?
    begin
      Net::SSH::Authentication::Agent.new.connect!
      @util.dbg('ssh-agent loaded')
      true
    rescue Net::SSH::Authentication::AgentNotAvailable
      @util.dbg('ssh-agent not loaded')
      false
    end
  end


end