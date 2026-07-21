const { parseCookies, verifySessionToken } = require('../../lib/session');

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  const cookies = parseCookies(req);
  if (!verifySessionToken(cookies.admin_session)) {
    return res.status(401).json({ ok: false, error: '인증이 필요합니다.' });
  }

  const { id, status } = req.body || {};
  if (!id || !['pending', 'done'].includes(status)) {
    return res.status(400).json({ ok: false, error: '잘못된 요청입니다.' });
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  try {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/quote_requests?id=eq.${id}`, {
      method: 'PATCH',
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({ status }),
    });

    if (!r.ok) {
      console.error('Supabase update failed:', await r.text());
      return res.status(502).json({ ok: false, error: '업데이트에 실패했습니다.' });
    }

    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Admin update-status error:', err);
    return res.status(500).json({ ok: false, error: '서버 오류가 발생했습니다.' });
  }
};
