// ============================================================
// BillFlow - Supabase Configuration
// ============================================================
// วิธีใช้:
// 1. ไปที่ https://supabase.com → เลือก Project ของคุณ
// 2. ไปที่ Settings → API
// 3. คัดลอก "Project URL" และ "anon public" key
// 4. แทนที่ค่า placeholder ด้านล่าง แล้ว save ไฟล์นี้
// ============================================================

const SUPABASE_URL = 'https://vqptvfajjsdmrdnbgtmb.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxcHR2ZmFqanNkbXJkbmJndG1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NjM1OTMsImV4cCI6MjA5MTMzOTU5M30.7dF0ySqPswsIiulUciliVMTu9DyxfIO2hFw1-kDnUs8';

// GitHub Pages repo name (ใช้สำหรับ redirect หลัง login)
// ถ้า repo ชื่อ SuperBill-Flow → ค่าคือ '/SuperBill-Flow'
const REPO_BASE = '/SuperBill-Flow';
