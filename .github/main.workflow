workflow "Serverless Deployment" {
  on = "push"
  resolves = ["Deploy Serverless"]
}

action "Deploy Serverless" {
  uses = "./server/ci"
}
