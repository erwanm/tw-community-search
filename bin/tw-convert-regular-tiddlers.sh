#!/bin/bash

progName="tw-convert-regular-tiddlers.sh"

function usage {
    echo "Usage: $progName [options] <collected wikis dir> <target wiki dir>"
    echo
    echo "TODO"
    echo "  The following steps are applied to every regular tiddler:"
    echo "  * convert to system tiddler"
    echo "  * rename as \$:/<wiki-name>/<title>"
    echo "  * remove any system tag"
    echo "  Plugin and theme tiddlers are ignored."
    echo
    echo "Options:"
    echo "  -h this help message"
    echo "  -b <wiki basis path>. Default: $inputWikiBasis."
    echo "  -o <standalone html output filename>. Default: $outputFilename."
    echo    
}

function isPluginOrTheme {
    local tiddlerFile="$1"
    local maxLineNo="$2"
    pluginField=$(head -n $(( $maxLineNo - 1 )) "$tiddlerFile" | grep "^plugin-type:" | wc -l)
    if [ $pluginField -gt 0 ]; then
	return 1
    else
	return 0
    fi
}

function writeTags {
    local name="$1"
    local tags="$2"

    echo "tags: $name"
    set -- $tags
#    echo "DEBUG TAGS='$tags'" 1>&2
    regex="^\\\$:/"
    while [ ! -z "$1" ]; do
	tag="$1"
	if [ "${tag:0:2}" == "[[" ]; then
	    while [ ${tag:(-2)} != "]]" ]; do
		shift
		tag="$tag $1"
	    done
#	    echo "DEBUG: found possible multiword tag='$tag'" 1>&2
	    if [[ ! ${tag:2} =~ $regex ]]; then # keep it if not a system tag, otherwise ignore it
		echo -n " $tag"
	    fi
	else
	    if [[ ! $tag =~ $regex ]]; then # keep it if not a system tag, otherwise ignore it
		echo -n " $tag"
	    fi
	fi
	shift
    done
    echo
}



while getopts 'h' option ; do
    case $option in
	"h" ) usage
	      exit 0;;
        "?" )
            echo "Error, unknow option." 1>&2
            usage 1>&2
	    exit 1
    esac
done
shift $(($OPTIND - 1)) # skip options already processed above
if [ $# -ne 2 ]; then
    echo "Error: 2 parameters expected, $# found." 1>&2
    usage 1>&2
    exit 1
fi
collectedWikisDir="$1"
targetWiki="$2"

regex="^\\\$__"
for wikiDir in "$collectedWikisDir"/*; do
    if [ -d "$wikiDir" ]; then
	if [ "$(basename "$targetWiki")" != "$(basename "$wikiDir")" ]; then # skip target wiki
	    name=$(basename "$wikiDir")
	    for tiddlerFile in "$wikiDir"/tiddlers/*.tid; do
		firstBlankLineNo=$(cat "$tiddlerFile" | grep -n "^$" | head -n 1 | cut -f 1 -d ":")
		isPluginOrTheme "$tiddlerFile" "$firstBlankLineNo"
		if [ $? -eq 0 ] && [[ ! $(basename "$tiddlerFile") =~ $regex ]]; then # ignore plugins, themes and system tiddlers
		    basef=$(basename "$tiddlerFile")
		    dest="$targetWiki/tiddlers/\$__${name}_$basef"
		    oldTitle=$(head -n $(( $firstBlankLineNo - 1 )) "$tiddlerFile" | grep "^title:" | sed 's/^title: //g')
		    newTitle="\$:/$name/$oldTitle" # convert title to system tiddler with wiki id prefix
		    echo "title: $newTitle" >"$dest"
		    head -n $(( $firstBlankLineNo - 1 )) "$tiddlerFile" | grep -v "^title:" | grep -v "^tags:" >>"$dest" # copy fields except title and tags
		    oldTags=$(head -n $(( $firstBlankLineNo - 1 )) "$tiddlerFile" | grep "^tags:" | sed 's/^tags: //g')
		    writeTags "$name" "$oldTags" >>"$dest"
		    echo "source-wiki-id: $name" >>"$dest" # store custom fields in order to recompute the original address
		    echo "source-tiddler-title: $oldTitle" >>"$dest" 
		    tail -n +$firstBlankLineNo "$tiddlerFile" >>"$dest"
		fi
	    done
	fi
    fi
done
