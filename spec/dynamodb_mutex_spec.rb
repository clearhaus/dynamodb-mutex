require 'spec_helper'

describe DynamoDBMutex::Lock do

  let(:locker) { DynamoDBMutex::Lock }
  let(:lockname) { 'test.lock' }

  describe '#with_lock' do
    it 'executes block' do
      locked = false
      locker.with_lock(lockname) do
        locked = true
      end
      expect(locked).to eq(true)
    end
  end

  describe '#with_lock', pipe: true do
    before(:example) do
      @notify = Class.new do
        def initialize
          @reader, @writer = IO.pipe
        end

        def poke
          @reader.close
          @writer.write "\n"
        end

        def wait
          @writer.close
          @reader.gets
        end
      end.new
    end

    def run_infinitely(notify)
      locker.with_lock(lockname) do
        notify.poke
        sleep
      end
    end

    it 'raises error after :wait_for_other timeout' do
      begin
        child = fork { run_infinitely(@notify) }

        @notify.wait

        expect {
          locker.with_lock(lockname, wait_for_other: 0, stale_after: 100) { return }
        }.to raise_error(DynamoDBMutex::LockError)

      ensure
        Process.kill('QUIT', child)
      end
    end


    it 'deletes lock if stale' do
      begin
        child = fork { run_infinitely(@notify) }

        @notify.wait

        locker.with_lock(lockname, stale_after: 0, wait_for_other: 100) do
          expect(locker).to receive(:delete).with(lockname)
        end

      ensure
        Process.kill('QUIT', child)
      end
    end

  end
end
