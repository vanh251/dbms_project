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
