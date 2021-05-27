#!/bin/sh

# if there is no ssh configured for current login user, generate the key pairs
if [ ! -f ~/.ssh/id_rsa ]; then
    echo 'No public/private RSA keypair found.'
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
    cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
    chmod 644 ~/.ssh/authorized_keys
    echo "StrictHostKeyChecking no" > ~/.ssh/config
    echo "ForwardAgent yes" >>  ~/.ssh/config
    chmod 644  ~/.ssh/config
fi
