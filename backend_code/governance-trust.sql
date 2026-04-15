ALTER TABLE users
  MODIFY COLUMN status VARCHAR(32) NOT NULL DEFAULT 'active';

CREATE TABLE IF NOT EXISTS moderation_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  reporter_id BIGINT NOT NULL,
  target_type VARCHAR(32) NOT NULL,
  target_id BIGINT NOT NULL,
  reported_user_id BIGINT NULL,
  related_order_id BIGINT NULL,
  related_product_id BIGINT NULL,
  related_thread_id BIGINT NULL,
  category VARCHAR(64) NULL,
  reason VARCHAR(128) NOT NULL,
  description TEXT NOT NULL,
  evidence_items JSON NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  priority VARCHAR(16) NOT NULL DEFAULT 'medium',
  assigned_admin_id BIGINT NULL,
  admin_comment TEXT NULL,
  resolution_code VARCHAR(64) NULL,
  governance_action_id BIGINT NULL,
  reviewed_by BIGINT NULL,
  reviewed_at DATETIME NULL,
  closed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_moderation_records_reporter_id FOREIGN KEY (reporter_id) REFERENCES users(id),
  CONSTRAINT fk_moderation_records_reported_user_id FOREIGN KEY (reported_user_id) REFERENCES users(id),
  CONSTRAINT fk_moderation_records_assigned_admin_id FOREIGN KEY (assigned_admin_id) REFERENCES users(id),
  CONSTRAINT fk_moderation_records_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS appeals (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  moderation_record_id BIGINT NOT NULL,
  appellant_id BIGINT NOT NULL,
  reason VARCHAR(128) NOT NULL,
  description TEXT NOT NULL,
  evidence_items JSON NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  reviewed_by BIGINT NULL,
  review_comment TEXT NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_appeals_moderation_record_id FOREIGN KEY (moderation_record_id) REFERENCES moderation_records(id),
  CONSTRAINT fk_appeals_appellant_id FOREIGN KEY (appellant_id) REFERENCES users(id),
  CONSTRAINT fk_appeals_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS governance_actions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  source_type VARCHAR(32) NOT NULL,
  source_id VARCHAR(64) NOT NULL,
  action_type VARCHAR(32) NOT NULL,
  reason VARCHAR(128) NOT NULL,
  comment TEXT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  canceled_at DATETIME NULL,
  canceled_by BIGINT NULL,
  CONSTRAINT fk_governance_actions_user_id FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_governance_actions_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_governance_actions_canceled_by FOREIGN KEY (canceled_by) REFERENCES users(id)
);

CREATE INDEX idx_moderation_records_reporter ON moderation_records (reporter_id, created_at);
CREATE INDEX idx_moderation_records_target ON moderation_records (target_type, target_id, created_at);
CREATE INDEX idx_moderation_records_reported_user_status ON moderation_records (reported_user_id, status, created_at);
CREATE INDEX idx_moderation_records_status_priority ON moderation_records (status, priority, created_at);

CREATE INDEX idx_appeals_appellant ON appeals (appellant_id, created_at);
CREATE INDEX idx_appeals_record_status ON appeals (moderation_record_id, status, created_at);

CREATE INDEX idx_governance_actions_user_active ON governance_actions (user_id, active, created_at);
CREATE INDEX idx_governance_actions_source ON governance_actions (source_type, source_id, created_at);
CREATE INDEX idx_governance_actions_action_type ON governance_actions (action_type, active, created_at);
