class Credential
  attr_accessor :username, :password, :pkey_password, :sudo_password

  def initialize(username: nil, password: nil, pkey_password: nil, sudo_password: nil, encrypted: false)
    @encrypted      = encrypted
    @username       = set_username
    @password       = set_password
    @pkey_password  = set_pkey_password
    @sudo_password  = set_sudo_password
  end


  def set_username
    print "Username: "
    username = gets.chomp
    return username
  end


  def set_password
    print "#{@username}'s password: "
    password = STDIN.noecho(&:gets).chomp
    puts "\n"
    if @encrypted
      password = @util.encrypt(password)
    end
    return password
  end


  def set_pkey_password
    epkey_password = nil
    unless @util.ssh_agent_loaded? # if ssh agent is loaded, we don't need a pkey_password
      if @util.private_key_exist? # if they haven't loaded their private key into ssh_agent but they use one
        print "#{@username}'s ssh key password: "
        pkey_password = STDIN.noecho(&:gets).chomp
        if @encrypted
          pkey_password = @util.encrypt(pkey_password)
        end
        puts "\n"
      end
    end
    return pkey_password
  end


  def set_sudo_password
    print "[sudo] password for #{@username}: "
    sudo_password = STDIN.noecho(&:gets).chomp
    puts "\n"
    if @encrypted
      sudo_password = @util.encrypt(sudo_password)
    end
    return sudo_password
  end

end