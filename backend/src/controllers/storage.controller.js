const gcsStorage = require('../services/gcs-storage.service');
const fs = require('fs-extra');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/storage-controller.log' })
  ]
});
const uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file provided' }
      });
    }
    if (!gcsStorage.isConfigured()) {
      return res.status(500).json({
        success: false,
        error: { message: 'Google Cloud Storage not configured' }
      });
    }
    const file = req.file;
    const userId = req.user?.userId || 'anonymous';
    const folder = req.body.folder || 'uploads';
    const fileName = gcsStorage.generateUniqueFilename(file.originalname, `${folder}/`);
    const downloadUrl = await gcsStorage.uploadFile(file.path, fileName, {
      contentType: file.mimetype,
      makePublic: req.body.makePublic === 'true',
      originalName: file.originalname,
      uploadedBy: userId,
      folder: folder
    });
    await fs.remove(file.path);
    logger.info(`File uploaded successfully: ${fileName}`, {
      userId,
      originalName: file.originalname,
      size: file.size
    });
    res.json({
      success: true,
      data: {
        fileName,
        originalName: file.originalname,
        size: file.size,
        contentType: file.mimetype,
        downloadUrl,
        uploadedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    logger.error('File upload failed:', error);
    if (req.file?.path) {
      try {
        await fs.remove(req.file.path);
      } catch (cleanupError) {
        logger.error('Failed to cleanup local file:', cleanupError);
      }
    }
    res.status(500).json({
      success: false,
      error: { message: 'File upload failed' }
    });
  }
};
const getDownloadUrl = async (req, res) => {
  try {
    const { fileName } = req.params;
    const { expires, public: isPublic } = req.query;
    if (!fileName) {
      return res.status(400).json({
        success: false,
        error: { message: 'File name is required' }
      });
    }
    const exists = await gcsStorage.fileExists(fileName);
    if (!exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'File not found' }
      });
    }
    const downloadUrl = await gcsStorage.getDownloadUrl(fileName, {
      expires: expires ? new Date(expires) : undefined,
      public: isPublic === 'true'
    });
    res.json({
      success: true,
      data: {
        fileName,
        downloadUrl,
        expiresAt: expires || null
      }
    });
  } catch (error) {
    logger.error('Get download URL failed:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get download URL' }
    });
  }
};
const deleteFile = async (req, res) => {
  try {
    const { fileName } = req.params;
    if (!fileName) {
      return res.status(400).json({
        success: false,
        error: { message: 'File name is required' }
      });
    }
    const exists = await gcsStorage.fileExists(fileName);
    if (!exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'File not found' }
      });
    }
    await gcsStorage.deleteFile(fileName);
    logger.info(`File deleted successfully: ${fileName}`, {
      userId: req.user?.userId || 'anonymous'
    });
    res.json({
      success: true,
      data: {
        fileName,
        deletedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    logger.error('File deletion failed:', error);
    res.status(500).json({
      success: false,
      error: { message: 'File deletion failed' }
    });
  }
};
const listFiles = async (req, res) => {
  try {
    const { folder = '' } = req.query;
    const { maxResults = 100 } = req.query;
    const files = await gcsStorage.listFiles(folder, {
      maxResults: parseInt(maxResults)
    });
    res.json({
      success: true,
      data: {
        files,
        folder,
        count: files.length
      }
    });
  } catch (error) {
    logger.error('List files failed:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to list files' }
    });
  }
};
const getStorageStatus = async (req, res) => {
  try {
    const config = gcsStorage.getConfigStatus();
    let bucketInfo = null;
    if (config.initialized) {
      try {
        bucketInfo = await gcsStorage.getBucketInfo();
      } catch (error) {
        logger.warn('Failed to get bucket info:', error.message);
      }
    }
    res.json({
      success: true,
      data: {
        status: config.initialized ? 'operational' : 'not_configured',
        configuration: config,
        bucket: bucketInfo,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    logger.error('Get storage status failed:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get storage status' }
    });
  }
};
module.exports = {
  uploadFile,
  getDownloadUrl,
  deleteFile,
  listFiles,
  getStorageStatus
};