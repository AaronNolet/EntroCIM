#!/bin/bash

# check for iotctl user
hasUser=false
getent passwd iotctl >/dev/null 2>&1 && hasUser=true

echo "Verifying if user already present..."
if ! $hasUser; then
    echo "User does not exist..."
    echo "Creating 'iotctl' user"
    echo ""
    groupadd -f iotctl > /dev/null
    adduser --system --ingroup iotctl iotctl > /dev/null
    mkdir /home/iotctl/.ssh
    touch /home/iotctl/.ssh/authorized_keys
    chown iotctl:iotctl /home/iotctl/ -R
    chmod 700 /home/iotctl/.ssh/
    chmod 600 /home/iotctl/.ssh/authorized_keys
else
  echo "User Already Exists... Exiting..."
fi

# check for and create non-root user service control for OnChange and EntroCIM
if [ ! -f /etc/sudoers.d/servicecontrol ]; then
  echo "Creating secure Services control for iotctl non-root user..."
  echo "iotctl  ALL = NOPASSWD: /bin/systemctl start entrocim.service, /bin/systemctl stop entrocim.service, /bin/systemctl restart entrocim.service, /bin/systemctl status entrocim.service, /bin/systemctl stop onchange.service, /bin/systemctl start onchange.service, /bin/systemctl restart onchange.service, /bin/systemctl status onchange.service" > /etc/sudoers.d/servicecontrol
  chmod 0440 /etc/sudoers.d/servicecontrol
  if [ -r /etc/sudoers.d/servicecontrol ]; then
    echo "Sucessfully Created"
  else
    echo "Failed to create necssary file... Please review."
  fi
else
  echo "Cannot attempt to create secure Services control for iotctl non-root user due to pre-existing sudoers file..."
fi

# Still requires additional check and control to enable "RSAAuthentication yes" an "PubkeyAuthentication yes" within /etc/ssh/sshd_config file
