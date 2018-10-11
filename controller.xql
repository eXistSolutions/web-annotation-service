xquery version "3.1";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:routes := [
  map {
    'pattern': '/annotations/.+',
    'methods': ('GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'),
    'handler': 'annotation-detail'
  },
  map {
    'pattern': '/annotations/',
    'methods': ('GET', 'POST', 'HEAD', 'OPTIONS'),
    'handler': "annotation-list"
  },
  map {
    'pattern': '.*',
    'methods': 'GET',
    'handler': 'index'
  }
];

declare function local:request-matches-route($request, $route) {
    let $matches := (
        $request?method = $route?methods and
        matches($request?url, $route?pattern)
    )

    return (
        util:log('info', string-join(
            ($request?url, $request?method, $route?methods, $route?pattern, $matches), '--')),
        $matches
    )
};

declare function local:route($request, $routes as array(*)) {
    let $rules := array:filter($routes, local:request-matches-route($request, ?))
    let $number-of-matching-rules := count($rules)
    let $d := util:log('info', $rules?1?handler)

    return (
        if ($number-of-matching-rules >= 1)
        then (
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="/wap/modules/{$rules?1?handler}.xq"></forward>
            </dispatch>
        )
        else (
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <data>404</data>
            </dispatch>
        )
    )
};

local:route(
    map {
        'url': $exist:path,
        'method': request:get-method(),
        'headers': map {
            'Accept': request:get-header('Accept')
        }
    },
    $local:routes)
