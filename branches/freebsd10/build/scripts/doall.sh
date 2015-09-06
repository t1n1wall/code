#!/usr/local/bin/bash

set -e

/usr/local/bin/bash 1makebuildenv.sh
/usr/local/bin/bash 2makebinaries.sh
/usr/local/bin/bash 3patchtools.sh
/usr/local/bin/bash 4crunch.sh
/usr/local/bin/bash 5buildkernel.sh
/usr/local/bin/bash 6makeimage.sh
