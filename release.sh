#!/bin/sh
pkgname="apacman"
manpages="apacman.8 apacman.conf.5"
tester="bats"
unit="test.bats"
tmpdir="${TMPDIR:-/tmp}"

manual2html() {
  mkdir -p docs/
  for manual in $manpages; do
    echo "==> Generating docs/${manual}.html"
    cat "$manual" | groff -mandoc -Thtml > "docs/${manual}.html"
  done
}

compare2rel() {
  if [[ "$lastrel" ]]; then
    tagged=$(git log -1 --pretty=oneline $lastrel | awk '{print $1}')
    head=$(git log -1 --pretty=oneline HEAD | awk '{print $1}')
    if [ "$tagged" = "$head" ]; then
      return 0
    fi
  fi
  return 1
}

testunits() {
  echo "==> Run unit tests"
  $tester "$unit" 2>&1 &>/dev/null
  return $?
}

createarchive() {
  newrel="${lastrel#v}"
  mkdir -p "$tmpdir/${pkgname}-${newrel}" &&
  cp * "$tmpdir/${pkgname}-${newrel}/" &&
  cd "$tmpdir" &&
  tar -czvf "${pkgname}-${newrel}.tar.gz" "${pkgname}-${newrel}/" &&
  echo "==> ${pkgname}-${newrel}.tar.gz" &&
  exit 0
}

manual2html
staging=$(git status -s --untracked-files=no 2>/dev/null)
ready=$(echo "$staging" | wc -l)
lastrel=$(git tag 2>/dev/null | tail -n 1)
if [ "$ready" -eq 0 ]; then
  compare2rel &&
  testunits &&
  createarchive &&
  echo "==> Release ready"
else
  echo "$staging"
fi

echo "==> Release not ready"
exit 1
