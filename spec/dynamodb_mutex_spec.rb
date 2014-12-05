require 'spec_helper'

describe DynamoDBMutex::Lock do
  
  let(:locker) { DynamoDBMutex::Lock }

  describe '#with_lock' do
    it 'should execute block by default' do
      locked = false
      locker.with_lock 'test.lock' do
        locked = true
      end
      expect(locked).to eq(true)
    end

    it 'should expire lock if stale' do
      thread = Thread.new { 
        locker.with_lock 'test.lock', ttl: 0.5 do
          sleep(1)
        end
      }
      locker.with_lock 'test.lock', ttl: 0.5 do
        expect(locker).to receive(:delete).with('test.lock')
      end 
      thread.join
    end

    it 'should raise error after block timeout', wip: true do
      thread = Thread.new { 
        locker.with_lock 'test.lock' do
          sleep(2)
        end
      }
      expect {
        locker.with_lock('test.lock'){ sleep 1 }
      }.to raise_error(DynamoDBMutex::LockError)

      thread.join
    end

  end

end
