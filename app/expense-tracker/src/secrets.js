const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const client = new SecretsManagerClient({ region: process.env.AWS_REGION });

async function getDbCredentials() {
  const secretArn = process.env.DB_SECRET_ARN;
  if (!secretArn) {
    throw new Error("DB_SECRET_ARN is not set");
  }

  const response = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
  const { username, password } = JSON.parse(response.SecretString);
  return { username, password };
}

module.exports = { getDbCredentials };
