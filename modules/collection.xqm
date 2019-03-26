xquery version '3.1';

module namespace collection="http://existsolutions.com/modules/collection";

(:~
 : create arbitrarily deep-nested sub-collection
 : @param   $new-collection absolute path that starts with "/db"
 :          the string can have a slash at the end
 : @returns map(*) with xs:boolean success, xs:string path and xs:string error,
 :          if something went wrong error contains the description and path is
 :          the collection where the error occurred
~:)
declare
function collection:create ($new-collection as xs:string) as map(*) {
    if (not(starts-with($new-collection, '/db')))
    then (
        map {
            'success': false(),
            'path': $new-collection,
            'error': 'New collection must start with /db'
        }
    )
    else (
        fold-left(
            tail(tokenize($new-collection, '/')),
            map { 'success': true(), 'path': '' },
            collection:fold-collections#2
        )
    )
};

declare
    %private
function collection:fold-collections ($result as map(*), $next as xs:string*) as map(*) {
    let $path := concat($result?path, '/', $next)

    return
        if (not($result?success))
        then ($result)
        else if (xmldb:collection-available($path))
        then (map { 'success': true(), 'path': $path })
        else (
            try {
                map {
                    'success': exists(xmldb:create-collection($result?path, $next)),
                    'path': $path
                }
            }
            catch * {
                map {
                    'success': false(),
                    'path': $path,
                    'error': $err:description
                }
            }
        )
};

(:~

Returns the content of the collection $collection in XML

NOTE:

If collections-only and files-only are true, an empty result will be returned
When files-only is true, the recursive option is not taken into account.

@param $collection:          name of the collection
@param $options: map() of options
        recursive:       if true subcollections will be included
        collections-only: true  = return only collections, defaults to false
        files-only:       true  = return only files, defaults to false

~:)
declare function collection:read($collection as xs:string, $options as map(*)) as element()* {
    if (not(xmldb:collection-available($collection)))
    then ()
    else (
        for $child in xmldb:get-child-collections($collection)
        let $path := $collection || '/' || $child
        order by $child
        return (
            (: collections :)
            if (exists($options?files-only) and $options?files-only eq false())
            then ()
            else (collection:read-subcollections($path, $options)),
            (: files :)
            if (exists($options?collections-only) and $options?collections-only eq false())
            then ()
            else (collection:read-resources($path))
        )
    )
};

declare function collection:read-subcollections($path, $options) {
    <collection name="{$child}" path="{$path}">
    {
        if (xmldb:collection-available($path))
        then (
            attribute resources { count(xmldb:get-child-resources($path)) },
            attribute collections { count(xmldb:get-child-collections($path)) },
            sm:get-permissions(xs:anyURI($path))/*/@*
        )
        else ('no permissions'),
        if ($is-recursive)
        then (collection:read($path, $options))
        else ()
    }
    </collection>
};

declare function collection:read-resources($path) {
    for $child in xmldb:get-child-resources($collection)
    let $path := $collection || '/' || $child
    order by $child
    return (
        <resource name="{$child}" path="{$path}"
            mime-type="{xmldb:get-mime-type(xs:anyURI($path))}"
            size="{ceiling(xmldb:size($collection, $child) div 1024)}">
            { sm:get-permissions(xs:anyURI($path))/*/@* }
        </resource>
    )
};
