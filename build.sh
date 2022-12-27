#!/bin/sh

zip -r -o -X -ll box_for_magisk-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'index.md' -x 'CHANGELOG.md' -x 'update.json' -x 'build.sh' -x '.github/*'