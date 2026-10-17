// PWA Service Worker 등록
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch((err) => console.log('SW error:', err));
  });
}

// 상태 데이터
const state = {
  totalSteps: 11450,
  realSteps: 9820,
  workoutSteps: 6180,
  targetSteps: 10000,
  targetCalories: 500,
  isTracking: false,
  timerSeconds: 0,
  trackingInterval: null,
  trackCoords: [],
  miniMap: null,
  detailMap: null,
  liveMap: null,
  livePolyline: null
};

// 울산대공원 모의 GPS 좌표
const ulsanRoute = [
  [35.5348, 129.3087],
  [35.5355, 129.3102],
  [35.5368, 129.3115],
  [35.5350, 129.3130],
  [35.5330, 129.3142],
  [35.5305, 129.3160],
  [35.5280, 129.3180]
];

// 배지 리스트
const badges = [
  { id: 'b1', title: '첫 번째 러닝', desc: '첫 러닝 세션 기록 완료', icon: '🏃', unlocked: true },
  { id: 'b2', title: '진짜 10,000보', desc: '유효 걸음으로 1만 보 달성', icon: '🔥', unlocked: true },
  { id: 'b3', title: '3일 연속 달성', desc: '3일 연속 목표 100% 달성', icon: '⚡', unlocked: false },
  { id: 'b4', title: '5km 완주', desc: '한 번에 5km 이상 달리기', icon: '🥇', unlocked: true },
  { id: 'b5', title: '나이트 러너', desc: '저녁 8시 이후 3km 완주', icon: '🌙', unlocked: true },
  { id: 'b6', title: '고도 정복자', desc: '누적 상승 100m 돌파', icon: '🏔️', unlocked: false }
];

document.addEventListener('DOMContentLoaded', () => {
  initTabs();
  initGrassMatrix();
  initMiniMap();
  initModals();
  initLiveTracker();
  renderBadges();
  updateStepProgress();
});

// MARK: - 1. 탭 전환
function initTabs() {
  const tabs = document.querySelectorAll('.tab-btn');
  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      btn.classList.add('active');

      const target = btn.dataset.tab;
      document.getElementById('tab-dashboard').style.display = target === 'dashboard' ? 'flex' : 'none';
      document.getElementById('tab-activities').style.display = target === 'activities' ? 'flex' : 'none';
    });
  });
}

// MARK: - 2. 최근 30일 잔디 매트릭스
function initGrassMatrix() {
  const container = document.getElementById('grass-container');
  container.innerHTML = '';
  for (let i = 0; i < 28; i++) {
    const dot = document.createElement('div');
    dot.className = 'grass-dot';
    // 2일마다 또는 특정 날짜에 초록 불
    if (i % 2 === 0 || i % 5 === 0) {
      dot.classList.add('active');
    }
    container.appendChild(dot);
  }
}

// MARK: - 3. Leaflet 미니 맵 초기화
function initMiniMap() {
  const mapElem = document.getElementById('mini-map');
  state.miniMap = L.map('mini-map', {
    zoomControl: false,
    attributionControl: false,
    dragging: false,
    touchZoom: false,
    scrollWheelZoom: false
  }).setView([35.5330, 129.3130], 14);

  // CartoDB DarkMatter 다크 테마 타일
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    maxZoom: 19
  }).addTo(state.miniMap);

  // 경로 Polyline
  L.polyline(ulsanRoute, {
    color: '#facc15',
    weight: 4,
    opacity: 0.9,
    lineCap: 'round'
  }).addTo(state.miniMap);

  // 탭 시 상세 모달 열기
  mapElem.addEventListener('click', openRunDetail);
  document.getElementById('activity-item-card').addEventListener('click', openRunDetail);
}

// MARK: - 4. 모달 제어
function initModals() {
  // 목표 설정 모달
  const modalGoals = document.getElementById('modal-goals');
  document.getElementById('btn-open-goals').addEventListener('click', () => {
    modalGoals.classList.add('open');
  });

  const stepSlider = document.getElementById('input-goal-steps');
  const stepText = document.getElementById('goal-step-text');
  stepSlider.addEventListener('input', (e) => {
    stepText.innerText = Number(e.target.value).toLocaleString() + '보';
  });

  const calSlider = document.getElementById('input-goal-cal');
  const calText = document.getElementById('goal-cal-text');
  calSlider.addEventListener('input', (e) => {
    calText.innerText = e.target.value + ' kcal';
  });

  document.getElementById('btn-save-goals').addEventListener('click', () => {
    state.targetSteps = Number(stepSlider.value);
    state.targetCalories = Number(calSlider.value);
    document.getElementById('val-target-steps').innerText = state.targetSteps.toLocaleString();
    updateStepProgress();
    modalGoals.classList.remove('open');
  });

  // 배지 모달
  const modalBadges = document.getElementById('modal-badges');
  document.getElementById('btn-open-badges').addEventListener('click', () => {
    modalBadges.classList.add('open');
  });

  // 축하 테스트 버튼
  document.getElementById('btn-test-celebration').addEventListener('click', triggerCelebration);
  document.getElementById('btn-close-celebration').addEventListener('click', () => {
    document.getElementById('modal-celebration').classList.remove('open');
  });

  // 공통 닫기 버튼
  document.querySelectorAll('.close-modal-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.modal-overlay').forEach(m => m.classList.remove('open'));
    });
  });
}

