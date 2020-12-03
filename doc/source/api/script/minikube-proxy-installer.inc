**minikube-proxy-installer**
-----------------------------------------------------------------------------

A bash script configuring system to handle proxy when using minikube

Globals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   **UPGRADE**

      Indicates if upgrade the system or not. Defaults to *false*.

Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   **get_parameters()**

      Get bash parameters.

      Accepts:

       - *h* (help).

      :Parameters:
         **$@** (*str*) – Bash arguments.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
        int

   **help()**

      Shows help message.

      :Parameters:
         Function has no arguments.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
        int

   **main()**

      A bash script configuring system to handle proxy when using minikube

      :Parameters:
         **$@** (*str*) – Bash arguments string.

      :Returns:
         0 if successful, 1 on failure.

      :Return type:
        int

   **sanitize()**

      Sanitize input.

      The applied operations are:

       - Trim.

      :Parameters:
         **$1** (*str*) – Text to sanitize.

      :Returns:
         The sanitized input.

      :Return type:
        str
