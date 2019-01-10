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


  def display_data(header, data)
    if @debug then puts debug_top(data) end
      
    data.split(/\r\n?/).each do |line|
      puts format_line(header, line)
    end

    if @debug then puts debug_bottom end
  end


  def format_line(header, line)
    if not line.chomp.empty?
      "#{header.blue}#{line}"
    end
  end


  def show_summary(worker)
    if @debug
      puts "\n\n#{worker.to_s.blue}\n"
    end
  end    


end