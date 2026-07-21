const { parseCookies, verifySessionToken } = require('../../lib/session');

module.exports = async function handler(req, res) {
  const cookies = parseCookies(req);
  if (!verifySessionToken(cookies.admin_session)) {
    return res.status(401).json({ ok: false, error: '인증이 필요합니다.' });
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  try {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/quote_requests?select=*&order=created_at.desc`, {
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
      },
    });

    if (!r.ok) {
      console.error('Supabase list failed:', await r.text());
      return res.status(502).json({ ok: false, error: '조회에 실패했습니다.' });
    }

    const data = await r.json();
    return res.status(200).json({ ok: true, data });
  } catch (err) {
    console.error('Admin list error:', err);
    return res.status(500).json({ ok: false, error: '서버 오류가 발생했습니다.' });
  }
};
