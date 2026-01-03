let currentMods = [];

window.addEventListener('message', (event) => {
    if (event.data.action === 'open') {
        document.getElementById('app').classList.remove('hidden');
        setupCategories();
    }
});

const categories = [
    { label: 'Engine', modType: 11 },
    { label: 'Brakes', modType: 12 },
    { label: 'Transmission', modType: 13 },
    { label: 'Suspension', modType: 15 },
    { label: 'Armor', modType: 16 },
    { label: 'Turbo', modType: 18, type: 'toggle' },
    { label: 'Spoilers', modType: 0 },
    { label: 'Front Bumper', modType: 1 },
    { label: 'Rear Bumper', modType: 2 },
    { label: 'Skirts', modType: 3 },
    { label: 'Exhaust', modType: 4 },
    { label: 'Grille', modType: 6 },
    { label: 'Bonnet', modType: 7 },
    { label: 'Fenders', modType: 8 },
    { label: 'Roof', modType: 10 },
    { label: 'Colors', type: 'custom_color' }
];

function setupCategories() {
    const container = document.getElementById('categories');
    container.innerHTML = '';

    categories.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = 'category-btn';
        btn.innerHTML = `<span>${cat.label}</span> <i class="fa-solid fa-chevron-right"></i>`;
        btn.onclick = () => openModCategory(cat);
        container.appendChild(btn);
    });

    document.getElementById('categories').classList.remove('hidden');
    document.getElementById('mods-list').classList.add('hidden');
}

function openModCategory(cat) {
    document.getElementById('categories').classList.add('hidden');
    document.getElementById('mods-list').classList.remove('hidden');
    const container = document.getElementById('mods-container');
    container.innerHTML = 'Loading...';

    // Request mods from client
    fetch(`https://${GetParentResourceName()}/getMods`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ modType: cat.modType, type: cat.type })
    }).then(resp => resp.json()).then(mods => {
        container.innerHTML = '';

        mods.forEach(mod => {
            const btn = document.createElement('button');
            btn.className = `mod-btn ${mod.installed ? 'active' : ''}`;
            btn.innerHTML = `<span>${mod.label}</span> <span>$${mod.price}</span>`;
            btn.onclick = () => applyMod(cat, mod.index, mod.price);
            container.appendChild(btn);
        });
    });
}

function showCategories() {
    document.getElementById('categories').classList.remove('hidden');
    document.getElementById('mods-list').classList.add('hidden');
}

function applyMod(cat, index, price) {
    fetch(`https://${GetParentResourceName()}/applyMod`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ modType: cat.modType, modIndex: index, price: price, type: cat.type })
    });
}

function closeMenu() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
}
