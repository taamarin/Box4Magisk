#!/bin/sh

zip -r -o -X -ll box_for_magisk-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'build.sh' -x '.github/*'