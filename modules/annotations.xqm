xquery version "3.1";

module namespace annotations="wap/annotations";

import module namespace config="http://exist-db.org/xquery/apps/config" at 'config.xqm';
import module namespace rp='wap/request-parameters' at 'request-parameters.xqm';

import module namespace errors="wap/errors" at 'errors.xqm';

declare variable $annotations:items-per-page := 10;

declare variable $annotations:body-type-group := 'GroupAnnotation';
declare variable $annotations:body-type-text := 'TextualBody';
declare variable $annotations:body-type-category := 'CategoryLabel';
declare variable $annotations:target-type-specific := 'SpecificResource';

declare %private
function annotations:filter-by-source ($document-id as xs:string, $anno as element(annotation)) as xs:boolean {
    $document-id = $anno/target/@source/string()
};

declare %private
function annotations:by-source ($document-id as xs:string) as element(annotation)* {
    collection($config:annotation-collection)/annotation[$document-id = ./target/@source/string()]
};

declare
function annotations:list ($document-id as xs:string?, $page as xs:integer?, $items-per-page as xs:integer?) as map(*) {
    let $annotations := 
        if (exists($document-id))
        then (annotations:by-source($document-id))
        else (collection($config:annotation-collection)/annotation)
    let $annotations-count := count($annotations)
    let $last-page := max((ceiling($annotations-count div $items-per-page)-1, 0))

    return (
        util:log('info', ('document ID:', $document-id, ' Page:',$page,' Last page:', $last-page)),
        if ($page > $last-page or $page < 0)
        then (error($errors:E400, 'requested page is out of bounds'))
        else (
            let $start-index := $page * $items-per-page
            let $next-page := if ($page + 1 >= $last-page) then ($last-page) else ($page + 1)
            return map {
                "@context": "http://www.w3.org/ns/anno.jsonld",
                "type": "AnnotationPage",
                "partOf": map {
                    "id": $config:annotation-id-prefix,
                    "total": $annotations-count,
                    "modified": xs:string(current-dateTime())
                },
                "startIndex": $start-index,
                "id": $config:annotation-id-prefix || rp:serialize(map {
                    'document': $document-id,
                    'page': $page
                }),
                "items": array { 
                    for-each(
                        subsequence($annotations, $start-index, $items-per-page),
                        annotations:entry2json(?)
                    )
                },
                "next": $config:annotation-id-prefix|| rp:serialize(map {
                    'document': $document-id,
                    'page': $next-page
                }),
                "last": $config:annotation-id-prefix || rp:serialize(map {
                    'document': $document-id,
                    'page': $last-page
                })
            }
        )
    )
};

(:~
    returns true if an annotation exists with xml:id equal to $id

    @params $id xs:string The annotation ID to check
    @returns xs:boolean
~:)
declare function annotations:exists ($id as xs:string?) as xs:boolean {
    util:log('info', 'annotations:exists ' || $id),
    exists(collection($config:annotation-collection)/id($id))
};

(:~
    returns a map of the annotation data,
    if an annotation exists with xml:id equal to $id
    throws an error otherwise

    @params $id xs:string The annotation ID to retrieve
    @throws wap:E404 if no annotation was found
    @returns xs:boolean
~:)
declare function annotations:by-id ($id as xs:string) as map()? {
    let $annotation := collection($config:annotation-collection)/id($id)

    return
        if (not($annotation)) 
        then (error($errors:E404, 'No Annotation Found', $id))
        else (map:merge((
            map { "@context": "http://www.w3.org/ns/anno.jsonld" },
            annotations:entry2json($annotation)
        )))
};

declare function annotations:categoryLabel2json ($category as element(category)) {
    map {
        "value": map {
            "name": $category/@name/string(),
            "label": $category/@label/string(),
            "color": $category/@color/string()
        }
    }
};

declare function annotations:groupAnnotation2json ($group as element(group)) {
    map {
        "color": $group/@color/string()
        (:~ "boundingBox": $body/group/@color/string() ~:)
    }
};

declare function annotations:body2json ($body as element(body)) {
    map:merge((
        map { "type": $body/@type/string() },
        switch ($body/@type/string())
            case 'GroupAnnotation' return annotations:groupAnnotation2json($body/group)
            case 'CategoryLabel' return annotations:categoryLabel2json($body/category)
            default return map { "value": $body/text() }
    ))
};

