xquery version "3.1";

module namespace annotations="wap/annotations";

import module namespace config="http://exist-db.org/xquery/apps/config" at 'config.xqm';

declare function annotations:list () {
    let $annotations := for-each(
        collection($config:annotation-collection)/annotation,
        annotations:entry2json(?)
    )
    return map { "items": array { $annotations } }
};

declare function annotations:by-id ($id) {
    let $annotation := collection($config:annotation-collection)/id($id)

    return
        if (not($annotation)) 
        then ( (: throw error ('') :) )
    else ( annotations:entry2json($annotation) )
};

declare function annotations:entry2json ($entry as element(annotation)) as map() {
    map {
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "id": $entry/@id/string(),
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
                    "value": $target/*
                }
            })
        }
    }
};