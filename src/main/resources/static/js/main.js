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

    // My payments section
    const myPaymentsTable = document.getElementById('myPaymentsTable');
    if (myPaymentsTable && isLoggedIn()) {
        loadMyPayments();
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
        const navLinks = document.querySelector('.nav-links');
        if (navLinks) {
            navLinks.insertAdjacentHTML('beforeend', `
                <a href="my-courses.html" class="hide-mobile">Khóa học của tôi</a>
                <a href="history.html" class="hide-mobile">Lịch sử giao dịch</a>
            `);
        }
        navAuth.innerHTML = `
            <span style="font-weight:600;color:var(--primary);margin-left:0.5rem;margin-right:0.5rem">${user.fullname}</span>
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
        container.innerHTML = `
            <div class="empty-state">
                <h3>Chưa có khóa học nào</h3>
                <p>Vui lòng quay lại sau.</p>
            </div>`;
        return;
    }
    container.innerHTML = courses.map(c => courseCardHTML(c)).join('');
}

async function loadMyCourses(container) {
    container.innerHTML = '<div class="loading-wrap"><div class="spinner"></div></div>';
    try {
        const courses = await apiFetch('/api/client/my-courses');
        if (!courses || courses.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>Chưa có khóa học nào</h3>
                    <p>Bạn chưa được cấp quyền truy cập khóa học nào.</p>
                </div>`;
            return;
        }
        container.innerHTML = courses.map(c => courseCardHTML(c)).join('');
    } catch {
        container.innerHTML = '<p style="color:#dc2626;text-align:center;padding:2rem">Vui lòng đăng nhập để xem khóa học của bạn.</p>';
    }
}

