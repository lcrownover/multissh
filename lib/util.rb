class Util
  def initialize(debug)
    @debug = debug
  end


  def debug_top(data)
    "\n\n\n#{('-'*80).blue}\n#{'raw data:'.yellow}\n#{data.inspect.yellow}\n\n#{'formatted:'.green}\n"
  end


  def debug_bottom
    "#{('-'*80).blue}"
  end

  def dbg(msg)
    if @debug
      puts "debug: #{msg}".blue
    end
  end

  def display_data(header, data)
    if @debug then puts debug_top(data) end
      
    data.split(/\r\n?/).each do |line|
      puts format_line(header, line)
    end

    if @debug then puts debug_bottom end
  end

  def check_affirmative
    ans = ['y', 'yes', ''].include?(gets.chomp) ? true : false
    dbg("affirmative = #{ans}")
    puts "\n"
    return ans
  end

  def format_line(header, line)
    if not line.chomp.empty?
      "#{header.blue}#{line}"
    end
  end

  def display_error(error)
    if @debug
      puts error.backtrace
      puts error
    end
  end


  def show_summary(worker)
    if @debug
      puts "\n\n#{worker.to_s.blue}\n"
    end
  end   

  def encrypt(s)
    if s
      ecarr = []
      s.chomp.each_byte do |c|
        (33..126).to_a.include?(c + 20) ? ecarr << (c + 20).chr : ecarr << (c + 20 - 94).chr
      end
      ecarr.join
    else
      ''
    end
  end



  def decrypt(s)
    if s
      carr = []
      s.chomp.each_byte do |c|
        (33..126).to_a.include?(c - 20) ? carr << (c - 20).chr : carr << (c - 20 + 94).chr
      end
      carr.join
    else
      ''
    end
  end


end