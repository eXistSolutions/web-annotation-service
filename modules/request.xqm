xquery version "3.1";

module namespace rq='wap/request';

declare function rq:map ($allowed-base-uris as xs:string+) as map(*) {
    let $base-and-local-url := rq:to-local-uri($allowed-base-uris, request:get-uri())
    let $base := head($base-and-local-url)
    let $local := tail($base-and-local-url)

    return
        map {
            'id': util:uuid(),
            'url': $local,
            'base': $base,
            'parts': tokenize($local, '/'),
            'method': request:get-method(),
            'body': request:get-data(),
            'headers': map {
                'Accept': request:get-header('Accept')
            }
        }
};

(:~
    find first matching base-uri
    If the request uri starts with one of the provided base-uris the string will start with '/'
    An empty string is returned if the request did not start with any of the base-uris.
    The router _must_ return an error (400, 401, 403 or 404) in this case
 :)
declare function rq:to-local-uri($allowed-base-uris as xs:string+, $uri as xs:string) as xs:string+ {
    fold-left($allowed-base-uris, ($uri, ""), rq:reducer#2)
};

declare %private function rq:reducer ($result as xs:string+, $base-uri as xs:string) as xs:string+ { 
    if (tail($result) eq "" and starts-with(head($result), $base-uri))
    then ($base-uri, substring-after(head($result), $base-uri))
    else ($result)
};
