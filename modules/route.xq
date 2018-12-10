xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace router="wap/router" at 'router.xqm';
import module namespace annotations="wap/annotations" at 'annotations.xqm';

declare variable $local:routes := [
  map {
    'pattern': '/annotations/:id',
    'methods': ('GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'),
    'handler': annotations:handle-single#1
  },
  map {
    'pattern': '/annotations/',
    'methods': ('GET', 'HEAD', 'OPTIONS'),
    'handler': annotations:handle-list#1
  },
  map {
    'pattern': '/annotations/',
    'methods': ('POST'),
    'handler': annotations:handle-add#1
  },
  map {
    'pattern': '/',
    'methods': 'GET',
    'handler': function ($request) {
        map {
            'request': $request
        }
    }
  }
];

router:route(router:request-map(), $local:routes)
