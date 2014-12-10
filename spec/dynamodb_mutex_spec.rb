require 'spec_helper'

describe DynamoDBMutex::Lock do

  let(:locker) { DynamoDBMutex::Lock }
  let(:lockname) { 'test.lock' }

  describe '#with_lock' do

    def run(id, ms)
      print "invoked worker #{id}...\n"
      locker.with_lock 'test.lock' do
        sleep(ms)
      end
    end

    it 'should execute block by default' do
      locked = false
      locker.with_lock(lockname) do
        locked = true
      end
      expect(locked).to eq(true)
    end

    it 'should raise error after block timeout' do
      if pid1 = fork
        sleep(1)
        expect {
          locker.with_lock(lockname) { sleep(1) }
        }.to raise_error(DynamoDBMutex::LockError)
        Process.waitall
      else
        run(1, 5)
      end
    end

    it 'should expire lock if stale' do
      if pid1 = fork
        sleep(2)
        locker.with_lock(lockname, wait_for_other: 10) do
          expect(locker).to receive(:delete).with('test.lock')
        end
        Process.waitall
      else
        run(1, 5)
      end
    end

  end
end
