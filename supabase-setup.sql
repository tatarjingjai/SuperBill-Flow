-- ============================================================
-- BillFlow v1.2 — Supabase Database Setup
-- วิธีใช้: ไปที่ Supabase → SQL Editor → New Query → วางทั้งหมดนี้ → Run
-- ============================================================

-- ============================================================
-- 1. TABLE: user_roles (admin / customer)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_roles (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email      text,
  role       text NOT NULL DEFAULT 'customer' CHECK (role IN ('admin','customer')),
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 2. TABLE: lots
-- ============================================================
CREATE TABLE IF NOT EXISTS lots (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_number       text NOT NULL,
  customer_id      uuid REFERENCES auth.users(id),
  customer_email   text,
  description      text,
  status           text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','docs','paid')),
  confirmed_total  numeric(15,2),
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- ============================================================
-- 3. TABLE: companies (NEW — หลายบริษัทต่อ 1 Lot)
-- ============================================================
CREATE TABLE IF NOT EXISTS companies (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id     uuid REFERENCES lots(id) ON DELETE CASCADE NOT NULL,
  name       text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 4. TABLE: projects (หลายโครงการต่อ 1 บริษัท)
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  lot_id     uuid REFERENCES lots(id) NOT NULL,   -- denormalized เพื่อ query ง่าย
  name       text NOT NULL,
  amount     numeric(15,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 5. TABLE: payments (สลิปการชำระเงิน)
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id             uuid REFERENCES lots(id) NOT NULL,
  submitted_by       uuid REFERENCES auth.users(id),
  slip_url           text,
  slip_uploaded_at   timestamptz,
  confirmed_by_admin boolean DEFAULT false,
  confirmed_at       timestamptz,
  note               text,
  created_at         timestamptz DEFAULT now()
);

-- ============================================================
-- 6. TABLE: withdrawals (การเบิกเงิน)
-- ============================================================
CREATE TABLE IF NOT EXISTS withdrawals (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id     uuid REFERENCES lots(id) NOT NULL,
  amount     numeric(15,2) NOT NULL,
  note       text,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- AUTO-UPDATE: updated_at trigger for lots
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lots_updated_at ON lots;
CREATE TRIGGER lots_updated_at
  BEFORE UPDATE ON lots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- AUTO-REGISTER: เพิ่ม user_roles อัตโนมัติเมื่อมี user ใหม่
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_roles (user_id, email, role)
  VALUES (NEW.id, NEW.email, 'customer')
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE user_roles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE lots        ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies   ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects    ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES: user_roles
-- ============================================================
-- ผู้ใช้ดูข้อมูลตัวเองได้
CREATE POLICY "user_roles_select_own" ON user_roles
  FOR SELECT USING (auth.uid() = user_id);

-- admin ดูทุกคนได้
CREATE POLICY "user_roles_select_admin" ON user_roles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- admin update ได้
CREATE POLICY "user_roles_update_admin" ON user_roles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- system insert (trigger)
CREATE POLICY "user_roles_insert_system" ON user_roles
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- RLS POLICIES: lots
-- ============================================================
-- admin เห็นทุก Lot
CREATE POLICY "lots_admin_all" ON lots
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- customer เห็นเฉพาะ Lot ของตัวเอง
CREATE POLICY "lots_customer_select" ON lots
  FOR SELECT USING (customer_id = auth.uid());

-- customer insert (ส่งงาน)
CREATE POLICY "lots_customer_insert" ON lots
  FOR INSERT WITH CHECK (customer_id = auth.uid());

-- ============================================================
-- RLS POLICIES: companies
-- ============================================================
CREATE POLICY "companies_admin_all" ON companies
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "companies_customer_select" ON companies
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM lots WHERE id = lot_id AND customer_id = auth.uid())
  );

CREATE POLICY "companies_customer_insert" ON companies
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM lots WHERE id = lot_id AND customer_id = auth.uid())
  );

-- ============================================================
-- RLS POLICIES: projects
-- ============================================================
CREATE POLICY "projects_admin_all" ON projects
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "projects_customer_select" ON projects
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM lots WHERE id = lot_id AND customer_id = auth.uid())
  );

CREATE POLICY "projects_customer_insert" ON projects
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM lots WHERE id = lot_id AND customer_id = auth.uid())
  );

-- ============================================================
-- RLS POLICIES: payments
-- ============================================================
CREATE POLICY "payments_admin_all" ON payments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "payments_customer_select" ON payments
  FOR SELECT USING (submitted_by = auth.uid());

CREATE POLICY "payments_customer_insert" ON payments
  FOR INSERT WITH CHECK (submitted_by = auth.uid());

CREATE POLICY "payments_customer_update" ON payments
  FOR UPDATE USING (submitted_by = auth.uid() AND confirmed_by_admin = false);

-- ============================================================
-- RLS POLICIES: withdrawals (admin only)
-- ============================================================
CREATE POLICY "withdrawals_admin_all" ON withdrawals
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- STORAGE: สร้าง bucket สำหรับเก็บสลิป
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('slips', 'slips', false)
ON CONFLICT (id) DO NOTHING;

-- Policy: customer อัปโหลดสลิปของตัวเองได้
CREATE POLICY "slips_customer_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'slips' AND
    auth.uid() IS NOT NULL
  );

-- Policy: เจ้าของ และ admin ดูสลิปได้
CREATE POLICY "slips_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'slips' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
    )
  );

-- ============================================================
-- INITIAL ADMIN SETUP
-- ============================================================
-- หลังจาก run SQL นี้แล้ว:
-- 1. ให้ admin login ก่อน (สร้าง account ด้วย email/google)
-- 2. หา user_id ของ admin จาก Authentication → Users
-- 3. Run คำสั่งนี้เพื่อตั้ง role เป็น admin:
--
-- UPDATE user_roles SET role = 'admin' WHERE email = 'your-admin@email.com';
--
-- ============================================================

SELECT 'BillFlow v1.2 Setup Complete!' AS status;
