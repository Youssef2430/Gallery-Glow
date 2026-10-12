(() => {
  'use strict';

  const root = document.documentElement;
  const storageKey = 'gallery-glow-theme';
  const systemTheme = matchMedia('(prefers-color-scheme: dark)');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const validPreference = value => ['light', 'dark'].includes(value) ? value : 'system';
  let preference = 'system';
  let toggle;
  let activeTransition;
  let revision = 0;

  try { preference = validPreference(localStorage.getItem(storageKey)); } catch {}

  const resolvedTheme = () => preference === 'system'
    ? (systemTheme.matches ? 'dark' : 'light') : preference;

  function updateTheme() {
    const theme = resolvedTheme();
    root.dataset.theme = theme;
    root.dataset.themePreference = preference;
    document.querySelector('meta[name="theme-color"]')?.setAttribute(
      'content', theme === 'dark' ? '#131514' : '#f6f5ef'
    );
    toggle?.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`);
  }

  // Runs in the head so a saved preference is applied before the first paint.
  updateTheme();

  function rippleOrigin() {
    const painting = document.querySelector('.mount img')?.getBoundingClientRect();
    const control = toggle.getBoundingClientRect();
    const visiblePainting = painting && painting.bottom > 0 && painting.top < innerHeight;
    const target = visiblePainting ? painting : control;
    const x = Math.max(0, Math.min(innerWidth, target.left + target.width / 2));
    const y = Math.max(0, Math.min(innerHeight, target.top + target.height / 2));
    const radius = Math.ceil(Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y))) + 2;
    return { x, y, radius };
  }

  function createRipple({ x, y, radius }) {
    const ripple = document.createElement('div');
    ripple.className = 'theme-ripple';
    ripple.setAttribute('aria-hidden', 'true');
    ripple.style.setProperty('--ripple-x', `${x}px`);
    ripple.style.setProperty('--ripple-y', `${y}px`);
    ripple.style.setProperty('--ripple-size', `${radius * 2}px`);
    ripple.innerHTML = '<i class="theme-drop"></i><i class="theme-wave"></i><i class="theme-wave theme-wave-echo"></i>';
    document.body.append(ripple);
    return ripple;
  }

  async function changeTheme(animate = true) {
    const currentRevision = ++revision;
    if (activeTransition) {
      activeTransition.skipTransition();
      await activeTransition.finished.catch(() => {});
    }
    if (currentRevision !== revision) return;

    if (root.dataset.theme === resolvedTheme() || !animate || reducedMotion.matches || !document.startViewTransition) {
      updateTheme();
      return;
    }

    const origin = rippleOrigin();
    const ripple = createRipple(origin);
    let transition;
    try {
      transition = document.startViewTransition(updateTheme);
      activeTransition = transition;
      await transition.ready;
      const { x, y, radius } = origin;
      root.animate([
        { clipPath: `circle(0px at ${x}px ${y}px)` },
        { clipPath: `circle(${radius}px at ${x}px ${y}px)` }
      ], {
        duration: 900,
        delay: 160,
        easing: 'cubic-bezier(.22, .8, .25, 1)',
        fill: 'both',
        pseudoElement: '::view-transition-new(root)'
      });
      ripple.classList.add('is-running');
      await transition.finished;
    } catch {
      // Skipped transitions and older browsers still get the chosen theme.
      transition?.skipTransition();
      updateTheme();
    } finally {
      ripple.remove();
      if (activeTransition === transition) activeTransition = undefined;
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    const slot = document.querySelector('.theme-slot');
    if (!slot) return;

    toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'theme-toggle';
    toggle.innerHTML = `
        <svg class="theme-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <defs>
            <mask id="theme-moon-mask">
              <rect width="24" height="24" fill="white" />
              <circle class="moon-cutout" cx="26" cy="-2" r="8" fill="black" />
            </mask>
          </defs>
          <circle class="sun-disc" cx="12" cy="12" r="5" fill="currentColor" mask="url(#theme-moon-mask)" />
          <g class="sun-rays" stroke="currentColor" stroke-width="1.7" stroke-linecap="round">
            <path d="M12 2v2 M12 20v2 M2 12h2 M20 12h2 M4.93 4.93l1.42 1.42 M17.65 17.65l1.42 1.42 M4.93 19.07l1.42-1.42 M17.65 6.35l1.42-1.42" />
          </g>
        </svg>`;
    slot.replaceWith(toggle);
    updateTheme();

    toggle.addEventListener('click', () => {
      preference = resolvedTheme() === 'dark' ? 'light' : 'dark';
      try { localStorage.setItem(storageKey, preference); } catch {}
      changeTheme();
    });

    systemTheme.addEventListener('change', () => {
      if (preference === 'system') changeTheme();
    });
    reducedMotion.addEventListener('change', () => {
      if (reducedMotion.matches) activeTransition?.skipTransition();
    });
    addEventListener('storage', event => {
      if (event.key === storageKey || event.key === null) {
        preference = validPreference(event.newValue);
        changeTheme(false);
      }
    });
    addEventListener('pageshow', event => {
      if (!event.persisted) return;
      try { preference = validPreference(localStorage.getItem(storageKey)); } catch {}
      changeTheme(false);
    });
  });
})();
