const { Storage } = require('@google-cloud/storage');
const fs = require('fs-extra');
const path = require('path');
const winston = require('winston');

// Configure logger
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
    this.initializeGCS();
  }

  initializeGCS() {
    try {
      // Initialize Google Cloud Storage
      this.storage = new Storage({
        projectId: process.env.GOOGLE_CLOUD_PROJECT,
        keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
      });

      // Get bucket reference
      const bucketName = process.env.GCS_BUCKET || `${process.env.GOOGLE_CLOUD_PROJECT}-storage`;
      this.bucket = this.storage.bucket(bucketName);
      
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

  /**
   * Upload file to Google Cloud Storage
   * @param {string} filePath - Local file path
   * @param {string} destination - Storage destination path
   * @param {Object} metadata - File metadata
   * @returns {Promise<string>} Download URL
   */
  async uploadFile(filePath, destination, metadata = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }

    try {
      logger.info(`Uploading file to GCS: ${destination}`);

      const file = this.bucket.file(destination);
      
      // Upload file with metadata
      await file.save(await fs.readFile(filePath), {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });

      // Make file publicly accessible if requested
      if (metadata.makePublic) {
        await file.makePublic();
        return `https://storage.googleapis.com/${this.bucket.name}/${destination}`;
      }

      // Get signed URL for private access
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

  /**
   * Upload buffer to Google Cloud Storage
   * @param {Buffer} buffer - File buffer
   * @param {string} destination - Storage destination path
   * @param {Object} metadata - File metadata
   * @returns {Promise<string>} Download URL
   */
  async uploadBuffer(buffer, destination, metadata = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }

    try {
      logger.info(`Uploading buffer to GCS: ${destination}`);

      const file = this.bucket.file(destination);
      
      // Upload buffer with metadata
      await file.save(buffer, {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });

      // Make file publicly accessible if requested
      if (metadata.makePublic) {
        await file.makePublic();
        return `https://storage.googleapis.com/${this.bucket.name}/${destination}`;
      }

      // Get signed URL for private access
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

  /**
   * Delete file from Google Cloud Storage
   * @param {string} filePath - Storage file path
   * @returns {Promise<void>}
   */
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

  /**
   * Get file download URL
   * @param {string} filePath - Storage file path
   * @param {Object} options - URL options
   * @returns {Promise<string>} Download URL
   */
  async getDownloadUrl(filePath, options = {}) {
    if (!this.initialized) {
      throw new Error('Google Cloud Storage not initialized');
    }

    try {
      const file = this.bucket.file(filePath);
      
      // Check if file is public
      if (options.public) {
        return `https://storage.googleapis.com/${this.bucket.name}/${filePath}`;
      }

      // Get signed URL for private access
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

  /**
   * Check if file exists
   * @param {string} filePath - Storage file path
   * @returns {Promise<boolean>}
   */
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

  /**
   * List files in a directory
   * @param {string} prefix - Directory prefix
   * @param {Object} options - List options
   * @returns {Promise<Array>} List of files
   */
  async listFiles(prefix = '', options = {}) {
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

  /**
   * Generate unique filename
   * @param {string} originalName - Original filename
   * @param {string} prefix - Filename prefix
   * @returns {string} Unique filename
   */
  generateUniqueFilename(originalName, prefix = '') {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    const extension = path.extname(originalName);
    const baseName = path.basename(originalName, extension);
    
    return `${prefix}${timestamp}-${random}-${baseName}${extension}`;
  }

  /**
   * Get file metadata
   * @param {string} filePath - Storage file path
   * @returns {Promise<Object>} File metadata
   */
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

  /**
   * Create bucket if it doesn't exist
   * @param {string} bucketName - Bucket name
   * @param {Object} options - Bucket options
   * @returns {Promise<void>}
   */
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

  /**
   * Copy file within GCS
   * @param {string} sourcePath - Source file path
   * @param {string} destinationPath - Destination file path
   * @returns {Promise<void>}
   */
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

  /**
   * Move file within GCS
   * @param {string} sourcePath - Source file path
   * @param {string} destinationPath - Destination file path
   * @returns {Promise<void>}
   */
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

  /**
   * Check if Google Cloud Storage is configured
   * @returns {boolean}
   */
  isConfigured() {
    return this.initialized && 
           !!process.env.GOOGLE_CLOUD_PROJECT && 
           !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }

  /**
   * Get configuration status
   * @returns {Object}
   */
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

  /**
   * Get bucket info
   * @returns {Promise<Object>}
   */
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

// Export singleton instance
module.exports = new GCSStorageService();