xquery version "3.0";

declare namespace json="http://www.json.org";
declare namespace control="http://exist-db.org/apps/dashboard/controller";

import module namespace login-helper="http://exist-db.org/apps/dashboard/login-helper" at "modules/login-helper.xql";


declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $login := login-helper:get-login-method();

request:set-attribute("betterform.filter.ignoreResponseBody", "true"),
if(starts-with($exist:path,"/package/icon")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/get-icon.xql"></forward>
        </dispatch>
else if(starts-with($exist:path, "/resources")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/no-service.html"></forward>
    </dispatch>
