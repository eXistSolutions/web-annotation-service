xquery version "3.1";

module namespace rq='wap/request';

declare function rq:map ($base-url as xs:string) as map(*) {
    let $sanitized-url := substring-after(request:get-uri(), $base-url)
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

declare function rq:add-parameters ($request as map(*), $parameters as map(*)?) as map(*) {
    map:merge(( $request, map { 'parameters':  $parameters }))
};
