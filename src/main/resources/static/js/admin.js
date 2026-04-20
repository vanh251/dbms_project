// =============================================
// admin.js - Admin panel logic
// =============================================

document.addEventListener('DOMContentLoaded', () => {
    // Guard: must be logged in as admin
    if (!isLoggedIn()) { window.location.href = 'login.html'; return; }
    const user = getUser();
    if (!user || user.groupId !== 1) {
        showToast('Bạn không có quyền truy cập trang này.', 'error');
        setTimeout(() => { window.location.href = 'index.html'; }, 1500);
        return;
    }

    document.getElementById('adminUsername').textContent = user.fullname;
    showSection('courses');
    loadAdminCourses();
});

// --- Section Navigation ---
function showSection(name) {
    document.querySelectorAll('.admin-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
    document.getElementById('section-' + name).classList.add('active');
    const link = document.querySelector(`[data-section="${name}"]`);
    if (link) link.classList.add('active');

    if (name === 'courses') loadAdminCourses();
    if (name === 'users') loadAdminUsers();
    if (name === 'categories') loadAdminCategories();
    if (name === 'payments') loadAdminPayments();
}

// =============================================================
// COURSES
// =============================================================
async function loadAdminCourses() {
    const tbody = document.getElementById('coursesTable');
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center"><div class="spinner" style="margin:1rem auto"></div></td></tr>';
    const courses = await apiFetch('/api/admin/courses');
    if (!courses || courses.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:#64748b">Không có khóa học</td></tr>';
        return;
    }
    tbody.innerHTML = courses.map(c => `
        <tr>
            <td>${c.id}</td>
            <td style="font-weight:600">${c.name}</td>
            <td>${c.categoryName || '-'}</td>
            <td>${c.price || 'Miễn phí'}</td>
            <td><span class="badge badge-${c.status === 1 ? 'active' : 'inactive'}">${c.status === 1 ? 'Hoạt động' : 'Ẩn'}</span></td>
            <td>
                <button class="btn btn-sm btn-outline" onclick="openEditCourse(${c.id})">Sửa</button>
                <button class="btn btn-sm btn-danger" onclick="deleteCourse(${c.id},'${c.name}')">Xóa</button>
                <button class="btn btn-sm btn-secondary" onclick="openPartModal(${c.id},'${c.name}')">Chương</button>
            </td>
        </tr>
    `).join('');
}

async function openCreateCourse() {
    const cats = await apiFetch('/api/admin/categories');
    const catOptions = (cats || []).map(c => `<option value="${c.id}">${c.name}</option>`).join('');
    showModal('Thêm khóa học mới', `
        <div class="form-group"><label>Tên khóa học *</label><input type="text" id="fc-name" placeholder="VD: Lập trình Java cơ bản"></div>
        <div class="form-group"><label>Slug</label><input type="text" id="fc-slug" placeholder="lap-trinh-java"></div>
        <div class="form-group">
            <label>URL ảnh bìa (Thumbnail)</label>
            <input type="url" id="fc-thumbnail" placeholder="https://..." oninput="previewThumb('fc-thumbnail','fc-thumb-preview')">
            <div id="fc-thumb-preview" style="margin-top:0.6rem;display:none">
                <img src="" alt="Preview" style="width:100%;border-radius:8px;border:1px solid var(--border);max-height:180px;object-fit:cover">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Giá</label><input type="text" id="fc-price" placeholder="499.000đ"></div>
            <div class="form-group"><label>Giá gốc</label><input type="text" id="fc-oldprice" placeholder="999.000đ"></div>
        </div>
        <div class="form-group"><label>Mô tả</label><textarea id="fc-desc"></textarea></div>
        <div class="form-group"><label>Yêu cầu</label><input type="text" id="fc-require"></div>
        <div class="form-row">
            <div class="form-group"><label>Thời lượng</label><input type="text" id="fc-time" placeholder="20 giờ"></div>
            <div class="form-group"><label>Trạng thái</label>
                <select id="fc-status"><option value="0">Ẩn</option><option value="1">Hiển thị</option></select>
            </div>
        </div>
        <div class="form-group"><label>Danh mục</label><select id="fc-cat"><option value="">-- Chọn --</option>${catOptions}</select></div>
        <button class="btn btn-primary btn-block" onclick="submitCreateCourse()">Tạo khóa học</button>
    `);
}

async function submitCreateCourse() {
    const body = {
        name: document.getElementById('fc-name').value.trim(),
        slug: document.getElementById('fc-slug').value.trim(),
        thumbnail: document.getElementById('fc-thumbnail').value.trim(),
        price: document.getElementById('fc-price').value.trim(),
        oldPrice: document.getElementById('fc-oldprice').value.trim(),
        description: document.getElementById('fc-desc').value.trim(),
        require: document.getElementById('fc-require').value.trim(),
        totalTime: document.getElementById('fc-time').value.trim(),
        status: parseInt(document.getElementById('fc-status').value),
        categoryId: document.getElementById('fc-cat').value ? parseInt(document.getElementById('fc-cat').value) : null
    };
    if (!body.name) { showToast('Tên khóa học không được để trống', 'warning'); return; }
    await apiFetch('/api/admin/courses', { method: 'POST', body: JSON.stringify(body) });
    closeModal();
    loadAdminCourses();
}

async function openEditCourse(id) {
    const courses = await apiFetch('/api/admin/courses');
    const course = (courses || []).find(c => c.id === id);
    const cats = await apiFetch('/api/admin/categories');
    const catOptions = (cats || []).map(c => `<option value="${c.id}">${c.name}</option>`).join('');
    if (!course) return;
    showModal(`Sửa khóa học #${id}`, `
        <div class="form-group"><label>Tên khóa học *</label><input id="ec-name" value="${course.name || ''}"></div>
        <div class="form-group"><label>Slug</label><input id="ec-slug" value="${course.slug || ''}"></div>
        <div class="form-group">
            <label>URL ảnh bìa (Thumbnail)</label>
            <input type="url" id="ec-thumbnail" value="${course.thumbnail || ''}" placeholder="https://..." oninput="previewThumb('ec-thumbnail','ec-thumb-preview')">
            <div id="ec-thumb-preview" style="margin-top:0.6rem;display:${course.thumbnail ? 'block' : 'none'}">
                <img src="${course.thumbnail || ''}" alt="Preview" style="width:100%;border-radius:8px;border:1px solid var(--border);max-height:180px;object-fit:cover">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Giá</label><input id="ec-price" value="${course.price || ''}"></div>
            <div class="form-group"><label>Giá gốc</label><input id="ec-oldprice" value="${course.oldPrice || ''}"></div>
        </div>
        <div class="form-group"><label>Mô tả</label><textarea id="ec-desc">${course.description || ''}</textarea></div>
        <div class="form-group"><label>Yêu cầu</label><input id="ec-require" value="${course.require || ''}"></div>
        <div class="form-row">
            <div class="form-group"><label>Thời lượng</label><input id="ec-time" value="${course.totalTime || ''}"></div>
            <div class="form-group"><label>Trạng thái</label>
                <select id="ec-status">
                    <option value="0" ${course.status === 0 ? 'selected' : ''}>Ẩn</option>
                    <option value="1" ${course.status === 1 ? 'selected' : ''}>Hiển thị</option>
                </select>
            </div>
        </div>
        <div class="form-group"><label>Danh mục</label><select id="ec-cat"><option value="">-- Chọn --</option>${catOptions}</select></div>
        <button class="btn btn-primary btn-block" onclick="submitEditCourse(${id})">Lưu thay đổi</button>
    `);
}

async function submitEditCourse(id) {
    const body = {
        name: document.getElementById('ec-name').value.trim(),
        slug: document.getElementById('ec-slug').value.trim(),
        thumbnail: document.getElementById('ec-thumbnail').value.trim(),
        price: document.getElementById('ec-price').value.trim(),
        oldPrice: document.getElementById('ec-oldprice').value.trim(),
        description: document.getElementById('ec-desc').value.trim(),
        require: document.getElementById('ec-require').value.trim(),
        totalTime: document.getElementById('ec-time').value.trim(),
        status: parseInt(document.getElementById('ec-status').value),
        categoryId: document.getElementById('ec-cat').value ? parseInt(document.getElementById('ec-cat').value) : null
    };
    await apiFetch(`/api/admin/courses/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    closeModal();
    loadAdminCourses();
}

async function deleteCourse(id, name) {
    showModal('Xác nhận xóa', `
        <p style="margin-bottom:1.5rem;color:var(--text)">Bạn chắc chắn muốn xóa khóa học "<strong>${name}</strong>"? Hành động này không thể hoàn tác.</p>
        <div style="display:flex;gap:0.5rem;justify-content:flex-end">
            <button class="btn btn-secondary" onclick="closeModal()">Hủy</button>
            <button class="btn btn-danger" onclick="submitDeleteCourse(${id})">Xóa</button>
        </div>
    `);
}

async function submitDeleteCourse(id) {
    await apiFetch(`/api/admin/courses/${id}`, { method: 'DELETE' });
    closeModal();
    loadAdminCourses();
}

// --- Part / Chapter ---
function openPartModal(courseId, courseName) {
    showModal(`Thêm chương – ${courseName}`, `
        <div class="form-group"><label>Tên chương</label><input id="part-name" placeholder="VD: Chương 1: Giới thiệu"></div>
        <button class="btn btn-primary btn-block" onclick="submitAddPart(${courseId})">Thêm chương</button>
        <hr style="margin:1.5rem 0">
        <div id="partLessonContent">
            <p style="color:#64748b;font-size:0.9rem">Sau khi thêm chương, dùng nút "Thêm bài" để thêm bài học.</p>
        </div>
    `);
}

async function submitAddPart(courseId) {
    const name = document.getElementById('part-name').value.trim();
    if (!name) { showToast('Tên chương không được để trống', 'warning'); return; }
    const result = await apiFetch(`/api/admin/courses/${courseId}/parts`, { method: 'POST', body: JSON.stringify({ name }) });
    if (result && result.id) {
        document.getElementById('part-name').value = '';
        document.getElementById('partLessonContent').innerHTML = `
            <p style="color:#22c55e;margin-bottom:1rem">Đã thêm chương "${result.name}" (ID: ${result.id})</p>
            <div class="form-group"><label>Tên bài học</label><input id="lesson-name" placeholder="VD: Bài 1: Hello World"></div>
            <div class="form-row">
                <div class="form-group"><label>Thời lượng</label><input id="lesson-len" placeholder="10:30"></div>
            </div>
            <div class="form-group"><label>Mô tả</label><textarea id="lesson-desc"></textarea></div>
            <div class="form-group"><label>Nội dung / URL Video</label><input id="lesson-value" placeholder="https://youtube.com/watch?v=... hoặc nội dung text"></div>
            <button class="btn btn-secondary btn-block" onclick="submitAddLesson(${result.id})">Thêm bài học</button>
        `;
        loadAdminCourses();
    }
}

async function submitAddLesson(partId) {
    const body = {
        name: document.getElementById('lesson-name').value.trim(),
        length: document.getElementById('lesson-len').value.trim(),
        description: document.getElementById('lesson-desc').value.trim(),
        value: document.getElementById('lesson-value').value.trim()
    };
    if (!body.name) { showToast('Tên bài học không được để trống', 'warning'); return; }
    const result = await apiFetch(`/api/admin/parts/${partId}/lessons`, { method: 'POST', body: JSON.stringify(body) });
    if (result && result.id) {
        showToast(`Đã thêm bài học "${result.name}"`, 'success');
        document.getElementById('lesson-name').value = '';
        document.getElementById('lesson-len').value = '';
        document.getElementById('lesson-desc').value = '';
        document.getElementById('lesson-value').value = '';
        loadAdminCourses();
    }
}

// =============================================================
// USERS & PERMISSIONS
// =============================================================
async function loadAdminUsers() {
    const tbody = document.getElementById('usersTable');
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center"><div class="spinner" style="margin:1rem auto"></div></td></tr>';
    const users = await apiFetch('/api/admin/users');
    if (!users || users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:#64748b">Không có người dùng</td></tr>';
        return;
    }
    tbody.innerHTML = users.map(u => `
        <tr>
            <td>${u.id}</td>
            <td style="font-weight:600">${u.fullname}</td>
            <td>${u.email}</td>
            <td><span class="badge badge-${u.groupId === 1 ? 'active' : 'inactive'}">${u.groupName || 'User'}</span></td>
            <td>
                <button class="btn btn-sm btn-outline" onclick="openUserCoursesModal(${u.id}, '${u.fullname}')">Xem khóa học</button>
            </td>
        </tr>
    `).join('');
}

async function openUserCoursesModal(userId, name) {
    showModal(`Khóa học của ${name}`, '<div style="text-align:center;padding:1rem"><div class="spinner"></div></div>');
    const courses = await apiFetch(`/api/admin/users/${userId}/courses`);
    let content;
    if (!courses || courses.length === 0) {
        content = '<p style="color:#64748b;text-align:center;padding:1rem">Người dùng này chưa ghi danh khóa học nào.</p>';
    } else {
        content = `
            <p style="color:#64748b;font-size:0.88rem;margin-bottom:0.8rem">Danh sách khóa học đã ghi danh (tự động cập nhật khi duyệt thanh toán):</p>
            <ul style="list-style:none;padding:0;margin:0">
                ${courses.map(c => `
                    <li style="display:flex;align-items:center;gap:0.6rem;padding:0.5rem 0;border-bottom:1px solid var(--border)">
                        <span style="color:#22c55e;font-size:1rem">&#10003;</span>
                        <span style="font-weight:500">${c.name}</span>
                        <span style="color:#64748b;font-size:0.82rem;margin-left:auto">${c.price || 'Miễn phí'}</span>
                    </li>
                `).join('')}
            </ul>
        `;
    }
    document.getElementById('modalBody').innerHTML = content + '<button class="btn btn-secondary btn-block" style="margin-top:1rem" onclick="closeModal()">Dóng</button>';
}

// =============================================================
// CATEGORIES
// =============================================================
async function loadAdminCategories() {
    const tbody = document.getElementById('categoriesTable');
    tbody.innerHTML = '<tr><td colspan="3" style="text-align:center"><div class="spinner" style="margin:1rem auto"></div></td></tr>';
    const cats = await apiFetch('/api/admin/categories');
    if (!cats || cats.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" style="text-align:center;color:#64748b">Không có danh mục</td></tr>';
        return;
    }
    tbody.innerHTML = cats.map(c => `
        <tr>
            <td>${c.id}</td>
            <td>${c.name}</td>
            <td>
                <button class="btn btn-sm btn-danger" onclick="deleteCategory(${c.id}, '${c.name}')">Xóa</button>
            </td>
        </tr>
    `).join('');
}

function openCreateCategory() {
    showModal('Thêm danh mục mới', `
        <div class="form-group"><label>Tên danh mục *</label><input type="text" id="cat-name" placeholder="VD: Lập trình Web"></div>
        <button class="btn btn-primary btn-block" onclick="submitCreateCategory()">Tạo danh mục</button>
    `);
}

async function submitCreateCategory() {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { showToast('Tên danh mục không được để trống', 'warning'); return; }
    await apiFetch('/api/admin/categories', { method: 'POST', body: JSON.stringify({ name }) });
    closeModal();
    loadAdminCategories();
}

function deleteCategory(id, name) {
    showModal('Xác nhận xóa', `
        <p style="margin-bottom:1.5rem;color:var(--text)">Bạn chắc chắn muốn xóa danh mục "<strong>${name}</strong>"? Thao tác này không thể hoàn tác.</p>
        <div style="display:flex;gap:0.5rem;justify-content:flex-end">
            <button class="btn btn-secondary" onclick="closeModal()">Hủy</button>
            <button class="btn btn-danger" onclick="submitDeleteCategory(${id})">Xóa</button>
        </div>
    `);
}

async function submitDeleteCategory(id) {
    await apiFetch(`/api/admin/categories/${id}`, { method: 'DELETE' });
    closeModal();
    loadAdminCategories();
}

// =============================================================
// PAYMENTS
// =============================================================
async function loadAdminPayments() {
    const tbody = document.getElementById('paymentsTable');
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center"><div class="spinner" style="margin:1rem auto"></div></td></tr>';
    const payments = await apiFetch('/api/admin/payments');
    if (!payments || payments.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#64748b">Không có đơn hàng nào</td></tr>';
        return;
    }
    tbody.innerHTML = payments.map(p => `
        <tr>
            <td>${p.id}</td>
            <td style="font-weight:600">${p.userFullname}</td>
            <td>${p.courseName}</td>
            <td style="color:#22c55e;font-weight:bold">${p.amount ? p.amount + 'đ' : 'Miễn phí'}</td>
            <td>${p.paymentMethod || 'N/A'}</td>
            <td><span class="badge badge-${p.status === 1 ? 'active' : 'inactive'}">${p.status === 1 ? 'Hoàn thành' : 'Chờ duyệt'}</span></td>
            <td>
                ${p.status === 0 ? `<button class="btn btn-sm btn-primary" onclick="openConfirmPaymentModal(${p.id})">Duyệt đơn</button>` : ''}
            </td>
        </tr>
    `).join('');
}

function openConfirmPaymentModal(paymentId) {
    showModal('Xác nhận duyệt', `
        <p style="margin-bottom:1.5rem;line-height:1.5;color:var(--text)">Bạn có chắc chắn muốn duyệt đơn thanh toán này?<br>Người dùng sẽ được cấp quyền học ngay lập tức.</p>
        <div style="display:flex;gap:0.5rem;justify-content:flex-end">
            <button class="btn btn-secondary" onclick="closeModal()">Hủy</button>
            <button class="btn btn-primary" onclick="submitConfirmPayment(${paymentId})">Xác nhận</button>
        </div>
    `);
}

async function submitConfirmPayment(paymentId) {
    try {
        const result = await apiFetch(`/api/admin/payments/${paymentId}/confirm`, {
            method: 'POST'
        });

        if (result) {
            showModal('Thành công', '<p style="margin-bottom:1.5rem;color:var(--text)">Duyệt đơn thành công. Hệ thống đã tự động ghi danh User!</p><button class="btn btn-primary btn-block" onclick="closeModal()">Đóng</button>');
            loadAdminPayments();
        } else {
            showModal('Lỗi', '<p style="margin-bottom:1.5rem;color:var(--text)">Lỗi: Không nhận được phản hồi từ máy chủ.</p><button class="btn btn-danger btn-block" onclick="closeModal()">Đóng</button>');
        }
    } catch (err) {
        showModal('Lỗi', '<p style="margin-bottom:1.5rem;color:var(--text)">' + (err.message || 'Lỗi khi duyệt đơn. Vui lòng thử lại.') + '</p><button class="btn btn-danger btn-block" onclick="closeModal()">Đóng</button>');
    }
}

// =============================================================
// MODAL UTILITIES
// =============================================================
function showModal(title, bodyHtml) {
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalBody').innerHTML = bodyHtml;
    document.getElementById('modalOverlay').classList.add('open');
}

function closeModal() {
    document.getElementById('modalOverlay').classList.remove('open');
}

// Close on overlay click
document.addEventListener('DOMContentLoaded', () => {
    const overlay = document.getElementById('modalOverlay');
    if (overlay) {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) closeModal();
        });
    }
});

async function getAllCourses() {
    return await apiFetch('/api/admin/courses') || [];
}

// Live thumbnail preview
function previewThumb(inputId, previewId) {
    const url = document.getElementById(inputId).value.trim();
    const box = document.getElementById(previewId);
    if (!box) return;
    if (url) {
        const img = box.querySelector('img');
        if (img) img.src = url;
        box.style.display = 'block';
    } else {
        box.style.display = 'none';
    }
}