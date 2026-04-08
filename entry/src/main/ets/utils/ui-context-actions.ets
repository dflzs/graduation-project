import { promptAction, router } from '@kit.ArkUI';

export interface UiContextRouterLike {
  pushUrl(options: router.RouterOptions): Promise<void>;
  replaceUrl(options: router.RouterOptions): Promise<void>;
  back(options?: router.RouterOptions): void;
  getParams(): Object;
}

export interface UiContextPromptLike {
  showToast(options: promptAction.ShowToastOptions): void;
}

export interface UiContextLike {
  getRouter(): UiContextRouterLike;
  getPromptAction(): UiContextPromptLike;
}

export interface UiContextHost {
  getUIContext(): UiContextLike;
}

export function pushUrlByContext(host: UiContextHost, options: router.RouterOptions): void {
  void host.getUIContext().getRouter().pushUrl(options);
}

export function replaceUrlByContext(host: UiContextHost, options: router.RouterOptions): void {
  void host.getUIContext().getRouter().replaceUrl(options);
}

export function backByContext(host: UiContextHost, options?: router.RouterOptions): void {
  host.getUIContext().getRouter().back(options);
}

export function getParamsByContext<T extends Object>(host: UiContextHost): T {
  return host.getUIContext().getRouter().getParams() as T;
}

export function showToastByContext(host: UiContextHost, options: promptAction.ShowToastOptions): void {
  host.getUIContext().getPromptAction().showToast(options);
}
