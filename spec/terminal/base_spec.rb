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

    describe "exec" do
      let(:commands) do
        [
            "true",
            "echo command2",
            "echo command3"
        ]
      end

      context 'valid successful commands' do
        before :each do
          allow(test_terminal).to receive(:sh).and_return(true)
          allow(test_terminal).to receive(:last_exit_status).and_return(double(Process::Status, exitstatus: 0))
        end

        it 'executes the command with correct hooks and appends to history' do
          test_terminal.exec("true")
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
          expect { test_terminal.exec("sleep 5", timeout) }.to raise_exception(Timeout::Error)
          expect(test_terminal.history.count).to eq(1)
          expect(test_terminal.history.first.command).to eq("sleep 5")
        end
      end
    end

    describe '#ssh' do
      before :each do
        allow(test_terminal).to receive(:sh).and_return(true)
        allow(test_terminal).to receive(:last_exit_status).and_return(double(Process::Status, exitstatus: 0))
      end

      it 'executes the correct ssh command' do
        test_terminal.ssh('abstractx1', '127.0.0.1', 22, "echo Hello")
        test_terminal.ssh('abstractx1', '127.0.0.1', 30, "cd /opt && echo Hello")
        test_terminal.ssh('abstractx1', '127.0.0.1', 30, "cd /opt && echo Hello", {'IdentityFile' => "/home/myuser/.ssh/id_rsa_another"})

        expected_history = ["ssh -o StrictHostKeyChecking=\"no\" -o NumberOfPasswordPrompts=\"0\" -o Port=\"22\" abstractx1@127.0.0.1 <<EOF\necho Hello\nEOF",
                            "ssh -o StrictHostKeyChecking=\"no\" -o NumberOfPasswordPrompts=\"0\" -o Port=\"30\" abstractx1@127.0.0.1 <<EOF\ncd /opt && echo Hello\nEOF",
                            "ssh -o StrictHostKeyChecking=\"no\" -o NumberOfPasswordPrompts=\"0\" -o Port=\"30\" -o IdentityFile=\"/home/myuser/.ssh/id_rsa_another\" abstractx1@127.0.0.1 <<EOF\ncd /opt && echo Hello\nEOF"]

        expect(test_terminal.history.map(&:command)).to eq(expected_history)
      end

      context 'exception' do
        before :each do
          allow(test_terminal).to receive(:exec).and_raise("Oops!")
        end

        it 'raises the error' do
          expect { test_terminal.ssh('abstractx1', '127.0.0.1', 22, "echo Hello") }.to raise_exception("Oops!")
        end
      end
    end
  end
end

