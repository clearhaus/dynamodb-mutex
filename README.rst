DynamoDB Mutex
==============

Using DynamoDB, it implements a simple semaphore that can be used to coordinate
access to shared data from multiple concurrent hosts or processes.

Usage
-----

.. code-block:: ruby

    require 'dynamodb-mutex'

    DynamoDBMutex.with_lock :your_lock do
       # Access to shared resource.
    end

You can pass following options to ``with_lock``

.. code-block:: ruby

    :block  => 1    # Specify in seconds how long you want to wait for the lock to be released. (default: 1)
                    # It will raise DynamoDBMutex::LockError after block timeout
    :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
                    # It is NOT recommended to go below 0.01. (default: 0.1)
    :ttl => 10      # Specify in seconds when the lock should be considered stale when something went wrong
                    # with the one who held the lock and failed to unlock. (default: 10)

