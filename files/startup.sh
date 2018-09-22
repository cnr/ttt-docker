#!/bin/bash

set -euxo pipefail

if [[ -z $WORKSHOP_ID ]]
then
    echo 'Missing $WORKSHOP_ID env variable'
    exit 1
fi

if [[ -z $RCON_PASSWORD ]]
then
    echo 'Missing $RCON_PASSWORD env variable'
    exit 1
fi

if [[ -z $SERVER_NAME ]]
then
    echo 'Missing $SERVER_NAME env variable'
    exit 1
fi

api() {
    local ENDPOINT=$1
    local LENGTH_ENTRY_NAME=$2
    shift 2

    local post_data="$LENGTH_ENTRY_NAME=$#"
    local cur_index=0

    for file in "$@"
    do
        post_data+="&publishedfileids[$cur_index]=$file"
        cur_index=$(( $cur_index + 1 ))
    done

    curl -s -X POST --data "$post_data" "https://api.steampowered.com/ISteamRemoteStorage/$ENDPOINT/v1/"
}

get_collection_details() {
    api 'GetCollectionDetails' 'collectioncount' "$@"
}

get_file_details() {
    api 'GetPublishedFileDetails' 'itemcount' "$@"
}

generate_fastdl() {
    local COLLECTION_ID=$1

    local FILE_LIST=( $(get_collection_details $COLLECTION_ID | jq -r '.response.collectiondetails[0].children[].publishedfileid') )

    get_file_details "${FILE_LIST[@]}" | jq -r '.response.publishedfiledetails | map(select(any(.tags[]; .tag == "map") | not)) | .[].publishedfileid' | \
        while read -r item
        do
            echo "resource.AddWorkshop(\"$item\")"
        done
}

generate_fastdl $WORKSHOP_ID > garrysmod/lua/autorun/server/workshop.lua

./srcds_run -console -maxplayers 32 \
    -game garrysmod +gamemode terrortown \
    +map ttt_minecraft_b5 \
    +host_workshop_collection $WORKSHOP_ID \
    +rcon_password $RCON_PASSWORD \
    +hostname "$SERVER_NAME"
