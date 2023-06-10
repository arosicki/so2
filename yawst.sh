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


# config
FILE_INPUT_DEFAULT=~/

# constants
URL_REGEX='(https?)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
SELECTOR_REGEX='^[a-zA-Z0-9\s.#:-]+$'
+6
# strings
TITLE="Yet Another Web Scraping Tool"
MAIN_MENU="Main Menu"
CHOOSE_OPTION="Choose an option"
SCRAPE_TEXT="Scrape Text"
SCRAPE_TABLE="Scrape Table"
ENTER_URL="Enter URL"
ENTER_URL_ERROR="Invalid URL"
ENTER_URL_ERROR_MSG="Please enter a valid URL"
FETCH_URL_ERROR="Unable to fetch URL"
FETCH_URL_ERROR_MSG="Please enter URL to exising resource"
ENTER_SELECTOR_QUERY="Enter Selector Query"
ENTER_SELECTOR_QUERY_ERROR="Invalid Selector Query"
ENTER_SELECTOR_QUERY_ERROR_MSG="Please enter a valid Selector Query"
SELECT_OUTPUT_FILE="Select Output File"
SELECT_OUTPUT_FILE_ERROR="Invalid Output File"
SELECT_OUTPUT_FILE_ERROR_MSG="Please enter a valid Output File with write permissions"
ENTER_TABLE_SELECTOR_QUERY="Enter Table Selector Query"
ENTER_HEADER_SELECTOR_QUERY="Enter Header Selector Query"
ENTER_CELL_SELECTOR_QUERY="Enter Cell Selector Query"
EXIT="Exit"

# views
function main_menu_view() {
    dialog --backtitle "$TITLE" \
    --title "$MAIN_MENU" \
    --menu "$CHOOSE_OPTION" 15 55 5 \
    1 "$SCRAPE_TEXT" \
    2 "$SCRAPE_TABLE" \
    3 "$EXIT" 2>$TEMP_FILE
}

function enter_url_view() {
    dialog --backtitle "$TITLE" \
    --title "$1" \
    --inputbox "$1" 8 60 "$2" 2>$TEMP_FILE
}

function enter_selector_query_view() {
    dialog --backtitle "$TITLE" \
    --title "$1" \
    --inputbox "$1" 8 60 "$2" 2>$TEMP_FILE
}

function select_output_file_view() {
    FILE=$2
    
    if [[ -z $FILE ]]; then
        FILE=$FILE_INPUT_DEFAULT
    fi
    
    dialog --backtitle "$TITLE" \
    --title "$1" \
    --fselect $FILE 8 60 2>$TEMP_FILE
}

function error_view() {
    dialog --backtitle "$TITLE" \
    --title "$1" \
    --msgbox "$2" 8 60
}

#helpers
function get_input() {
    cat $TEMP_FILE
}

function init_tempfile() {
    TEMP_FILE=$(mktemp /tmp/yawst-XXXXXX)
    
    trap "rm -f $TEMP_FILE" EXIT
}

# processors
function process_fetch_url() {
    curl -sL $1
}

function process_scrape_text() {
    echo "$1" | pup "$2 text{}" > $3
}

function handle_scrape_table() {
    echo "handle_scrape_table"
}

# handlers
function handle_url_input() {
    enter_url_view "$ENTER_URL" $1
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    URL=$(get_input)
    
    HTML=''
    if [[ $URL =~ $URL_REGEX ]]; then
        HTML=$(process_fetch_url $URL)
    fi
    
    while [[ ! $URL =~ $URL_REGEX || -z $HTML ]]; do
        if [[ ! $URL =~ $URL_REGEX ]]; then
            error_view "$ENTER_URL_ERROR" "$ENTER_URL_ERROR_MSG"
            elif [[ -z $HTML ]]; then
            error_view "$FETCH_URL_ERROR" "$FETCH_URL_ERROR_MSG"
        fi
        enter_url_view "$ENTER_URL" $URL
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        URL=$(get_input)
        
        HTML=''
        if [[ $URL =~ $URL_REGEX ]]; then
            HTML=$(process_fetch_url $URL)
        fi
    done
    
    RETURN_VALUE=$URL
    return 0
}

function handle_selector_query_input() {
    enter_selector_query_view "$ENTER_SELECTOR_QUERY" $1
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    SELECTOR_QUERY=$(get_input)
    
    while [[ ! $SELECTOR_QUERY =~ $SELECTOR_REGEX ]]; do
        error_view "$ENTER_SELECTOR_QUERY_ERROR" "$ENTER_SELECTOR_QUERY_ERROR_MSG"
        enter_selector_query_view "$ENTER_SELECTOR_QUERY" $SELECTOR_QUERY
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        SELECTOR_QUERY=$(get_input)
    done
    
    RETURN_VALUE=$SELECTOR_QUERY
    return 0
}

function handle_file_input() {
    select_output_file_view "$SELECT_OUTPUT_FILE" $1
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    OUTPUT_FILE=$(get_input)
    
    if [[ ! -f $OUTPUT_FILE ]]; then
        touch $OUTPUT_FILE > /dev/null
    fi
    
    while [[ ! -f $OUTPUT_FILE ]]; do
        error_view "$SELECT_OUTPUT_FILE_ERROR" "$SELECT_OUTPUT_FILE_ERROR_MSG"
        select_output_file_view "$SELECT_OUTPUT_FILE" $OUTPUT_FILE
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        OUTPUT_FILE=$(get_input)
        
        if [[ ! -f $OUTPUT_FILE ]]; then
            touch $OUTPUT_FILE > /dev/null
        fi
    done
    
    RETURN_VALUE=$OUTPUT_FILE
    return 0
}

# drivers
function base_driver() {
    CONFIG=$1
    declare -a RETURN_VALUES
    CURRENT_STEP=0
    TOTAL_STEPS=${#CONFIG[@]}
    
    while [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; do
        ${CONFIG[$CURRENT_STEP]} ${RETURN_VALUES[$CURRENT_STEP]}
        
        if [ $? -eq 1 ]; then
            if [ $CURRENT_STEP -eq 0 ]; then
                return 0
            fi
            CURRENT_STEP=$(($CURRENT_STEP-1))
            continue
        fi
        
        RETURN_VALUES[$CURRENT_STEP]=$RETURN_VALUE
        CURRENT_STEP=$(($CURRENT_STEP+1))
    done
}


function scrape_text_driver() {
    CONFIG=(
        handle_url_input
        handle_selector_query_input
        handle_file_input
    )
    
    base_driver $CONFIG
    
    process_scrape_text "$HTML" "$SELECTOR_QUERY" "$OUTPUT_FILE"
}

function scrape_table_driver() {
    echo "scrape_text_driver"
}

function main_driver() {
    init_tempfile
    
    while true; do
        main_menu_view
        
        case $(get_input) in
            1)
                scrape_text_driver
            ;;
            2)
                scrape_table_driver
            ;;
            *)
                clear
                exit 1
            ;;
        esac
    done
}

main_driver