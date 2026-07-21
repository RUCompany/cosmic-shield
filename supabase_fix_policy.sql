-- quote_requests 테이블에 "누구나 제출(INSERT) 가능" 정책만 다시 적용
-- (이미 있으면 지우고 새로 만들어서 중복 오류 없이 안전하게 재실행 가능)

ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert" ON quote_requests;

CREATE POLICY "Anyone can insert" ON quote_requests
  FOR INSERT WITH CHECK (true);
