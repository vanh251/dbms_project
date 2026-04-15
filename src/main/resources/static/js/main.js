// =============================================
// main.js - Homepage and Course detail logic
// =============================================

document.addEventListener('DOMContentLoaded', () => {
    updateNavbar();

    // Homepage: load course list
    const courseGrid = document.getElementById('courseGrid');
    if (courseGrid) {
        loadCourses(courseGrid);
    }

    // My courses section
    const myCoursesGrid = document.getElementById('myCoursesGrid');
    if (myCoursesGrid && isLoggedIn()) {
        loadMyCourses(myCoursesGrid);
    }

    // Course detail page
    const courseDetailEl = document.getElementById('courseDetail');
    if (courseDetailEl) {
        const params = new URLSearchParams(window.location.search);
        const id = params.get('id');
        if (id) loadCourseDetail(id);
    }
});

// ---- Navbar ----
function updateNavbar() {
    const navAuth = document.getElementById('navAuth');
    if (!navAuth) return;
    const user = getUser();
    if (user) {
        navAuth.innerHTML = `
            <span style="font-weight:600;color:#4f46e5">👤 ${user.fullname}</span>
            ${user.groupId === 1 ? `<a href="admin.html" class="btn btn-sm btn-outline">Admin</a>` : ''}
            <button class="btn btn-sm btn-danger" onclick="logout()">Đăng xuất</button>
        `;
    } else {
        navAuth.innerHTML = `
            <a href="login.html" class="btn btn-sm btn-outline">Đăng nhập</a>
            <a href="register.html" class="btn btn-sm btn-primary">Đăng ký</a>
        `;
    }
}

// ---- Course List ----
async function loadCourses(container) {
    container.innerHTML = '<div class="loading-wrap"><div class="spinner"></div></div>';
    const courses = await apiFetch('/api/client/courses');
    if (!courses || courses.length === 0) {
        container.innerHTML = '<p style="color:#64748b;text-align:center;padding:2rem">Không có khóa học nào.</p>';
        return;
    }
    container.innerHTML = courses.map(c => courseCardHTML(c)).join('');
}

async function loadMyCourses(container) {
    container.innerHTML = '<div class="loading-wrap"><div class="spinner"></div></div>';
    try {
        const courses = await apiFetch('/api/client/my-courses');
        if (!courses || courses.length === 0) {
            container.innerHTML = '<p style="color:#64748b;text-align:center;padding:2rem">Bạn chưa được cấp quyền truy cập khóa học nào.</p>';
            return;
        }
        container.innerHTML = courses.map(c => courseCardHTML(c)).join('');
    } catch {
        container.innerHTML = '<p style="color:#ef4444;text-align:center;padding:2rem">Vui lòng đăng nhập để xem khóa học của bạn.</p>';
    }
}

function courseCardHTML(c) {
    const emoji = ['📚', '🎯', '💻', '🚀', '🎨', '🔬', '🧮', '🌐'][c.id % 8];
    return `
    <div class="course-card" onclick="window.location.href='course.html?id=${c.id}'">
        <div class="card-thumb">${emoji}</div>
        <div class="card-body">
            <div class="card-category">${c.categoryName || 'Khóa học'}</div>
            <div class="card-title">${c.name}</div>
            <div class="card-desc">${c.description || ''}</div>
            <div class="card-meta">
                <span>📖 ${c.totalLession || 0} bài</span>
                <span>🗂 ${c.totalPart || 0} chương</span>
                ${c.totalTime ? `<span>⏱ ${c.totalTime}</span>` : ''}
            </div>
        </div>
        <div class="card-footer">
            <div>
                <span class="price">${c.price || 'Miễn phí'}</span>
                ${c.oldPrice ? `<span class="old-price">${c.oldPrice}</span>` : ''}
            </div>
            <button class="btn btn-sm btn-primary">Xem ngay</button>
        </div>
    </div>`;
}

