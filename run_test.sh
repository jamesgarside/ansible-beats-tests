#! /bin/bash

# Check if in 'tests' directory, if not exit
if [[ "$PWD" != *beat/tests ]]; then
    echo "Not in tests directory"
    exit 1
fi

# Load .env file
if [ -f .env ]
then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    echo ""
    echo "Beat Type: $BEAT_TYPE"
    echo "Version: $VERSION"
    echo "Container Persist: $CONTAINER_PERSIST"
    echo ""
else
    echo "No .env file found. This is required to run tests"
    exit 1
fi

# Check if docker-compose installed
DOCKER_COMPOSE_VERSION=$(docker-compose --version)
if [[ "$DOCKER_COMPOSE_VERSION" != "docker-compose version"* ]]; then
    echo "Docker-compose not installed"
    exit 1
else
    echo $DOCKER_COMPOSE_VERSION
fi

# Build the test containers using docker-compose
docker-compose up --detach --quiet-pull 1>/dev/null

for iter in {1..6}; do
    TEST_OUTPUT=$(docker logs --tail 1 ubuntu_ansible)
    if [ "$TEST_OUTPUT" == "Successful $BEAT_TYPE deployment" ]; then
        EXIT_CODE=0
        break
    elif [ "$TEST_OUTPUT" == "Failed $BEAT_TYPE deployment" ]; then
        EXIT_CODE=1
        break
    else
        EXIT_CODE=1
    fi
    sleep 10;
done;


LOG_OUTPUT="$(docker logs --tail 1000 ubuntu_ansible 2>&1)"

# If container persist is true the script will wait until a key is pressed until
# finishing off and cleaning up containers/
if [[ "$CONTAINER_PERSIST" == true ]]; then
    echo -e "\nTest status: $TEST_OUTPUT\n"
    echo ""
    echo        "------- Service Access -------"
    echo "Kibana:           http://"$(hostname -I | xargs)":$(docker inspect --format='{{(index (index .NetworkSettings.Ports "5601/tcp") 0).HostPort}}' kibana)"
    echo "Elasticsearch:    http://"$(hostname -I | xargs)":$(docker inspect --format='{{(index (index .NetworkSettings.Ports "9200/tcp") 0).HostPort}}' es01)"
    echo "Ubuntu            docker exec -it ubuntu_ansible /bin/bash"
    echo ""
    echo "Press any key to shutdown and remove containers"
    while [ true ]; do
        read -t 3 -n 1
        if [ $? = 0 ]; then
            break;
        fi
    done;
fi

# Remove the docker-compose containers
echo -e "\nRemoving created docker containers"
docker-compose down
echo -e "\nRemoving created docker images\n"
docker rmi tests_ubuntu >> /dev/null

# Check return status of the test
if [ $EXIT_CODE == 0 ]; then
    echo -e "Test SUCCESSFUL\n"
elif [ $EXIT_CODE != 0 ]; then
    echo "$LOG_OUTPUT"
    echo -e "\nTest FAILED\n"
else
    echo "$LOG_OUTPUT"
    echo -e "\nTest FAILED. Unknown Error\n"    
fi

exit $exit_code