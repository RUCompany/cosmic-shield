-- COSMIC SHIELD 견적문의 테이블 v2 마이그레이션
-- 폼 항목 변경: 이름·이메일 삭제, 차종(자유 입력)·연식 추가
-- Supabase 대시보드 > SQL Editor 에서 한 번만 실행하세요.

-- 1) 이름 / 이메일은 더 이상 받지 않으므로 필수 제약 해제 (기존 데이터는 그대로 보존)
ALTER TABLE quote_requests ALTER COLUMN name DROP NOT NULL;
ALTER TABLE quote_requests ALTER COLUMN email DROP NOT NULL;

-- 2) 연식 컬럼 추가
ALTER TABLE quote_requests ADD COLUMN IF NOT EXISTS car_year TEXT;
