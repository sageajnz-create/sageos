#!/bin/bash
# Stage 40: register SageOS ujust recipes.
# Same mechanism Bazzite itself uses: append an import line to the master
# justfile. Our recipes live at 70-* (uBlue core is 00-60, Bazzite is 80-95).

set -ouex pipefail

echo 'import "/usr/share/ublue-os/just/70-sageos.just"' >> /usr/share/ublue-os/justfile
