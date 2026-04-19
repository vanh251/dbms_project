// =============================================
// admin.js - Admin panel logic
// =============================================

document.addEventListener('DOMContentLoaded', () => {
    // Guard: must be logged in as admin
    if (!isLoggedIn()) { window.location.href = 'login.html'; return; }
    const user = getUser();
    if (!user || user.groupId !== 1) {
        alert('Bạn không có quyền truy cập trang này.');
        window.location.href = 'index.html'; return;
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
                <button class="btn btn-sm btn-outline" onclick="openEditCourse(${c.id})">✏️ Sửa</button>
                <button class="btn btn-sm btn-danger" onclick="deleteCourse(${c.id},'${c.name}')">🗑 Xóa</button>
                <button class="btn btn-sm btn-secondary" onclick="openPartModal(${c.id},'${c.name}')">➕ Chương</button>
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
        <button class="btn btn-primary btn-block" onclick="submitCreateCourse()">💾 Tạo khóa học</button>
    `);
}

async function submitCreateCourse() {
    const body = {
        name: document.getElementById('fc-name').value.trim(),
        slug: document.getElementById('fc-slug').value.trim(),
        price: document.getElementById('fc-price').value.trim(),
        oldPrice: document.getElementById('fc-oldprice').value.trim(),
        description: document.getElementById('fc-desc').value.trim(),
        require: document.getElementById('fc-require').value.trim(),
        totalTime: document.getElementById('fc-time').value.trim(),
        status: parseInt(document.getElementById('fc-status').value),
        categoryId: document.getElementById('fc-cat').value ? parseInt(document.getElementById('fc-cat').value) : null
    };
    if (!body.name) { alert('Tên khóa học không được để trống'); return; }
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
        <button class="btn btn-primary btn-block" onclick="submitEditCourse(${id})">💾 Lưu thay đổi</button>
    `);
}

async function submitEditCourse(id) {
    const body = {
        name: document.getElementById('ec-name').value.trim(),
        slug: document.getElementById('ec-slug').value.trim(),
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
    if (!confirm(`Bạn chắc chắn muốn xóa khóa học "${name}"?`)) return;
    await apiFetch(`/api/admin/courses/${id}`, { method: 'DELETE' });
    loadAdminCourses();
}

// --- Part / Chapter ---
function openPartModal(courseId, courseName) {
    showModal(`Thêm chương – ${courseName}`, `
        <div class="form-group"><label>Tên chương</label><input id="part-name" placeholder="VD: Chương 1: Giới thiệu"></div>
        <button class="btn btn-primary btn-block" onclick="submitAddPart(${courseId})">➕ Thêm chương</button>
        <hr style="margin:1.5rem 0">
        <div id="partLessonContent">
            <p style="color:#64748b;font-size:0.9rem">Sau khi thêm chương, dùng nút "Thêm bài" để thêm bài học.</p>
        </div>
    `);
}

async function submitAddPart(courseId) {
    const name = document.getElementById('part-name').value.trim();
    if (!name) { alert('Tên chương không được để trống'); return; }
    const result = await apiFetch(`/api/admin/courses/${courseId}/parts`, { method: 'POST', body: JSON.stringify({ name }) });
    if (result && result.id) {
        document.getElementById('part-name').value = '';
        document.getElementById('partLessonContent').innerHTML = `
            <p style="color:#22c55e;margin-bottom:1rem">✅ Đã thêm chương "${result.name}" (ID: ${result.id})</p>
            <div class="form-group"><label>Tên bài học</label><input id="lesson-name" placeholder="VD: Bài 1: Hello World"></div>
            <div class="form-row">
                <div class="form-group"><label>Thời lượng</label><input id="lesson-len" placeholder="10:30"></div>
            </div>
            <div class="form-group"><label>Mô tả</label><textarea id="lesson-desc"></textarea></div>
            <div class="form-group"><label>Nội dung / URL Video</label><input id="lesson-value" placeholder="https://youtube.com/watch?v=... hoặc nội dung text"></div>
            <button class="btn btn-secondary btn-block" onclick="submitAddLesson(${result.id})">➕ Thêm bài học</button>
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
    if (!body.name) { alert('Tên bài học không được để trống'); return; }
    const result = await apiFetch(`/api/admin/parts/${partId}/lessons`, { method: 'POST', body: JSON.stringify(body) });
    if (result && result.id) {
        alert(`✅ Đã thêm bài học "${result.name}"`);
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
                <button class="btn btn-sm btn-outline" onclick="openPermissionModal(${u.id},'${u.fullname}','${u.permission || ''}')">🔑 Phân quyền</button>
            </td>
        </tr>
    `).join('');
}

async function openPermissionModal(userId, name, currentPerm) {
    const courses = await apiFetch('/api/admin/courses');
    const permList = (currentPerm || '').split(',').map(s => s.trim()).filter(Boolean);
    const courseCheckboxes = (courses || []).map(c => `
        <label style="display:flex;align-items:center;gap:0.5rem;padding:0.4rem 0;cursor:pointer">
            <input type="checkbox" value="${c.id}" ${permList.includes(String(c.id)) ? 'checked' : ''}>
            ${c.name}
        </label>
    `).join('');

    showModal(`🔑 Phân quyền – ${name}`, `
        <p style="color:#64748b;font-size:0.88rem;margin-bottom:1rem">Chọn các khóa học mà người dùng được phép truy cập:</p>
        <div id="courseCheckboxes" style="max-height:300px;overflow-y:auto;border:1px solid #e2e8f0;border-radius:8px;padding:0.8rem">
            ${courseCheckboxes}
        </div>
        <button class="btn btn-primary btn-block" style="margin-top:1rem" onclick="submitPermission(${userId})">💾 Lưu phân quyền</button>
    `);
}

async function submitPermission(userId) {
    const checkboxes = document.querySelectorAll('#courseCheckboxes input[type=checkbox]:checked');
    const permission = Array.from(checkboxes).map(cb => cb.value).join(',');
    await apiFetch(`/api/admin/users/${userId}/permission`, {
        method: 'PUT',
        body: JSON.stringify({ permission })
    });
    alert('✅ Đã cập nhật phân quyền thành công!');
    closeModal();
    loadAdminUsers();
}

// =============================================================
// CATEGORIES
// =============================================================
async function loadAdminCategories() {
    const tbody = document.getElementById('categoriesTable');
    tbody.innerHTML = '<tr><td colspan="2" style="text-align:center"><div class="spinner" style="margin:1rem auto"></div></td></tr>';
    const cats = await apiFetch('/api/admin/categories');
    if (!cats || cats.length === 0) {
        tbody.innerHTML = '<tr><td colspan="2" style="text-align:center;color:#64748b">Không có danh mục</td></tr>';
        return;
    }
    tbody.innerHTML = cats.map(c => `
        <tr><td>${c.id}</td><td>${c.name}</td></tr>
    `).join('');
}

function openCreateCategory() {
    showModal('Thêm danh mục mới', `
        <div class="form-group"><label>Tên danh mục *</label><input type="text" id="cat-name" placeholder="VD: Lập trình Web"></div>
        <button class="btn btn-primary btn-block" onclick="submitCreateCategory()">💾 Tạo danh mục</button>
    `);
}

async function submitCreateCategory() {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { alert('Tên danh mục không được để trống'); return; }
    await apiFetch('/api/admin/categories', { method: 'POST', body: JSON.stringify({ name }) });
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
                ${p.status === 0 ? `<button class="btn btn-sm btn-primary" onclick="openConfirmPaymentModal(${p.id})">✅ Duyệt đơn</button>` : ''}
            </td>
        </tr>
    `).join('');
}

function openConfirmPaymentModal(paymentId) {
    showModal('Duyệt đơn thanh toán', `
        <p style="color:#64748b;font-size:0.9rem;margin-bottom:1rem">Vui lòng nhập mã giao dịch thực tế (hoặc mã bill) để xác nhận.</p>
        <div class="form-group">
            <label>Mã giao dịch *</label>
            <input type="text" id="tx-id" placeholder="VD: MOMO123456789">
        </div>
        <button class="btn btn-primary btn-block" onclick="submitConfirmPayment(${paymentId})">Xác nhận duyệt</button>
    `);
}

async function submitConfirmPayment(paymentId) {
    const txId = document.getElementById('tx-id').value.trim();
    if (!txId) {
        alert('Mã giao dịch không được để trống!');
        return;
    }
    await apiFetch(`/api/admin/payments/${paymentId}/confirm`, {
        method: 'POST',
        body: JSON.stringify({ transactionId: txId })
    });
    alert('✅ Duyệt đơn thành công. Hệ thống đã tự động ghi danh User!');
    closeModal();
    loadAdminPayments();
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
