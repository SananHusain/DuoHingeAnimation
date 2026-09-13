/* ==========================================================================
   iPhone Duo 3D Physical Folding Web Engine
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  const duoContainer = document.getElementById('duoContainer');
  const rightDisplayPanel = document.getElementById('rightDisplayPanel');
  const leftDisplayPanel = document.getElementById('leftDisplayPanel');
  const hingeView = document.getElementById('hingeView');
  const panelBody = document.getElementById('panelBody');
  const togglePanelBtn = document.getElementById('togglePanelBtn');
  
  const foldSlider = document.getElementById('foldSlider');
  const foldVal = document.getElementById('foldVal');
  const foldAngleReadout = document.getElementById('foldAngleReadout');
  const stateBadge = document.getElementById('stateBadge');
  
  const closePresetBtn = document.getElementById('closePresetBtn');
  const halfFoldPresetBtn = document.getElementById('halfFoldPresetBtn');
  const openPresetBtn = document.getElementById('openPresetBtn');

  // State: 0.0 = closed, 1.0 = fully open
  let foldProgress = 0.0;
  let isDragging = false;
  let startX = 0;
  let startProgress = 0;

  function updateFoldState(progress, animate = false) {
    foldProgress = Math.max(0.0, Math.min(1.0, progress));
    
    // Rotation Angle: 0° closed, 180° fully open
    const angleDeg = foldProgress * 180.0;
    const rightRotation = angleDeg - 180.0; // -180deg when closed, 0deg when open
    const leftRotation = (1.0 - foldProgress) * 15.0; // Subtle counter angle when closing

    // Update Slider & Readouts
    foldSlider.value = Math.round(foldProgress * 100);
    foldVal.textContent = `${Math.round(foldProgress * 100)}%`;
    foldAngleReadout.textContent = `${Math.round(angleDeg)}°`;

    if (foldProgress === 0) {
      stateBadge.textContent = 'Closed (0°)';
      stateBadge.className = 'status-badge closed';
    } else if (foldProgress === 1) {
      stateBadge.textContent = 'Fully Open (180°)';
      stateBadge.className = 'status-badge open';
    } else {
      stateBadge.textContent = 'Folding...';
      stateBadge.className = 'status-badge folding';
    }

    // Apply 3D Rotations attached to Central Hinge Axis
    if (animate) {
      rightDisplayPanel.style.transition = 'transform 0.45s cubic-bezier(0.175, 0.885, 0.32, 1.275), opacity 0.3s ease';
      leftDisplayPanel.style.transition = 'transform 0.45s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
    } else {
      rightDisplayPanel.style.transition = 'none';
      leftDisplayPanel.style.transition = 'none';
    }

    rightDisplayPanel.style.transform = `rotateY(${rightRotation}deg)`;
    leftDisplayPanel.style.transform = `rotateY(${leftRotation}deg)`;
    
    // Hinge ambient occlusion
    hingeView.style.opacity = (1.0 - foldProgress * 0.7).toFixed(2);
  }

  // Touch & Mouse Drag Gesture Controllers (1:1 finger tracking)
  function onPointerDown(e) {
    isDragging = true;
    startX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
    startProgress = foldProgress;
    duoContainer.style.cursor = 'grabbing';
  }

  function onPointerMove(e) {
    if (!isDragging) return;
    const currentX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
    const deltaX = currentX - startX;
    
    // Drag distance mapping: 280px drag = 100% fold
    const deltaProgress = deltaX / 280.0;
    updateFoldState(startProgress + deltaProgress, false);
  }

  function onPointerUp(e) {
    if (!isDragging) return;
    isDragging = false;
    duoContainer.style.cursor = 'grab';

    // Snap to nearest 0.0 or 1.0 with spring ease
    const snapTarget = foldProgress >= 0.5 ? 1.0 : 0.0;
    updateFoldState(snapTarget, true);
  }

  // Gesture Event Listeners
  window.addEventListener('mousedown', onPointerDown);
  window.addEventListener('mousemove', onPointerMove);
  window.addEventListener('mouseup', onPointerUp);

  window.addEventListener('touchstart', onPointerDown, { passive: true });
  window.addEventListener('touchmove', onPointerMove, { passive: true });
  window.addEventListener('touchend', onPointerUp, { passive: true });

  // Control Listeners
  foldSlider.addEventListener('input', (e) => {
    updateFoldState(parseFloat(e.target.value) / 100.0, false);
  });

  closePresetBtn.addEventListener('click', () => updateFoldState(0.0, true));
  halfFoldPresetBtn.addEventListener('click', () => updateFoldState(0.5, true));
  openPresetBtn.addEventListener('click', () => updateFoldState(1.0, true));

  togglePanelBtn.addEventListener('click', () => {
    panelBody.classList.toggle('collapsed');
  });

  // Initial State: Closed
  updateFoldState(0.0, false);
});
