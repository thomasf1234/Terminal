require 'timeout'

module Terminal
  class Base
    EXIT_STATUS_SUCCESS = 0
    DEFAULT_TIMEOUT_SECONDS = 30*60

    def initialize
      @history = History.new
    end

    def exec(command, timeout=DEFAULT_TIMEOUT_SECONDS)
      begin
        before_exec(command)
        return_value = sh(command, timeout)
        exit_status = last_exit_status
        raise exit_status.inspect unless exit_status.exitstatus == EXIT_STATUS_SUCCESS
        return_value
      ensure
        @history.record(command)
      end
    end

    def history
      @history.records
    end

    def last_command
      history.last
    end

    def ssh(username, host, port, command, options={})
      options = { 'StrictHostKeyChecking' => 'no', 'NumberOfPasswordPrompts' => 0, 'Port' => port }.merge(options)
      exec("ssh #{format_options(options)} #{username}@#{host} <<EOF\n#{command}\nEOF")
    end

    def scp(username, host, port, source, destination, to_remote=true, options={})
      options = { 'StrictHostKeyChecking' => 'no', 'NumberOfPasswordPrompts' => 0, 'Port' => port }.merge(options)

      if to_remote == true
        exec("scp #{format_options(options)} #{source} #{username}@#{host}:#{destination}")
      else
        exec("scp #{format_options(options)} #{username}@#{host}:#{source} #{destination}")
      end
    end

    protected
    def before_exec(command)
      #this hook is called prior to executing a command line call
    end

    def sh(command, timeout)
      Timeout::timeout(timeout) do
        `#{command}`
      end
    end

    def last_exit_status
      $?
    end

    def format_options(hash)
      hash.map {|name,value| "-o #{name}=\"#{value}\"" }.join(' ')
    end

    class History
      include Terminal::Lock

      def initialize
        @records = []
      end

      def record(command)
        lock do
          @records.push(Record.new(command))
        end
      end

      def records
        lock do
          @records.dup.freeze
        end
      end

      protected
      class Record
        attr_reader :command, :recorded_at

        def initialize(command)
          @command = command
          @recorded_at = Time.now
          freeze
        end
      end
    end
  end
end