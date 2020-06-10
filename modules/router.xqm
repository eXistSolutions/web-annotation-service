xquery version "3.1";

module namespace router="wap/router";
import module namespace errors="wap/errors" at 'errors.xqm';
import module namespace rp="wap/request-parameters" at 'request-parameters.xqm';

declare function router:request-matches-method($request, $route) { 
    util:log('debug', 'router:request-matches-method: ' || string-join($route?methods, ',')),
    $request?method = $route?methods
};

(:~ 
    TODO better support for path parameters => /annotations/:id
 :)
declare function router:request-matches-pattern($request, $route) {
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
    util:log('info', 'REQUEST ' || $request?id),
    util:log('debug', 'REQUEST ' || serialize($request, map {'method': 'adaptive'})),
    response:set-header('content-type', 'application/json'),
    try {
        let $matching :=
            $routes 
                => array:filter(router:request-matches-method($request, ?))
                => array:filter(router:request-matches-pattern($request, ?))

        let $number-of-matching-routes := array:size($matching)

        return 
            if ($number-of-matching-routes < 1)
            then (error($errors:E404, 'Not found', $request))
            else (
                let $response := 
                    rp:add-parameters($request, $matching?1?parameters)
                    => ($matching?1?handler)()
                
                return (
                    $response,
                    util:log('info', 'RESPONSE ' || $request?id),
                    util:log('debug', $response)
                )
            )
    }
    catch errors:E400 {
        response:set-status-code(400),
        map { 'error': 400, 'description': $err:description },
        util:log('error', 'ERROR 400 ' || $request?id || ' description: ' || $err:description)
    }
    catch errors:E404 {
        response:set-status-code(404),
        map { 'error': 404, 'description': $err:description, 'sent': $request },
        util:log('error', 'ERROR 404 ' || $request?id || ' description: ' || $err:description)
    }
    catch * {
        response:set-status-code(500),
        map { 'error': 500, 'description': 'The request could not be processed because of a server-side error', 'sent': $request },
        util:log('error', 'ERROR 500 ' || $request?id || ' description: ' || $err:description || " value: " || $err:value)
    }
};
