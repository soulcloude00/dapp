export const webcrypto = window.crypto;
export const getRandomValues = (buffer: any) => window.crypto.getRandomValues(buffer);
export default {
    webcrypto,
    getRandomValues
};
