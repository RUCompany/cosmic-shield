// COSMIC SHIELD — shared front-end behavior

document.addEventListener('DOMContentLoaded', () => {
  initNavToggle();
  initScrollReveal();
  initActiveNav();
  initQuoteForm();
});

function initNavToggle() {
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');
  if (!toggle || !links) return;
  toggle.addEventListener('click', () => {
    links.classList.toggle('open');
  });
  links.querySelectorAll('a').forEach((a) => {
    a.addEventListener('click', () => links.classList.remove('open'));
  });
}

function initScrollReveal() {
  const items = document.querySelectorAll('.reveal');
  if (!items.length) return;
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  items.forEach((el) => observer.observe(el));
}

function initActiveNav() {
  const current = document.body.dataset.page;
  if (!current) return;
  document.querySelectorAll('.nav-links a[data-page]').forEach((a) => {
    if (a.dataset.page === current) a.classList.add('active');
  });
}

function initQuoteForm() {
  const form = document.getElementById('quote-form');
  if (!form) return;
  const successPanel = document.getElementById('quote-form-success');
  const errorBanner = document.getElementById('quote-form-error');
  const submitBtn = form.querySelector('button[type="submit"]');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    let valid = true;
    form.querySelectorAll('[required]').forEach((field) => {
      const wrap = field.closest('.form-field');
      const isChecked = field.type === 'checkbox' ? field.checked : field.value.trim();
      if (!isChecked) {
        valid = false;
        wrap && wrap.classList.add('invalid');
      } else {
        wrap && wrap.classList.remove('invalid');
      }
    });

    if (!valid) return;

    if (errorBanner) errorBanner.classList.remove('show');
    submitBtn.disabled = true;
    submitBtn.textContent = '제출 중...';

    const payload = Object.fromEntries(new FormData(form).entries());
    payload.agree = form.querySelector('#q-agree').checked;

    try {
      const res = await fetch('/api/quote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json();

      if (!res.ok || !data.ok) throw new Error(data.error || '제출에 실패했습니다.');

      form.style.display = 'none';
      if (successPanel) successPanel.classList.add('show');
    } catch (err) {
      if (errorBanner) {
        errorBanner.textContent = err.message || '제출 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        errorBanner.classList.add('show');
      }
      submitBtn.disabled = false;
      submitBtn.textContent = '견적 문의하기';
    }
  });

  form.querySelectorAll('[required]').forEach((field) => {
    const evt = field.type === 'checkbox' ? 'change' : 'input';
    field.addEventListener(evt, () => {
      const wrap = field.closest('.form-field');
      const isChecked = field.type === 'checkbox' ? field.checked : field.value.trim();
      if (isChecked && wrap) wrap.classList.remove('invalid');
    });
  });
}
