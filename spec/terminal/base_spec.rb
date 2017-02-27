require 'spec_helper'

module BaseSpec
  describe Terminal::Base do
    let(:base) { Terminal::Base.new }

    describe "#initialize" do
      it 'sets default instance variables' do
        expect(base.history).to eq([])
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
        expect(base).to receive(:before_exec).with(commands[0]).ordered
        expect(base).to receive(:sh).with(commands[0], 1800).ordered
        base.exec("false")
        expect(base).to receive(:before_exec).with(commands[1]).ordered
        expect(base).to receive(:sh).with(commands[1], 1800).ordered
        base.exec("echo command2")
        expect(base).to receive(:before_exec).with(commands[2]).ordered
        expect(base).to receive(:sh).with(commands[2], 1800).ordered
        base.exec("echo command3")

        expect(base.history).to eq(commands)
      end

      context "unknown command" do
        it 'raises a RuntimeError and appends to history' do
          expect { base.exec("unknown command") }.to raise_exception
          expect(base.history).to eq(["unknown command"])
        end
      end

      context 'timeout' do
        let(:timeout) { 1 }

        it "raises Timeout::Error" do
          expect { base.exec("sleep 5", timeout) }.to raise_error(Timeout::Error)
          expect(base.history).to eq(["sleep 5"])
        end
      end
    end
  end
end

