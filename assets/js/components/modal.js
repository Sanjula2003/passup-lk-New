// Minimal accessible confirm/prompt modal, promise-based.
export function confirmModal({ title, message, confirmLabel = 'Confirm', danger = false }) {
  return new Promise((resolve) => {
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.innerHTML = `
      <div class="modal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
        <h3 id="modalTitle">${title}</h3>
        <p style="margin-top:8px">${message}</p>
        <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:24px;">
          <button class="btn btn-ghost" id="modalCancel">Cancel</button>
          <button class="btn ${danger ? 'btn-danger' : 'btn-primary'}" id="modalConfirm">${confirmLabel}</button>
        </div>
      </div>`;
    document.body.appendChild(backdrop);

    const close = (result) => { backdrop.remove(); resolve(result); };
    backdrop.querySelector('#modalCancel').addEventListener('click', () => close(false));
    backdrop.querySelector('#modalConfirm').addEventListener('click', () => close(true));
    backdrop.addEventListener('click', (e) => { if (e.target === backdrop) close(false); });
    document.addEventListener('keydown', function onKey(e) {
      if (e.key === 'Escape') { close(false); document.removeEventListener('keydown', onKey); }
    });
  });
}
