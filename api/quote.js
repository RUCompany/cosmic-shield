// Vercel Serverless Function — 견적문의 폼 제출 처리
// 1) Supabase에 저장  2) 관리자에게 Resend로 이메일 알림

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  const { name, phone, email, car_type, film_type, message, agree } = req.body || {};

  if (!name || !phone || !email || !agree) {
    return res.status(400).json({ ok: false, error: '필수 항목이 누락되었습니다.' });
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  const ADMIN_EMAIL = process.env.ADMIN_EMAIL;

  try {
    const dbRes = await fetch(`${SUPABASE_URL}/rest/v1/quote_requests`, {
      method: 'POST',
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({ name, phone, email, car_type, film_type, message }),
    });

    if (!dbRes.ok) {
      const errText = await dbRes.text();
      console.error('Supabase insert failed:', errText);
      return res.status(502).json({ ok: false, error: '저장에 실패했습니다. 잠시 후 다시 시도해주세요.' });
    }

    if (RESEND_API_KEY && ADMIN_EMAIL) {
      try {
        await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${RESEND_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: 'onboarding@resend.dev',
            to: ADMIN_EMAIL,
            subject: `[COSMIC SHIELD] 새 견적문의 - ${name}`,
            html: `
              <h2>새 견적문의가 접수되었습니다</h2>
              <p><b>이름:</b> ${name}</p>
              <p><b>연락처:</b> ${phone}</p>
              <p><b>이메일:</b> ${email}</p>
              <p><b>차종:</b> ${car_type || '-'}</p>
              <p><b>관심 필름:</b> ${film_type || '-'}</p>
              <p><b>문의사항:</b> ${message || '-'}</p>
            `,
          }),
        });
      } catch (mailErr) {
        // 이메일 발송 실패는 DB 저장 성공에 영향을 주지 않는다.
        console.error('Resend email failed:', mailErr);
      }
    }

    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Quote submission error:', err);
    return res.status(500).json({ ok: false, error: '서버 오류가 발생했습니다.' });
  }
};
