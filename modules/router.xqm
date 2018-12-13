xquery version "3.1";

module namespace router="wap/router";
import module namespace errors="wap/errors" at 'errors.xqm';

declare function router:request-matches-method($request, $route) { 
    util:log('info', 'router:request-matches-method: ' || string-join($route?methods, ',')),
    $request?method = $route?methods
};

declare function router:request-matches-pattern($request, $route) {
    let $p-parts := tokenize($route?pattern, '/')
    
    return (
        util:log('info', serialize(('a;sldfja;sdlj', map{ 'route': $p-parts, 'request': $request?parts }), map {'method': 'adaptive'})),
        count($p-parts) eq count($request?parts) and
        fold-left(
            for-each-pair($p-parts, $request?parts, function ($a, $b) {
                util:log('info', serialize(($a, ':', $b), map {'method': 'adaptive'})),
                if (starts-with($a, ':'))
                then (string-length($b) > 0)
                else ($a eq $b)
            }),
            true(),
            function ($res, $next) { $res and $next}
        )
    )
};

declare function router:route($request, $routes as array(*)) {
    let $matching :=
        $routes 
            => array:filter(router:request-matches-method($request, ?))
            => array:filter(router:request-matches-pattern($request, ?))

    let $number-of-matching-routes := array:size($matching)

    return (
        util:log('info', 'REQUEST' || serialize($request, map {'method': 'adaptive'})),
        util:log('info', 'Number of matching routes: ' || $number-of-matching-routes),
        response:set-header('content-type', 'application/json'),
        if ($number-of-matching-routes < 1)
        then (
            response:set-status-code(404),
            serialize(
                map { 'error': 404, 'request': $request },
                map { "method": "json" }
            )
        )
        else (
            try {
                util:log('info', ('number of matching routes', $number-of-matching-routes)),
                (: replace(replace( $serialized-result, '&gt;', '>'), '&lt;', '<') :)
                serialize(
                    $matching?1?handler($request),
                    map { "method": "json" }
                )
            }
            catch errors:E400 {
                response:set-status-code(400),
                serialize(
                    map { 'error': 400, 'description': $err:description },
                    map { "method": "json" }
                )
            }
            catch errors:E404 {
                response:set-status-code(404),
                serialize(
                    map { 'error': 404, 'description': $err:description },
                    map { "method": "json" }
                )
            }
            catch * {
                response:set-status-code(500),
                serialize(
                    map { 'error': 500, 'description': $err:description, 'sent': $request?body },
                    map { "method": "json" }
                )
            }
        )
    )
};

declare function router:request-map () as map(*) {
    let $sanitized-url := substring-after(request:get-uri(), '/exist/apps/wap')
    return
    map {
        'url': $sanitized-url,
        'parts': tokenize($sanitized-url, '/'),
        'method': request:get-method(),
        'body': request:get-data(),
        'headers': map {
            'Accept': request:get-header('Accept')
        }
    }
};