function courseCardHTML(c) {
    const label = (c.categoryName || 'Khóa học').toUpperCase().slice(0, 12);
    const thumbContent = c.thumbnail
        ? `<img src="${c.thumbnail}" alt="${c.name}" style="width:100%;height:100%;object-fit:cover" onerror="this.parentElement.innerHTML='<span class=\'card-thumb-placeholder\'>${label}</span>'">`
        : `<span class="card-thumb-placeholder">${label}</span>`;
    return `
    <div class="course-card" onclick="window.location.href='course.html?id=${c.id}'">
        <div class="card-thumb">
            ${thumbContent}
        </div>
        <div class="card-body">
            <div class="card-category">${c.categoryName || 'Khóa học'}</div>
            <div class="card-title">${c.name}</div>
            <div class="card-desc">${c.description || ''}</div>
            <div class="card-meta">
                <span>${c.totalLession || 0} bài học</span>
                <span>${c.totalPart || 0} chương</span>
                ${c.totalTime ? `<span>${c.totalTime}</span>` : ''}
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

    const myCourses = isLoggedIn() ? await apiFetch('/api/client/my-courses').catch(() => []) : [];
    const isEnrolled = (myCourses || []).some(c => c.id === course.id);

    // Sidebar
    if (sidebarArea) {
        const label = (course.categoryName || 'Khóa học').toUpperCase().slice(0, 12);
        const thumbHtml = course.thumbnail
            ? `<img src="${course.thumbnail}" alt="${course.name}" style="width:100%;height:200px;object-fit:cover;border-radius:var(--radius);margin-bottom:1.25rem" onerror="this.outerHTML='<div class=\'thumb\'><span style=\'font-size:0.85rem;font-weight:700;color:#2563eb;text-transform:uppercase\'>${label}</span></div>'">`
            : `<div class="thumb"><span style="font-size:0.85rem;font-weight:700;color:#2563eb;text-transform:uppercase;letter-spacing:0.5px">${label}</span></div>`;
        const btnHtml = isEnrolled
            ? `<button class="btn btn-primary btn-block" onclick="switchTab('learn')">Học ngay</button>`
            : `<button class="btn btn-primary btn-block" onclick="handleEnroll(${course.id}, '${course.name}', '${course.price}')">
                ${isLoggedIn() ? 'Mua khóa học' : 'Đăng nhập để mua'}
               </button>`;

        sidebarArea.innerHTML = `
            ${thumbHtml}
            <div class="price-block">
                <span class="current">${course.price || 'Miễn phí'}</span>
                ${course.oldPrice ? `<span class="original">${course.oldPrice}</span>` : ''}
            </div>
            <div class="course-stats">
                <div class="stat-item"><div class="stat-value">${course.totalLession || 0}</div><div class="stat-label">Bài học</div></div>
                <div class="stat-item"><div class="stat-value">${course.totalPart || 0}</div><div class="stat-label">Chương</div></div>
                <div class="stat-item"><div class="stat-value">${course.totalTime || 'N/A'}</div><div class="stat-label">Thời lượng</div></div>
                <div class="stat-item"><div class="stat-value">Online</div><div class="stat-label">Hình thức</div></div>
            </div>
            ${btnHtml}
        `;
    }

    // Main: Tabs
    mainArea.innerHTML = `
        <h1 class="course-title">${course.name}</h1>
        <p class="course-desc">${course.description || ''}</p>
        <div class="course-tags">
            ${course.categoryName ? `<span class="tag">${course.categoryName}</span>` : ''}
            ${course.require ? `<span class="tag">${course.require}</span>` : ''}
        </div>

        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('curriculum')">Nội dung khóa học</button>
            <button class="tab-btn" onclick="switchTab('learn')">Học bài</button>
        </div>

        <div id="tab-curriculum" class="tab-content active">
            <div class="curriculum" id="curriculumContent">
                ${renderCurriculum(course.parts || [], id)}
            </div>
        </div>

        <div id="tab-learn" class="tab-content">
            <div id="lessonPlayer" class="lesson-player">
                <div class="placeholder">Chọn bài học từ tab "Nội dung khóa học" để bắt đầu.</div>
            </div>
            <div id="lessonInfo"></div>
            <div class="comments-section" id="commentsSection" style="display:none">
                <h3>Bình luận</h3>
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
    if (!parts || parts.length === 0) return '<p style="color:var(--text-muted)">Chưa có nội dung.</p>';
    return parts.map(p => `
        <div class="part-header">
            <span>${p.name}</span>
            <span style="color:var(--text-muted);font-size:0.82rem;font-weight:500">${(p.lessons || []).length} bài học</span>
        </div>
        <div class="lesson-list">
            ${(p.lessons || []).map((l, idx) => `
                <div class="lesson-item" id="lesson-${l.id}" onclick="loadLesson(${l.id})">
                    <div class="lesson-icon">${idx + 1}</div>
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
        player.innerHTML = '<div class="placeholder">Không thể tải bài học. Vui lòng thử lại.</div>';
        return;
    }

    const lessonInfo = document.getElementById('lessonInfo');
    lessonInfo.innerHTML = `<h2 style="margin-bottom:0.5rem;margin-top:1rem;font-size:1.4rem;color:var(--text)">${lesson.name}</h2>${lesson.description ? `<p style="color:var(--text-secondary);margin-bottom:1rem">${lesson.description}</p>` : ''}`;

    if (!lesson.value) {
        player.innerHTML = `<div class="placeholder">Bạn chưa được cấp quyền xem bài học này. Vui lòng liên hệ Admin để được kích hoạt.</div>`;
    } else if (lesson.value.includes('youtube.com') || lesson.value.includes('youtu.be')) {
        const videoId = extractYouTubeId(lesson.value);
        player.innerHTML = `<iframe src="https://www.youtube.com/embed/${videoId}" allowfullscreen></iframe>`;
    } else if (lesson.value.startsWith('http')) {
        player.innerHTML = `<iframe src="${lesson.value}" allowfullscreen></iframe>`;
    } else {
        player.innerHTML = `<div style="padding:2rem;text-align:left;color:var(--text);max-width:700px;margin:0 auto;white-space:pre-wrap;line-height:1.7">${lesson.value}</div>`;
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
        list.innerHTML = '<p style="color:var(--text-muted);padding:1rem 0">Chưa có bình luận nào.</p>';
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

function handleEnroll(courseId, courseName, price) {
    if (!isLoggedIn()) {
        window.location.href = 'login.html';
        return;
    }
    openBuyModal(courseId, courseName, price);
}

// =============================================================
// PAYMENTS (Client) - VietQR Integration
// =============================================================
function openBuyModal(courseId, courseName, price) {
    const modal = document.getElementById('buyModalOverlay');
    const body = document.getElementById('buyModalBody');
    if (!modal) return;

    let amountStr = String(price || '0').replace(/[^0-9]/g, '');
    let amountNum = parseInt(amountStr) || 0;
    let isFree = amountNum === 0;

    const bankBin = '970407'; // MBBank
    const accountNo = '19037247346017';
    const accountName = 'NGUYEN VIET ANH';
    const addInfo = encodeURIComponent(`Thanh toan khoa hoc ${courseId}`);
    const vietQrUrl = `https://img.vietqr.io/image/${bankBin}-${accountNo}-compact.png?amount=${amountNum}&addInfo=${addInfo}&accountName=${encodeURIComponent(accountName)}`;

    body.innerHTML = `
        <p style="margin-bottom:0.75rem;color:var(--text-secondary)">Khóa học: <strong style="color:var(--text)">${courseName}</strong></p>
        <p style="margin-bottom:1.25rem;color:var(--text-secondary)">Số tiền: <strong style="color:var(--success)">${price || 'Miễn phí'}</strong></p>

        ${!isFree ? `
        <div class="form-group">
            <label>Phương thức thanh toán</label>
            <select id="pm-method" onchange="toggleVietQR()">
                <option value="VietQR">Chuyển khoản VietQR (Khuyên dùng)</option>
                <option value="VNPay">Ví VNPay</option>
                <option value="Momo">Ví Momo</option>
                <option value="Chuyển khoản ngân hàng">Chuyển khoản thủ công</option>
            </select>
        </div>

        <div id="vietQrBox" style="text-align:center;margin-top:1.25rem;padding:1rem;border:1px solid #e2e8f0;border-radius:8px;background:#f8fafc">
            <p style="font-size:0.85rem;color:#64748b;margin-bottom:0.75rem">Mở ứng dụng ngân hàng để quét mã QR</p>
            <img src="${vietQrUrl}" alt="VietQR" style="max-width:100%;height:auto;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
            <p style="font-size:0.82rem;color:#dc2626;margin-top:0.75rem">Vui lòng quét QR chuyển khoản trước khi nhấn xác nhận.</p>
        </div>
        ` : `
        <div class="form-group" style="display:none">
            <select id="pm-method"><option value="Miễn phí">Miễn phí</option></select>
        </div>
        <p style="color:#16a34a;font-weight:700;margin-bottom:1rem">Khóa học này miễn phí!</p>
        `}

        <button class="btn btn-primary btn-block" style="margin-top:1.25rem" onclick="submitBuyCourse(${courseId})">
            ${isFree ? 'Nhận khóa học miễn phí' : 'Xác nhận tạo đơn'}
        </button>
    `;
    modal.classList.add('open');
}

window.toggleVietQR = function() {
    const method = document.getElementById('pm-method').value;
    const qrBox = document.getElementById('vietQrBox');
    if (qrBox) {
        qrBox.style.display = (method === 'VietQR') ? 'block' : 'none';
    }
};

function closeBuyModal() {
    const modal = document.getElementById('buyModalOverlay');
    if (modal) modal.classList.remove('open');
}

async function submitBuyCourse(courseId) {
    const method = document.getElementById('pm-method').value;
    const btn = document.querySelector('#buyModalBody button.btn-primary');

    if (btn) {
        btn.disabled = true;
        btn.textContent = 'Đang xử lý...';
    }

    try {
        const res = await apiFetch(`/api/client/courses/${courseId}/buy`, {
            method: 'POST',
            body: JSON.stringify({ paymentMethod: method })
        });

        if (res && res.id) {
            showToast('Đã tạo đơn hàng thành công! Vui lòng chờ Admin duyệt.', 'success');
            closeBuyModal();
            setTimeout(() => { window.location.href = 'index.html'; }, 1500);
        } else {
            showToast('Có lỗi xảy ra, không thể tạo đơn hàng.', 'error');
        }
    } catch (err) {
        showToast(err.message || 'Đã xảy ra lỗi hệ thống.', 'error');
    } finally {
        if (btn) {
            btn.disabled = false;
            const isFree = method === 'Miễn phí';
            btn.textContent = isFree ? 'Nhận khóa học miễn phí' : 'Xác nhận tạo đơn';
        }
    }
}

async function loadMyPayments() {
    const tbody = document.getElementById('myPaymentsTable');
    if (!tbody) return;

    try {
        const payments = await apiFetch('/api/client/my-payments');
        if (!payments || payments.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:1.5rem;color:#64748b">Bạn chưa có giao dịch nào.</td></tr>';
            return;
        }
        tbody.innerHTML = payments.map(p => `
            <tr>
                <td>#${p.id}</td>
                <td style="font-weight:600;color:var(--text)">${p.courseName}</td>
                <td style="color:var(--success);font-weight:700">${p.amount ? p.amount + 'đ' : 'Miễn phí'}</td>
                <td>${p.paymentMethod}</td>
                <td><span class="badge badge-${p.status === 1 ? 'active' : 'inactive'}">${p.status === 1 ? 'Hoàn thành' : 'Chờ duyệt'}</span></td>
                <td>${p.transactionId || '—'}</td>
                <td>${formatDate(p.createAt)}</td>
            </tr>
        `).join('');
    } catch {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:1.5rem;color:#dc2626">Lỗi khi tải lịch sử giao dịch.</td></tr>';
    }
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