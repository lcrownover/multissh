class Worker
  def initialize(hostname, username, password, key_password, command, stream, debug)
    @hostname = hostname
    @username = username
    @password = password
    @key_password = key_password
    @command = command
    @stream = stream

    @header = "#{hostname} -- "
    @util = Util.new(debug)
  end


  def go
    @util.show_summary(self)

    result = ''
    begin
      Net::SSH.start(@hostname, @username, :password => @password, :passphrase => @key_password) do |ssh|
        channel = ssh.open_channel do |channel, success|

          channel.on_data do |channel, data|

            if data =~ /Sorry, try again/
              raise 'incorrect sudo password'
            end

            if data =~ /^\[sudo\] password for /
              if @password.nil?
                channel.send_data "#{@credentials['global']['sudo_password']}"
              end
              channel.send_data "#{@password}\n"
            end

            if @stream
              @util.display_data(@header, data)
            else
              result += data.to_s
            end

          end

          # request a pseudo TTY formatted to screen width
          cols = %x{tput cols}.chomp.to_i - @header.length
          channel.request_pty(opts={:term=>'xterm',:chars_wide => cols})
          channel.exec(@command)

        end

        channel.wait

        unless @stream
          @util.display_data(@header, result)
          puts "\n"
        end

      end#start

    rescue SocketError => e
      @util.display_error(e)
      puts "Failed to connect to #{@hostname}\n".red

    rescue RuntimeError => e
      @util.display_error(e)
      puts "#{@hostname} -- incorrect sudo password in credential file, failed to connect".red

    end

  end
  

  def to_s
    "Worker: {hostname:'#{@hostname}',username:'#{@username}',password:'#{@password}',command:'#{@command}',stream:'#{@stream}'"
  end


end