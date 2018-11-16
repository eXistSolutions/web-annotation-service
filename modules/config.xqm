xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://exist-db.org/xquery/apps/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;
declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;
declare variable $config:SETTINGS := doc($config:app-root || "/configuration.xml")/settings;

declare variable $config:annotation-collection := doc($config:app-root || "/configuration.xml")/settings/annotatios/@collection/string();

(:
declare variable $config:AUTH := doc($config:app-root || "/configuration.xml")/settings/authorization;
declare variable $config:VIEW-PACKAGE-PERMISSION := data(doc($config:app-root || "/configuration.xml")/settings/authorization/action[@name eq "view-packages"]/@required-level);
declare variable $config:DEFAULT-APPS-PERMISSION := data(doc($config:app-root || "/configuration.xml")/settings/authorization/action[@name eq "view-default-apps"]/@required-level);
declare variable $config:VIEW-DETAILS-PERMISSION := data(doc($config:app-root || "/configuration.xml")/settings/authorization/action[@name eq "view-package-details"]/@required-level);
declare variable $config:INSTALL-PACKAGE-PERMISSION := data(doc($config:app-root || "/configuration.xml")/settings/authorization/action[@name eq "install-package"]/@required-level);
declare variable $config:REMOVE-PACKAGE-PERMISSION := data(doc($config:app-root || "/configuration.xml")/settings/authorization/action[@name eq "remove-package"]/@required-level);
:)

(: ### default to first found entry of repository element for now - to be extended for multiple repos ### :)
declare variable $config:DEFAULT-REPO := xs:anyURI($config:SETTINGS//repository[1]);

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};
