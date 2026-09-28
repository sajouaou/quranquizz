import '@testing-library/jest-dom/vitest';

// jsdom does not implement matchMedia, which Ionic relies on.
window.matchMedia = window.matchMedia || function () {
  return {
    matches: false,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
  } as unknown as MediaQueryList;
};