declare function annotations:target2json ($target as element(target)) {
    map {
        "selector": map {
            "type": $target/selector/@type/string(),
            "value": serialize($target/selector/*, map{'method': 'adaptive'})
        },
        "id": $target/@xml:id/string(),
        "type": $target/@type/string(),
        "source": $target/@source/string()
    }
};

declare function annotations:entry2json ($entry as element(annotation)) as map() {
    map {
        "id": $entry/@xml:id/string(),
        "type": "Annotation",
        "created": $entry/@created/string(),
        "body": array {
            for-each($entry/body, annotations:body2json#1)
        },
        "target": array {
            for-each($entry/target, annotations:target2json#1)
        }
    }
};

declare %private function annotations:body2xml ($body as map(*)) as element(body) {
    <body type="{$body?type}">
        {
            switch ($body?type)
            case 'GroupAnnotation' return
                <group color="{$body?color}" id="{$body?id}"/>
            case 'CategoryLabel' return
                <category name="{$body?value?name}" color="{$body?value?color}" label="{$body?value?label}"/>
            case 'TextualBody' return $body?value
            default return ''
            (:
                error($errors:E400, 'Unsupported Annotation Body', $body)
            :)
        }
    </body>
};

declare %private function annotations:json2entry ($data as map(*)) as element(annotation) {
    <annotation xml:id="{$data?id}" created="{$data?created}">
        {
            array:for-each($data?body, annotations:body2xml#1),
            array:for-each($data?target, function ($target) {
                <target xml:id="{$target?id}" type="{$target?type}" source="{$target?source}">
                    <selector type="{$target?selector?type}">
                        {parse-xml($target?selector?value)}
                    </selector>
                </target>
            })
        }
    </annotation>
};

(:~
    returns the annotation IRI that was created,
    throws an error if an annotation with the ID already exists

    @params $data map() The annotation data to store
    @throws wap:E400 if the annotation exists
    @returns xs:string annotation IRI
~:)
declare function annotations:add ($data as map(*)) as xs:string {
    if (not(exists($data?id)))
    then (error($errors:E400, 'ID is missing', $data))
    else if (annotations:exists($data?id))
    then (error($errors:E400, 'Annotation Exists', $data?id))
    else (
        let $annotation := annotations:json2entry($data)
        let $file := $data?id || '.xml'
        let $stored := xmldb:store($config:annotation-collection, $file, $annotation)
        return $config:annotation-id-prefix || $data?id
    )
};

declare function annotations:update ($data as map(*)) as xs:string {
    let $annotation := annotations:json2entry($data)
    let $file := $data?id || '.xml'
    let $stored := xmldb:store($config:annotation-collection, $file, $annotation)
    return $data?id
};

declare function annotations:update-container-item ($item as map(*)) as map(*) {
    util:log('info', 'annotations:update-container-item ' || serialize($item, map { 'method': 'adaptive' })),
    try {
        let $id := 
            if (starts-with($item?id, $config:annotation-id-prefix))
            then ($item?id)
            else (concat($config:annotation-id-prefix, $item?id))
        
        let $item-with-prefixed-id := map:merge(($item, map { 'id': $id }))
        let $migrate :=
            if (annotations:exists($item?id) and not(annotations:exists($id)))
            then (annotations:delete($item?id))
            else ()
        let $result :=
            if (annotations:exists($item?id))
            then (annotations:update($item))
            else (annotations:add($item))

        return map {
            "id": $item?id,
            "result": $result
        }
    }
    catch * {
        map {
            "id": $item?id,
            "error": $err:description
        }
    }
};

declare function annotations:file-by-id ($id as xs:string?) {
    let $annotation := collection($config:annotation-collection)/id($id)

    return
        if (not(exists($annotation)))
        then ()
        else ($config:annotation-collection || util:document-name($annotation))
};

(:~ 
 ~:)
declare function annotations:delete ($id as xs:string) {
    if (not(annotations:exists($id)))
    then (true())
    else (
        xmldb:remove(
            $config:annotation-collection,
            util:document-name(collection($config:annotation-collection)/id($id))
        )
    )
};

(:~
    
~:)
declare function annotations:delete-elements-by-document($container-document as xs:string, $container-items as array(*)) {
    let $submitted-annotation-ids := array:for-each($container-items, function ($item) {$item?id})
    let $annotation-ids-to-delete := annotations:by-source($container-document)[not(./@xml:id/string() = $submitted-annotation-ids?*)]/@xml:id/string()

    return (
        util:log('info', 'sub: ' || serialize($submitted-annotation-ids, map {'method': 'adaptive'})),
        util:log('info', 'del: ' || serialize($annotation-ids-to-delete, map {'method': 'adaptive'})),
        for-each($annotation-ids-to-delete, function ($id) {
            if (annotations:delete($id))
            then (``[deleted `{$id}`]``)
            else (``[could not delete `{$id}`]``)
        })
    )
};


(:~
    update and create multiple annotations in a BasicContainer

    @params $container map() BasicContainer data 
    @throws wap:E400 if no 'items' key is found or it is not an array
    @returns array() An array of strings, where each entry represents the result of a single operation
~:)
declare function annotations:batch-update ($container as map(*)) as array(*)? {
    util:log('info', ('annotations:batch-update ', 'document ', $container?document)),
    if (not(exists($container?document)))
    then (error($errors:E400, '"document" missing in BasicContainer', $container))
    else if (
        not(exists($container?items)) or 
        not($container?items instance of array(*))
    )
    then (error($errors:E400, '"items" missing or of wrong type in BasicContainer', $container))
    else (
        util:log('info', 'annotations:batch-update found ' || array:size($container?items) || ' items'),
        array:append(
            array:for-each($container?items, annotations:update-container-item#1),
            annotations:delete-elements-by-document($container?document, $container?items)
        )
    )
};

(:~
    handles the request to retrive an annotation by its ID

    @params $request map() request data
    @throws wap:E400 if no annotation ID is part of the request URL
    @returns map() the annotation data
~:)
declare function annotations:handle-single($request as map(*)) as map(*) {
    let $id := $request?parts[3]

    return
        if (string-length($id) = 0)
        then (error($errors:E400, 'No ID given', $request))
        else (annotations:by-id($id))
};

declare function annotations:handle-update($request as map(*)) as map(*) {
    let $data := parse-json($request?body)

    return (
        util:log('info', 'annotation:handle-add type:' || $data?type),
        if ($data?type = 'Annotation')
        then (map {
            "id": $data?id,
            "result": annotations:add($data)
        })
        else if ($data?type eq 'BasicContainer')
        then (map {
            "result": annotations:batch-update($data)
        })
        else (error($errors:E400, 'Unknown item type', $data?type))
    )
};

declare function annotations:handle-list($request as map(*)) as map(*) {
    annotations:list($request?parameters?document, $request?parameters?page, $request?parameters?items-per-page)
};
