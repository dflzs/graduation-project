const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { success, fail } = require('../utils/response');

const uploadDir = process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads');
const imageExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif']);

function ensureUploadDir() {
  fs.mkdirSync(uploadDir, { recursive: true });
}

function buildFilename(file) {
  const originalName = String(file.originalname || '').trim();
  const originalExtension = path.extname(originalName).toLowerCase();
  const safeExtension = imageExtensions.has(originalExtension) ? originalExtension : '.jpg';
  return `product_${Date.now()}_${Math.random().toString(36).slice(2, 8)}${safeExtension}`;
}

function buildPublicUrl(req, relativePath) {
  const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'http';
  const host = req.get('host') || '49.232.30.147';
  return `${protocol}://${host}${relativePath}`;
}

const storage = multer.diskStorage({
  destination(_req, _file, callback) {
    ensureUploadDir();
    callback(null, uploadDir);
  },
  filename(_req, file, callback) {
    callback(null, buildFilename(file));
  }
});

function fileFilter(_req, file, callback) {
  const extension = path.extname(String(file.originalname || '')).toLowerCase();
  const mimeType = String(file.mimetype || '').toLowerCase();
  const looksLikeImage = mimeType.startsWith('image/');
  if (imageExtensions.has(extension) || looksLikeImage) {
    callback(null, true);
    return;
  }
  callback(new Error('Only jpg, jpeg, png, webp, and gif images are supported'));
}

const uploadMiddleware = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024
  },
  fileFilter
}).single('file');

function uploadProductImage(req, res) {
  if (!req.file) {
    return res.status(400).json(fail('Please choose an image to upload'));
  }

  const relativePath = `/uploads/${req.file.filename}`;
  return res.json(success({
    path: relativePath,
    url: buildPublicUrl(req, relativePath)
  }, 'Image uploaded successfully'));
}

function handleUploadError(error, _req, res, _next) {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json(fail('Image size must be 5MB or smaller'));
    }
    return res.status(400).json(fail(`Upload failed: ${error.message}`));
  }

  return res.status(400).json(fail(error.message || 'Image upload failed'));
}

module.exports = {
  uploadMiddleware,
  uploadProductImage,
  handleUploadError
};
