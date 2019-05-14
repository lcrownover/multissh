class Update
  attr_reader :local_revision, :remote_revision

  def initialize(called_command)
    begin
      %x{git fetch -q}
      @local_revision = %x{git rev-parse HEAD}
      @remote_revision = (%x{git ls-remote --heads --tags origin}).split.first
    rescue
      @local_revision = nil
      @remote_revision = nil
    end

    if update.local_revision != update.remote_revision
      printf "MultiSSH update available. Would you like to update? (y/n): "
      if ['y', 'Y'].include? gets.chomp
        %x{git reset --hard origin/master && git pull}
        at_exit do
          %x{#{called_command}}
        end#at_exit
        exit 0
      end#if
    end#if
  end#initialize

  def show
    puts "local: #{@local_revision}"
    puts "remote: #{@remote_revision}"
  end

end