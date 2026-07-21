-- COSMIC SHIELD 견적문의 테이블 생성
-- Supabase 대시보드 > SQL Editor 에서 실행하세요 (한 번만 실행하면 됩니다)

CREATE TABLE quote_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,   -- 고유 번호 (자동 생성)
  name TEXT NOT NULL,                              -- 이름
  phone TEXT NOT NULL,                             -- 연락처
  email TEXT NOT NULL,                             -- 이메일
  car_type TEXT,                                   -- 차종
  film_type TEXT,                                  -- 관심 필름 종류
  message TEXT,                                    -- 희망 시공 부위 / 문의사항
  status TEXT DEFAULT 'pending',                   -- 처리 상태 (pending / done)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- 접수 시간 (자동)
);

-- 보안 설정: RLS 활성화
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;

-- 누구나 견적 문의 폼 제출(INSERT)은 가능하도록 허용
CREATE POLICY "Anyone can insert" ON quote_requests
  FOR INSERT WITH CHECK (true);

-- 조회(SELECT)는 관리자 페이지에서 별도 인증을 거쳐서만 접근 (Phase 5에서 연동)
