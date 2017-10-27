==============
celery-Formula
==============

Formula to setup and configure `celery` to be run as a daemon

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.


Available states
==================

.. contents::
   :local:

``celery``
------------
Installs everything by including `celery.env`

``celery.env``
------------
Installs the Celery library and executables according to the pillar and grain data

``celery.worker``
------------------
Creates a systemd service for running Celery Workers and by default will setup a single queue named **default**, `See defaults.yaml <https://github.com/978inc/celery-formula/blob/master/celery/defaults.yaml>`_ for a more complete example.

`celery.worker_queues` is a list of maps which contain four keys: `name`, `concurrency` and `opts`.
- `name` controls the name of the queue
- `concurrency` controls how many worker processes per queue
- `opts` is a map where the keys are mapped to environment variables prefixed with **CELERYD_**


``celery.debug``
-----------------
Helpful for debugging, dumps the jinja map to a text file in **/tmp**.


``celery.testing``
------------------
Only used during testing, will install redis to back the broker.



Testing
=========

Requirements
------------

Testing is done with KitchenSalt_ which means you'll also need a working Ruby setup and preferably 2.2.2, but you can use whatever version as long as you update the `Gemfile`.  You will also need `bundler` installed and can be done so with `gem install bundler`.

If all that works, you should be able to run `kitchen test` which is an alias for `kitchen converge` + `kitchen verify` but it deletes the box on completion so it isn't very useful during development.  

.. _KitchenSalt: https://github.com/simonmcc/kitchen-salt

Cheat Sheet
------------

.. code-block::

   # Initial setup
   which bundle || gem install bundler
   bundle install
   
   # build vagrant box and run states
   kitchen converge
   
   # run tests in `test/integration/default`
   kitchen verify

   # sledgehammer
   kitchen destroy

   # alias for running  (destroy + converge + verify + destroy)
   kitchen test

  
