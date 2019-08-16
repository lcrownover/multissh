class Config
  require 'credential'

  attr_accessor :config_file_path, :username, :password, :pkey_password, :sudo_password

  def initialize(debug)
    @debug            = debug
    @util             = Util.new(@debug)

    @config_file_path = "#{%x{echo ~}.chomp}/.multissh.cfg"
    @config           = load_config(@config_file_path)

    @enabled                = @config['authentication']['enabled']
    @credentials            = @config['authentication']['credentials']

    @default_user           = @config['authentication']['credentials']['default']['username']
    @default_password       = @util.decrypt(@config['authentication']['credentials']['default']['password'])
    @default_pkey_password  = @util.decrypt(@config['authentication']['credentials']['default']['pkey_password'])
    @default_sudo_password  = @util.decrypt(@config['authentication']['credentials']['default']['pkey_password'])

    @special_access   = @config['special_access']

  end


  def load_config
    config = {
      "authentication" => {
        "enabled" => nil,
        "credentials" => {
          "default" => {},
          "fallback" => [],
        },
      },
      "special_access" => {},
    }

    if File.exist? @config_file_path
      @util.dbg('configuration file exists')
    else
      @util.dbg('couldnt find configuration file')
      generate_config
    end

    begin
      config = YAML.load_file(@config_file_path)
    rescue
      raise 'Configuration file detected but unable to properly load. Please regenerate using "multissh.rb --regenerate_config"'
    end

    return config
  end


  def generate_config
    @util.dbg('starting generation process')
    puts    "\n\n\n\n"
    puts    "* No existing configuration file found at path: ".red + "#{@config_file_path}".yellow
    puts    "*"
    puts    "* MultiSSH handles [sudo] prompts and private key failures by storing your credentials in its config file"
    puts    "* The owner of this config file will be set to #{@username.green} with a mode of #{'600'.green}"
    puts    "*"
    puts    "* If you opt out, you will be prompted for your password on every run"
    puts    "*"
    printf  "* Would you like MultiSSH to store your credentials? (y/n): "
    run_generate = get_answer

    # else
    #   generate = true
    #   puts 'MultiSSH called with "--regenerate_config", generating new configuration file'
    # end

    if run_generate
      @config = ['authentication']["enabled"] = true
      dc = Credential.new(encrypted: true)
      @config['authentication']['credentials']['default']['username']       = dc.username
      @config['authentication']['credentials']['default']['password']       = dc.password
      @config['authentication']['credentials']['default']['pkey_password']  = dc.pkey_password
      @config['authentication']['credentials']['default']['sudo_password']  = dc.sudo_password

      puts "Would you like to add any fallback credentials? (y/n): "
      if get_answer
        add_cred = true
        while add_cred
          c = Credential.new(encrypted: true)
          @config['authentication']['credentials']['fallback'] << c
          puts "Would you like to add another fallback credential? (y/n): "
          add_cred = get_answer
        end
      end
    else
      @config = ['authentication']["enabled"] = false
    end

    save_config
    set_secure_permissions

    unless run_generate then puts "configuration file set to disabled" end
    @util.dbg('end generation process')
  end


  def get_answer
    ans = gets.chomp.downcase
    @util.dbg(ans)
    until ['y','n'].include? ans
      printf "Please answer only with 'y' or 'n': "
      ans = gets.chomp.downcase
    end
    if ans == 'y'
      return true
    end
    return false
  end





  def add_default_credential
    @util.dbg("generating default credential")


  def add_fallback_credential
    @util.dbg("generating fallback credential")
    print "Username: "
    username = gets.chomp
    print "#{@username}'s password: "
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
    File.open(@config_file_path, 'w') { |f| f.write @config.to_config }
    puts "Configuration file saved to #{@config_file_path}".yellow
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