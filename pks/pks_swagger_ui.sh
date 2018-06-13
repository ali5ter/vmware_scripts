#!/usr/bin/env bash
# @file pks_swagger_ui.sh
# Crank up an instance of Swagger UI to show the PKS API docs
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# retrieve swagger definition  -----------------------------------------------

SWAGGER_YAML='pks_api_swagger.yaml'
SWAGGER_SWAGGER_URL='https://gitlab.eng.vmware.com/PKS/pks-ui/blob/master/pks-service/specs/swagger.yaml'

rm -f "$SWAGGER_YAML"
curl "$SWAGGER_SWAGGER_URL" -o "$SWAGGER_YAML" || {
    echo "Failed to fetch the swagger definition file from $SWAGGER_SWAGGER_URL"
    exit 1
}

# start swagger-ui contianer -------------------------------------------------

pgrep -f docker > /dev/null || {
    echo "Your system doesn't appear to be running the Docker daemon."
    echo "To run swagger-ui in a container, I need to use docker."
    echo "Please make sure Docker is running and try again."
    exit 1
}

SWAGGER_UI_IMAGE='swaggerapi/swagger-ui'
SWAGGER_UI_PORT=8888
SWAGGER_URL="http://localhost:$SWAGGER_UI_PORT/"

docker ps -a | grep "$SWAGGER_UI_IMAGE" | awk '{print $1}' | xargs docker rm -fv > /dev/null 2>&1

docker run -d --name swagguer-ui -p "$SWAGGER_UI_PORT":8080 \
    -e SWAGGER_JSON="/specs/$SWAGGER_YAML" \
    -v "${SCRIPTPATH}":/specs \
    "$SWAGGER_UI_IMAGE" > /dev/null 2>&1

# Open brower using swagger ui view on the swagger definition ----------------

[[ "$OSTYPE" == "darwin"* ]] && open "$SWAGGER_URL"
echo -e "Start Swagger-UI in your browser using $SWAGGER_URL\n"
