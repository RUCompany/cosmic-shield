-- ============================================================
-- COSMIC SHIELD — anon 권한 최소화 (보안 정리)
-- ============================================================
--
-- 진단 결과 anon(사이트 손님) 역할에 아래 권한이 전부 열려 있었습니다:
--   INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
--
-- 실제로 필요한 건 INSERT 하나뿐입니다.
--   · 견적폼(api/quote.js)  → INSERT 만 사용 (Prefer: return=minimal)
--   · 관리자페이지(api/admin) → service role 키 사용 (이 권한과 무관, 영향 없음)
--
-- ⚠️ 특히 TRUNCATE 는 RLS 정책을 우회합니다.
--    정책이 없어도 테이블 전체를 비울 수 있으므로 반드시 회수해야 합니다.
--
-- ▶ 실행 방법: SQL Editor 에 붙여넣고, 선택 영역을 푼 뒤 Run
-- ▶ 여러 번 실행해도 안전합니다.
--
-- ============================================================


-- ── [1] 과한 권한 전부 회수 ─────────────────────────────────
REVOKE ALL ON public.quote_requests FROM anon;
REVOKE ALL ON public.quote_requests FROM authenticated;


-- ── [2] 꼭 필요한 것만 다시 부여 ────────────────────────────
GRANT USAGE  ON SCHEMA public          TO anon, authenticated;
GRANT INSERT ON public.quote_requests  TO anon, authenticated;


-- ── [3] 앞으로 만들 테이블에도 같은 실수가 반복되지 않도록 ──
--    (Supabase 기본값이 전체 권한을 자동 부여하는 것을 막습니다)
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;


-- ============================================================
--  확인 (데이터를 바꾸지 않습니다)
-- ============================================================

DROP TABLE IF EXISTS _check;
CREATE TEMP TABLE _check (순서 int, 항목 text, 결과 text);

-- [확인 1] 정리 후 남은 권한 — anon 은 INSERT 만 나와야 정상
INSERT INTO _check
SELECT 1, '▶ 권한: ' || grantee, string_agg(privilege_type, ', ' ORDER BY privilege_type)
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name='quote_requests'
  AND grantee IN ('anon','authenticated','PUBLIC')
GROUP BY grantee;

-- [확인 2] 권한을 줄인 뒤에도 폼 제출이 여전히 되는지 재확인
--          (테스트 행은 바로 아래에서 스스로 지웁니다)
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    SET LOCAL ROLE anon;
    INSERT INTO public.quote_requests (car_type, car_year, phone, film_type, message)
    VALUES ('ZZTEST-grant', '2024', '010-0000-0000', 'COSMIC-75', '권한 정리 후 테스트');
    msg := '✅ 성공 — 폼 제출 정상 (권한 줄여도 문제 없음)';
  EXCEPTION WHEN OTHERS THEN
    msg := '❌ 실패 — ' || SQLSTATE || ' : ' || SQLERRM;
  END;
  RESET ROLE;
  INSERT INTO _check VALUES (2, '▶ 제출 재테스트', msg);
END $$;

DELETE FROM public.quote_requests WHERE car_type = 'ZZTEST-grant';

-- [확인 3] anon 이 남의 문의를 훔쳐볼 수 없는지 (실패가 정상입니다)
DO $$
DECLARE msg text; n int;
BEGIN
  BEGIN
    SET LOCAL ROLE anon;
    SELECT count(*) INTO n FROM public.quote_requests;
    msg := '⚠️ 조회됨 (' || n || '건) — 점검 필요';
  EXCEPTION WHEN OTHERS THEN
    msg := '✅ 차단됨 — 손님은 문의 내역을 볼 수 없습니다';
  END;
  RESET ROLE;
  INSERT INTO _check VALUES (3, '▶ 무단 조회 차단', msg);
END $$;

-- [확인 4] 데이터가 그대로인지
INSERT INTO _check
SELECT 4, '▶ 저장된 문의 건수', count(*)::text || ' 건' FROM public.quote_requests;

SELECT 항목, 결과 FROM _check ORDER BY 순서, 항목;
