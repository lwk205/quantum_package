.. _dft_keywords:

.. program:: dft_keywords

.. default-role:: option

============
dft_keywords
============

This module contains the main keywords related to a DFT calculation or RS-DFT calculation, such as:

# :option:`dft_keywords exchange_functional`
# :option:`dft_keywords correlation_functional`
# :option:`dft_keywords HF_exchange`  : only relevent for the :ref:`ks_scf` program

The keyword for the range separation parameter :math:`\mu` is the :option:`ao_two_e_erf_integrals mu_erf` keyword. 

The keyword for the type of density used in RS-DFT calculation with a multi-configurational wave function is the :option:`density_for_dft density_for_dft` keyword.



EZFIO parameters
----------------

.. option:: exchange_functional

    name of the exchange functional

    Default: short_range_LDA

.. option:: correlation_functional

    name of the correlation functional

    Default: short_range_LDA

.. option:: HF_exchange

    Percentage of HF exchange in the DFT model

    Default: 0.


Providers
---------


.. c:var:: dft_type

    .. code:: text

        character*(32)	:: dft_type

    File: :file:`keywords.irp.f`

    defines the type of DFT applied: LDA, GGA etc ...

