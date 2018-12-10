xquery version "3.1";

module namespace annotations="wap/annotations";

import module namespace config="http://exist-db.org/xquery/apps/config" at 'config.xqm';
import module namespace errors="wap/errors" at 'errors.xqm';

declare variable $annotations:items-per-page := 10;

declare function annotations:list ($document-id, $page) {
    let $annotations := for-each(
        collection($config:annotation-collection)/annotation,
        annotations:entry2json(?)
    )
    let $annotations-count := count($annotations)
    let $start-index := $page * $annotations:items-per-page
    let $last-page := ceiling($annotations-count div $annotations:items-per-page)
    let $next-page := if ($page + 1 >= $last-page) then ($last-page) else ($page + 1)

    return map {
        "collection": $config:annotation-collection,
        "@context": [
            "http://www.w3.org/ns/anno.jsonld",
            "http://www.w3.org/ns/ldp.jsonld"
        ],
        "id": "http://example.org/annotations/?iris=0",
        "type": ["BasicContainer", "AnnotationCollection"],
        "total": $annotations-count,
        "modified": "2016-07-20T12:00:00Z", (: TODO :)
        "label": "A Container for Web Annotations",
        "first": map {
            "id": "?page=" || $page,
            "type": "AnnotationPage",
            "next": "?page=" || $next-page,
            "items": array { 
                subsequence($annotations, $start-index, $annotations:items-per-page)
            } 
        },
        "last": "?page=" || $last-page
    }
};

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

declare function annotations:entry2json ($entry as element(annotation)) as map() {
    map {
        "id": $entry/@xml:id/string(),
        "type": "Annotation",
        "created": $entry/@created/string(),
        "body": map {
            "type": $entry/body/entry/@type/string(),
            "value": $entry/body/entry/text()
        },
        "target": array {
            for-each($entry/target/entry, function ($target) {
                map {
                    "id": $target/@id/string(),
                    "type": $target/@type/string(),
                    "value": 
                        serialize($target/*, map{'method': 'adaptive'})
                }
            })
        }
    }
};

declare function annotations:json2entry ($data) {
    <annotation xml:id="{$data?id}" created="{$data?created}">
        <body>
            <entry type="{$data?body?type}">{$data?body?value}</entry>
        </body>
        <target>
            {
                array:for-each($data?target, function ($target) {
                    <entry id="{$target?id}" type="{$target?type}">
                        {parse-xml($target?value)}
                    </entry>
                })
            }
        </target>
    </annotation>
};

declare function annotations:add ($data) {
    if (exists(collection($config:annotation-collection)/id($data?id)))
    then (error($errors:E400, 'Annotation Exists', $data?id))
    else (
        let $annotation := annotations:json2entry($data)
        let $file := $data?id || '.xml'
        return 
            xmldb:store($config:annotation-collection, $file, $annotation)
    )
};

declare function annotations:batch-add ($container-data) {
    array:for-each($container-data?items, function ($item) {
        try {
            annotations:add($item)
        }
        catch * {
            $err:description
        }     
    })
};

declare function annotations:handle-single($request) {
    util:log('info', serialize(('PARTS:', $request?parts), map {'method': 'adaptive'})),
    annotations:by-id($request?parts[3])
};

declare function annotations:handle-add($request) {
    let $data := parse-json(xs:string($request?body))

    return
        if ($data?type eq 'Annotation')
        then (annotations:add($data))
        else if ($data?type eq 'BasicContainer')
        then (annotations:batch-add($data))
        else (error($errors:E400, 'Unknown item type', $data?type))
};

declare function annotations:handle-list($request) {
    let $document := request:get-parameter('document', '')
    let $page := xs:integer(request:get-parameter('page', 0))

    return
        annotations:list($document, $page)
};
