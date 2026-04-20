// =============================================
// api.js - Core fetch wrapper with JWT support
// =============================================

// When served from Spring Boot (localhost:8080), use relative path.
// For standalone file:// access, change to: const BASE_URL = 'http://localhost:8080';
const BASE_URL = '';

/**
 * Authenticated fetch wrapper.
 * - Automatically attaches Authorization: Bearer <token> from localStorage
 * - On 401: redirects to login.html
 * - Unwraps ApiResponse { success, message, data } and returns data directly
 * - On success=false: throws an error with the message
 */
async function apiFetch(path, options = {}) {
    const token = localStorage.getItem('token');
    const headers = {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...(options.headers || {})
    };

    const response = await fetch(`${BASE_URL}${path}`, {
        ...options,
        headers
    });

    if (response.status === 401) {
        localStorage.clear();
        window.location.href = 'login.html';
        return null;
    }

    if (response.status === 204 || response.headers.get('content-length') === '0') {
        return null;
    }

    const text = await response.text();
    let parsed;
    try {
        parsed = JSON.parse(text);
    } catch {
        return text;
    }

    // Unwrap ApiResponse wrapper
    if (parsed !== null && typeof parsed === 'object' && 'success' in parsed) {
        if (!parsed.success) {
            throw new Error(parsed.message || 'Yêu cầu thất bại');
        }
        return parsed.data !== undefined ? parsed.data : parsed;
    }

    return parsed;
}

/**
 * Helper: Check if current user is logged in
 */
function isLoggedIn() {
    return !!localStorage.getItem('token');
}

/**
 * Helper: Get stored user info
 */
function getUser() {
    try {
        return JSON.parse(localStorage.getItem('user') || 'null');
    } catch {
        return null;
    }
}

/**
 * Helper: Check if user is admin (group_id === 1)
 */
function isAdmin() {
    const user = getUser();
    return user && user.groupId === 1;
}

/**
 * Helper: Logout
 */
function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'login.html';
}

// =============================================
// TOAST NOTIFICATION SYSTEM
// =============================================

/**
 * Show custom toast notification
 */
function showToast(message, type = 'info') {
    let container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = `custom-toast ${type}`;

    const msgSpan = document.createElement('span');
    msgSpan.textContent = message;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'custom-toast-close';
    closeBtn.innerHTML = '&times;';
    closeBtn.onclick = () => removeToast(toast);

    toast.appendChild(msgSpan);
    toast.appendChild(closeBtn);
    container.appendChild(toast);

    // Auto remove
    setTimeout(() => {
        removeToast(toast);
    }, 5000);
}

function removeToast(toast) {
    if (toast.classList.contains('fadeOut')) return;
    toast.classList.add('fadeOut');
    setTimeout(() => {
        if (toast.parentNode) {
            toast.parentNode.removeChild(toast);
        }
    }, 300);
}

/**
 * Override default window.alert globally
 */
window.alert = function(msg) {
    let type = 'info';
    let textStr = String(msg).toLowerCase();

    // Simple heuristic to determine toast type
    if (textStr.includes('thành công') || textStr.includes('đã thêm') || textStr.includes('đã cập nhật')) type = 'success';
    if (textStr.includes('lỗi') || textStr.includes('thất bại') || textStr.includes('không')) type = 'error';
    if (textStr.includes('cảnh báo')) type = 'warning';

    showToast(msg, type);
};