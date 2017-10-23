#!/usr/bin/env bash

# makedocker Copyright (C) 2017 Alister Sanders

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

template=${DOCKERFILE_TEMPLATE:-@PREFIX@@DATADIR@/makedocker/template}

log() {
    echo -ne "[$1] :: "
    shift
    echo -e "$@"
}

info() {
    log "\e[36minfo\e[0m" $@
}

warn() {
    log "\e[33mwarn\e[0m" $@
}

die() {
    log "\e[31merr \e[0m" $@
    exit 1
}

ask() {
    default=$1
    shift

    if [ ! -z "$default" ]; then
	echo -ne ":: $@ (default: \e[32m$default\e[0m) "
	read -r response

	if [ -z "$response" ]; then
	    response="$default"
	fi
    else
	echo -ne ":: $@ "
	read -r response
    fi
}

yesno() {
    response=""
    while [ "$response" != "y" ] && [ "$response" != "n" ]; do
	ask "" $@ "(y/n)"
	response="$(echo $response | tr '[:upper:]' '[:lower:]')"
    done
}

do_help()
{
    echo -e "Usage: $0 [-o FILENAME] [-h]"
    echo -e ""
    echo -e "Asks a series of questions and generates a Dockerfile based on these."
    echo -e ""
    echo -e "By default, the output file is 'Dockerfile' in the current directory, "
    echo -e "but this can be changed by using \e[1m-o FILENAME\e[0m to set FILENAME as the "
    echo -e "output."
}

# Get the command line options
outputfile="Dockerfile"
while getopts "o:h" opt; do
    case "$opt" in
	o) outputfile="$OPTARG" ;;
	h) do_help; exit 0 ;;
	*) do_help; exit 1 ;;
    esac
done


[ ! -r "$template" ] && die "Failed to read template file ($template)"

ask "alpine:latest" "Base Docker image?"
base="$response"

ask "" "Package dependencies? (space-separated, blank for none)"
pkg_deps="$response"

ask "" "Pip dependencies? (space-separated, blank for none)"
pip_deps="$response"

# Generate a random name as the default project name
random_name="$(grep -E '^[a-z]+$' /usr/share/dict/* | shuf | head -n 1)"
if [ $? -ne 0 ]; then
    random_name="project"
fi

ask "$random_name" "Project name?"
proj_name="$response"

ask "$proj_name" "Project source?"
src="$response"

ask "/src" "Destination (inside Docker image)?"
dest="$response"

ask "80/tcp" "Ports/protocols to expose (port/protocol, space-separated)"
ports="$response"

echo ""

# Make sure all the details are correct
echo "Summary"
echo "-------"
echo "Base image ....................... $base"
echo "Package dependencies ............. $pkg_deps"
echo "Python (Pip) dependencies ........ $pip_deps"
echo "Project name ..................... $proj_name"
echo "Project source directory ......... $src"
echo "Project destination (internal) ... $dest"
echo "Ports/Protocols to expose ........ $ports"
echo ""

yesno "Is everything correct?"

if [ "$response" = "n" ]; then
    info "Starting again..."
    exec $0 $@
fi

if [ -f "$outputfile" ]; then
    yesno "$outputfile exists. Overwrite?"
    if [ "$response" == "n" ]; then
	info "Exiting..."
	exit 0
    fi

    info "Overwrite existing file..."
    rm -f "$outputfile"
fi

m4 -P \
   -D "__base__=\`$base'" \
   -D "__pkgdeps__=\`$pkg_deps'" \
   -D "__pipdeps__=\`$pip_deps'" \
   -D "__srcdir__=\`$src'" \
   -D "__destdir__=\`$dest'" \
   -D "__projectname__=\`$proj_name'" \
   -D "__ports__=\`$ports'" \
   < "$template" | cat -s > "$outputfile"

if [ $? -ne 0 ]; then
    die "Failed to create $outputfile"
fi

info "Created $outputfile."

info "Building Docker image..."
docker build -t "$proj_name:latest" "$src" || die "Failed to build the Docker image"

info "Tagging the image..."
docker tag "$proj_name:latest" "localhost:5000/$proj_name" || die "Failed to tag the Docker image"

info "Pushing to the local registry..."
docker push "localhost:5000/$proj_name" || die "Failed to push the image to the local registry"
