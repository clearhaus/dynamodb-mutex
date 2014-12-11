DynamoDB Mutex
==============

.. image:: https://travis-ci.org/clearhaus/dynamodb-mutex.svg?branch=master
    :alt: Build Status
    :target: https://travis-ci.org/clearhaus/dynamodb-mutex

.. image:: https://codeclimate.com/github/clearhaus/dynamodb-mutex/badges/gpa.svg
    :alt: Code Climate
    :target: https://codeclimate.com/github/clearhaus/dynamodb-mutex

.. image:: https://gemnasium.com/clearhaus/dynamodb-mutex.svg
    :alt: Dependency Status
    :target: https://gemnasium.com/clearhaus/dynamodb-mutex

.. image:: http://img.shields.io/license/MIT.png?color=green
    :alt: MIT License
    :target: http://opensource.org/licenses/MIT

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
