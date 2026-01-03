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
    { label: 'Colors', type: 'custom_color' },
    { label: 'Lights', type: 'lights' }
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

    if (cat.type === 'lights') {
        renderLightsMenu(container, cat);
        return;
    }

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

function renderLightsMenu(container, cat) {
    container.innerHTML = `
        <div class="lights-controls" style="color:white; padding:10px;">
            <h3>Xenon Headlights</h3>
            <button class="mod-btn" onclick="toggleXenon()">Toggle Xenon ($500)</button>
            <hr style="border-color:rgba(255,255,255,0.1); margin:15px 0;">
            <h3>Neon Layout</h3>
            <button class="mod-btn" onclick="toggleNeon('all')">Install All Neons ($2000)</button>
            <button class="mod-btn" style="background:#ef4444;" onclick="clearNeon()">Remove Neons</button>
            <hr style="border-color:rgba(255,255,255,0.1); margin:15px 0;">
            <h3>Neon Color (RGB)</h3>
            <div style="display:flex; gap:10px; flex-direction:column;">
                <label>R: <input type="range" id="neon-r" min="0" max="255" oninput="updateNeonColor()"></label>
                <label>G: <input type="range" id="neon-g" min="0" max="255" oninput="updateNeonColor()"></label>
                <label>B: <input type="range" id="neon-b" min="0" max="255" oninput="updateNeonColor()"></label>
            </div>
            <button class="mod-btn" style="margin-top:10px;" onclick="applyNeonColor()">Apply Color ($100)</button>
        </div>
    `;
}

function toggleXenon() {
    fetch(`https://${GetParentResourceName()}/applyLights`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'xenon' })
    });
}

function toggleNeon(layout) {
    fetch(`https://${GetParentResourceName()}/applyLights`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'neon_layout', layout: layout })
    });
}

function clearNeon() {
    fetch(`https://${GetParentResourceName()}/applyLights`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'neon_clear' })
    });
}

function updateNeonColor() {
    // Preview logic if we wanted live preview without confirm, 
    // but typically we wait for apply. 
    // We could add a debounce here for live preview.
    const r = document.getElementById('neon-r').value;
    const g = document.getElementById('neon-g').value;
    const b = document.getElementById('neon-b').value;

    fetch(`https://${GetParentResourceName()}/previewNeon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ r: r, g: g, b: b })
    });
}

function applyNeonColor() {
    const r = document.getElementById('neon-r').value;
    const g = document.getElementById('neon-g').value;
    const b = document.getElementById('neon-b').value;

    fetch(`https://${GetParentResourceName()}/applyLights`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'neon_color', r: r, g: g, b: b })
    });
}

function showCategories() {
    document.getElementById('categories').classList.remove('hidden');
    document.getElementById('mods-list').classList.add('hidden');
}

function applyMod(cat, index, price) {
    // Trigger Server check instead of applying directly
    fetch(`https://${GetParentResourceName()}/applyMod`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ modType: cat.modType, modIndex: index, price: price, type: cat.type, modLabel: cat.label })
    });
}

function closeMenu() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
}
