const { createRunner } = require('atom-jasmine3-test-runner');

// optional options to customize the runner
const extraOptions = {
  suffix: "-spec",
  specHelper: {
    atom: false,
    attachToDom: true,
    ci: true,
    customMatchers: true,
    jasmineFocused: false,
    jasmineJson: false,
    jasminePass: false,
    jasmineShouldFail: false,
    jasmineTagged: false,
    mockClock: false, // this was key for setTimeout.
    mockLocalStorage: false,
    pathwatcher: true, // finds leaking subscriptions after each test.
    profile: false, // might want to use this to profile in the future!
    set: false,
    unspy: false
  }
};

module.exports = createRunner(extraOptions);
