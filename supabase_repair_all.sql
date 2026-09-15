-- ============================================================
-- COSMIC SHIELD — 견적문의 저장 문제 통합 점검·복구 스크립트
-- ============================================================
--
-- 이 파일 하나만 실행하면 됩니다.
--   · 테이블이 없으면 만들고
--   · v2 마이그레이션(차종·연식 / 이름·이메일 선택화)을 적용하고
--   · 제출 허용 정책(RLS)을 다시 걸고
--   · 마지막에 "지금 실제로 저장되는지" 진단표를 보여줍니다.
--
-- 이미 실행한 적이 있어도 안전합니다. 여러 번 돌려도 같은 결과입니다.
--
-- ▶ 실행 방법
--   1) https://supabase.com/dashboard/project/fktlayvtezcpxmaoutyi/sql
--   2) 이 파일 내용을 전부 붙여넣기
--   3) 글자가 드래그로 "선택"되어 있지 않은지 확인 (선택 영역만 실행됩니다)
--      → 아무 데나 한 번 클릭해서 선택을 푸세요
--   4) Run
--   5) 맨 아래 나오는 표를 통째로 복사해서 알려주세요
--
-- ============================================================


-- ── [1] 테이블이 없으면 생성 ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quote_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  car_type TEXT NOT NULL,
  phone TEXT NOT NULL,
  film_type TEXT,
  message TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ── [2] v2 마이그레이션 (있어도 없어도 안전하게) ─────────────
-- 연식 컬럼 추가
ALTER TABLE public.quote_requests ADD COLUMN IF NOT EXISTS car_year TEXT;

-- 이름·이메일은 더 이상 받지 않음 → 컬럼이 남아 있다면 NOT NULL 만 해제
-- (컬럼이 아예 없는 경우에도 오류 없이 넘어갑니다. 기존 데이터는 보존)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='quote_requests' AND column_name='name') THEN
    ALTER TABLE public.quote_requests ALTER COLUMN name DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='quote_requests' AND column_name='email') THEN
    ALTER TABLE public.quote_requests ALTER COLUMN email DROP NOT NULL;
  END IF;
END $$;


-- ── [3] 제출 허용 (RLS + 권한 + 정책) ───────────────────────
ALTER TABLE public.quote_requests ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT INSERT ON public.quote_requests TO anon, authenticated;

DROP POLICY IF EXISTS "Anyone can insert" ON public.quote_requests;
CREATE POLICY "Anyone can insert"
  ON public.quote_requests
  AS PERMISSIVE
  FOR INSERT
  TO public
  WITH CHECK (true);


-- ============================================================
--  여기서부터는 진단입니다 (데이터를 바꾸지 않습니다)
-- ============================================================

DROP TABLE IF EXISTS _diag;
CREATE TEMP TABLE _diag (순서 int, 항목 text, 결과 text);

-- [진단 1] 사이트 손님(anon) 역할을 그대로 흉내내어 실제 저장 시도
--          테스트 행은 바로 아래에서 스스로 지웁니다.
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    SET LOCAL ROLE anon;
    INSERT INTO public.quote_requests (car_type, car_year, phone, film_type, message)
    VALUES ('ZZTEST-diag', '2024', '010-0000-0000', 'COSMIC-75', '진단용 테스트');
    msg := '✅ 성공 — 폼 제출이 정상 저장됩니다';
  EXCEPTION WHEN OTHERS THEN
    msg := '❌ 실패 — ' || SQLSTATE || ' : ' || SQLERRM;
  END;
  RESET ROLE;
  INSERT INTO _diag VALUES (1, '▶ anon 저장 테스트', msg);
END $$;

DELETE FROM public.quote_requests WHERE car_type = 'ZZTEST-diag';

-- [진단 2] 폼이 보내는 컬럼이 전부 있는지 (v2 마이그레이션 적용 여부)
INSERT INTO _diag
SELECT 2,
       '▶ 컬럼 확인: ' || c.col,
       CASE WHEN EXISTS (
         SELECT 1 FROM information_schema.columns i
         WHERE i.table_schema='public' AND i.table_name='quote_requests' AND i.column_name = c.col
       ) THEN '있음' ELSE '❌ 없음 — 저장 실패 원인' END
FROM (VALUES ('car_type'),('car_year'),('phone'),('film_type'),('message'),('status'),('created_at')) AS c(col);

-- [진단 3] 남아 있는 NOT NULL 제약 (폼이 안 보내는 컬럼에 걸려 있으면 저장 실패)
INSERT INTO _diag
SELECT 3, '▶ NOT NULL 컬럼', coalesce(string_agg(column_name, ', ' ORDER BY column_name), '(없음)')
FROM information_schema.columns
WHERE table_schema='public' AND table_name='quote_requests'
  AND is_nullable = 'NO' AND column_default IS NULL;

-- [진단 4] RLS 상태
INSERT INTO _diag
SELECT 4, '▶ RLS 켜짐 / 강제됨',
       c.relrowsecurity::text || ' / ' || c.relforcerowsecurity::text
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='public' AND c.relname='quote_requests';

-- [진단 5] 걸려 있는 정책 전체 (RESTRICTIVE 가 하나라도 있으면 그게 막는 것)
INSERT INTO _diag
SELECT 5, '▶ 정책: ' || policyname,
       cmd || ' / ' || permissive || ' / roles=' || array_to_string(roles, ',')
       || ' / check=' || coalesce(with_check, '(없음)')
FROM pg_policies
WHERE schemaname='public' AND tablename='quote_requests';

-- [진단 6] anon 에게 부여된 테이블 권한
INSERT INTO _diag
SELECT 6, '▶ 권한: ' || grantee, string_agg(privilege_type, ', ')
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name='quote_requests'
  AND grantee IN ('anon','authenticated','PUBLIC')
GROUP BY grantee;

-- [진단 7] 지금까지 실제로 쌓인 문의 건수
INSERT INTO _diag
SELECT 7, '▶ 저장된 문의 건수', count(*)::text || ' 건'
FROM public.quote_requests;

SELECT 항목, 결과 FROM _diag ORDER BY 순서, 항목;
