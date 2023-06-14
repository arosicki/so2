#!/bin/bash

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

#################################################################################
# Yet Another Web Scraping Tool
#
# Web scraping tool with command line UI.
# Provides two basic functionalities:
#
# 1. Scraping text from HTML document - you can use selector query to specify which text to scrape
# 2. Scraping table (or other 2 dimensional data format) from HTML document - 
#    you can use selector query to specify which table to scrape and which selectors are headers and cells
#
# Config can be provided in .yawstrc file in home directory.
# If no config is provided, default config is generated and used.
#
# Config options:
#
# FILE_INPUT_DEFAULT=/home/[current_user]/ - default directory for file input
# TABLE_SEPARATOR=';' - separator used in table output
# OMIT_TABLE_HEADER=false - if true, table header will not be included in table output
# AUTOCLOSE=true - if true, program will close after successful scrape
# WHOLE_ELEMENTS=false - if true, whole HTML elements will be returned instead of just text
#
# Usage:  yawsct.sh [-v] [-h]"# Options:
#
# -v - print version
# -h - print help
#################################################################################

#################################################################################
# Config
#################################################################################
VERSION="0.1.0"
AUTHOR="Adrian Rosicki"
# Defaults for config file
CONFIG_FILE=~/.yawstrc
CONFIG_FILE_INPUT_DEFAULT=~/
CONFIG_FILE_TABLE_SEPARATOR=';'
CONFIG_FILE_OMIT_TABLE_HEADERS=false
CONFIG_FILE_AUTOCLOSE=true
CONFIG_FILE_WHOLE_ELEMENTS=false

#################################################################################
# Constants
#################################################################################
URL_REGEX='(https?)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
SELECTOR_REGEX='[a-zA-Z0-9\s.#:-]+'

#################################################################################
# Strings
#
# All promts and messages
#################################################################################
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

#################################################################################
# Views
#
# Most basic fuctions used to create UI. Should be made generic and reusable.
#################################################################################
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

function version_view() {
    echo "$TITLE $VERSION"
    echo "Author: $AUTHOR"
}

function help_view() {
    echo "$TITLE $VERSION"
    echo "Web scraping tool with command line UI."
    echo "Provides two basic functionalities:"
    echo
    echo "1. Scraping text from HTML document - you can use selector query to specify which text to scrape"
    echo "2. Scraping table (or other 2 dimensional data format) from HTML document - you can use selector query to specify which table to scrape and which selectors are headers and cells"
    echo
    echo "Config can be provided in .yawstrc file in home directory."
    echo "If no config is provided, default config is generated and used."
    echo "Config options:"
    echo
    echo "FILE_INPUT_DEFAULT=/home/[current_user]/ - default directory for file input"
    echo "TABLE_SEPARATOR=';' - separator used in table output"
    echo "OMIT_TABLE_HEADER=false - if true, table header will not be included in table output"
    echo "AUTOCLOSE=true - if true, program will close after successful scrape"
    echo "WHOLE_ELEMENTS=false - if true, whole HTML elements will be returned instead of just text"
    echo
    echo "Usage: $0 [-v] [-h]"
    echo
    echo "Options:"
    echo "-v - print version"
    echo "-h - print help"
}

#################################################################################
# Helpers
#
# Utility functions
#################################################################################
function get_input() {
    # reads input from temp file overwritten by last view
    cat $TEMP_FILE
}

function init_tempfile() {
    TEMP_FILE=$(mktemp /tmp/yawst-XXXXXX)
    
    trap "rm -f $TEMP_FILE" EXIT
}

#################################################################################
# Processors
#
# Functions that process data from user inputs, should contain logic only.
#################################################################################
function process_fetch_url() {
    curl -sL $1
}

function process_scrape_text() {
    if [ $WHOLE_ELEMENTS = true ]; then
        echo "$1" | pup --charset utf-8 "$2" > $3
    else
        echo "$1" | pup --charset utf-8 "$2 text{}" > $3
    fi
}

function process_scrape_table() {
    if [ $WHOLE_ELEMENTS = true ]; then
        HEADERS=$(echo "$1" | pup --charset utf-8 "$2 $3")
        ROWS=$(echo "$1" | pup --charset utf-8 "$2 $4")
    else
        HEADERS=$(echo "$1" | pup --charset utf-8 "$2 $3 text{}")
        ROWS=$(echo "$1" | pup --charset utf-8 "$2 $4 text{}")
    fi
    COLUMN_COUNT=$(echo "$1" | pup -n "$2 $3")  
    
    # Create table from data listed in newlines based amount of headers
    if [ $OMIT_TABLE_HEADERS = false ]; then
        echo "$HEADERS" | awk -v n=$COLUMN_COUNT "{printf \"%s%s\", \$0, (NR%n ? \"$TABLE_SEPARATOR\" : \"\n\")}" > $5
        echo "$ROWS" | awk -v n=$COLUMN_COUNT "{printf \"%s%s\", \$0, (NR%n ? \"$TABLE_SEPARATOR\" : \"\n\")}" > $5
    else
        echo "$ROWS" | awk -v n=$COLUMN_COUNT "{printf \"%s%s\", \$0, (NR%n ? \"$TABLE_SEPARATOR\" : \"\n\")}" > $5
    fi
}

