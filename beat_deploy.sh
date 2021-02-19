#! /bin/bash

################################################################
#
# This script gets ran within the test docker contianer
# It runs the ansible role and then checks the beat is
# successfully writing data to a test elasticsearch cluster.
#
################################################################


cd /root/$BEAT_TYPE/tests
ansible-playbook ../playbooks/$BEAT_TYPE.yml
echo ""
# Checks is an index exists for the beat
for iter in {1..10}; do
    INDEX_STATS=$(curl -s es01:9200/${BEAT_TYPE}*/_stats | jq -r "._shards")
    if [[ $(echo $INDEX_STATS | jq -r ".successful") -eq 1 ]]; then
        echo "$BEAT_TYPE index exists"
        exit_code=0
        break
    elif [[ $(echo $INDEX_STATS | jq -r ".failed") -ge 1 ]]; then
        exit_code=1
    elif [[ $(echo $INDEX_STATS | jq -r ".successful") -eq 0 ]]; then
        exit_code=1
    else
        exit_code=1
    fi
    sleep 2;
done;

if [[ $exit_code -eq 0 ]]; then # Breaks the bash script if no index or index error occurs
        echo "$BEAT_TYPE index stats: $INDEX_STATS"
        echo "Successful $BEAT_TYPE deployment"
        if [[ "$CONTAINER_PERSIST" != true ]]; then
            exit $exit_code
        fi
else
    echo "$BEAT_TYPE index stats: $INDEX_STATS"
    echo -e "\nFailed $BEAT_TYPE deployment"
    if [[ "$CONTAINER_PERSIST" != true ]]; then
        exit $exit_code
    fi
fi


# Keep container running to generate logs
tail -f /dev/null