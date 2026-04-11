const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const {
  listSchools,
  listCampuses,
  listLocationGroups,
  listTradeLocations,
  getMyCampusProfile,
  updateMyCampusProfile,
  getMyVerification,
  submitVerification,
  listVerificationApplications,
  reviewVerification,
  upsertSchool,
  upsertCampus,
  upsertLocationGroup,
  upsertTradeLocation,
  updateTradeLocationStatus
} = require('../controllers/campus.controller');

const router = express.Router();

router.get('/schools', listSchools);
router.get('/campuses', listCampuses);
router.get('/location-groups', listLocationGroups);
router.get('/trade-locations', listTradeLocations);

router.get('/profile', authMiddleware, getMyCampusProfile);
router.put('/profile', authMiddleware, updateMyCampusProfile);
router.get('/verification', authMiddleware, getMyVerification);
router.post('/verification', authMiddleware, submitVerification);

router.get('/admin/verifications', authMiddleware, listVerificationApplications);
router.post('/admin/verifications/:id/review', authMiddleware, reviewVerification);
router.post('/admin/schools', authMiddleware, upsertSchool);
router.post('/admin/campuses', authMiddleware, upsertCampus);
router.post('/admin/location-groups', authMiddleware, upsertLocationGroup);
router.post('/admin/trade-locations', authMiddleware, upsertTradeLocation);
router.put('/admin/trade-locations/:id/status', authMiddleware, updateTradeLocationStatus);

module.exports = router;
