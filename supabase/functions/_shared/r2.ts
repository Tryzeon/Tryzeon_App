import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectsCommand } from "npm:@aws-sdk/client-s3";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner";
import { FetchHttpHandler } from "npm:@smithy/fetch-http-handler";

let _r2Client: S3Client | null = null;

const SIGNED_URL_EXPIRY_SECONDS = 604800; // 7 days

const TRYON_CACHE_CONTROL =
  `private, max-age=${SIGNED_URL_EXPIRY_SECONDS}, immutable`;

const validateR2Env = () => {
  const requiredVars = [
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "R2_ENDPOINT",
    "R2_TRYON_VIDEOS_BUCKET_NAME",
    "R2_TRYON_IMAGES_BUCKET_NAME",
  ];

  for (const envVar of requiredVars) {
    if (!Deno.env.get(envVar)) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  }
};

export const getR2Client = () => {
  if (!_r2Client) {
    validateR2Env();
    _r2Client = new S3Client({
      region: "auto",
      endpoint: Deno.env.get("R2_ENDPOINT")!,
      requestHandler: new FetchHttpHandler(),
      credentials: {
        accessKeyId: Deno.env.get("R2_ACCESS_KEY_ID")!,
        secretAccessKey: Deno.env.get("R2_SECRET_ACCESS_KEY")!,
      },
      requestChecksumCalculation: "WHEN_REQUIRED",
      responseChecksumValidation: "WHEN_REQUIRED",
    });
  }
  return _r2Client;
};

async function uploadToR2(
  bucket: string,
  key: string,
  body: Uint8Array,
  contentType: string,
): Promise<string> {
  const s3Client = getR2Client();

  const putCommand = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: body,
    ContentType: contentType,
    CacheControl: TRYON_CACHE_CONTROL,
  });

  await s3Client.send(putCommand);

  const getCommand = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  return await getSignedUrl(s3Client, getCommand, {
    expiresIn: SIGNED_URL_EXPIRY_SECONDS,
  });
}

export async function uploadTryonVideoToR2(body: Uint8Array, fileName: string): Promise<string> {
  const bucketName = Deno.env.get("R2_TRYON_VIDEOS_BUCKET_NAME")!;
  return await uploadToR2(bucketName, fileName, body, "video/mp4");
}

export async function uploadTryonImageToR2(
  body: Uint8Array,
  fileName: string,
  contentType: string,
): Promise<string> {
  const bucketName = Deno.env.get("R2_TRYON_IMAGES_BUCKET_NAME")!;
  return await uploadToR2(bucketName, fileName, body, contentType);
}

const PUBLIC_CACHE_CONTROL = "public, max-age=31536000, immutable";

function getPublicImagesBucketName(): string {
  const bucket = Deno.env.get("R2_PUBLIC_IMAGES_BUCKET_NAME");
  if (!bucket) {
    throw new Error("Missing required environment variable: R2_PUBLIC_IMAGES_BUCKET_NAME");
  }
  return bucket;
}

export async function uploadPublicImageToR2(
  buffer: ArrayBuffer,
  key: string,
  contentType: string,
): Promise<void> {
  const bucket = getPublicImagesBucketName();
  const s3Client = getR2Client();
  await s3Client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: new Uint8Array(buffer),
    ContentType: contentType,
    CacheControl: PUBLIC_CACHE_CONTROL,
  }));
}

export async function deletePublicImagesFromR2(keys: string[]): Promise<void> {
  const bucket = getPublicImagesBucketName();
  const s3Client = getR2Client();
  
  const result = await s3Client.send(new DeleteObjectsCommand({
    Bucket: bucket,
    Delete: { Objects: keys.map((Key) => ({ Key })) },
  }));
  
  const errors = result.Errors ?? [];
  if (errors.length > 0) {
    const summary = errors.map((e) => `${e.Key}: ${e.Code}`).join(", ");
    throw new Error(`Failed to delete ${errors.length} object(s): ${summary}`);
  }
}

export async function downloadPublicImageFromR2(key: string): Promise<Uint8Array> {
  const bucket = getPublicImagesBucketName();
  const resp = await getR2Client().send(new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  }));
  if (!resp.Body) {
    throw new Error(`No body returned from R2 for key: ${key}`);
  }
  return resp.Body.transformToByteArray();
}

const PRESIGNED_PUT_EXPIRY_SECONDS = 600; // 10 minutes — short window since URL is single-use per upload

export async function generatePresignedPutUrl(params: {
  key: string;
  contentType: string;
  contentLength: number;
  expiresIn?: number;
}): Promise<string> {
  const bucket = getPublicImagesBucketName();
  const s3Client = getR2Client();
  // ContentLength is signed: client must PUT exactly this many bytes (SigV4 will reject otherwise).
  // Cache-Control is intentionally NOT signed; it's applied via bucket default / CDN cache rules.
  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: params.key,
    ContentType: params.contentType,
    ContentLength: params.contentLength,
  });
  return await getSignedUrl(s3Client, command, {
    expiresIn: params.expiresIn ?? PRESIGNED_PUT_EXPIRY_SECONDS,
  });
}
