"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const globals_1 = require("@jest/globals");
(0, globals_1.beforeAll)(async () => {
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = 'test-secret';
    process.env.GEMINI_API_KEY = 'test-gemini-key';
    process.env.FIREBASE_PROJECT_ID = 'test-project';
    process.env.FIREBASE_PRIVATE_KEY = 'test-key';
    process.env.FIREBASE_CLIENT_EMAIL = 'test@test.com';
});
(0, globals_1.afterAll)(async () => {
    // Cleanup test resources
});
//# sourceMappingURL=setup.js.map