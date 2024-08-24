# kloudnuk-scripts
 
These scripts are utilities to help with several different functions:

1. Install software and client certificate into your device to allow for secure mutual tls communication between your device and the Kloudnuk service.
2. Enroll your device under your organization using your Kloudnuk username and password.
3. Run the app as a service, so it can auto-restart on reboot.
4. Remove the service.
5. Uninstall all software.

## Install Script (install.sh)

The install script calls out to the Kloudnuk service with a user's name, password and organization. Currently there are five parameters to be passed by the user when running the script:

* A descriptive name for the new device to be enrolled into Kloudnuk.
* The user's organization's name.
* User name.
* User's password.
* The server's URL. This will only be needed during testing and beta as the testing and production environments get migrated from local machines to containers on the cloud.

In order to run the script follow the steps below:
1. Download the script from github `wget https://raw.githubusercontent.com/viteski/kloudnuk-scripts/main/install/install.sh`
2. Make sure the scripts are executable `sudo chmod +x install.sh`
3. Make sure you are the owner `sudo chown $USER:$USER install.sh`
4. Run it `install.sh device-a my-org my-username my-pass https://test.kloudnuk.com*`

## Service Setup Script (addservice.sh)

The addservice.sh script uses your device's linux user name and user group to configure the kloudnuk local application as a service under the linux user account and group you specify as parameters when you run the script.

All the steps to follow are the same as the previous script, but for the number of parameters used when executing the script `addservice.sh my-linux-username my-linux-user-group`

## Remove Service Script (removeservice.sh)

As the name implies this script simply removes the application from the service list and reloads the services daemon to make the changes effective.
This script requires no parameters.

## Uninstall Script (uninstall.sh)

Removes the python packages, the application directory, the debian packages installed to support the python app (if you uncomment the line), and the client certificate. No parameters are needed.

**vtsmolinski@outlook.com**