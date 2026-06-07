// This file will be obfuscated during the build process
export async function verifyLicense(licenseKey: string, domain: string): Promise<boolean> {
  try {
    // In production, point this to the actual central license server URL
    const licenseServerUrl = process.env.LICENSE_SERVER_URL || 'http://localhost:3001';
    
    const response = await fetch(`${licenseServerUrl}/api/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Optional: Add a secret app token if you want to verify requests are coming from your app
        'x-app-token': 'kiosly-secret-token'
      },
      body: JSON.stringify({
        licenseKey,
        domain
      }),
      // Don't cache this request
      cache: 'no-store'
    });

    if (!response.ok) {
      return false;
    }

    const data = await response.json();
    return data.status === 'valid';
  } catch (error) {
    console.error('License verification failed:', error);
    // If the central server is down, we can either block access or allow it temporarily.
    // Blocking is more secure but might affect uptime if your license server is down.
    return false;
  }
}
