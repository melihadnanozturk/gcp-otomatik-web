document.addEventListener('DOMContentLoaded', async function() {
  const container = document.getElementById('sentences');
  try {
    const res = await fetch('http://localhost:5000/api/sentences');
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
  } catch (e) {
    container.innerHTML = '<div style="color:red">Veriler alınamadı.</div>';
  }
});