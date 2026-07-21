// COSMIC SHIELD — 관리자 대시보드

document.addEventListener('DOMContentLoaded', () => {
  const loginView = document.getElementById('login-view');
  const dashboardView = document.getElementById('dashboard-view');
  const loginForm = document.getElementById('login-form');
  const loginError = document.getElementById('login-error');
  const logoutBtn = document.getElementById('logout-btn');
  const tbody = document.getElementById('quote-table-body');
  const emptyState = document.getElementById('admin-empty');

  function showLogin() {
    loginView.style.display = 'flex';
    dashboardView.style.display = 'none';
  }

  function showDashboard() {
    loginView.style.display = 'none';
    dashboardView.style.display = 'block';
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str == null ? '' : String(str);
    return div.innerHTML;
  }

  function renderRows(rows) {
    if (!rows.length) {
      tbody.innerHTML = '';
      emptyState.style.display = 'block';
      return;
    }
    emptyState.style.display = 'none';

    tbody.innerHTML = rows
      .map((row) => {
        const isDone = row.status === 'done';
        const created = row.created_at ? new Date(row.created_at).toLocaleString('ko-KR') : '-';
        return `
        <tr data-id="${row.id}">
          <td>${escapeHtml(row.name)}</td>
          <td>${escapeHtml(row.phone)}</td>
          <td>${escapeHtml(row.email)}</td>
          <td>${escapeHtml(row.car_type || '-')}</td>
          <td>${escapeHtml(row.film_type || '-')}</td>
          <td class="admin-msg-cell" title="${escapeHtml(row.message || '')}">${escapeHtml(row.message || '-')}</td>
          <td>${created}</td>
          <td>
            <span class="status-badge ${isDone ? 'done' : 'pending'}">${isDone ? '완료' : '대기중'}</span>
            <button class="status-toggle-btn" data-status="${isDone ? 'pending' : 'done'}">
              ${isDone ? '대기중으로' : '완료 처리'}
            </button>
          </td>
        </tr>`;
      })
      .join('');
  }

  function renderStats(rows) {
    const today = new Date().toDateString();
    const total = rows.length;
    const pending = rows.filter((r) => r.status !== 'done').length;
    const todayCount = rows.filter((r) => r.created_at && new Date(r.created_at).toDateString() === today).length;

    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-pending').textContent = pending;
    document.getElementById('stat-today').textContent = todayCount;
  }

  let currentRows = [];

  async function loadDashboard() {
    const res = await fetch('/api/admin/list');
    if (res.status === 401) {
      showLogin();
      return;
    }
    const data = await res.json();
    if (!data.ok) {
      showLogin();
      return;
    }
    currentRows = data.data || [];
    renderStats(currentRows);
    renderRows(currentRows);
    showDashboard();
  }

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    loginError.classList.remove('show');
    const password = document.getElementById('admin-password').value;

    try {
      const res = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      });
      const data = await res.json();
      if (!res.ok || !data.ok) throw new Error(data.error || '로그인에 실패했습니다.');
      document.getElementById('admin-password').value = '';
      await loadDashboard();
    } catch (err) {
      loginError.textContent = err.message;
      loginError.classList.add('show');
    }
  });

  logoutBtn.addEventListener('click', async () => {
    await fetch('/api/admin/logout', { method: 'POST' });
    showLogin();
  });

  tbody.addEventListener('click', async (e) => {
    const btn = e.target.closest('.status-toggle-btn');
    if (!btn) return;

    const tr = btn.closest('tr');
    const id = tr.dataset.id;
    const nextStatus = btn.dataset.status;

    btn.disabled = true;
    try {
      const res = await fetch('/api/admin/update-status', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status: nextStatus }),
      });
      const data = await res.json();
      if (!res.ok || !data.ok) throw new Error(data.error || '업데이트 실패');

      const row = currentRows.find((r) => String(r.id) === String(id));
      if (row) row.status = nextStatus;
      renderStats(currentRows);
      renderRows(currentRows);
    } catch (err) {
      btn.disabled = false;
      alert(err.message);
    }
  });

  loadDashboard();
});
