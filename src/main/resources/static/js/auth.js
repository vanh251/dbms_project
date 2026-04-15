// =============================================
// auth.js - Login and Register logic
// (Compatible with ApiResponse wrapper from backend)
// =============================================

document.addEventListener('DOMContentLoaded', () => {
    // --- Redirect if already logged in ---
    if (isLoggedIn()) {
        window.location.href = 'index.html';
        return;
    }

    // ---- LOGIN FORM ----
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAlert();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value;
            const btn = loginForm.querySelector('button[type=submit]');

            btn.disabled = true;
            btn.textContent = 'Đang đăng nhập...';

            try {
                // apiFetch now returns AuthResponse directly (data field unwrapped)
                const data = await apiFetch('/api/auth/login', {
                    method: 'POST',
                    body: JSON.stringify({ email, password })
                });
                if (data && data.token) {
                    localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data));
                    window.location.href = data.groupId === 1 ? 'admin.html' : 'index.html';
                }
            } catch (err) {
                showAlert(err.message || 'Đăng nhập thất bại.', 'error');
            } finally {
                btn.disabled = false;
                btn.textContent = 'Đăng nhập';
            }
        });
    }

    // ---- REGISTER FORM ----
    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAlert();
            const fullname = document.getElementById('fullname').value.trim();
            const email = document.getElementById('email').value.trim();
            const phone = document.getElementById('phone').value.trim();
            const password = document.getElementById('password').value;
            const confirm = document.getElementById('confirm').value;
            const btn = registerForm.querySelector('button[type=submit]');

            if (password !== confirm) {
                showAlert('Mật khẩu xác nhận không khớp.', 'error');
                return;
            }
            if (password.length < 6) {
                showAlert('Mật khẩu phải có ít nhất 6 ký tự.', 'error');
                return;
            }

            btn.disabled = true;
            btn.textContent = 'Đang tạo tài khoản...';

            try {
                const data = await apiFetch('/api/auth/register', {
                    method: 'POST',
                    body: JSON.stringify({ fullname, email, phone, password })
                });
                if (data && data.token) {
                    localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data));
                    showAlert('Đăng ký thành công! Đang chuyển hướng...', 'success');
                    setTimeout(() => { window.location.href = 'index.html'; }, 1200);
                }
            } catch (err) {
                showAlert(err.message || 'Đăng ký thất bại. Email có thể đã tồn tại.', 'error');
            } finally {
                btn.disabled = false;
                btn.textContent = 'Tạo tài khoản';
            }
        });
    }
});

function showAlert(msg, type) {
    const el = document.getElementById('alertBox');
    if (!el) return;
    el.className = `alert alert-${type}`;
    el.textContent = msg;
    el.style.display = 'block';
}

function clearAlert() {
    const el = document.getElementById('alertBox');
    if (el) el.style.display = 'none';
}
