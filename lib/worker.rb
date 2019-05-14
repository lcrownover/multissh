class Worker
  def initialize(hostname, username, password, pkey_password, sudo_password, command, block, debug)
    @hostname       = hostname
    @username       = username
    @password       = password
    @pkey_password  = pkey_password
    @sudo_password  = sudo_password
    @command        = command
    @block          = block

    @header         = "#{hostname} -- "
    @util           = Util.new(debug)
  end


  def go
    @util.show_summary(self)

    result = ''
    begin
      Net::SSH.start(@hostname, @username, :password => @password, :passphrase => @pkey_password, :non_interactive => true) do |ssh|
        channel = ssh.open_channel do |channel, success|

          # request a pseudo TTY formatted to screen width
          cols = %x{tput cols}.chomp.to_i - @header.length
          channel.request_pty(opts={:term=>'xterm',:chars_wide => cols})

          @util.dbg("sending command: #{@command}")
          channel.exec(@command)

          channel.on_data do |channel, data|

            attempts = 0

            if attempts >= 2
              raise 'failed to connect -- too many attempts'
            end

            if data =~ /Sorry, try again/
              raise 'failed to connect -- incorrect sudo password'
            end

            if data =~ /#{@username}@#{@hostname}'s password:/
              raise 'failed to connect -- password failed'
            end

            if data =~ /^\[sudo\] password for / and attempts == 0
              if @sudo_password
                channel.send_data "#{@sudo_password}\n"
              elsif @password
                channel.send_data "#{@password}\n"
              else
                raise 'failed to connect -- no sudo_password or password defined'
              end
              attempts += 1
              @util.dbg("attempts: #{attempts}")
            elsif data =~ /^\[sudo\] password for / and attempts == 1
              channel.send_data "#{@password}\n"
              attempts += 1
              @util.dbg("attempts: #{attempts}")
            end

            unless @block
              @util.display_data(@header, data)
            else
              result += data.to_s
            end

          end

        end

        channel.wait

        if @block
          @util.display_data(@header, result)
          puts "\n"
        end

      end#start

    rescue SocketError => e
      @util.display_error(e)
      puts "Failed to connect to #{@hostname}\n".red

    rescue RuntimeError => e
      @util.display_error(e)
      puts "#{@hostname} -- incorrect password, failed to connect".red

    rescue => e
      @util.display_error(e)

    end

  end
  

  def to_s
    "Worker: {hostname:'#{@hostname}',username:'#{@username}',password:'#{@password}',command:'#{@command}',block:'#{@block}'"
  end


end