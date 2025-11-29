"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRandomValues = exports.webcrypto = void 0;
exports.webcrypto = window.crypto;
const getRandomValues = (buffer) => window.crypto.getRandomValues(buffer);
exports.getRandomValues = getRandomValues;
exports.default = {
    webcrypto: exports.webcrypto,
    getRandomValues: exports.getRandomValues
};