function process_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        touch $CONFIG_FILE > /dev/null
        echo "FILE_INPUT_DEFAULT=$CONFIG_FILE_INPUT_DEFAULT" > $CONFIG_FILE
        echo "TABLE_SEPARATOR=\"$CONFIG_FILE_TABLE_SEPARATOR\"" >> $CONFIG_FILE
        echo "OMIT_TABLE_HEADERS=$CONFIG_FILE_OMIT_TABLE_HEADERS" >> $CONFIG_FILE
        echo "AUTOCLOSE=$CONFIG_FILE_AUTOCLOSE" >> $CONFIG_FILE
        echo "WHOLE_ELEMENTS=$CONFIG_FILE_WHOLE_ELEMENTS" >> $CONFIG_FILE
    fi

    . $CONFIG_FILE
}


#################################################################################
# Handlers
#
# Functions that handle and validate user input for single view in specyfic
# use case. Should return 1 if user wants to go back to previous view
# and 0 otherwise.
#################################################################################
function handle_url_input() {
    enter_url_view "$ENTER_URL" "$1"
    
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
    
    RETURN_VALUE="$URL"
    return 0
}

function handle_selector_query_input() {
    enter_selector_query_view "$ENTER_SELECTOR_QUERY" "$1"
    
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
    
    RETURN_VALUE="$SELECTOR_QUERY"
    return 0
}

function handle_file_input() {
    select_output_file_view "$SELECT_OUTPUT_FILE" "$1"
    
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

function handle_table_query_input() {
    enter_selector_query_view "$ENTER_TABLE_SELECTOR_QUERY" "$1"
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    TABLE_SELECTOR_QUERY=$(get_input)
    
    while [[ ! $TABLE_SELECTOR_QUERY =~ $SELECTOR_REGEX ]]; do
        error_view "$ENTER_SELECTOR_QUERY_ERROR" "$ENTER_SELECTOR_QUERY_ERROR_MSG"
        enter_selector_query_view "$ENTER_TABLE_SELECTOR_QUERY" $TABLE_SELECTOR_QUERY
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        TABLE_SELECTOR_QUERY=$(get_input)
    done
    
    RETURN_VALUE="$TABLE_SELECTOR_QUERY"
    return 0
}

function handle_table_header_query_input() {
    enter_selector_query_view "$ENTER_HEADER_SELECTOR_QUERY" "$1"
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    HEADER_SELECTOR_QUERY=$(get_input)
    
    while [[ ! $HEADER_SELECTOR_QUERY =~ $SELECTOR_REGEX ]]; do
        error_view "$ENTER_SELECTOR_QUERY_ERROR" "$ENTER_SELECTOR_QUERY_ERROR_MSG"
        enter_selector_query_view "$ENTER_HEADER_SELECTOR_QUERY" $HEADER_SELECTOR_QUERY
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        HEADER_SELECTOR_QUERY=$(get_input)
    done
    
    RETURN_VALUE="$HEADER_SELECTOR_QUERY"
    return 0
}

function handle_table_row_query_input() {
    enter_selector_query_view "$ENTER_CELL_SELECTOR_QUERY" "$1"
    
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    CELL_SELECTOR_QUERY=$(get_input)
    
    while [[ ! $CELL_SELECTOR_QUERY =~ $SELECTOR_REGEX ]]; do
        error_view "$ENTER_SELECTOR_QUERY_ERROR" "$ENTER_SELECTOR_QUERY_ERROR_MSG"
        enter_selector_query_view "$ENTER_CELL_SELECTOR_QUERY" $CELL_SELECTOR_QUERY
        
        if [ $? -eq 1 ]; then
            return 1
        fi
        
        CELL_SELECTOR_QUERY=$(get_input)
    done
    
    RETURN_VALUE="$CELL_SELECTOR_QUERY"
    return 0
}

#################################################################################
# Drivers
#
# Functions that define functionality and flow given functionality.
# All except main driver should use base driver, and only handler functions
# to define inputs and processor functions to define actions and outputs
#################################################################################
function base_driver() {
    # Base driver
    # Takes in an array of functions to call in order
    # Each function should return 0 if driver is to proceed to next step and 1
    # if driver is to go back to previous step
    # Driver also stores return values of each function in order to preserve
    # state of program if users goes back a step
    CONFIG=$1
    declare -a RETURN_VALUES
    CURRENT_STEP=0
    TOTAL_STEPS=${#CONFIG[@]}
    
    while [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; do
        ${CONFIG[$CURRENT_STEP]} "${RETURN_VALUES[$CURRENT_STEP]}"
        
        if [ $? -eq 1 ]; then
            if [ $CURRENT_STEP -eq 0 ]; then
                return 0
            fi
            CURRENT_STEP=$(($CURRENT_STEP-1))
            continue
        fi
        
        RETURN_VALUES[$CURRENT_STEP]="$RETURN_VALUE"
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
    CONFIG=(
        handle_url_input
        handle_table_query_input
        handle_table_header_query_input
        handle_table_row_query_input
        handle_file_input
    )
    
    base_driver $CONFIG
    
    process_scrape_table "$HTML" "$TABLE_SELECTOR_QUERY" "$HEADER_SELECTOR_QUERY" "$CELL_SELECTOR_QUERY" "$OUTPUT_FILE"
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

        if [ $AUTOCLOSE = true ]; then
            clear
            exit 0
        fi
    done
}

while getopts vh OPT; do
    case $OPT in
        v)
            version_view
            exit 0
        ;;
        h)
            help_view
            exit 0
        ;;
        *)
            echo "Invalid option: -$OPT:"
            echo "Usage: $0 [-v] [-h]"
            exit 1
        ;;
    esac
done

process_config
main_driver