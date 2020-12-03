
minikube-proxy-installer
************************

.. image:: https://git.beta.ucr.ac.cr/Romain/minikube-proxy-installer/badges/master/pipeline.svg
   :alt: pipeline

.. image:: https://travis-ci.com/Romain/minikube-proxy-installer.svg
   :alt: travis

.. image:: https://readthedocs.org/projects/minikube-proxy-installer/badge
   :alt: readthedocs

A bash script configuring system to handle proxy when using minikube

.. image:: https://git.beta.ucr.ac.cr/Romain/minikube-proxy-installer/raw/master/img/avatar.png
   :alt: avatar

Full documentation on `Readthedocs
<https://minikube-proxy-installer.readthedocs.io>`_.

Source code on:

`Github
<https://github.com/RomainTHERRAT(POCKOST)/minikube-proxy-installer>`_.

`Gitlab
<https://git.beta.ucr.ac.cr/RomainTHERRAT(POCKOST)/minikube-proxy-installer>`_.


Contents
********

* `Description <#Description>`_
* `Usage <#Usage>`_
* `Parameters <#Parameters>`_
   * `help <#help>`_
* `Compatibility <#Compatibility>`_
* `License <#License>`_
* `Links <#Links>`_
* `UML <#UML>`_
   * `Flow <#flow>`_
* `Author <#Author>`_

API Contents
************

* `API <#API>`_
* `Scripts <#scripts>`_
   * `minikube-proxy-installer <#minikube-proxy-installer>`_
      * `Globals <#globals>`_
      * `Functions <#functions>`_

Description
***********

A bash script configuring system to handle proxy when using minikube



Usage
*****

Download the script, give it execution permissions and execute it:

To run tests:

On some tests you may need to use *sudo* to succeed.



Parameters
**********

The following parameters are supported:


help
====

* *-h* (help): Show help message and exit.

..



Compatibility
*************

* `Debian Buster <https://wiki.debian.org/DebianBuster>`_.

* `Debian Raspbian <https://raspbian.org/>`_.

* `Debian Stretch <https://wiki.debian.org/DebianStretch>`_.

* `Ubuntu Bionic <http://releases.ubuntu.com/18.04/>`_.

* `Ubuntu Xenial <http://releases.ubuntu.com/16.04/>`_.



License
*******

GPL 3. See the LICENSE file for more details.



Links
*****

`Github
<https://github.com/RomainTHERRAT(POCKOST)/minikube-proxy-installer>`_.

`Github CI
<https://github.com/RomainTHERRAT(POCKOST)/minikube-proxy-installer/actions>`_.

`Gitlab
<https://git.beta.ucr.ac.cr/RomainTHERRAT(POCKOST)/minikube-proxy-installer>`_.

`Gitlab CI
<https://git.beta.ucr.ac.cr/RomainTHERRAT(POCKOST)/minikube-proxy-installer/pipelines>`_.

`Readthedocs <https://minikube-proxy-installer.readthedocs.io>`_.

`Travis CI
<https://travis-ci.com/RomainTHERRAT(POCKOST)/minikube-proxy-installer>`_.



UML
***


Flow
====

The program flow is shown below:

.. image:: https://git.beta.ucr.ac.cr/Romain/minikube-proxy-installer/raw/master/img/flow.png
   :alt: flow



Author
******

.. image:: https://git.beta.ucr.ac.cr/Romain/minikube-proxy-installer/raw/master/img/author.png
   :alt: author

Comunidad de Software Libre de la Universidad de Costa Rica.



API
***


Scripts
*******


**minikube-proxy-installer**
============================

A bash script configuring system to handle proxy when using minikube


Globals
-------

..

   **UPGRADE**

   ..

      Indicates if upgrade the system or not. Defaults to *false*.


Functions
---------

..

   **get_parameters()**

   ..

      Get bash parameters.

      Accepts:

      ..

         * *h* (help).

      :Parameters:
         **$@** (*str*) – Bash arguments.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
         int

   **help()**

   ..

      Shows help message.

      :Parameters:
         Function has no arguments.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
         int

   **main()**

   ..

      A bash script configuring system to handle proxy when using
      minikube

      :Parameters:
         **$@** (*str*) – Bash arguments string.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
         int

   **sanitize()**

   ..

      Sanitize input.

      The applied operations are:

      ..

         * Trim.

      :Parameters:
         **$1** (*str*) – Text to sanitize.

      :Returns:
         The sanitized input.

      :Return type:
         str


