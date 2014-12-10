require 'spec_helper'

describe DynamoDBMutex::Lock do

  let(:locker) { DynamoDBMutex::Lock }
  let(:lockname) { 'test.lock' }

  describe '#with_lock' do

    def run_for(seconds)
      locker.with_lock(lockname) do
        sleep(seconds)
      end
    end

    it 'should execute block by default' do
      locked = false
      locker.with_lock(lockname) do
        locked = true
      end
      expect(locked).to eq(true)
    end

    it 'should raise error after :wait_for_other timeout' do
      begin
        fork { run_for(2) }

        sleep(1)

        expect {
          locker.with_lock(lockname, wait_for_other: 0.1) { return }
        }.to raise_error(DynamoDBMutex::LockError)

      ensure
        Process.waitall
      end
    end

    it 'should delete lock if stale' do
      begin
        stale_after = 0
        reader, writer = IO.pipe

        fork do
          locker.with_lock(lockname) do
            # Notify that I acquired the lock.
            reader.close
            writer.puts()
            sleep(stale_after+1)
          end
        end

        # Wait for notification that child acquired lock.
        writer.close
        reader.gets

        locker.with_lock(lockname, stale_after: stale_after, wait_for_other: stale_after+0.5) do
          expect(locker).to receive(:delete).with(lockname)
        end

      ensure
        Process.waitall
      end
    end

  end
end
