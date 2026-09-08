-- COSMIC SHIELD 견적문의 테이블 생성 (신규 설치용)
-- Supabase 대시보드 > SQL Editor 에서 실행하세요 (한 번만 실행하면 됩니다)
-- ※ 이미 v1 테이블이 있다면 이 파일 대신 supabase_migration_v2.sql 을 실행하세요.

CREATE TABLE quote_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,   -- 고유 번호 (자동 생성)
  car_type TEXT NOT NULL,                          -- 차종 (자유 입력)
  car_year TEXT,                                   -- 연식
  phone TEXT NOT NULL,                             -- 연락처
  film_type TEXT,                                  -- 관심 필름 종류
  message TEXT,                                    -- 희망 시공 부위 / 문의사항
  name TEXT,                                       -- (v1 호환용, 현재 미사용)
  email TEXT,                                      -- (v1 호환용, 현재 미사용)
  status TEXT DEFAULT 'pending',                   -- 처리 상태 (pending / done)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- 접수 시간 (자동)
);

-- 보안 설정: RLS 활성화
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;

-- 누구나 견적 문의 폼 제출(INSERT)은 가능하도록 허용
CREATE POLICY "Anyone can insert" ON quote_requests
  FOR INSERT WITH CHECK (true);

-- 조회(SELECT)는 관리자 페이지에서 service role 키로만 접근
