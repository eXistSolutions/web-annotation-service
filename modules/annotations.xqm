xquery version "3.1";

module namespace annotations="wap/annotations";

import module namespace config="http://exist-db.org/xquery/apps/config" at 'config.xqm';
import module namespace errors="wap/errors" at 'errors.xqm';

declare variable $annotations:items-per-page := 10;

declare function annotations:list ($document-id, $page) {
    let $annotations := collection($config:annotation-collection)/annotation
    let $annotations-count := count($annotations)
    let $start-index := $page * $annotations:items-per-page
    let $last-page := ceiling($annotations-count div $annotations:items-per-page)
    let $next-page := if ($page + 1 >= $last-page) then ($last-page) else ($page + 1)

    return map {
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "AnnotationPage",
        "partOf": map {
            "id": $config:annotation-id-prefix,
            "total": $annotations-count,
            "modified": xs:string(current-dateTime())
        },
        "startIndex": 0,
        "id": $config:annotation-id-prefix || "?page=" || $page,
        "items": array { 
            for-each(
                subsequence($annotations, $start-index, $annotations:items-per-page),
                annotations:entry2json(?)
            )
        },
        "next": $config:annotation-id-prefix || "?page=" || $next-page,
        "last": $config:annotation-id-prefix || "?page=" || $last-page
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
        "body": array {
            for-each($entry/body, function ($body) {
                map {
                    "type": $body/@type/string(),
                    "value": map {
                        "name": $body/category/@name/string(),
                        "label": $body/category/@label/string(),
                        "color": $body/category/@color/string()
                    }
                }
            })
        },
        "target": array {
            for-each($entry/target, function ($target) {
                map {
                    "selector": map {
                        "type": $target/selector/@type/string(),
                        "value": serialize($target/selector/*, map{'method': 'adaptive'})
                    },
                    "id": $target/@xml:id/string(),
                    "type": $target/@xml:id/string(),
                    "source": $target/@source/string()
                }
            })
        }
    }
};

declare function annotations:body2xml($body) {
    <body type="{$body?type}">
        {
            switch ($body?type)
            case 'CategoryLabel' return
                <category name="{$body?value?name}" color="{$body?value?color}" label="{$body?value?label}"/>
            default return serialize($body?value)
        }
    </body>
};

declare function annotations:json2entry ($data) {
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
    util:log('info', 'annotation:batch-add FIRST:' || serialize($container-data?1, map {'method': 'adaptive'})),
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
    let $data := parse-json(util:binary-to-string($request?body))

    return (
        util:log('info', 'annotation:handle-add DATA:' || serialize($data, map {'method': 'adaptive'})),
        if ($data?type eq 'Annotation')
        then (annotations:add($data))
        else if ($data?type eq 'BasicContainer')
        then (annotations:batch-add($data))
        else (error($errors:E400, 'Unknown item type', $data?type))
    )
};

declare function annotations:handle-list($request) {
    let $document := request:get-parameter('document', '')
    let $page := xs:integer(request:get-parameter('page', 0))

    return
        annotations:list($document, $page)
};
