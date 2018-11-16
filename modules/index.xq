xquery version '3.1';

import module namespace config="http://exist-db.org/xquery/apps/config" at 'config.xqm';

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:media-type "text/html";
declare option output:method "html5";
declare option output:indent "false";


declare variable $expath := config:expath-descriptor();
declare variable $repo := config:repo-descriptor();

<html>
<head>
    <meta name="description" content="{$config:repo-descriptor/repo:description/text()}"/>
    {
        for $author in $config:repo-descriptor/repo:author
        return
            <meta name="creator" content="{$author/text()}"/>
    }
</head>
<body>
<header>
<h1>WAP</h1>
<h2>web annotation protocol server</h2>
</header>
<main>
<h3>examples</h3>
    <ul>
        <li><a href="/exist/apps/wap/annotations/">List of all annotations</a></li>
        <li><a href="/exist/apps/wap/annotations/1">Detailview of an annotation</a></li>
    </ul>
</main>
<footer>
    <table class="app-info">
        <tr>
            <td>app collection:</td>
            <td>{$config:app-root}</td>
        </tr>
        {
            for $prop in ($expath/@*, $expath/*, $repo/*)
            return
                <tr>
                    <td>{node-name($prop)}:</td>
                    <td>{$prop/string()}</td>
                </tr>
        }
    </table>
</footer>
</body>
</html>