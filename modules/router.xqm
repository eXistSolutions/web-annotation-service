xquery version "3.1";

module namespace router="wap/router";
import module namespace errors="wap/errors" at 'errors.xqm';
import module namespace rq="wap/request" at 'request.xqm';
import module namespace rp="wap/request-parameters" at 'request-parameters.xqm';

declare function router:request-matches-method($request, $route) { 
    util:log('info', 'router:request-matches-method: ' || string-join($route?methods, ',')),
    $request?method = $route?methods
};

declare function router:request-matches-pattern($request, $route) {
    (:~ TODO better support for path parameters => /annotations/:id ~:)

    let $p-parts := tokenize($route?pattern, '/')
    
    return (
        util:log('debug', 'router:request-matches-pattern ' || serialize((map{ 'route': $p-parts, 'request': $request?parts }), map {'method': 'adaptive'})),
        count($p-parts) eq count($request?parts) and
        fold-left(
            for-each-pair($p-parts, $request?parts, function ($a, $b) {
                util:log('debug', serialize(($a, ':', $b), map { 'method': 'adaptive' })),
                if (starts-with($a, ':'))
                then (string-length($b) > 0)
                else ($a eq $b)
            }),
            true(),
            function ($res, $next) { $res and $next }
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
        util:log('info', 'REQUEST ' || serialize($request, map {'method': 'adaptive'})),
        util:log('info', 'Number of matching routes: ' || $number-of-matching-routes),
        response:set-header('content-type', 'application/json'),
        if ($number-of-matching-routes < 1)
        then (
            response:set-status-code(404),
            map { 'error': 404, 'request': $request }
        )
        else (
            try {
                let $parameters := rp:get($matching?1?parameters)
                let $request-with-parameters := rq:add-parameters($request, $parameters)
                let $response := $matching?1?handler($request-with-parameters)
                return (
                    util:log('info', 'RESPONSE ' || serialize($response, map { "method": "adaptive" })),
                    $response
                )
            }
            catch errors:E400 {
                response:set-status-code(400),
                map { 'error': 400, 'description': $err:description }
            }
            catch errors:E404 {
                response:set-status-code(404),
                map { 'error': 404, 'description': $err:description }
            }
            catch * {
                response:set-status-code(500),
                map { 'error': 500, 'description': $err:description, 'sent': $request?body }
            }
        )
    )
};
