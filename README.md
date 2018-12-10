# Web Annotation Service

aims to be an implementation of [Web Annotation Protocol](http://w3c.github.io/web-annotation/protocol/wd/) running as
a service app on eXist-db.

## Approach

Implementing the full spec is a huge effort as always with W3C specs. We'll drive the development
incrementally using our concrete requirements to steer priorities.

Beyond that the effort will target the feature marked as MUST und just eventually consider SHOULD or SHALL features.

## read

   curl http://localhost:8080/exist/apps/wap/annotations/a1

## list

   curl http://localhost:8080/exist/apps/wap/annotations/

read next page

   curl http://localhost:8080/exist/apps/wap/annotations/?page=1


Not implemented yet, list by document

   curl http://localhost:8080/exist/apps/wap/annotations/?document-id=1

## add

   curl -X POST http://localhost:8080/exist/apps/wap/annotations/ -d @doc/single.json -H "Content-Type: multipart/mixed"

## add batch

    curl -X POST http://localhost:8080/exist/apps/wap/annotations/ -d @doc/data.json -H "Content-Type: multipart/mixed"
