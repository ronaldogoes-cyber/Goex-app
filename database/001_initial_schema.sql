-- GOEX APP - Initial Database Schema
-- Production-ready PostgreSQL schema for Electrical Engineering ERP
-- Supabase compatible

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- CLIENTS TABLE
-- ============================================================================
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100),
  document_number VARCHAR(50) UNIQUE,
  document_type VARCHAR(50), -- CPF, CNPJ, etc
  company_name VARCHAR(255),
  contact_person VARCHAR(255),
  notes TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_document ON clients(document_number);
CREATE INDEX idx_clients_active ON clients(active);

-- ============================================================================
-- LEADS TABLE
-- ============================================================================
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'new', -- new, qualified, contacted, proposal_sent, won, lost
  source VARCHAR(100), -- website, referral, social_media, email, phone, etc
  budget_estimate DECIMAL(15,2),
  priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high, urgent
  assigned_to UUID, -- Will reference professionals table
  expected_close_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_leads_client ON leads(client_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_assigned ON leads(assigned_to);

-- ============================================================================
-- BUDGET ORDERS TABLE
-- ============================================================================
CREATE TABLE budget_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, in_progress, completed, cancelled
  total_value DECIMAL(15,2),
  description TEXT,
  start_date DATE,
  estimated_end_date DATE,
  actual_end_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budget_orders_client ON budget_orders(client_id);
CREATE INDEX idx_budget_orders_status ON budget_orders(status);
CREATE INDEX idx_budget_orders_number ON budget_orders(order_number);

-- ============================================================================
-- SITE VISITS TABLE
-- ============================================================================
CREATE TABLE site_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_order_id UUID REFERENCES budget_orders(id) ON DELETE CASCADE,
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  visit_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER,
  location TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  observations TEXT,
  findings TEXT,
  next_steps TEXT,
  visited_by UUID, -- Will reference professionals table
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, rescheduled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_site_visits_budget_order ON site_visits(budget_order_id);
CREATE INDEX idx_site_visits_date ON site_visits(visit_date);
CREATE INDEX idx_site_visits_status ON site_visits(status);

-- ============================================================================
-- BUDGETS TABLE
-- ============================================================================
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_number VARCHAR(50) UNIQUE NOT NULL,
  budget_order_id UUID NOT NULL REFERENCES budget_orders(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'draft', -- draft, sent, approved, rejected, expired
  total_value DECIMAL(15,2) NOT NULL,
  discount_percent DECIMAL(5,2) DEFAULT 0,
  discount_value DECIMAL(15,2),
  final_value DECIMAL(15,2),
  validity_days INTEGER DEFAULT 30,
  issued_date DATE NOT NULL,
  valid_until DATE,
  approved_date DATE,
  approved_by UUID, -- Will reference professionals table
  notes TEXT,
  terms_conditions TEXT,
  payment_terms VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budgets_number ON budgets(budget_number);
CREATE INDEX idx_budgets_order ON budgets(budget_order_id);
CREATE INDEX idx_budgets_client ON budgets(client_id);
CREATE INDEX idx_budgets_status ON budgets(status);

-- ============================================================================
-- BUDGET ITEMS TABLE
-- ============================================================================
CREATE TABLE budget_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(12,4) NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  total_price DECIMAL(15,2) NOT NULL,
  category VARCHAR(100),
  item_order INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budget_items_budget ON budget_items(budget_id);

-- ============================================================================
-- PROFESSIONALS TABLE
-- ============================================================================
CREATE TABLE professionals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20),
  document_number VARCHAR(50) UNIQUE,
  role VARCHAR(100) NOT NULL, -- Electrician, Engineer, Technician, Manager, etc
  specialization VARCHAR(255), -- High voltage, Low voltage, Solar, etc
  registration_number VARCHAR(100), -- CREA, etc
  qualifications TEXT,
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  active BOOLEAN DEFAULT true,
  hire_date DATE,
  birth_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_professionals_email ON professionals(email);
CREATE INDEX idx_professionals_role ON professionals(role);
CREATE INDEX idx_professionals_active ON professionals(active);

-- ============================================================================
-- TEAMS TABLE
-- ============================================================================
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  leader_id UUID REFERENCES professionals(id) ON DELETE SET NULL,
  active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_teams_leader ON teams(leader_id);
CREATE INDEX idx_teams_active ON teams(active);

-- ============================================================================
-- TEAM MEMBERS (Junction table)
-- ============================================================================
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  role_in_team VARCHAR(100),
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(team_id, professional_id)
);

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_professional ON team_members(professional_id);

