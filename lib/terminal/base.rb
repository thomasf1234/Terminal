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
        exit_status = $?
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

    protected
    def before_exec(command)
      #this hook is called prior to executing a command line call
    end

    def sh(command, timeout)
      Timeout::timeout(timeout) do
        `#{command}`
      end
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