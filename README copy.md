# Beat deployment testing

To test that the ansible works as expected run the 'run_test.sh' script which does the following:
1. Builds a custom Ubuntu container which is packaged with the ansible role.
2. Runs an Elasticsearch, Kibana and Ubuntu container.
3. Runs the 'beat_deploy.sh' script from within the container
4. Checks the result of the output


## Debugging
If the test is failing and the default output isnt enough to debug with set the CONTAINER_PERSIST variable within the .env file to true, this will pause the script before the containers are brought down to allow for further debugging. 