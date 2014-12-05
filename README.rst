DynamoDB Mutex
==============

Using DynamoDB, it implements a simple semaphore that can be used to coordinate
access to shared data from multiple concurrent hosts.

Usage
-----

.. code-block:: ruby

    require 'dynamodb-mutex'

    DynamoDBMutex.with_lock do
      # Access to shared resource.
    end
