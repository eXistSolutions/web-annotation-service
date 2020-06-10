xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace router="wap/router" at 'router.xqm';
import module namespace rq="wap/request" at 'request.xqm';
import module namespace annotations="wap/annotations" at 'annotations.xqm';

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";
declare option output:indent "no";

declare variable $local:routes := [
  map {
    'pattern': '/annotations/:id',
    'methods': ('GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'),
    'handler': annotations:handle-single#1
  },
  map {
    'pattern': '/annotations/',
    'methods': ('GET', 'HEAD', 'OPTIONS'),
    'parameters': [
      map { 'name': 'page', 'type': 'xs:integer', 'default': 0 },
      map { 'name': 'items-per-page', 'type': 'xs:integer', 'default': $annotations:items-per-page },
      'document'
    ],
    'handler': annotations:handle-list#1
  },
  map {
    'pattern': '/annotations/',
    'methods': 'POST',
    'parameters': ['batch'],
    'handler': annotations:handle-update#1
  },
  map {
    'pattern': '/',
    'methods': 'GET',
    'parameters': ['test'],
    'handler': function ($request) {
        map {
            'request': $request
        }
    }
  }
];

router:route(rq:map(('/exist/apps/wap', '/exist/apps/ecpo/api')), $local:routes)
