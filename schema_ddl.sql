PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS diseases (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REMISSION', 'CURED')),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_diseases_status ON diseases(status);

CREATE TABLE IF NOT EXISTS consultations (
    id TEXT PRIMARY KEY,
    consultation_date INTEGER NOT NULL,
    doctor_name TEXT,
    specialty TEXT,
    facility TEXT,
    motive TEXT,
    diagnosis TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_consultations_date ON consultations(consultation_date DESC);
CREATE INDEX IF NOT EXISTS idx_consultations_doctor ON consultations(doctor_name);

CREATE TABLE IF NOT EXISTS consultation_diseases (
    consultation_id TEXT NOT NULL,
    disease_id TEXT NOT NULL,
    PRIMARY KEY (consultation_id, disease_id),
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_assoc_disease ON consultation_diseases(disease_id);

CREATE TABLE IF NOT EXISTS prescriptions (
    id TEXT PRIMARY KEY,
    consultation_id TEXT,
    prescription_date INTEGER NOT NULL,
    notes TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_prescriptions_consultation ON prescriptions(consultation_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_date ON prescriptions(prescription_date DESC);

CREATE TABLE IF NOT EXISTS attachments (
    id TEXT PRIMARY KEY,
    prescription_id TEXT,
    consultation_id TEXT,
    file_path TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('PRESCRIPTION_PHOTO', 'LAB_RESULT', 'RADIOLOGY', 'OTHER')),
    created_at INTEGER NOT NULL,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_attachments_prescription ON attachments(prescription_id);
CREATE INDEX IF NOT EXISTS idx_attachments_consultation ON attachments(consultation_id);

CREATE TABLE IF NOT EXISTS medications (
    id TEXT PRIMARY KEY,
    prescription_id TEXT NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ONGOING' CHECK (status IN ('ONGOING', 'COMPLETED', 'STOPPED')),
    start_date INTEGER NOT NULL,
    end_date INTEGER,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_medications_prescription ON medications(prescription_id);
CREATE INDEX IF NOT EXISTS idx_medications_status ON medications(status);
CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(name);

CREATE VIRTUAL TABLE IF NOT EXISTS medical_fts USING fts5(
    entity_id UNINDEXED,
    entity_type UNINDEXED,
    content_text
);