// ---- Course Detail ----
async function loadCourseDetail(id) {
    const mainArea = document.getElementById('courseDetail');
    const sidebarArea = document.getElementById('courseSidebar');
    mainArea.innerHTML = '<div class="loading-wrap"><div class="spinner"></div></div>';

    const course = await apiFetch(`/api/client/courses/${id}`);
    if (!course) {
        mainArea.innerHTML = '<p>Không tìm thấy khóa học.</p>';
        return;
    }

    document.title = course.name + ' | LearnHub';

    // Sidebar
    if (sidebarArea) {
        const emoji = ['📚', '🎯', '💻', '🚀', '🎨', '🔬', '🧮', '🌐'][course.id % 8];
        sidebarArea.innerHTML = `
            <div class="thumb">${emoji}</div>
            <div class="price-block">
                <span class="current">${course.price || 'Miễn phí'}</span>
                ${course.oldPrice ? `<span class="original">${course.oldPrice}</span>` : ''}
            </div>
            <div class="course-stats">
                <div class="stat-item"><div class="stat-value">${course.totalLession || 0}</div><div class="stat-label">Bài học</div></div>
                <div class="stat-item"><div class="stat-value">${course.totalPart || 0}</div><div class="stat-label">Chương</div></div>
                <div class="stat-item"><div class="stat-value">${course.totalTime || 'N/A'}</div><div class="stat-label">Thời lượng</div></div>
                <div class="stat-item"><div class="stat-value">🌐</div><div class="stat-label">Online</div></div>
            </div>
            <button class="btn btn-primary btn-block" onclick="handleEnroll(${course.id})">
                ${isLoggedIn() ? '🚀 Học ngay' : '🔑 Đăng nhập để học'}
            </button>
        `;
    }

    // Main: Tabs
    mainArea.innerHTML = `
        <h1 class="course-title">${course.name}</h1>
        <p class="course-desc">${course.description || ''}</p>
        <div class="course-tags">
            ${course.categoryName ? `<span class="tag">📂 ${course.categoryName}</span>` : ''}
            ${course.require ? `<span class="tag">📋 ${course.require}</span>` : ''}
        </div>

        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('curriculum')">📖 Nội dung</button>
            <button class="tab-btn" onclick="switchTab('learn')">▶️ Học</button>
        </div>

        <div id="tab-curriculum" class="tab-content active">
            <div class="curriculum" id="curriculumContent">
                ${renderCurriculum(course.parts || [], id)}
            </div>
        </div>

        <div id="tab-learn" class="tab-content">
            <div id="lessonPlayer" class="lesson-player">
                <div class="placeholder">👆 Chọn bài học từ danh sách bên trái để bắt đầu học.</div>
            </div>
            <div id="lessonInfo"></div>
            <div class="comments-section" id="commentsSection" style="display:none">
                <h3>💬 Bình luận</h3>
                <div class="comment-form" id="commentForm" style="${isLoggedIn() ? '' : 'display:none'}">
                    <input type="text" id="commentInput" placeholder="Viết bình luận...">
                    <button class="btn btn-primary btn-sm" onclick="postComment()">Gửi</button>
                </div>
                <div id="commentsList"></div>
            </div>
        </div>
    `;
}

function renderCurriculum(parts, courseId) {
    if (!parts || parts.length === 0) return '<p style="color:#64748b">Chưa có nội dung.</p>';
    return parts.map(p => `
        <div class="part-header">
            <span>📁 ${p.name}</span>
            <span style="color:#64748b;font-size:0.85rem">${(p.lessons || []).length} bài</span>
        </div>
        <div class="lesson-list">
            ${(p.lessons || []).map(l => `
                <div class="lesson-item" id="lesson-${l.id}" onclick="loadLesson(${l.id})">
                    <div class="lesson-icon">▶</div>
                    <span>${l.name}</span>
                    ${l.length ? `<span class="lesson-len">${l.length}</span>` : ''}
                </div>
            `).join('')}
        </div>
    `).join('');
}