// MARK: - 5. 걸음 수 프로그레스 갱신
function updateStepProgress() {
  const percent = Math.min(100, Math.round((state.realSteps / state.targetSteps) * 100));
  document.getElementById('bar-step-progress').style.width = percent + '%';
  const remain = Math.max(0, state.targetSteps - state.realSteps);
  const remainLabel = document.getElementById('label-step-remain');

  if (remain === 0) {
    remainLabel.innerHTML = '🎉 <strong style="color:var(--accent-green)">오늘 목표 달성 완료!</strong>';
  } else {
    remainLabel.innerText = `목표까지 -${remain.toLocaleString()} 걸음`;
  }
}

// MARK: - 6. 배지 렌더링
function renderBadges() {
  const grid = document.getElementById('badge-grid');
  grid.innerHTML = '';
  badges.forEach(b => {
    const card = document.createElement('div');
    card.style.background = '#1a1a1d';
    card.style.border = b.unlocked ? '1px solid rgba(250, 204, 21, 0.4)' : '1px solid rgba(255, 255, 255, 0.08)';
    card.style.borderRadius = '16px';
    card.style.padding = '14px';
    card.style.textAlign = 'center';
    card.innerHTML = `
      <div style="font-size:32px; filter:${b.unlocked ? 'none' : 'grayscale(100%) opacity(30%)'};">${b.icon}</div>
      <h4 style="font-size:13px; font-weight:700; margin-top:8px; color:${b.unlocked ? '#fff' : '#666'};">${b.title}</h4>
      <p style="font-size:11px; color:#888; margin-top:2px;">${b.desc}</p>
    `;
    grid.appendChild(card);
  });
}

// MARK: - 7. 축하 파티클(Confetti) 및 햅틱
function triggerCelebration() {
  if (navigator.vibrate) {
    navigator.vibrate([100, 50, 150]);
  }
  if (typeof confetti === 'function') {
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 }
    });
  }
  document.getElementById('modal-celebration').classList.add('open');
}

// MARK: - 8. 스크린샷 1번 상세 러닝 뷰 열기
function openRunDetail() {
  const modal = document.getElementById('modal-run-detail');
  modal.classList.add('open');

  setTimeout(() => {
    if (!state.detailMap) {
      state.detailMap = L.map('detail-map', {
        zoomControl: false,
        attributionControl: false
      }).setView([35.5330, 129.3130], 14);

      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(state.detailMap);
      L.polyline(ulsanRoute, { color: '#f87171', weight: 5 }).addTo(state.detailMap);
    } else {
      state.detailMap.invalidateSize();
    }
  }, 200);
}

// MARK: - 9. 실시간 GPS 러닝 트래커
function initLiveTracker() {
  const trackerModal = document.getElementById('live-tracker-modal');
  const btnStart = document.getElementById('btn-start-run');
  const btnClose = document.getElementById('btn-close-tracker');
  const btnPause = document.getElementById('btn-pause-run');
  const btnStop = document.getElementById('btn-stop-run');

  btnStart.addEventListener('click', () => {
    trackerModal.classList.add('active');
    startTrackingSession();
  });

  btnClose.addEventListener('click', () => {
    stopTrackingSession();
    trackerModal.classList.remove('active');
  });

  btnPause.addEventListener('click', () => {
    state.isTracking = !state.isTracking;
    btnPause.innerText = state.isTracking ? '⏸️' : '▶️';
  });

  btnStop.addEventListener('click', () => {
    stopTrackingSession();
    trackerModal.classList.remove('active');
    openRunDetail();
  });
}

function startTrackingSession() {
  state.isTracking = true;
  state.timerSeconds = 0;
  state.trackCoords = [];

  setTimeout(() => {
    if (!state.liveMap) {
      state.liveMap = L.map('live-map', {
        zoomControl: false,
        attributionControl: false
      }).setView([35.5348, 129.3087], 15);

      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(state.liveMap);
      state.livePolyline = L.polyline([], { color: '#facc15', weight: 6 }).addTo(state.liveMap);
    } else {
      state.liveMap.invalidateSize();
      state.livePolyline.setLatLngs([]);
    }
  }, 200);

  state.trackingInterval = setInterval(() => {
    if (!state.isTracking) return;
    state.timerSeconds++;
    const m = String(Math.floor(state.timerSeconds / 60)).padStart(2, '0');
    const s = String(state.timerSeconds % 60).padStart(2, '0');
    document.getElementById('live-time').innerText = `${m}:${s}`;

    // 가상 위치 이동 시뮬레이션
    const idx = Math.min(ulsanRoute.length - 1, Math.floor(state.timerSeconds / 3));
    const coord = ulsanRoute[idx];
    state.trackCoords.push(coord);
    if (state.livePolyline) state.livePolyline.setLatLngs(state.trackCoords);

    const dist = (state.timerSeconds * 0.003).toFixed(2);
    document.getElementById('live-dist').innerText = dist;
  }, 1000);
}

function stopTrackingSession() {
  state.isTracking = false;
  if (state.trackingInterval) clearInterval(state.trackingInterval);
}
