const { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const client = new S3Client({ region: process.env.AWS_REGION });
const bucket = process.env.S3_BUCKET;

function receiptKey(id, filename) {
  const env = process.env.APP_ENV || "dev";
  return `${env}/receipts/${id}-${filename}`;
}

async function uploadReceipt(key, buffer, contentType) {
  await client.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    })
  );
}

async function deleteReceipt(key) {
  await client.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
}

async function presignedReceiptUrl(key) {
  const command = new GetObjectCommand({ Bucket: bucket, Key: key });
  return getSignedUrl(client, command, { expiresIn: 300 });
}

module.exports = { receiptKey, uploadReceipt, deleteReceipt, presignedReceiptUrl };
