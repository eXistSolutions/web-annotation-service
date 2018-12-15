xquery version "3.1";

module namespace rp='wap/request-parameters';

(:~
EXAMPLES:

add a parameter to a link

    '/mylink' || rp:serialize((map { 'id': 1 }))

RESULT: "/mylink?id=1"

----

array values are supported

    '/mylink' || rp:serialize((map { 'tags': ['John', 'Doe'] }))

RESULT: "/mylink?tags=John&tags=Doe"

----

add the current value of the "page" parameter to a link

    '/mylink' || rp:serialize(rp:get(('page')))

RESULT:
    "/mylink?page=1" when page=1 was requested
    "/mylink?" when no page parameter is found in the request

----

change 'page' parameter value and add a new 
a list current

    let $parameters := map:merge((
        rp:get(('page', 'document')),
        map { 'page': 0 }))
    return '/mylink' || rp:serialize($parameters)

RESULT:
    "/mylink?page=1&" when page=1 was requested
    "/mylink?" when no page parameter is found in the request

~:)
declare
function rp:serialize ($parameters as map(*)) as xs:string {
    let $parameter-names := map:keys($parameters) (: TODO sort :)
    let $serialized-parameters := for-each($parameter-names, rp:serialize-parameter($parameters, ?))
    return '?' || string-join($serialized-parameters, '&amp;')
};


(:~
 : serializes a parameter
 : omits parameters with no value -> `()`
 : usually a single pair of `name=value`
 : multiple entries for parameters that return a sequence
 :)
declare
function rp:serialize-parameter ($parameters as map(*), $parameter-name as xs:string) as xs:string* {
    for-each($parameters($parameter-name), function ($value) {
        $parameter-name || '=' || encode-for-uri($value)
    })
};

(:~
 : return a map:entry with $parameter-name as key and
 : its current value as value
 :
 : @param $parameter-name the name of a parameter 'lang'
~:)
declare
    %private
function rp:get-parameter-value-as-map ($parameter-name as xs:string) as map(*) {
    map:entry($parameter-name, request:get-parameter($parameter-name, ()))
};

(:~
 : return a map of all parameters in the sequence $parameter-names as key and
 : their current value as value
 :
 : @param $parameter-names a sequence of parameter names ('page', 'document')
~:)
declare
function rp:get ($parameter-names as xs:string*) as map(*) {
    map:new(for-each($parameter-names, rp:get-parameter-value-as-map#1))
};

declare
    %private
function rp:get-parameter-value-as-map ($parameter-name as xs:string, $default-value as xs:string?, $type as item()?, $required as xs:boolean?) as map(*) {
    let $value := request:get-parameter($parameter-name, $default-value)

    return
        if ($required and not(value))
        then ()
        else if ($type)
        then (
            map:entry(
                $parameter-name, 
                util:eval(``["`{$value}`" cast as `{$type}`]``))
        )
        else (map:entry($parameter-name, $value))
};

declare function rp:get-by-name-or-definition ($definition-or-name as item()) as map(*) {
    if ($definition-or-name instance of map(*))
    then (
        rp:get-parameter-value-as-map(
            $definition-or-name?name, 
            $definition-or-name?default, 
            $definition-or-name?type, 
            $definition-or-name?required
        )
    )
    else (rp:get-parameter-value-as-map($definition-or-name))
};

declare
function rp:get ($parameter-definition as array(*)?) as map(*)? {
    if (not(exists($parameter-definition)))
    then ()
    else (
        map:new(
            array:for-each(
                $parameter-definition, 
                rp:get-by-name-or-definition#1)?*)
    )
};

declare
function rp:get-cachebusting-parameter () {
    map:entry('c', substring-before(util:uuid(), '-'))
};
