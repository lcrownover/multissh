class Worker
  def initialize(hostname, username, password, command, stream, debug)
    @hostname = hostname
    @username = username
    @password = password
    @command = command
    @stream = stream

    @header = "#{hostname} -- "
    @util = Util.new(debug)
  end


  def go
    @util.show_summary(self)

    result = ''
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      channel = ssh.open_channel do |channel, success|

        channel.on_data do |channel, data|

          if data =~ /^\[sudo\] password for /
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
    end

    unless @stream
      @util.display_data(@header, result)
      puts "\n"
    end

  end
  

  def to_s
    "Worker: {hostname:'#{@hostname}',username:'#{@username}',password:'#{@password}',command:'#{@command}',stream:'#{@stream}'"
  end


end