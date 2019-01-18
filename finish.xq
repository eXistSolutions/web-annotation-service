declare variable $target external;

sm:chmod(xs:anyURI($target || "/modules/route.xq"), "rwxr-Sr-x")
