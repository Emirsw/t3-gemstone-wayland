#!/usr/bin/env bash
set -euo pipefail

cd /repo
mkdir -p dist/sbom
for deb in dist/*.deb; do
  test -e "$deb" || continue
  name="$(basename "$deb" .deb)"
  pkg="$(dpkg-deb -f "$deb" Package)"
  version="$(dpkg-deb -f "$deb" Version)"
  arch="$(dpkg-deb -f "$deb" Architecture)"
  sha="$(sha256sum "$deb" | awk '{print $1}')"
  files="$(mktemp)"
  dpkg-deb --contents "$deb" | awk '{print $NF}' | jq -Rsc 'split("\n")[:-1]' >"$files"
  jq -n \
    --arg pkg "$pkg" --arg version "$version" --arg arch "$arch" --arg sha "$sha" \
    --slurpfile files "$files" \
    '{
      spdxVersion:"SPDX-2.3",
      dataLicense:"CC0-1.0",
      SPDXID:"SPDXRef-DOCUMENT",
      name:($pkg+"-"+$version),
      documentNamespace:("https://t3gemstone.org/spdx/"+$pkg+"/"+$sha),
      creationInfo:{creators:["Organization: T3 Foundation"],created:(now|strftime("%Y-%m-%dT%H:%M:%SZ"))},
      packages:[{SPDXID:"SPDXRef-Package",name:$pkg,versionInfo:$version,
        primaryPackagePurpose:"LIBRARY",downloadLocation:"NOASSERTION",
        checksums:[{algorithm:"SHA256",checksumValue:$sha}],
        externalRefs:[{referenceCategory:"PACKAGE-MANAGER",
          referenceType:"purl",referenceLocator:("pkg:deb/ubuntu/"+$pkg+"@"+$version+"?arch="+$arch)}],
        filesAnalyzed:false,comment:("Payload paths: "+($files[0]|length|tostring))}]
    }' >"dist/sbom/$name.spdx.json"
  rm -f "$files"
done

