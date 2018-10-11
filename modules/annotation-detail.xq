xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:media-type "application/json";
declare option output:method "json";

(:
Content-Type: application/ld+json; profile="http://www.w3.org/ns/anno.jsonld"
Link: <http://www.w3.org/ns/ldp#Resource>; rel="type"
ETag: "_87e52ce126126"
Allow: PUT,GET,OPTIONS,HEAD,DELETE,PATCH
Vary: Accept
Content-Length: 287
:)

map {
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "http://annotations/anno1",
    "type": "Annotation",
    "created": "2018-10-10T12:00:00Z",
    "body": map {
        "type": "TextualBody",
        "value": "Some Text"
    },
    "target": array { (
        map {
            "id": "s-15392581128382",
            "type": "SvgSelector",
            "value": "<circle id=&quot;s-15392581128382&quot; cx=&quot;0&quot; cy=&quot;0&quot; r=&quot;126.953125&quot; transform=&quot;translate(577.64 666.02) scale(1.16 1.21)&quot; />"
        }
        )
    }
}
