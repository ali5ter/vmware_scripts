#!/usr/bin/env bash
# @file vke_api.sh
# Crank up an instance of Swagger UI to show the VMware Container Service API docs
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/vke_env.sh"

heading 'Authenticate with VMware Container Service service'
"$PWD/vke_auth.sh"

## Currently you need to convert CSP token to a Lightwave token to auth with
## the API
TOKEN="$(jq -r .Token ~/.vke-cli/vke-config)"

TENANT="$(vke account show | grep Tenant | cut -d':' -f2)"

# retrieve swagger definition  -----------------------------------------------

heading 'Fetching swagger definition file'

SWAGGER_YAML='vke_api_swagger.yml'
SWAGGER_SWAGGER_URL='https://review.ec.eng.vmware.com/gitweb?p=cascade-api-proxy.git;a=blob_plain;f=idl/api-swagger.yml;hb=refs/heads/develop'

rm -f "$SWAGGER_YAML"
curl "$SWAGGER_SWAGGER_URL" -o "$SWAGGER_YAML" || {
    echo "Failed to fetch the swagger definition file from $SWAGGER_SWAGGER_URL"
    exit 1
}
sed -i '' 's/proxy-api\.cloud\.vmware\.com/api\.vke-cloud\.com/g' "$SWAGGER_YAML"

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

[[ "$OSTYPE" == "darwin"* ]] && open "$SWAGGER_URL"
echo -e "Start Swagger-UI in your browser using $SWAGGER_URL\n"
echo -e "Authenticate using the OATH token\\nBearer $TOKEN\n"
echo -e "You Organization name is\\n$TENANT"
