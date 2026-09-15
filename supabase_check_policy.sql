-- quote_requests 종합 진단
--
-- SQL Editor 안에서 anon(사이트 손님) 역할을 그대로 흉내내어 저장을 시도하고,
-- 실패하면 그 이유를 표로 보여줍니다.
-- 테스트로 넣은 행은 마지막에 스스로 지우므로 데이터는 남지 않습니다.
--
-- 붙여넣고 아무 데나 클릭해 선택을 푼 뒤 Run 하세요.
-- 마지막에 나오는 표를 통째로 알려주시면 됩니다.

CREATE TEMP TABLE _diag (순서 int, 항목 text, 결과 text);

-- [1] anon 역할로 실제 저장 시도
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    SET ROLE anon;
    INSERT INTO public.quote_requests (car_type, car_year, phone)
    VALUES ('ZZTEST-diag', '2024', '010-0000-0000');
    msg := '성공';
  EXCEPTION WHEN OTHERS THEN
    msg := SQLSTATE || ' — ' || SQLERRM;
  END;
  RESET ROLE;
  INSERT INTO _diag VALUES (1, '▶ anon 저장 테스트', msg);
END $$;

-- 테스트 행 제거 (성공했을 경우에만 해당)
DELETE FROM public.quote_requests WHERE car_type = 'ZZTEST-diag';

-- [2] RLS 상태
INSERT INTO _diag
SELECT 2, '▶ RLS 켜짐 / 강제됨',
       c.relrowsecurity::text || ' / ' || c.relforcerowsecurity::text
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'quote_requests';

-- [3] 걸려 있는 정책 전체 (RESTRICTIVE 가 하나라도 있으면 그게 막는 것)
INSERT INTO _diag
SELECT 3, '▶ 정책: ' || policyname,
       cmd || ' / ' || permissive
       || ' / roles=' || array_to_string(roles, ',')
       || ' / check=' || coalesce(with_check, '(없음)')
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'quote_requests';

-- [4] anon 에게 부여된 테이블 권한
INSERT INTO _diag
SELECT 4, '▶ 권한: ' || grantee, string_agg(privilege_type, ', ')
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND table_name = 'quote_requests'
  AND grantee IN ('anon', 'authenticated', 'PUBLIC')
GROUP BY grantee;

-- [5] 테이블 소유자 (소유자면 RLS 를 우회하므로 참고용)
INSERT INTO _diag
SELECT 5, '▶ 테이블 소유자', tableowner
FROM pg_tables WHERE schemaname = 'public' AND tablename = 'quote_requests';

SELECT 항목, 결과 FROM _diag ORDER BY 순서, 항목;
