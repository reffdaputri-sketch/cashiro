import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
// We import the obfuscated version if available, otherwise fallback to the raw version
// In a real build pipeline, you would replace the raw file with the obfuscated one
import { verifyLicense } from './lib/license-checker';

export async function proxy(request: NextRequest) {
  // Allow requests to the unauthorized page and static assets
  if (
    request.nextUrl.pathname.startsWith('/unauthorized') ||
    request.nextUrl.pathname.startsWith('/_next/') ||
    request.nextUrl.pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // Get the domain of the current request
  const domain = request.headers.get('host') || 'unknown';

  // Pengecualian (Whitelist) untuk domain admin utama (cashiro.web.id, cashiro.vercel.app) dan localhost
  if (
    domain.includes('cashiro.web.id') || 
    domain.includes('cashiro.vercel.app') || 
    domain.includes('localhost') || 
    domain.includes('127.0.0.1')
  ) {
    return NextResponse.next();
  }

  // Get license key from environment variable
  const licenseKey = process.env.LICENSE_KEY;

  if (!licenseKey) {
    // Redirect to unauthorized page if no license key is found
    return NextResponse.redirect(new URL('/unauthorized?reason=no_key', request.url));
  }

  // Call our obfuscated checker
  const isValid = await verifyLicense(licenseKey, domain);

  if (!isValid) {
    // Redirect to unauthorized page if license is invalid
    return NextResponse.redirect(new URL('/unauthorized?reason=invalid_key', request.url));
  }

  return NextResponse.next();
}

// Only run middleware on the main routes
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico, sitemap.xml, robots.txt (metadata files)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)',
  ],
};
