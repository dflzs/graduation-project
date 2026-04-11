ALTER TABLE users
  ADD COLUMN IF NOT EXISTS school_id VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS campus_id VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS student_no VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS grade_year INT NULL,
  ADD COLUMN IF NOT EXISTS college_name VARCHAR(128) NULL,
  ADD COLUMN IF NOT EXISTS major_name VARCHAR(128) NULL,
  ADD COLUMN IF NOT EXISTS verification_status VARCHAR(32) NOT NULL DEFAULT 'UNVERIFIED',
  ADD COLUMN IF NOT EXISTS verification_method VARCHAR(64) NULL,
  ADD COLUMN IF NOT EXISTS verified_at DATETIME NULL,
  ADD COLUMN IF NOT EXISTS verification_rejected_reason VARCHAR(255) NULL,
  ADD COLUMN IF NOT EXISTS verification_updated_at DATETIME NULL,
  ADD COLUMN IF NOT EXISTS completed_order_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS report_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_active_at DATETIME NULL;

CREATE TABLE IF NOT EXISTS schools (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  short_name VARCHAR(64) NULL,
  province_name VARCHAR(64) NULL,
  city_name VARCHAR(64) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS campuses (
  id VARCHAR(64) PRIMARY KEY,
  school_id VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  short_name VARCHAR(64) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_campuses_school_id FOREIGN KEY (school_id) REFERENCES schools(id)
);

CREATE TABLE IF NOT EXISTS location_groups (
  id VARCHAR(64) PRIMARY KEY,
  school_id VARCHAR(64) NOT NULL,
  campus_id VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  description VARCHAR(255) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_location_groups_school_id FOREIGN KEY (school_id) REFERENCES schools(id),
  CONSTRAINT fk_location_groups_campus_id FOREIGN KEY (campus_id) REFERENCES campuses(id)
);

CREATE TABLE IF NOT EXISTS trade_locations (
  id VARCHAR(64) PRIMARY KEY,
  school_id VARCHAR(64) NOT NULL,
  campus_id VARCHAR(64) NOT NULL,
  group_id VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  alias VARCHAR(128) NULL,
  description VARCHAR(255) NULL,
  safety_tips VARCHAR(255) NULL,
  recommended_categories JSON NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_hot TINYINT(1) NOT NULL DEFAULT 0,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_trade_locations_school_id FOREIGN KEY (school_id) REFERENCES schools(id),
  CONSTRAINT fk_trade_locations_campus_id FOREIGN KEY (campus_id) REFERENCES campuses(id),
  CONSTRAINT fk_trade_locations_group_id FOREIGN KEY (group_id) REFERENCES location_groups(id)
);

CREATE TABLE IF NOT EXISTS student_verifications (
  id VARCHAR(64) PRIMARY KEY,
  user_id BIGINT NOT NULL,
  school_id VARCHAR(64) NOT NULL,
  campus_id VARCHAR(64) NOT NULL,
  student_no VARCHAR(64) NOT NULL,
  grade_year INT NULL,
  college_name VARCHAR(128) NULL,
  major_name VARCHAR(128) NULL,
  verification_method VARCHAR(64) NOT NULL,
  material_urls JSON NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING_REVIEW',
  review_comment VARCHAR(255) NULL,
  reject_reason VARCHAR(255) NULL,
  reviewed_by BIGINT NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_student_verifications_user_id FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_student_verifications_school_id FOREIGN KEY (school_id) REFERENCES schools(id),
  CONSTRAINT fk_student_verifications_campus_id FOREIGN KEY (campus_id) REFERENCES campuses(id)
);

CREATE INDEX idx_users_school_campus ON users (school_id, campus_id);
CREATE INDEX idx_campuses_school_id ON campuses (school_id, is_enabled, display_order);
CREATE INDEX idx_location_groups_campus_id ON location_groups (campus_id, is_enabled, display_order);
CREATE INDEX idx_trade_locations_campus_id ON trade_locations (campus_id, group_id, is_enabled, sort_order);
CREATE INDEX idx_student_verifications_user_id ON student_verifications (user_id, created_at);
CREATE INDEX idx_student_verifications_status ON student_verifications (status, created_at);

INSERT INTO schools (id, name, short_name, province_name, city_name, display_order, is_enabled)
VALUES ('school_hnrlkjxy', '湖南人文科技学院', '湖人文', '湖南省', '娄底市', 1, 1)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  short_name = VALUES(short_name),
  province_name = VALUES(province_name),
  city_name = VALUES(city_name),
  display_order = VALUES(display_order),
  is_enabled = VALUES(is_enabled);

INSERT INTO campuses (id, school_id, name, short_name, display_order, is_enabled)
VALUES ('campus_main', 'school_hnrlkjxy', '主校区', '主校区', 1, 1)
ON DUPLICATE KEY UPDATE
  school_id = VALUES(school_id),
  name = VALUES(name),
  short_name = VALUES(short_name),
  display_order = VALUES(display_order),
  is_enabled = VALUES(is_enabled);

INSERT INTO location_groups (id, school_id, campus_id, name, description, display_order, is_enabled)
VALUES
  ('group_library', 'school_hnrlkjxy', 'campus_main', '教学区', '适合教材、资料、学习用品的当面交易', 1, 1),
  ('group_life', 'school_hnrlkjxy', 'campus_main', '生活区', '适合宿舍用品和日用百货的近距离交易', 2, 1),
  ('group_express', 'school_hnrlkjxy', 'campus_main', '快递点', '适合数码设备和大件物品的安全交接', 3, 1)
ON DUPLICATE KEY UPDATE
  school_id = VALUES(school_id),
  campus_id = VALUES(campus_id),
  name = VALUES(name),
  description = VALUES(description),
  display_order = VALUES(display_order),
  is_enabled = VALUES(is_enabled);

INSERT INTO trade_locations (
  id, school_id, campus_id, group_id, name, alias, description, safety_tips,
  recommended_categories, sort_order, is_hot, is_enabled
)
VALUES
  (
    'location_library_hall',
    'school_hnrlkjxy',
    'campus_main',
    'group_library',
    '图书馆大厅',
    '图书馆大厅',
    '适合教材、书籍、资料类商品现场确认后快速交接',
    '建议白天交易，优先在监控覆盖区域完成验货。',
    JSON_ARRAY('教材书籍', '电子数码'),
    1,
    1,
    1
  ),
  (
    'location_first_canteen_gate',
    'school_hnrlkjxy',
    'campus_main',
    'group_life',
    '一食堂门口',
    '一食堂门口',
    '适合宿舍用品、生活百货等小件商品面交',
    '建议避开就餐高峰，确认商品完整后再结束交易。',
    JSON_ARRAY('日用百货', '宿舍闲置'),
    2,
    1,
    1
  ),
  (
    'location_north_express',
    'school_hnrlkjxy',
    'campus_main',
    'group_express',
    '北门快递点',
    '北门快递点',
    '适合大件、数码设备和毕业季集中转让场景',
    '建议双方现场开箱验货，贵重物品保留聊天确认记录。',
    JSON_ARRAY('电子数码', '毕业转卖'),
    3,
    0,
    1
  )
ON DUPLICATE KEY UPDATE
  school_id = VALUES(school_id),
  campus_id = VALUES(campus_id),
  group_id = VALUES(group_id),
  name = VALUES(name),
  alias = VALUES(alias),
  description = VALUES(description),
  safety_tips = VALUES(safety_tips),
  recommended_categories = VALUES(recommended_categories),
  sort_order = VALUES(sort_order),
  is_hot = VALUES(is_hot),
  is_enabled = VALUES(is_enabled);
