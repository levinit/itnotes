#!/bin/sh
PASSFILE="/etc/openvpn/server/user-pwd"
LOG_FILE="/var/log/openvpn/user-pwd-auth.log"
TIME_STAMP=$(date "+%Y-%m-%d %T")

###########################################################
echo -e "#syntax example \n#user1    #pwd_for_user1" >> $PASSFILE
if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for reading." >> ${LOG_FILE}
  exit 1
fi

CORRECT_PASSWORD=$(awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${PASSFILE})

if [ "${CORRECT_PASSWORD}" = "" ]; then
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
  exit 1
fi

if [ "${password}" = "${CORRECT_PASSWORD}" ]; then
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> ${LOG_FILE}
  exit 0
fi

echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
exit 1