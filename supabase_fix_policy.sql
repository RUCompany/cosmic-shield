-- quote_requests: "누구나 견적문의 제출(INSERT) 가능" 정책 적용 + 결과 확인
--
-- ⚠️ 실행 전 확인 2가지
--   1) 주소창의 프로젝트 ID 가 fktlayvtezcpxmaoutyi 인지
--      https://supabase.com/dashboard/project/fktlayvtezcpxmaoutyi/sql
--   2) 에디터에 글자가 "선택(드래그)" 되어 있지 않은지
--      Supabase SQL Editor 는 선택된 부분이 있으면 그 부분만 실행합니다.
--      Ctrl+A 로 전체 선택하거나, 아무 데나 클릭해 선택을 푼 뒤 Run 하세요.
--
-- 여러 번 실행해도 안전합니다.

-- 1) RLS 켜기
ALTER TABLE public.quote_requests ENABLE ROW LEVEL SECURITY;

-- 2) 테이블 사용 권한 (RLS 와 별개로 필요)
GRANT INSERT ON public.quote_requests TO anon, authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- 3) 제출 허용 정책 (있으면 지우고 새로 생성)
DROP POLICY IF EXISTS "Anyone can insert" ON public.quote_requests;

CREATE POLICY "Anyone can insert"
  ON public.quote_requests
  AS PERMISSIVE
  FOR INSERT
  TO public
  WITH CHECK (true);

-- 4) 방금 만든 정책이 실제로 들어갔는지 바로 확인
--    아래 표에 "Anyone can insert" 행이 보여야 성공입니다.
SELECT
  policyname,
  cmd,
  permissive,
  roles,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'quote_requests';
