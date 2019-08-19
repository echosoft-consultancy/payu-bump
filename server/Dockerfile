FROM softinstigate/serverless

LABEL "com.github.actions.name"="Deploy Serverless"
LABEL "com.github.actions.description"="Build and deploy serverless code"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="https://github.com/echosoft-consultancy/payu-bump"
LABEL "homepage"="https://github.com/echosoft-consultancy/payu-bump"
LABEL "maintainer"="Ben Jefferies <ben.jefferies@echosoft.uk>"

ADD . /opt/server

WORKDIR /opt/server/
ENTRYPOINT ["/opt/server/entrypoint.sh"]