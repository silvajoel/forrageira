-- Ajustes necessarios na estrutura existente do MariaDB (db: forrageira)
-- Rode uma unica vez. Seguro para reexecucao com checagem manual.

-- 1) Campos preenchidos pelo admin ao FINALIZAR a analise.
--    (ForageService.finalizeAnalysisRequest grava species_name/care_instructions/admin_notes/reviewed_at)
ALTER TABLE `analysis_requests`
  ADD COLUMN `species_name`      VARCHAR(150) DEFAULT NULL,
  ADD COLUMN `care_instructions` TEXT         DEFAULT NULL,
  ADD COLUMN `admin_notes`       TEXT         DEFAULT NULL,
  ADD COLUMN `reviewed_at`       DATETIME     DEFAULT NULL,
  ADD COLUMN `reviewed_by`       VARCHAR(100) DEFAULT NULL;

-- 2) Metadata do log de auditoria (AuditLogService.log grava um mapa -> JSON serializado).
ALTER TABLE `admin_audit_logs`
  ADD COLUMN `metadata` LONGTEXT DEFAULT NULL;
