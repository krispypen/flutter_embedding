
export interface HandoverResponderInterface {

  /**
   * This will be used when the exit button is clicked in the app-in-app. The super app is then
   * responsible to navigate away from the app-in-app.
   *
   * This will be triggered by the back button on the home screen.
   */
  exit?(): void;

  /**
   * This will be used to invoke a handover event to the native app.
   *
   * @param name
   * @param data
   * @param completion
   */
  invokeHandover(name: string, data: any, completion: (response: any, error: any) => void): void;

}
