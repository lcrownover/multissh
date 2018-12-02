class Worker

  def initialize(hostname, username, password, command, stream, debug)
    @hostname = hostname.chomp
    @username = username
    @password = password
    @command = command
    @stream = stream
    @debug = debug
  end


  def go
    result = ''
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      channel = ssh.open_channel do |channel, success|
        channel.on_data do |channel, data|
          if data =~ /^\[sudo\] password for /
            channel.send_data "#{@password}\n"
          else
            if @stream == true
              data.split("\r").each do |line|
                if not line.chomp.empty?
                  puts "#{@hostname} -- #{line}"
                end
              end
            else
              result += data.to_s
            end
          end
        end
        # request a pseudo TTY
        channel.request_pty
        # execute command
        channel.exec(@command)
        # wait for response
        channel.wait
      end

      # wait for opened channel
      channel.wait
    end

    if @stream == false
      puts result
    end

  end
  
  def to_s
    "Worker: {hostname:'#{@hostname}',username:'#{@username}',password:'#{@password}',command:'#{@command}',stream:'#{@stream}'"
  end

end