name: Serverless Deployment
# This workflow is triggered on pushes to the repository.
on: [push]

jobs:
  build:
    # Job name is Greeting
    name: Deploy Serverless
    # This job runs on Linux
    runs-on: ubuntu-latest
    steps:
    - uses: ./server/ci