import { NextMiddleware, NextResponse } from "next/server";

export const middleware: NextMiddleware = async (request) => {
    switch (request.nextUrl.pathname) {
        case "/middleware-rewrite": {
            const {nextUrl: url} = request;
            url.searchParams.set("rewritten", "true")
            return NextResponse.rewrite(url);
        }

        case "/middleware-redirect":
            return NextResponse.redirect(new URL("/middleware-redirect-destination", request.url));
        
        case "/middleware-set-header": {
            const requestHeaders = new Headers(request.headers);
            requestHeaders.set("x-hello-from-middleware-1", "hello");

            const response = NextResponse.next({ request: { headers: requestHeaders } });

            response.headers.set("x-hello-from-middleware-2", "hello");
            return response;
        }

        case "/middleware-geolocation": {
            const { nextUrl: url, geo } = request
            const country = geo?.country || "UK"
            const city = geo?.city || "Leeds"
            const region = geo?.region || "West Yorkshire"
          
            url.searchParams.set('country', country)
            url.searchParams.set('city', city)
            url.searchParams.set('region', region)
          
            return NextResponse.rewrite(url);
        }
    }
}

export const config = {
    matcher: [
        "/middleware-rewrite",
        "/middleware-redirect",
        "/middleware-set-header",
        "/middleware-fetch",
        "/middleware-geolocation",
    ]
}