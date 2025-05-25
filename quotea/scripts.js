document.addEventListener('DOMContentLoaded', async function() {
  const container = document.getElementById('sentences');
  let vmName = '';
  try {
    const vmRes = await fetch('/api/vm-info');
    const vmData = await vmRes.json();
    vmName = vmData.hostname;
  } catch (e) {
    vmName = '';
  }
  try {
    const res = await fetch('/api/sentences');
    const data = await res.json();
    container.innerHTML = '';
    data.forEach(item => {
      const card = document.createElement('div');
      card.className = 'sentence-card';
      card.innerHTML = `
        <div>${item.sentence}</div>
        <span class="sentence-person">${item.person}</span>
      `;
      container.appendChild(card);
    });
    // VM adı kutusunu en alta, sola hizalı ekle
    const vmDiv = document.createElement('div');
    vmDiv.className = 'sentence-vm';
    vmDiv.style.textAlign = 'left';
    vmDiv.style.marginTop = '16px';
    vmDiv.textContent = `VM: ${vmName}`;
    container.appendChild(vmDiv);
  } catch (e) {
    container.innerHTML = '<div style="color:red">Veriler alınamadı.</div>';
  }
});