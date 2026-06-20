/*
 Navicat Premium Dump SQL

 Source Server         : localhost_3306_1
 Source Server Type    : MySQL
 Source Server Version : 80045 (8.0.45)
 Source Host           : localhost:3306
 Source Schema         : aviation

 Target Server Type    : MySQL
 Target Server Version : 80045 (8.0.45)
 File Encoding         : 65001

 Date: 20/06/2026 18:10:38
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for aircraft
-- ----------------------------
DROP TABLE IF EXISTS `aircraft`;
CREATE TABLE `aircraft`  (
  `aircraft_id` int NOT NULL AUTO_INCREMENT,
  `registration` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `status` enum('ACTIVE','MAINTENANCE','RETIRED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'ACTIVE',
  `entry_date` date NOT NULL,
  PRIMARY KEY (`aircraft_id`) USING BTREE,
  UNIQUE INDEX `registration`(`registration` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for component
-- ----------------------------
DROP TABLE IF EXISTS `component`;
CREATE TABLE `component`  (
  `component_id` int NOT NULL AUTO_INCREMENT,
  `serial_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `model_id` int NOT NULL,
  `batch_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `production_date` date NULL DEFAULT NULL,
  `status` enum('IN_STOCK','INSTALLED','REMOVED','MAINTENANCE','RETIRED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'IN_STOCK',
  `total_flight_hours` decimal(10, 2) NOT NULL DEFAULT 0.00,
  `total_flight_cycles` int NOT NULL DEFAULT 0,
  `retired` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`component_id`) USING BTREE,
  UNIQUE INDEX `serial_number`(`serial_number` ASC) USING BTREE,
  INDEX `model_id`(`model_id` ASC) USING BTREE,
  CONSTRAINT `component_ibfk_1` FOREIGN KEY (`model_id`) REFERENCES `component_model` (`model_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for component_model
-- ----------------------------
DROP TABLE IF EXISTS `component_model`;
CREATE TABLE `component_model`  (
  `model_id` int NOT NULL AUTO_INCREMENT,
  `model_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `category` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `design_life_hours` int NOT NULL,
  `maintenance_interval_hours` int NULL DEFAULT NULL,
  `applicable_aircraft` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`model_id`) USING BTREE,
  UNIQUE INDEX `model_code`(`model_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for flight_log
-- ----------------------------
DROP TABLE IF EXISTS `flight_log`;
CREATE TABLE `flight_log`  (
  `flight_id` int NOT NULL AUTO_INCREMENT,
  `aircraft_id` int NOT NULL,
  `takeoff_time` datetime NOT NULL,
  `landing_time` datetime NOT NULL,
  `flight_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`flight_id`) USING BTREE,
  INDEX `idx_flight_aircraft_time`(`aircraft_id` ASC, `takeoff_time` ASC) USING BTREE,
  CONSTRAINT `flight_log_ibfk_1` FOREIGN KEY (`aircraft_id`) REFERENCES `aircraft` (`aircraft_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_flight_time` CHECK (`takeoff_time` < `landing_time`)
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for installation_record
-- ----------------------------
DROP TABLE IF EXISTS `installation_record`;
CREATE TABLE `installation_record`  (
  `install_id` int NOT NULL AUTO_INCREMENT,
  `component_id` int NOT NULL,
  `aircraft_id` int NOT NULL,
  `position` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `install_time` datetime NOT NULL,
  `remove_time` datetime NULL DEFAULT NULL,
  `install_reason` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `remove_reason` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `installed_by` int NULL DEFAULT NULL,
  PRIMARY KEY (`install_id`) USING BTREE,
  INDEX `aircraft_id`(`aircraft_id` ASC) USING BTREE,
  INDEX `installed_by`(`installed_by` ASC) USING BTREE,
  INDEX `idx_install_component`(`component_id` ASC, `install_time` ASC) USING BTREE,
  INDEX `idx_install_active`(`component_id` ASC, `remove_time` ASC) USING BTREE,
  CONSTRAINT `installation_record_ibfk_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `installation_record_ibfk_2` FOREIGN KEY (`aircraft_id`) REFERENCES `aircraft` (`aircraft_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `installation_record_ibfk_3` FOREIGN KEY (`installed_by`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_install_remove_time` CHECK ((`remove_time` is null) or (`install_time` < `remove_time`))
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for maintenance_record
-- ----------------------------
DROP TABLE IF EXISTS `maintenance_record`;
CREATE TABLE `maintenance_record`  (
  `maintenance_id` int NOT NULL AUTO_INCREMENT,
  `component_id` int NOT NULL,
  `maintenance_type` enum('PREVENTIVE','CORRECTIVE','OVERHAUL','INSPECTION') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NULL DEFAULT NULL,
  `result` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `technician_id` int NULL DEFAULT NULL,
  PRIMARY KEY (`maintenance_id`) USING BTREE,
  INDEX `component_id`(`component_id` ASC) USING BTREE,
  INDEX `technician_id`(`technician_id` ASC) USING BTREE,
  CONSTRAINT `maintenance_record_ibfk_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `maintenance_record_ibfk_2` FOREIGN KEY (`technician_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_maintenance_time` CHECK ((`end_time` is null) or (`start_time` < `end_time`))
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for operator
-- ----------------------------
DROP TABLE IF EXISTS `operator`;
CREATE TABLE `operator`  (
  `operator_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `role` enum('INSTALLER','TECHNICIAN','APPROVER','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `contact` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`operator_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for scrap_retirement_record
-- ----------------------------
DROP TABLE IF EXISTS `scrap_retirement_record`;
CREATE TABLE `scrap_retirement_record`  (
  `retirement_id` int NOT NULL AUTO_INCREMENT,
  `component_id` int NOT NULL,
  `retirement_time` datetime NOT NULL,
  `reason` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `approved_by` int NULL DEFAULT NULL,
  PRIMARY KEY (`retirement_id`) USING BTREE,
  UNIQUE INDEX `component_id`(`component_id` ASC) USING BTREE,
  INDEX `approved_by`(`approved_by` ASC) USING BTREE,
  CONSTRAINT `scrap_retirement_record_ibfk_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `scrap_retirement_record_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Procedure structure for AddComponent
-- ----------------------------
DROP PROCEDURE IF EXISTS `AddComponent`;
delimiter ;;
CREATE PROCEDURE `AddComponent`(IN p_serial_number VARCHAR(50),
    IN p_model_id INT,
    IN p_batch_no VARCHAR(50),
    IN p_production_date DATE,
    IN p_operator_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM component WHERE serial_number = p_serial_number) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件序列号已存在';
    END IF;
    INSERT INTO component (serial_number, model_id, batch_no, production_date, status)
    VALUES (p_serial_number, p_model_id, p_batch_no, p_production_date, 'IN_STOCK');
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for AddFlightLog
-- ----------------------------
DROP PROCEDURE IF EXISTS `AddFlightLog`;
delimiter ;;
CREATE PROCEDURE `AddFlightLog`(IN p_aircraft_id INT,
    IN p_takeoff DATETIME,
    IN p_landing DATETIME,
    IN p_type VARCHAR(30))
BEGIN
    DECLARE v_duration DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 起飞时间必须晚于所有当前安装部件的安装时间
    IF EXISTS (
        SELECT 1
        FROM installation_record
        WHERE aircraft_id = p_aircraft_id
          AND remove_time IS NULL
          AND install_time > p_takeoff
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '起飞时间早于部件安装时间';
    END IF;

    INSERT INTO flight_log (
        aircraft_id,
        takeoff_time,
        landing_time,
        flight_type
    )
    VALUES (
        p_aircraft_id,
        p_takeoff,
        p_landing,
        p_type
    );

    SET v_duration =
        TIMESTAMPDIFF(MINUTE,p_takeoff,p_landing)/60.0;

    UPDATE component c
    JOIN installation_record ir
        ON c.component_id = ir.component_id
    SET c.total_flight_hours =
            c.total_flight_hours + v_duration,
        c.total_flight_cycles =
            c.total_flight_cycles + 1
    WHERE ir.aircraft_id = p_aircraft_id
      AND ir.remove_time IS NULL
      AND ir.install_time <= p_takeoff;

    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for CompleteMaintenance
-- ----------------------------
DROP PROCEDURE IF EXISTS `CompleteMaintenance`;
delimiter ;;
CREATE PROCEDURE `CompleteMaintenance`(IN p_maintenance_id INT,
    IN p_end_time DATETIME,
    IN p_result VARCHAR(200))
BEGIN
    DECLARE v_component_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT component_id INTO v_component_id FROM maintenance_record
    WHERE maintenance_id = p_maintenance_id AND end_time IS NULL;
    IF v_component_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '维修工单不存在或已关闭';
    END IF;
    UPDATE maintenance_record SET end_time = p_end_time, result = p_result
    WHERE maintenance_id = p_maintenance_id;
    UPDATE component SET status = 'IN_STOCK' WHERE component_id = v_component_id AND status = 'MAINTENANCE';
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for CreateMaintenanceRecord
-- ----------------------------
DROP PROCEDURE IF EXISTS `CreateMaintenanceRecord`;
delimiter ;;
CREATE PROCEDURE `CreateMaintenanceRecord`(IN p_component_id INT,
    IN p_type VARCHAR(30),
    IN p_start_time DATETIME,
    IN p_technician_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF (SELECT retired FROM component WHERE component_id = p_component_id) = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '退役部件不能维修';
    END IF;
    INSERT INTO maintenance_record (component_id, maintenance_type, start_time, technician_id)
    VALUES (p_component_id, p_type, p_start_time, p_technician_id);
    UPDATE component SET status = 'MAINTENANCE' WHERE component_id = p_component_id;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for GetComponentLifecycle
-- ----------------------------
DROP PROCEDURE IF EXISTS `GetComponentLifecycle`;
delimiter ;;
CREATE PROCEDURE `GetComponentLifecycle`(IN p_serial VARCHAR(50))
BEGIN
    SELECT 
        c.serial_number, c.status, cm.model_code, c.total_flight_hours,
        c.total_flight_cycles, c.created_at AS in_stock_time,
        ir.install_time, ir.remove_time, a.registration AS aircraft,
        ir.position, mr.maintenance_id, mr.maintenance_type,
        mr.start_time AS maint_start, mr.end_time AS maint_end, mr.result,
        sr.retirement_time, sr.reason AS retire_reason
    FROM component c
    LEFT JOIN component_model cm ON c.model_id = cm.model_id
    LEFT JOIN installation_record ir ON c.component_id = ir.component_id
    LEFT JOIN aircraft a ON ir.aircraft_id = a.aircraft_id
    LEFT JOIN maintenance_record mr ON c.component_id = mr.component_id
    LEFT JOIN scrap_retirement_record sr ON c.component_id = sr.component_id
    WHERE c.serial_number = p_serial
    ORDER BY ir.install_time, mr.start_time;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for InstallComponent
-- ----------------------------
DROP PROCEDURE IF EXISTS `InstallComponent`;
delimiter ;;
CREATE PROCEDURE `InstallComponent`(IN p_component_id INT,
    IN p_aircraft_id INT,
    IN p_position VARCHAR(50),
    IN p_install_time DATETIME,
    IN p_install_reason VARCHAR(100),
    IN p_operator_id INT)
BEGIN
    DECLARE v_retired TINYINT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_created_at DATETIME;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;

    SELECT retired, status, created_at INTO v_retired, v_status, v_created_at
    FROM component WHERE component_id = p_component_id;

    IF p_install_time < v_created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '安装时间不能早于部件入库时间';
    END IF;
    IF v_retired = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件已退役，无法安装';
    END IF;
    IF v_status NOT IN ('IN_STOCK', 'REMOVED') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件当前状态不允许安装';
    END IF;
    IF (SELECT status FROM aircraft WHERE aircraft_id = p_aircraft_id) <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '飞机状态不可用';
    END IF;

    IF EXISTS (
        SELECT 1 FROM installation_record
        WHERE component_id = p_component_id
          AND install_time < p_install_time
          AND (remove_time IS NULL OR remove_time > p_install_time)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '该部件在此时段已有安装记录，区间不能重叠';
    END IF;

    INSERT INTO installation_record
        (component_id, aircraft_id, position, install_time, install_reason, installed_by)
    VALUES (p_component_id, p_aircraft_id, p_position, p_install_time, p_install_reason, p_operator_id);

    UPDATE component SET status = 'INSTALLED' WHERE component_id = p_component_id;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for RemoveComponent
-- ----------------------------
DROP PROCEDURE IF EXISTS `RemoveComponent`;
delimiter ;;
CREATE PROCEDURE `RemoveComponent`(IN p_install_id INT,
    IN p_remove_time DATETIME,
    IN p_remove_reason VARCHAR(100),
    IN p_operator_id INT)
BEGIN
    DECLARE v_component_id INT;
    DECLARE v_install_time DATETIME;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;

    SELECT component_id, install_time INTO v_component_id, v_install_time
    FROM installation_record
    WHERE install_id = p_install_id AND remove_time IS NULL;

    IF v_component_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '该安装记录不存在或已拆卸';
    END IF;
    IF p_remove_time <= v_install_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '拆卸时间必须晚于安装时间';
    END IF;

    -- 检查与其他记录是否重叠
    IF EXISTS (
        SELECT 1 FROM installation_record
        WHERE component_id = v_component_id
          AND install_id <> p_install_id
          AND install_time < p_remove_time
          AND (remove_time IS NULL OR remove_time > v_install_time)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '拆卸后区间与已有安装记录重叠';
    END IF;

    UPDATE installation_record
    SET remove_time = p_remove_time, remove_reason = p_remove_reason
    WHERE install_id = p_install_id;

    UPDATE component SET status = 'REMOVED' WHERE component_id = v_component_id;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for ReplaceComponent
-- ----------------------------
DROP PROCEDURE IF EXISTS `ReplaceComponent`;
delimiter ;;
CREATE PROCEDURE `ReplaceComponent`(IN p_old_install_id INT,
    IN p_new_component_id INT,
    IN p_aircraft_id INT,
    IN p_position VARCHAR(50),
    IN p_install_time DATETIME,
    IN p_install_reason VARCHAR(100),
    IN p_remove_reason VARCHAR(100),
    IN p_operator_id INT)
BEGIN
    DECLARE v_old_component_id INT;
    DECLARE v_old_install_time DATETIME;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;

    SELECT component_id, install_time INTO v_old_component_id, v_old_install_time
    FROM installation_record
    WHERE install_id = p_old_install_id AND remove_time IS NULL;
    IF v_old_component_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '旧安装记录不存在或已拆卸';
    END IF;
    IF p_install_time <= v_old_install_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '更换时间必须晚于旧件安装时间';
    END IF;

    -- 检查旧记录新区间是否与其他记录重叠
    IF EXISTS (
        SELECT 1 FROM installation_record
        WHERE component_id = v_old_component_id
          AND install_id <> p_old_install_id
          AND install_time < p_install_time
          AND (remove_time IS NULL OR remove_time > v_old_install_time)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '拆卸后旧部件区间与已有记录重叠';
    END IF;

    UPDATE installation_record
    SET remove_time = p_install_time, remove_reason = p_remove_reason
    WHERE install_id = p_old_install_id;

    SELECT status, retired INTO @s, @r FROM component WHERE component_id = p_new_component_id;
    IF @r = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '新部件已退役';
    END IF;
    IF @s NOT IN ('IN_STOCK', 'REMOVED') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '新部件状态不可安装';
    END IF;
    IF (SELECT status FROM aircraft WHERE aircraft_id = p_aircraft_id) <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '飞机状态不可用';
    END IF;

    IF EXISTS (
        SELECT 1 FROM installation_record
        WHERE component_id = p_new_component_id
          AND install_time < p_install_time
          AND (remove_time IS NULL OR remove_time > p_install_time)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '新部件安装区间与已有记录重叠';
    END IF;

    INSERT INTO installation_record
        (component_id, aircraft_id, position, install_time, install_reason, installed_by)
    VALUES (p_new_component_id, p_aircraft_id, p_position, p_install_time, p_install_reason, p_operator_id);

    UPDATE component SET status = 'INSTALLED' WHERE component_id = p_new_component_id;
    UPDATE component SET status = 'REMOVED' WHERE component_id = v_old_component_id;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for RetireComponent
-- ----------------------------
DROP PROCEDURE IF EXISTS `RetireComponent`;
delimiter ;;
CREATE PROCEDURE `RetireComponent`(IN p_component_id INT,
    IN p_retire_time DATETIME,
    IN p_reason VARCHAR(200),
    IN p_approved_by INT)
BEGIN
    DECLARE v_latest_time DATETIME;
    DECLARE v_msg VARCHAR(200);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;

    IF (SELECT retired FROM component WHERE component_id = p_component_id) = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件已经退役';
    END IF;
    IF EXISTS (
        SELECT 1 FROM installation_record WHERE component_id = p_component_id AND remove_time IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件仍安装在飞机上，请先拆卸再退役';
    END IF;

    SELECT MAX(COALESCE(remove_time, install_time)) INTO v_latest_time
    FROM installation_record WHERE component_id = p_component_id;

    IF v_latest_time IS NOT NULL AND p_retire_time <= v_latest_time THEN
        SET v_msg = CONCAT('退役时间必须晚于最后活动时间（', v_latest_time, '）');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    INSERT INTO scrap_retirement_record (component_id, retirement_time, reason, approved_by)
    VALUES (p_component_id, p_retire_time, p_reason, p_approved_by);

    UPDATE component SET status = 'RETIRED', retired = 1 WHERE component_id = p_component_id;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table component
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_prevent_delete_component`;
delimiter ;;
CREATE TRIGGER `trg_prevent_delete_component` BEFORE DELETE ON `component` FOR EACH ROW BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '不允许物理删除部件，请使用退役操作';
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table flight_log
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_flight_check_install_time`;
delimiter ;;
CREATE TRIGGER `trg_flight_check_install_time` BEFORE INSERT ON `flight_log` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1
        FROM installation_record
        WHERE aircraft_id = NEW.aircraft_id
          AND remove_time IS NULL
          AND install_time > NEW.takeoff_time
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '起飞时间不能早于部件安装时间';
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_check_retired`;
delimiter ;;
CREATE TRIGGER `trg_install_check_retired` BEFORE INSERT ON `installation_record` FOR EACH ROW BEGIN
    IF (SELECT retired FROM component WHERE component_id = NEW.component_id) = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件已退役，无法安装';
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_check_created_at`;
delimiter ;;
CREATE TRIGGER `trg_install_check_created_at` BEFORE INSERT ON `installation_record` FOR EACH ROW BEGIN
    DECLARE v_created_at DATETIME;
    SELECT created_at INTO v_created_at FROM component WHERE component_id = NEW.component_id;
    IF NEW.install_time < v_created_at THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '安装时间不能早于部件入库时间';
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_unique_insert`;
delimiter ;;
CREATE TRIGGER `trg_install_unique_insert` BEFORE INSERT ON `installation_record` FOR EACH ROW BEGIN
    IF NEW.remove_time IS NULL THEN
        IF EXISTS (SELECT 1 FROM installation_record WHERE component_id = NEW.component_id AND remove_time IS NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '该部件当前已有有效安装记录';
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_no_overlap`;
delimiter ;;
CREATE TRIGGER `trg_install_no_overlap` BEFORE INSERT ON `installation_record` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1 FROM installation_record
        WHERE component_id = NEW.component_id
          AND install_time < NEW.install_time
          AND (remove_time IS NULL OR remove_time > NEW.install_time)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '安装区间与已有记录重叠';
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_check_aircraft_model`;
delimiter ;;
CREATE TRIGGER `trg_install_check_aircraft_model` BEFORE INSERT ON `installation_record` FOR EACH ROW BEGIN

    DECLARE v_aircraft_model VARCHAR(50);
    DECLARE v_applicable VARCHAR(200);

    SELECT model
    INTO v_aircraft_model
    FROM aircraft
    WHERE aircraft_id = NEW.aircraft_id;

    SELECT cm.applicable_aircraft
    INTO v_applicable
    FROM component c
    JOIN component_model cm
         ON c.model_id = cm.model_id
    WHERE c.component_id = NEW.component_id;

    SET v_applicable = REPLACE(v_applicable,'，',',');
    SET v_applicable = REPLACE(v_applicable,' ','');

    IF FIND_IN_SET(v_aircraft_model,v_applicable)=0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='该部件型号不适用于当前飞机型号';
    END IF;

END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_unique_update`;
delimiter ;;
CREATE TRIGGER `trg_install_unique_update` BEFORE UPDATE ON `installation_record` FOR EACH ROW BEGIN
    IF NEW.remove_time IS NULL AND OLD.remove_time IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM installation_record WHERE component_id = NEW.component_id AND remove_time IS NULL AND install_id <> NEW.install_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '更新后会导致同一部件存在多个有效安装';
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_prevent_delete_install`;
delimiter ;;
CREATE TRIGGER `trg_prevent_delete_install` BEFORE DELETE ON `installation_record` FOR EACH ROW BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '禁止物理删除安装记录，历史不可覆盖';
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_install_sync_status`;
delimiter ;;
CREATE TRIGGER `trg_install_sync_status` AFTER INSERT ON `installation_record` FOR EACH ROW BEGIN
    UPDATE component
    SET status = 'INSTALLED'
    WHERE component_id = NEW.component_id;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table installation_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_remove_sync_status`;
delimiter ;;
CREATE TRIGGER `trg_remove_sync_status` AFTER UPDATE ON `installation_record` FOR EACH ROW BEGIN
    IF OLD.remove_time IS NULL AND NEW.remove_time IS NOT NULL THEN
        UPDATE component
        SET status = 'REMOVED'
        WHERE component_id = NEW.component_id;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table maintenance_record
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_maintenance_check_retired`;
delimiter ;;
CREATE TRIGGER `trg_maintenance_check_retired` BEFORE INSERT ON `maintenance_record` FOR EACH ROW BEGIN
    IF (SELECT retired FROM component WHERE component_id = NEW.component_id) = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '部件已退役，无法创建维修记录';
    END IF;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