let currentLessonId = null;
async function loadLesson(lessonId) {
    if (!isLoggedIn()) {
        window.location.href = 'login.html';
        return;
    }
    switchTab('learn');

    // Highlight active
    document.querySelectorAll('.lesson-item').forEach(el => el.classList.remove('active'));
    const activeEl = document.getElementById(`lesson-${lessonId}`);
    if (activeEl) activeEl.classList.add('active');

    const player = document.getElementById('lessonPlayer');
    player.innerHTML = '<div class="loading-wrap"><div class="spinner"></div></div>';

    const lesson = await apiFetch(`/api/client/lessons/${lessonId}`);
    currentLessonId = lessonId;

    if (!lesson) {
        player.innerHTML = '<div class="placeholder">❌ Không thể tải bài học.</div>';
        return;
    }

    const lessonInfo = document.getElementById('lessonInfo');
    lessonInfo.innerHTML = `<h2 style="margin-bottom:0.5rem">${lesson.name}</h2>${lesson.description ? `<p style="color:#64748b;margin-bottom:1rem">${lesson.description}</p>` : ''}`;

    if (!lesson.value) {
        player.innerHTML = `<div class="placeholder">🔒 Bạn chưa được cấp quyền xem bài học này. Liên hệ Admin để được kích hoạt.</div>`;
    } else if (lesson.value.includes('youtube.com') || lesson.value.includes('youtu.be')) {
        const videoId = extractYouTubeId(lesson.value);
        player.innerHTML = `<iframe src="https://www.youtube.com/embed/${videoId}" allowfullscreen></iframe>`;
    } else if (lesson.value.startsWith('http')) {
        player.innerHTML = `<iframe src="${lesson.value}" allowfullscreen></iframe>`;
    } else {
        player.innerHTML = `<div style="padding:2rem;text-align:left;color:#fff;max-width:700px;margin:0 auto;white-space:pre-wrap">${lesson.value}</div>`;
    }

    // Load comments
    const commentsSection = document.getElementById('commentsSection');
    commentsSection.style.display = 'block';
    loadComments(lessonId);
}

async function loadComments(lessonId) {
    const list = document.getElementById('commentsList');
    list.innerHTML = '<div class="spinner"></div>';
    const comments = await apiFetch(`/api/client/lessons/${lessonId}/comments`);
    if (!comments || comments.length === 0) {
        list.innerHTML = '<p style="color:#64748b;padding:1rem 0">Chưa có bình luận nào.</p>';
        return;
    }
    list.innerHTML = comments.map(c => `
        <div class="comment-item">
            <div class="comment-avatar">${c.userFullname ? c.userFullname[0].toUpperCase() : '?'}</div>
            <div class="comment-body">
                <div class="name">${c.userFullname}</div>
                <div class="text">${c.content}</div>
                <div class="time">${formatDate(c.createAt)}</div>
            </div>
        </div>
    `).join('');
}

async function postComment() {
    const input = document.getElementById('commentInput');
    const content = input.value.trim();
    if (!content || !currentLessonId) return;
    input.value = '';
    await apiFetch(`/api/client/lessons/${currentLessonId}/comments`, {
        method: 'POST',
        body: JSON.stringify({ content })
    });
    loadComments(currentLessonId);
}

function switchTab(tabName) {
    document.querySelectorAll('.tab-btn').forEach((btn, i) => {
        const names = ['curriculum', 'learn'];
        btn.classList.toggle('active', names[i] === tabName);
    });
    document.querySelectorAll('.tab-content').forEach(tc => tc.classList.remove('active'));
    const target = document.getElementById(`tab-${tabName}`);
    if (target) target.classList.add('active');
}

function handleEnroll(courseId) {
    if (!isLoggedIn()) {
        window.location.href = 'login.html';
    }
    // If already has permission, start learning
    switchTab('learn');
}

function extractYouTubeId(url) {
    const match = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\s]+)/);
    return match ? match[1] : '';
}

function formatDate(isoString) {
    if (!isoString) return '';
    const d = new Date(isoString);
    return d.toLocaleDateString('vi-VN') + ' ' + d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
}
