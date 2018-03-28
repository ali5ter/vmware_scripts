#!/usr/bin/env bash
# @file cascade_api.sh
# Crank up an instance of Swagger UI to show the Cascade API docs
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

heading 'Authenticate with Cascade service'
"$PWD/cascade_authenticate.sh"

## Currently you need to convert CSP token to a Lightwave token to auth with
## the API
TOKEN="$(cat ~/.cascade-cli/cascade-config  | jq -r .Token)"

## Can also use 'cascade tenant get'
TENANT="$(cat ~/.cascade-cli/cascade-config  | jq -r .Tenant.Name)"

# retrieve swagger yaml and convert json -------------------------------------

SWAGGER_YAML='cascade_api_swagger.yml'
SWAGGER_SWAGGER_URL="https://confluence.eng.vmware.com/download/attachments/276837032/idl_api-swagger.yml.txt?version=1&modificationDate=1517411082000&api=v2"

[[ -f "$SWAGGER_YAML" ]] || {
    echo "Download the swagger definition file from"
    echo "$SWAGGER_SWAGGER_URL"
    echo "Once downloaded, rename it to $SWAGGER_YAML"
    exit 1
}

sed -i '' 's/proxy-api\.cascade\.vmware\.com/api\.cascade-cloud\.com/g' "$SWAGGER_YAML"

# start swagger-ui contianer -------------------------------------------------

heading 'Starting up a swagger-ui container'

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
    -v "$SCRIPTPATH":/specs \
    "$SWAGGER_UI_IMAGE" > /dev/null 2>&1

# Open brower using swagger ui view on the swagger definition ----------------

if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$SWAGGER_URL"
else
    echo "Start Swagger-UI in your browser using $SWAGGER_URL"
fi
echo -e "Authenticate using the OATH token\n$TOKEN"
echo -e "You Tenant name is\n$TENANT"