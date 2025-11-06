# Regenerating keys

## SWUpdate

1. Use `openssl genrsa -out swupdate_private.pem` to generate a private key
2. Use `openssl rsa -in swupdate_private.pem -out swupdate_public.pem -outform PEM -pubout` to export the public key
3. Place both keys (`swupdate_private.pem` and `swupdate_public.pem`) in the folder `RESOURCES/KEYS`

## SSH

1. Run `ssh-keygen -b 2048 -t rsa -f ./id_rsa -q -N ""`
2. Update authorized keys with `mv id_rsa.pub authorized_keys`