-- ============================================================================
-- SUPPLIERS TABLE
-- ============================================================================
CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100),
  document_number VARCHAR(50) UNIQUE,
  document_type VARCHAR(50), -- CPF, CNPJ
  company_name VARCHAR(255),
  contact_person VARCHAR(255),
  payment_terms VARCHAR(255),
  active BOOLEAN DEFAULT true,
  notes TEXT,
  rating DECIMAL(3,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_suppliers_name ON suppliers(name);
CREATE INDEX idx_suppliers_active ON suppliers(active);
CREATE INDEX idx_suppliers_document ON suppliers(document_number);

-- ============================================================================
-- SUPPLIER QUOTES TABLE
-- ============================================================================
CREATE TABLE supplier_quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quote_number VARCHAR(50) UNIQUE NOT NULL,
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  budget_id UUID REFERENCES budgets(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, received, approved, rejected, expired
  description TEXT,
  total_value DECIMAL(15,2),
  delivery_days INTEGER,
  valid_until DATE,
  notes TEXT,
  received_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_supplier_quotes_supplier ON supplier_quotes(supplier_id);
CREATE INDEX idx_supplier_quotes_budget ON supplier_quotes(budget_id);
CREATE INDEX idx_supplier_quotes_status ON supplier_quotes(status);

-- ============================================================================
-- PROPOSALS TABLE
-- ============================================================================
CREATE TABLE proposals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  proposal_number VARCHAR(50) UNIQUE NOT NULL,
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'draft', -- draft, sent, viewed, accepted, rejected, expired
  title VARCHAR(255) NOT NULL,
  description TEXT,
  total_value DECIMAL(15,2),
  discount_percent DECIMAL(5,2) DEFAULT 0,
  discount_value DECIMAL(15,2),
  final_value DECIMAL(15,2),
  validity_days INTEGER DEFAULT 30,
  issued_date DATE NOT NULL,
  valid_until DATE,
  sent_date DATE,
  accepted_date DATE,
  accepted_by VARCHAR(255),
  notes TEXT,
  terms_conditions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proposals_number ON proposals(proposal_number);
CREATE INDEX idx_proposals_budget ON proposals(budget_id);
CREATE INDEX idx_proposals_client ON proposals(client_id);
CREATE INDEX idx_proposals_status ON proposals(status);

-- ============================================================================
-- PROJECTS TABLE
-- ============================================================================
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_number VARCHAR(50) UNIQUE NOT NULL,
  proposal_id UUID REFERENCES proposals(id) ON DELETE SET NULL,
  budget_order_id UUID REFERENCES budget_orders(id) ON DELETE SET NULL,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  scope TEXT,
  status VARCHAR(50) DEFAULT 'planning', -- planning, approved, in_progress, on_hold, completed, cancelled
  start_date DATE,
  estimated_end_date DATE,
  actual_end_date DATE,
  budget_value DECIMAL(15,2),
  actual_cost DECIMAL(15,2),
  team_lead_id UUID REFERENCES professionals(id) ON DELETE SET NULL,
  team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
  priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high, urgent
  location TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_projects_number ON projects(project_number);
CREATE INDEX idx_projects_client ON projects(client_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_team_lead ON projects(team_lead_id);
CREATE INDEX idx_projects_team ON projects(team_id);

-- ============================================================================
-- ATTACHMENTS TABLE
-- ============================================================================
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name VARCHAR(255) NOT NULL,
  file_size INTEGER,
  file_type VARCHAR(100),
  file_path TEXT NOT NULL,
  storage_url TEXT,
  document_type VARCHAR(50), -- budget, proposal, contract, report, drawing, etc
  related_table VARCHAR(100), -- budgets, proposals, projects, leads, etc
  related_id UUID NOT NULL,
  uploaded_by UUID REFERENCES professionals(id) ON DELETE SET NULL,
  description TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_attachments_related ON attachments(related_table, related_id);
CREATE INDEX idx_attachments_type ON attachments(document_type);
CREATE INDEX idx_attachments_uploaded_by ON attachments(uploaded_by);

-- ============================================================================
-- ENERGY ANALYZERS TABLE
-- ============================================================================
CREATE TABLE energy_analyzers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  analyzer_name VARCHAR(255) NOT NULL,
  analyzer_model VARCHAR(100),
  serial_number VARCHAR(100) UNIQUE,
  status VARCHAR(50) DEFAULT 'active', -- active, maintenance, inactive, retired
  acquisition_date DATE,
  last_calibration_date DATE,
  next_calibration_date DATE,
  current_location TEXT,
  assigned_to UUID REFERENCES professionals(id) ON DELETE SET NULL,
  manufacturer VARCHAR(255),
  specifications TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_energy_analyzers_status ON energy_analyzers(status);
CREATE INDEX idx_energy_analyzers_assigned ON energy_analyzers(assigned_to);

-- ============================================================================
-- ENERGY ANALYSIS RECORDS TABLE
-- ============================================================================
CREATE TABLE energy_analysis_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  energy_analyzer_id UUID NOT NULL REFERENCES energy_analyzers(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  analysis_date TIMESTAMP WITH TIME ZONE NOT NULL,
  performed_by UUID REFERENCES professionals(id) ON DELETE SET NULL,
  voltage_phase_a DECIMAL(10,2),
  voltage_phase_b DECIMAL(10,2),
  voltage_phase_c DECIMAL(10,2),
  current_phase_a DECIMAL(10,2),
  current_phase_b DECIMAL(10,2),
  current_phase_c DECIMAL(10,2),
  frequency DECIMAL(8,2),
  power_factor DECIMAL(5,3),
  active_power DECIMAL(15,2),
  reactive_power DECIMAL(15,2),
  apparent_power DECIMAL(15,2),
  total_harmonic_distortion DECIMAL(5,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_energy_analysis_records_analyzer ON energy_analysis_records(energy_analyzer_id);
CREATE INDEX idx_energy_analysis_records_project ON energy_analysis_records(project_id);
CREATE INDEX idx_energy_analysis_records_date ON energy_analysis_records(analysis_date);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for all tables with updated_at
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budget_orders_updated_at BEFORE UPDATE ON budget_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_site_visits_updated_at BEFORE UPDATE ON site_visits
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON budget_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_professionals_updated_at BEFORE UPDATE ON professionals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_members_updated_at BEFORE UPDATE ON team_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_supplier_quotes_updated_at BEFORE UPDATE ON supplier_quotes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_proposals_updated_at BEFORE UPDATE ON proposals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attachments_updated_at BEFORE UPDATE ON attachments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_energy_analyzers_updated_at BEFORE UPDATE ON energy_analyzers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_energy_analysis_records_updated_at BEFORE UPDATE ON energy_analysis_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- GRANTS FOR SUPABASE (uncomment if using Supabase)
-- ============================================================================
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
