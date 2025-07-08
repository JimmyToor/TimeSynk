export default class Utility {
  /**
   * Debounces a function call, ensuring that it is not called too frequently.
   * @param func - The function to debounce.
   * @param delay - The execution delay and debounce window in milliseconds.
   * @returns {(function(...[*]): void)|*} - The debounced function.
   */
  static debounceFn(func, delay) {
    let timeout;

    return function (...args) {
      const context = this;
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(context, args), delay);
    };
  }
}
