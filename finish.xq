xquery version "3.1";

import module namespace collection='http://existsolutions.com/modules/collection' at 'modules/collection.xqm';
(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(:~
The finish step of the installation will create a separate data collection to
prevent data loss on subsequent installs.

The collection xconf in the app root collection will be moved to the data collection
and applied automatically.
This means updated index configurations will also always be applied.
~:)
declare variable $local:DATA_COLLECTION := '/db/apps/wap-data';
declare variable $local:SYSTEM_CONFIG_DATA_COLLECTION := '/db/system/config' || $local:DATA_COLLECTION;
declare variable $local:XCONF := 'collection.xconf';
declare variable $local:router := $target || '/modules/route.xq';
declare variable $local:router-permissions := 'rwxr-Sr-x';

(: generate prc-binary collections :)
util:log('info', 'create DATA_ROOT and DATA_COLLECTION'),
util:log('info', collection:create($local:DATA_COLLECTION)?path),

(: set permissions for the collections :)

sm:chmod($local:DATA_COLLECTION, 'rwxrwxr-x'),
sm:chown($local:DATA_COLLECTION, 'wap'),
sm:chgrp($local:DATA_COLLECTION, 'wap'),

(:~ set group ID for routes ~:)
util:log('info', ('set permissions to ', $local:router-permissions ,' for ', $local:router)),
sm:chmod($local:router, $local:router-permissions),

(: store the collection configuration :)
util:log('info', ('created folder ', collection:create($local:SYSTEM_CONFIG_DATA_COLLECTION)?path)),
util:log('info', ('copy ', $local:XCONF, ' to ', $local:SYSTEM_CONFIG_DATA_COLLECTION)),
xmldb:copy($target, $local:SYSTEM_CONFIG_DATA_COLLECTION, $local:XCONF),
util:log('info', ('move ', $local:XCONF, ' to ', $local:DATA_COLLECTION)),
xmldb:move($target, $local:DATA_COLLECTION, $local:XCONF),
util:log('info', ('installation finished'))
