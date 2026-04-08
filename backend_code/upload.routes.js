const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const {
  uploadMiddleware,
  uploadProductImage,
  handleUploadError
} = require('../controllers/upload.controller');

const router = express.Router();

router.post('/image', authMiddleware, (req, res, next) => {
  uploadMiddleware(req, res, (error) => {
    if (error) {
      return handleUploadError(error, req, res, next);
    }
    return uploadProductImage(req, res, next);
  });
});

module.exports = router;
