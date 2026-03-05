import { callable } from '@steambrew/webkit';

export const VERSION = '4.2.1';
export let CDN: string;
const COMMIT_SHA = 'a9272e40f9a561cd756304f90b07858b6b2607ed';
export const LOOPBACK_CDN = `https://cdn.jsdelivr.net/gh/IsThereAnyDeal/AugmentedSteam@${COMMIT_SHA}/src`;
export const DEV = false;

export function getCdn(path: string): string {
  if (path.startsWith('/')) {
    return `${CDN}${path}`;
  }

  return `${CDN}/${path}`;
}

export function getLoopbackCdn(path: string): string {
  if (path.startsWith('/')) {
    return `${LOOPBACK_CDN}${path}`;
  }

  return `${LOOPBACK_CDN}/${path}`;
}

const PLUGIN_DIR_STORAGE = 'augmented_plugin_dir';
const getPluginDir = callable<[], string>('GetPluginDir');

export async function initCdn(): Promise<void> {
  let pluginDir = sessionStorage.getItem(PLUGIN_DIR_STORAGE);
  if (pluginDir === null) {
    pluginDir = await getPluginDir();
    sessionStorage.setItem(PLUGIN_DIR_STORAGE, pluginDir);
  }
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  const envString = DEV ? 'dev' : 'prod';
  const extensionFolder = `${pluginDir.replace(/.*\\([^\\]+)\\([^\\]+)$/, '/$1/$2')}/AugmentedSteam/dist/${envString}.chrome`;
  CDN = `https://pseudo.millennium.app${extensionFolder}`;
}

const backendError = callable<[{ message: string; }], void>('AugmentedSteam_LogError');
const backendWarn = callable<[{ message: string; }], void>('AugmentedSteam_LogWarn');

export const Logger = {
  error: (...message: unknown[]): void => {
    console.error('%c AugmentedSteam plugin ', 'background: red; color: white', ...message);
    backendError({ message: message.join(' ') }).catch(() => undefined);
  },
  log: (...message: unknown[]): void => {
    console.log('%c AugmentedSteam plugin ', 'background: purple; color: white', ...message);
  },
  debug: (...message: unknown[]): void => {
    console.debug('%c AugmentedSteam plugin ', 'background: black; color: white', ...message);
  },
  warn: (...message: unknown[]): void => {
    console.warn('%c AugmentedSteam plugin ', 'background: orange; color: white', ...message);
    backendWarn({ message: message.join(' ') }).catch(() => undefined);
  },
};

export async function sleep(ms: number): Promise<void> {
  return new Promise((res) => {
    setTimeout(res, ms);
  });
}
