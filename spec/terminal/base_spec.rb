require 'spec_helper'

module BaseSpec
  class TestTerminal < Terminal::Base
    attr_reader :log

    def initialize
      super
      @log = []
    end

    def before_exec(command)
      @log << Terminal::Base::History::Record.new(command)
      sleep 1
    end
  end

  describe Terminal::Base do
    let(:test_terminal) { TestTerminal.new }

    describe "#initialize" do
      it 'sets default instance variables' do
        expect(test_terminal.history).to eq([])
      end
    end

    describe "execute" do
      let(:commands) do
        [
            "false",
            "echo command2",
            "echo command3"
        ]
      end

      it 'executes the command with correct hooks and appends to history' do
        expect { test_terminal.exec("false") }.to raise_exception(RuntimeError, /exit 1/)
        sleep 2
        expect(test_terminal.last_command.recorded_at > test_terminal.log.last.recorded_at)

        test_terminal.exec("echo command2")
        sleep 2
        expect(test_terminal.last_command.recorded_at > test_terminal.log.last.recorded_at)

        test_terminal.exec("echo command3")
        expect(test_terminal.last_command.recorded_at > test_terminal.log.last.recorded_at)


        expect(test_terminal.log.count).to eq(3)
        expect(test_terminal.history.count).to eq(3)
        expect(test_terminal.history.sort_by(&:recorded_at).map(&:command)).to eq(commands)
      end

      context "unknown command" do
        it 'raises a RuntimeError and appends to history' do
          expect { test_terminal.exec("unknown command") }.to raise_exception
          expect(test_terminal.history.count).to eq(1)
          expect(test_terminal.history.first.command).to eq("unknown command")
        end
      end

      context "non-zero exit status" do
        it 'raises a RuntimeError and appends to history' do
          expect { test_terminal.exec("false") }.to raise_exception(RuntimeError, /exit 1/)
          expect(test_terminal.history.count).to eq(1)
          expect(test_terminal.history.first.command).to eq("false")
        end
      end

      context 'timeout' do
        let(:timeout) { 1 }

        it "raises Timeout::Error" do
          expect { test_terminal.exec("sleep 5", timeout) }.to raise_error(Timeout::Error)
          expect(test_terminal.history.count).to eq(1)
          expect(test_terminal.history.first.command).to eq("sleep 5")
        end
      end
    end
  end
end

