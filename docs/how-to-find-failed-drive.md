In April 2018 a drive failed in chromium-store8. The Silicon Mechanics hardware does not provide any visual indication of
which drive failed. The instructions provide some guidance to determine which physical drive to replace in the chassis. 

These instructions work for Silicon Mechanics Storform R518. 

## How to make drive's LED flash 

A Silicon support staff provided the following guidance.

1. Download the Broadcom SAS3IRCU from https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_12g_p15/SAS3IRCU_P15.zip
1. Unzip 
    ```
    unzip SAS3IRCU_P15.zip
    chmod +x SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x64_rel/sas3ircu
    ```
1. List available SAS controllers 
    ```
    sudo SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x64_rel/sas3ircu list
    [sudo] password for bconnoll:
    Avago Technologies SAS3 IR Configuration Utility.
    Version 16.00.00.00 (2017.04.26)
    Copyright (c) 2009-2017 Avago Technologies. All rights reserved.


             Adapter      Vendor  Device                       SubSys  SubSys
     Index    Type          ID      ID    Pci Address          Ven ID  Dev ID
     -----  ------------  ------  ------  -----------------    ------  ------
       0     SAS3008       1000h   97h    00h:03h:00h:00h      1000h   30e0h
    SAS3IRCU: Utility Completed Successfully.
    ```
1. Detailed list of all drives on adapter 
    ```
    sudo SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x64_rel/sas3ircu 0 display
    ```
1. Turn on LED for a single physical drive 
    ```
    sudo SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x86_rel/sas3ircu 0 locate 2:19 ON
    
    This command will turn on LED for physical drive that is in enclosure #2 and drive bay 19
    ```
1. Turn off LED for a single physical drive 
    ```
    sudo SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x86_rel/sas3ircu 0 locate 2:19 OFF
    ```



## Additional tools that might be of interest 

1. Lumberjack: Silicon Mechanics asked me to install this software and provide them with the output. 
    * https://github.com/jjsx/scripts
    * https://bitbucket.org/CurtisElgin/lumberjack
1. smartctl (Ubuntu package is named `)
