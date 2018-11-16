xquery version "3.1";

import module namespace annotations="wap/annotations" at 'annotations.xqm';

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:media-type "application/json";
declare option output:method "json";
declare option output:indent "false";

annotations:list()