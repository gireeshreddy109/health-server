CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE specialties (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'doctor', 'admin')),
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE TABLE doctor_profiles (
  id SERIAL PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  specialty_id INTEGER REFERENCES specialties(id),
  bio TEXT,
  license_number VARCHAR(50) UNIQUE,
  years_experience INTEGER DEFAULT 0,
  consultation_fee DECIMAL(10, 2),
  languages_spoken TEXT[],
  education TEXT[],
  rating DECIMAL(3, 2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  slot_duration_mins INTEGER DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_doctor_profiles_specialty ON doctor_profiles(specialty_id);

CREATE TABLE doctor_availability_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  is_booked BOOLEAN DEFAULT false,
  is_blocked BOOLEAN DEFAULT false,
  CONSTRAINT valid_slot_time CHECK (end_time > start_time),
  CONSTRAINT no_overlapping_slots EXCLUDE USING gist (
    doctor_id WITH =,
    tstzrange(start_time, end_time) WITH &&
  )
);

CREATE INDEX idx_slots_doctor_time ON doctor_availability_slots(doctor_id, start_time);
CREATE INDEX idx_slots_available ON doctor_availability_slots(doctor_id) WHERE is_booked = false;

CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES users(id),
  doctor_id UUID NOT NULL REFERENCES users(id),
  slot_id UUID UNIQUE REFERENCES doctor_availability_slots(id),
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
  appointment_type VARCHAR(20) DEFAULT 'in-person'
    CHECK (appointment_type IN ('in-person', 'video', 'phone')),
  reason TEXT,
  notes TEXT,
  prescription JSONB,
  reminder_24h_sent BOOLEAN DEFAULT false,
  reminder_1h_sent BOOLEAN DEFAULT false,
  booked_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_reminder ON appointments(booked_at)
  WHERE reminder_24h_sent = false OR reminder_1h_sent = false;

CREATE TABLE medical_histories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  timeline JSONB DEFAULT '[]'::jsonb,
  blood_type VARCHAR(5),
  height_cm DECIMAL(5, 2),
  weight_kg DECIMAL(5, 2),
  allergies TEXT[] DEFAULT '{}'::TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_medical_history_timeline ON medical_histories USING gin(timeline);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID UNIQUE NOT NULL REFERENCES appointments(id),
  patient_id UUID NOT NULL REFERENCES users(id),
  doctor_id UUID NOT NULL REFERENCES users(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO specialties (name, description) VALUES
  ('General Medicine', 'Primary care and common illnesses'),
  ('Cardiology', 'Heart and cardiovascular system'),
  ('Dermatology', 'Skin, hair, and nail conditions'),
  ('Orthopedics', 'Bones, joints, and muscles'),
  ('Pediatrics', 'Medical care for children'),
  ('Neurology', 'Brain and nervous system'),
  ('Psychiatry', 'Mental health and behavioral disorders');
