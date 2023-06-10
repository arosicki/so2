#################################################################################
# Copyright (c) 2023 Adrian Rosicki
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#################################################################################

#!/bin/bash

# views

TEMP_FILE=$(mktemp /tmp/yawst-XXXXXX)

trap "rm -f $TEMP_FILE" EXIT

function main_menu() {
    dialog --backtitle "Yet Another Web Scraping Tool" \
        --title "Main Menu" \
        --menu "Choose an option" 15 55 5 \
        1 "Scrape Text" \
        2 "Scrape Table" \
        3 "Quit" 2>$TEMP_FILE

    cat $TEMP_FILE
}

main_menu