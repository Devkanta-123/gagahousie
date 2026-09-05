import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const sessionCookie = request.cookies.get("gaga_admin_session");

  let isAuthenticated = false;
  if (sessionCookie?.value) {
    try {
      const parsed = JSON.parse(decodeURIComponent(sessionCookie.value));
      if (parsed.expiresAt && parsed.expiresAt > Date.now()) {
        isAuthenticated = true;
      }
    } catch {
      // Invalid cookie format
      isAuthenticated = false;
    }
  }

  // Exact root "/admin" redirect to dashboard
  if (pathname === "/admin") {
    return NextResponse.redirect(new URL("/admin/dashboard", request.url));
  }

  // Protected admin routes
  const isProtectedAdminRoute =
    pathname.startsWith("/admin/") &&
    !pathname.startsWith("/admin/login");

  // If unauthenticated and trying to access protected route -> redirect to /admin/login
  if (isProtectedAdminRoute && !isAuthenticated) {
    const loginUrl = new URL("/admin/login", request.url);
    // Optionally preserve return redirect
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  // If already authenticated and trying to access /admin/login -> redirect to /admin/dashboard
  if (pathname === "/admin/login" && isAuthenticated) {
    return NextResponse.redirect(new URL("/admin/dashboard", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    "/((?!api|_next/static|_next/image|favicon.ico).*)",
  ],
};
