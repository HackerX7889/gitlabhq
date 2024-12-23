import { debounce } from 'lodash';
import Tracking from '~/tracking';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { convertToSnakeCase } from '~/lib/utils/text_utility';

export default class FormErrorTracker {
  constructor() {
    this.elements = document.querySelectorAll('.js-track-error');
    this.trackErrorOnEmptyField = FormErrorTracker.trackErrorOnEmptyField.bind(this);

    this.trackErrorOnChange = debounce(
      FormErrorTracker.trackErrorOnChange.bind(this),
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );

    this.elements.forEach((element) => {
      // on item change
      element.addEventListener('input', this.trackErrorOnChange);

      // on invalid item - adding separately to track submit click without
      // changing any field
      element.addEventListener('invalid', this.trackErrorOnEmptyField);
    });
  }

  destroy() {
    this.elements.forEach((element) => {
      element.removeEventListener('input', this.trackErrorOnChange);
      element.removeEventListener('invalid', this.trackErrorOnEmptyField);
    });
  }

  static trackErrorOnChange(event) {
    const inputDomElement = event.target;

    if (inputDomElement.value && !inputDomElement.checkValidity()) {
      const message = FormErrorTracker.errorMessage(inputDomElement);

      Tracking.event(undefined, FormErrorTracker.action(inputDomElement), {
        label: FormErrorTracker.label(inputDomElement, message),
      });
    }
  }

  static trackErrorOnEmptyField(event) {
    const inputDomElement = event.target;

    const uncheckedRadio =
      !inputDomElement.checked && FormErrorTracker.isRadio(inputDomElement.type);

    if (inputDomElement.value === '' || uncheckedRadio) {
      const message = FormErrorTracker.inputErrorMessage(inputDomElement);

      Tracking.event(undefined, FormErrorTracker.action(inputDomElement), {
        label: FormErrorTracker.label(inputDomElement, message),
      });
    }
  }

  static errorMessage(element) {
    if (element.id.includes('email')) {
      return 'invalid_email_address';
    }

    if (element.id.includes('password')) {
      return 'password_is_too_short';
    }

    return FormErrorTracker.inputErrorMessage(element);
  }

  static inputErrorMessage(element) {
    return convertToSnakeCase(element.validationMessage);
  }

  static action(element) {
    return `track_${element.dataset.trackActionForErrors}_error`;
  }

  static label(element, message) {
    if (FormErrorTracker.isRadio(element.type)) {
      const labelText = element.closest('.form-group').querySelector('label').textContent;
      return `missing_${convertToSnakeCase(labelText)}`;
    }

    return `${element.id}_${message}`;
  }

  static isRadio(type) {
    return type === 'radio';
  }
}
