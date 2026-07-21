-- quote_requests 테이블에 실제로 어떤 정책이 걸려있는지 확인하는 조회 전용 쿼리 (데이터 변경 없음)
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'quote_requests';
