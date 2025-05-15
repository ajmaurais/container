#!/usr/bin/env bash
set -e

# If no UID/GID supplied, run the command as root
if [ -z "$LOCAL_USER_ID" ] || [ -z "$LOCAL_GROUP_ID" ]; then
  exec "$@"
fi

# resolve or create group
if getent group "$LOCAL_GROUP_ID" >/dev/null; then
  GROUP_NAME=$(getent group "$LOCAL_GROUP_ID" | cut -d: -f1)
else
  GROUP_NAME=localgroup
  groupadd -g "$LOCAL_GROUP_ID" "$GROUP_NAME"
fi

# resolve or create user
if id -u "$LOCAL_USER_ID" >/dev/null 2>&1; then
  USER_NAME=$(getent passwd "$LOCAL_USER_ID" | cut -d: -f1)
  if ! id -nG "$USER_NAME" | grep -qw "$GROUP_NAME"; then
    usermod -g "$GROUP_NAME" "$USER_NAME"
  fi
else
  USER_NAME=localuser
  useradd -u "$LOCAL_USER_ID" -g "$LOCAL_GROUP_ID" -s /bin/bash "$USER_NAME"
fi

# give ownership of wineprefix to that UID/GID
chown "$LOCAL_USER_ID:$LOCAL_GROUP_ID" /wineprefix64

# drop privileges and exec under the resolved username
exec gosu "$USER_NAME" "$@"