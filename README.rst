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

If no lock name (``:your_lock`` above) is given, ``#with_lock`` uses
``'default.lock'``.

You can pass ``with_lock`` the following options:

* ``:wait_for_other`` (default ``1``):
  Seconds to to wait for another process to release the lock.
* ``:polling_interval`` (default ``0.1``):
  Seconds between retrials to acquire lock. Should be at least
  "``(:wait_for_other / 5) * (no_of_instances - 1)``".
* ``:stale_after`` (default ``10``):
  Seconds after which the lock is considered stale and will be automatically
  deleted; set to "falsey" (``nil`` or ``false``) to disable.
