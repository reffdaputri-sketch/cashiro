export function generateDynamicQris(staticQris: string, amount: number): string {
  try {
    let payload = staticQris.substring(0, staticQris.length - 4);
    
    // Check if amount tag (54) already exists
    // The format is like "...540510000..." where 54 is tag, 05 is length, 10000 is amount.
    // It is safer to assume static QRIS doesn't have tag 54, or we find and replace it.
    // But EMVCo format is sequential, though order is not strictly enforced.
    // We can just append it before tag 63.
    // Tag 63 is the last tag, always 6304.
    
    // Find index of '6304' from the end
    const tag63Index = payload.lastIndexOf('6304');
    if (tag63Index === -1) {
      return staticQris; // invalid format
    }
    
    const basePayload = payload.substring(0, tag63Index);
    
    const amountStr = amount.toString();
    const amountLength = amountStr.length.toString().padStart(2, '0');
    const amountTag = `54${amountLength}${amountStr}`;
    
    const newPayload = `${basePayload}${amountTag}6304`;
    const crc = crc16Ccitt(newPayload);
    
    return `${newPayload}${crc}`;
  } catch (e) {
    return staticQris;
  }
}

function crc16Ccitt(data: string): string {
  let crc = 0xFFFF;
  for (let i = 0; i < data.length; i++) {
    let x = ((crc >> 8) ^ data.charCodeAt(i)) & 0xFF;
    x ^= x >> 4;
    crc = ((crc << 8) ^ (x << 12) ^ (x << 5) ^ x) & 0xFFFF;
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}
