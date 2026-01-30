const { Storage } = require('@google-cloud/storage');
const fs = require('fs-extra');
const path = require('path');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/gcs-storage.log' })
  ]
});
class GCSStorageService {
  constructor() {
    this.storage = null;
    this.bucket = null;
    this.initialized = false;
    this.initializationPromise = this.initializeGCS();
  }
  async initializeGCS() {
    try {
      this.storage = new Storage({
        projectId: process.env.GOOGLE_CLOUD_PROJECT,
        keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS || "etc/secrets/scholar-lens-fa555-7f5fba046557.json",
      });
      const bucketName = process.env.GCS_BUCKET || `${process.env.GOOGLE_CLOUD_PROJECT}-storage`;
      this.bucket = this.storage.bucket(bucketName);
      
      // Check if bucket exists, create if it doesn't
      const [exists] = await this.bucket.exists();
      if (!exists) {
        logger.info(`Creating GCS bucket: ${bucketName}`);
        await this.storage.createBucket(bucketName, {
          location: 'US',
          storageClass: 'STANDARD',
        });
        logger.info(`Bucket created successfully: ${bucketName}`);
      }
      
      this.initialized = true;
      logger.info('Google Cloud Storage initialized successfully', {
        project: process.env.GOOGLE_CLOUD_PROJECT,
        bucket: bucketName
      });
    } catch (error) {
      logger.error('Google Cloud Storage initialization failed', {
        name: error.name,
        message: error.message,
        stack: error.stack,
      });
      this.initialized = false;
    }
  }
  async uploadFile(filePath, destination, metadata = {}) {
    await this.initializationPromise;
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Uploading file to GCS: ${destination}`);
      const file = this.bucket.file(destination);
      await file.save(await fs.readFile(filePath), {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });
      if (metadata.makePublic) {
        await file.makePublic();
        return `https://storage.googleapis.com/${this.bucket.name}/${destination}`;
      }
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: metadata.expires || Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
      });
      logger.info(`File uploaded successfully: ${destination}`);
      return url;
    } catch (error) {
      logger.error(`File upload failed: ${error.message}`);
      throw error;
    }
  }
  async uploadBuffer(buffer, destination, metadata = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Uploading buffer to GCS: ${destination}`);
      const file = this.bucket.file(destination);
      await file.save(buffer, {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });
      if (metadata.makePublic) {
        await file.makePublic();
        return `https://storage.googleapis.com/${this.bucket.name}/${destination}`;
      }
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: metadata.expires || Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
      });
      logger.info(`Buffer uploaded successfully: ${destination}`);
      return url;
    } catch (error) {
      logger.error(`Buffer upload failed: ${error.message}`);
      throw error;
    }
  }
  async deleteFile(filePath) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Deleting file from GCS: ${filePath}`);
      const file = this.bucket.file(filePath);
      await file.delete();
      logger.info(`File deleted successfully: ${filePath}`);
    } catch (error) {
      logger.error(`File deletion failed: ${error.message}`);
      throw error;
    }
  }
  async getDownloadUrl(filePath, options = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      if (options.public) {
        return `https://storage.googleapis.com/${this.bucket.name}/${filePath}`;
      }
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: options.expires || Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
      });
      return url;
    } catch (error) {
      logger.error(`Get download URL failed: ${error.message}`);
      throw error;
    }
  }
  async fileExists(filePath) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      const [exists] = await file.exists();
      return exists;
    } catch (error) {
      logger.error(`File exists check failed: ${error.message}`);
      return false;
    }
  }
  async listFiles(prefix = '', options = {}) {
    await this.initializationPromise;
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const [files] = await this.bucket.getFiles({
        prefix,
        maxResults: options.maxResults || 100,
      });
      return files.map(file => ({
        name: file.name,
        size: file.metadata.size,
        contentType: file.metadata.contentType,
        created: file.metadata.timeCreated,
        updated: file.metadata.updated,
      }));
    } catch (error) {
      logger.error(`List files failed: ${error.message}`);
      throw error;
    }
  }
  generateUniqueFilename(originalName, prefix = '') {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    const extension = path.extname(originalName);
    const baseName = path.basename(originalName, extension);
    return `${prefix}${timestamp}-${random}-${baseName}${extension}`;
  }
  async getFileMetadata(filePath) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      const [metadata] = await file.getMetadata();
      return metadata;
    } catch (error) {
      logger.error(`Get file metadata failed: ${error.message}`);
      throw error;
    }
  }
  async createBucketIfNotExists(bucketName, options = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const bucket = this.storage.bucket(bucketName);
      const [exists] = await bucket.exists();
      if (!exists) {
        logger.info(`Creating GCS bucket: ${bucketName}`);
        await this.storage.createBucket(bucketName, {
          location: options.location || 'US',
          storageClass: options.storageClass || 'STANDARD',
        });
        logger.info(`Bucket created successfully: ${bucketName}`);
      }
    } catch (error) {
      logger.error(`Bucket creation failed: ${error.message}`);
      throw error;
    }
  }
  async copyFile(sourcePath, destinationPath) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Copying file in GCS: ${sourcePath} -> ${destinationPath}`);
      const sourceFile = this.bucket.file(sourcePath);
      const destinationFile = this.bucket.file(destinationPath);
      await sourceFile.copy(destinationFile);
      logger.info(`File copied successfully: ${sourcePath} -> ${destinationPath}`);
    } catch (error) {
      logger.error(`File copy failed: ${error.message}`);
      throw error;
    }
  }
  async moveFile(sourcePath, destinationPath) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Moving file in GCS: ${sourcePath} -> ${destinationPath}`);
      const sourceFile = this.bucket.file(sourcePath);
      const destinationFile = this.bucket.file(destinationPath);
      await sourceFile.move(destinationFile);
      logger.info(`File moved successfully: ${sourcePath} -> ${destinationPath}`);
    } catch (error) {
      logger.error(`File move failed: ${error.message}`);
      throw error;
    }
  }
  isConfigured() {
    return this.initialized && 
           !!process.env.GOOGLE_CLOUD_PROJECT && 
           !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }
  getConfigStatus() {
    const bucketName = process.env.GCS_BUCKET || `${process.env.GOOGLE_CLOUD_PROJECT}-storage`;
    return {
      initialized: this.initialized,
      projectConfigured: !!process.env.GOOGLE_CLOUD_PROJECT,
      credentialsConfigured: !!process.env.GOOGLE_APPLICATION_CREDENTIALS,
      bucketName: bucketName,
      bucketConfigured: !!bucketName,
    };
  }
  async updateFileMetadata(filePath, newMetadata) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      logger.info(`Updating metadata for file: ${filePath}`);
      const file = this.bucket.file(filePath);
      
      // Get current metadata
      const [currentMetadata] = await file.getMetadata();
      
      // Merge with new metadata
      const updatedMetadata = {
        ...currentMetadata.metadata,
        ...newMetadata
      };
      
      await file.setMetadata({
        metadata: updatedMetadata
      });
      
      logger.info(`Metadata updated successfully for: ${filePath}`);
    } catch (error) {
      logger.error(`Update metadata failed: ${error.message}`);
      throw error;
    }
  }

  async getBucketInfo() {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }
    try {
      const [metadata] = await this.bucket.getMetadata();
      return {
        name: metadata.name,
        location: metadata.location,
        storageClass: metadata.storageClass,
        created: metadata.timeCreated,
        updated: metadata.updated,
      };
    } catch (error) {
      logger.error(`Get bucket info failed: ${error.message}`);
      throw error;
    }
  }
}
module.exports = new GCSStorageService();