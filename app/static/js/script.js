function showEditForm(taskId) {
    document.getElementById(`edit-form-${taskId}`).classList.remove('hidden');
}

function hideEditForm(taskId) {
    document.getElementById(`edit-form-${taskId}`).classList.add('hidden');
}