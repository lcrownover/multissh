class Credential
  attr_accessor :config_file_path, :username, :password, :pkey_password, :sudo_password, :snowflakes

  def initialize(username, password, pkey_password, regenerate, debug)
    @debug            = debug
    @util             = Util.new(@debug)

    @config_file_path = "#{%x{echo ~}.chomp}/.ssh/multissh.yaml"
    @username         = set_username(username)
    @password         = set_password(password)
    @pkey_password    = pkey_password
    @sudo_password    = nil
    @snowflakes       = nil
    @regenerate       = true if regenerate

    generate_config if @regenerate
    process_config
  end


  def process_config
    if File.exist? @config_file_path
      @util.dbg('configuration file exists')
    else
      @util.dbg('couldnt find configuration file')
      generate_config
    end

    begin
      @yaml = YAML.load_file(@config_file_path)
    rescue
      raise 'Configuration file detected but unable to properly load. Please regenerate using "multissh.rb --regenerate_config"'
    end

    if @yaml['enabled']
      @util.dbg('credential enabled')
      @util.dbg(@yaml)

      unless @yaml['credentials'][@username]
        printf "No saved credential for #{@username}, create one? [yes]: "
        if @util.check_affirmative
          credential = generate_credential_entry
          @yaml['credentials'][@username] = credential
          save_config
          load_config
        end
      end

      unless @password
        @password = @util.decrypt(@yaml['credentials'][@username]['password'])
        @util.dbg("password - #{@password}")
      end

      unless @pkey_password
        @pkey_password = @util.decrypt(@yaml['credentials'][@username]['pkey_password'])
        @util.dbg("pkey_password - #{@pkey_password}")
      end

      @sudo_password = @util.decrypt(@yaml['credentials'][@username]['sudo_password'])
      @util.dbg("sudo_password - #{@sudo_password}")

    else
      @util.dbg('credential disabled')
      unless @password
        printf "Enter System Password: "
        @password = STDIN.noecho(&:gets).chomp
        puts "\n"
      end

      unless ssh_agent_loaded?
        unless @pkey_password
          puts "ssh-agent is not in use, falling back to manual entry"
          printf "Enter Private Key Password: "
          @pkey_password = STDIN.noecho(&:gets).chomp
          puts "\n"
        end
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

  def set_password(password)
    if password == ""
      printf "Enter System Password: "
      password = STDIN.noecho(&:gets).chomp
      password
    else
      password
    end
  end


  def generate_config
    @util.dbg('starting generation process')
    unless @regenerate
      puts    "\n\n\n\n"
      puts    "* No existing configuration file found at path: ".red + "#{@config_file_path}".yellow
      puts    "*"
      puts    "* MultiSSH handles [sudo] prompts and private key failures by storing your credentials in its config file"
      puts    "* The owner of this config file will be set to #{@username.green} with a mode of #{'600'.green}"
      puts    "*"
      puts    "* If you opt out, you will be prompted for your password on every run"
      puts    "*"
      printf  "* Would you like MultiSSH to store your credentials? (y/n): "
      ans = gets.chomp.downcase
      @util.dbg(ans)
      until ['y','n'].include? ans
        printf "Please answer only with 'y' or 'n': "
        ans = gets.chomp.downcase
      end
      generate = (ans == 'y') ? true : false

    else
      generate = true
      puts 'MultiSSH called with "--regenerate_config", generating new configuration file'
    end

    if generate
      credential = generate_credential_entry
      @yaml = { "enabled" => true, "credentials" => { @username => credential } }
    else
      @yaml = { "enabled" => false }
    end

    save_config
    set_secure_permissions

    unless generate then puts "configuration file set to disabled" end

    puts "Configuration file saved to #{@config_file_path}".yellow
    @util.dbg('end generation process')
  end


  def ssh_agent_loaded?
    begin
      @util.dbg('ssh-agent begin check')
      Net::SSH::Authentication::Agent.new.connect!
      @util.dbg('ssh-agent loaded')
      true
    rescue Net::SSH::Authentication::AgentNotAvailable
      @util.dbg('ssh-agent not loaded')
      false
    end
  end

  def private_key_exist?
    if !Dir.glob("#{%x{echo ~}.chomp}/.ssh/id_*").empty?
      false
    else
      true
    end
  end

  def generate_credential_entry
    @util.dbg("generating new entry for #{@username}")
    print "#{@username} - Password: "
    password = STDIN.noecho(&:gets).chomp
    epassword = @util.encrypt(password)
    puts "\n"

    unless ssh_agent_loaded?
      pkey_password = nil
      if private_key_exist?
        print "#{@username} - SSH Private Key Password: "
        pkey_password = STDIN.noecho(&:gets).chomp
        epkey_password = @util.encrypt(pkey_password)
        puts "\n"
      end
    end

    credential = { "password" => epassword, "pkey_password" => epkey_password }
    @util.dbg("credential:")
    @util.dbg(credential)
    return credential
  end

  def save_config
    @util.dbg("saving config to '#{@config_file_path}'")
    File.open(@config_file_path, 'w') { |f| f.write @yaml.to_yaml }
  end

  def load_config
    @util.dbg("loading config from '#{@config_file_path}'")
    @yaml = YAML.load_file(@config_file_path)
  end


  def set_secure_permissions
    %x{chown #{@username} #{@config_file_path}; chmod 600 #{@config_file_path} }
    target_uid = %x{id}.split[0].match('\d+').to_s
    target_mode = '600'
    file_uid = File.stat(@config_file_path).uid.to_s
    file_mode = File.stat(@config_file_path).mode.to_s(8)[-3..-1]
    @util.dbg("target_uid: #{target_uid}, target_mode: #{target_mode}")
    @util.dbg("file_uid:   #{file_uid},   file_mode:   #{file_mode}")
    unless target_uid == file_uid && target_mode == file_mode 
      raise "Failed to set permissions on #{@config_file_path}".red
    end
  end

end