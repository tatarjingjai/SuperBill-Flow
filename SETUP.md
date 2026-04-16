# BillFlow — คู่มือ Setup

## ขั้นตอนทั้งหมด (ทำครั้งเดียว)

---

## ขั้นที่ 1: สร้าง Supabase Project

1. ไปที่ [https://supabase.com](https://supabase.com) → Sign up / Login
2. กด **"New project"**
3. ตั้งชื่อ project (เช่น `billflow`) และตั้ง password ฐานข้อมูล
4. เลือก region: **Southeast Asia (Singapore)**
5. รอประมาณ 2 นาทีให้ project พร้อม

---

## ขั้นที่ 2: Run SQL Setup

1. ใน Supabase → เปิด **SQL Editor** (เมนูซ้าย)
2. กด **"New query"**
3. เปิดไฟล์ `supabase-setup.sql` → คัดลอกทั้งหมด → วางใน SQL Editor
4. กด **"Run"** (Ctrl+Enter)
5. รอจนเห็น `BillFlow v1.2 Setup Complete!`

---

## ขั้นที่ 3: เปิดใช้ Google OAuth

1. ใน Supabase → **Authentication** → **Providers**
2. หา **Google** → เปิด Enable
3. ไปที่ [Google Cloud Console](https://console.cloud.google.com)
   - สร้าง OAuth 2.0 Client ID
   - Authorized redirect URIs: `https://[your-project-id].supabase.co/auth/v1/callback`
4. คัดลอก Client ID และ Client Secret → ใส่ใน Supabase Google Provider

---

## ขั้นที่ 4: ตั้ง Redirect URL

1. ใน Supabase → **Authentication** → **URL Configuration**
2. **Site URL**: `https://tatarjingjai.github.io/SuperBill-Flow`
3. **Redirect URLs** (Additional): เพิ่ม
   ```
   https://tatarjingjai.github.io/SuperBill-Flow/index.html
   https://tatarjingjai.github.io/SuperBill-Flow/
   ```

---

## ขั้นที่ 5: ใส่ Supabase Key ในไฟล์ config.js

1. ใน Supabase → **Settings** → **API**
2. คัดลอก:
   - **Project URL** (เช่น `https://abcxyz.supabase.co`)
   - **anon public** key
3. เปิดไฟล์ `config.js` → แทนที่ค่า placeholder:

```js
const SUPABASE_URL = 'https://abcxyz.supabase.co';   // ← ใส่ URL จริง
const SUPABASE_ANON_KEY = 'eyJhbGci...';              // ← ใส่ key จริง
```

---

## ขั้นที่ 6: Push ขึ้น GitHub

```bash
git add .
git commit -m "Initial BillFlow setup"
git push origin main
```

---

## ขั้นที่ 7: เปิด GitHub Pages

1. ใน GitHub repo → **Settings** → **Pages**
2. Source: **Deploy from a branch** → Branch: `main` → Folder: `/ (root)`
3. กด Save → รอ 1-2 นาที
4. URL ของระบบ: `https://tatarjingjai.github.io/SuperBill-Flow`

---

## ขั้นที่ 8: ตั้ง Admin คนแรก

1. ไปที่ URL ระบบ → สมัครสมาชิกด้วยอีเมล admin
2. ใน Supabase → **SQL Editor** → Run:

```sql
UPDATE user_roles SET role = 'admin' WHERE email = 'your-admin@email.com';
```

3. Login ใหม่ → ระบบจะ redirect ไป Admin Dashboard

---

## โครงสร้างไฟล์

```
SuperBill-Flow/
├── index.html          ← หน้า Login
├── admin.html          ← Admin Dashboard (4 tabs)
├── customer.html       ← Customer Portal (3 tabs)
├── config.js           ← Supabase credentials ← แก้ไขตรงนี้!
├── supabase-setup.sql  ← SQL สำหรับ setup database
└── SETUP.md            ← คู่มือนี้
```

---

## สรุปการทำงานของระบบ

| บทบาท | สิ่งที่ทำได้ |
|--------|-------------|
| **Admin** | สร้าง Lot → มอบหมายลูกค้า → ดูการส่งงาน → ยืนยันบิล → เบิกเงิน |
| **Customer** | ส่งงาน (หลายบริษัท/หลายโครงการ) → ติดตามสถานะ → แนบสลิป |

## สูตรคำนวณบิล

```
ยอดรวม × 1.07 (VAT 7%)  = ราคารวม VAT
ราคารวม VAT - (ยอดรวม × 0.03) WHT 3%  = ยอดโอนสุทธิ
= ยอดรวม × 1.04

ค่าทำงาน 1.2% แสดงเป็น reference เท่านั้น ไม่ถูกนำมาคำนวณ
```

---

หากมีปัญหา ติดต่อทีมพัฒนา
