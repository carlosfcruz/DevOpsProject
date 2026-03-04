// -----------------------------
// State
// -----------------------------
let currentUptime = 0;
let uptimeInterval = null;

// -----------------------------
// Helpers
// -----------------------------
function $(id) { return document.getElementById(id); }

function setHealthIndicator(dotId, labelId, status) {
    const dot = $(dotId);
    const label = $(labelId);

    dot.className = 'health-dot';
    label.className = 'health-label';

    if (status === 'ok') {
        dot.classList.add('health-dot--ok');
        label.classList.add('health-label--ok');
        label.textContent = 'Healthy';
    } else {
        dot.classList.add('health-dot--error');
        label.classList.add('health-label--error');
        label.textContent = 'Error';
    }
}

function formatUptime(totalSeconds) {
    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = Math.floor(totalSeconds % 60);

    const parts = [];
    if (days > 0) parts.push(days + 'd');
    if (hours > 0) parts.push(hours + 'h');
    if (minutes > 0) parts.push(minutes + 'm');
    parts.push(seconds + 's');

    return parts.join(' ');
}

// -----------------------------
// Data fetching
// -----------------------------
async function fetchStatus() {
    try {
        const res = await fetch('/api/status');
        const data = await res.json();

        $('app-name').textContent = data.app.name;
        $('app-version').textContent = 'v' + data.app.version;
        $('app-env').textContent = data.app.environment;
        $('app-commit').textContent = '🔗 ' + data.app.commit.substring(0, 7);

        currentUptime = data.app.uptime_seconds;
        $('uptime').textContent = formatUptime(currentUptime);

        setHealthIndicator('dot-db', 'health-db', data.health.database);
        setHealthIndicator('dot-redis', 'health-redis', data.health.redis);
        setHealthIndicator('dot-overall', 'health-overall', data.health.overall);

        $('sys-hostname').textContent = data.system.hostname;
        $('sys-python').textContent = data.system.python_version;
        $('sys-platform').textContent = data.system.platform;

        $('last-updated').textContent = new Date().toLocaleTimeString();
    } catch (err) {
        console.error('Failed to fetch /api/status:', err);
    }
}

async function fetchStats() {
    try {
        const res = await fetch('/api/stats');
        const data = await res.json();

        $('stat-users').textContent = data.user_count;

        if (data.redis_ping_ms >= 0) {
            $('stat-redis-ping').innerHTML =
                data.redis_ping_ms + '<span class="data-unit">ms</span>';
        } else {
            $('stat-redis-ping').textContent = 'unreachable';
            $('stat-redis-ping').style.color = '#ef4444';
        }
    } catch (err) {
        console.error('Failed to fetch /api/stats:', err);
    }
}

// -----------------------------
// Live uptime ticker
// -----------------------------
function startUptimeTicker() {
    if (uptimeInterval) clearInterval(uptimeInterval);

    uptimeInterval = setInterval(() => {
        currentUptime += 1;
        $('uptime').textContent = formatUptime(currentUptime);
    }, 1000);
}

// -----------------------------
// Init
// -----------------------------
async function init() {
    await fetchStatus();
    await fetchStats();
    startUptimeTicker();

    setInterval(() => {
        fetchStatus();
        fetchStats();
    }, 5000);
}

init();
