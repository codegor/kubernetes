#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 02 / Task 3 — Kyverno: person label"

check "ClusterPolicy add-person-label is Ready" \
  kubectl wait --for=condition=Ready clusterpolicy/add-person-label --timeout=30s

person_is() { # namespace input-labels expected ("" = no label)
  local got
  got=$(dry_run_pod "$1" hw-test-label "$2" | jq -r '.metadata.labels.person // ""')
  [ "$got" = "$3" ]
}

for ns in student01 student02 student03; do
  check "$ns: new pod gets person=student"            person_is "$ns" ""              student
done
check "student02: person=hacker is overwritten to student" person_is student02 person=hacker student
check "mentor: new pod gets person=mentor"                 person_is mentor    ""              mentor
check "mentor: person=student is overwritten to mentor"    person_is mentor    person=student  mentor
check "default: pod without label stays without"           person_is default   ""              ""
check "default: person=student is removed"                 person_is default   person=student  ""
check "default: other labels are kept"                     eval '[ "$(dry_run_pod default hw-test-label person=x,team=a | jq -r .metadata.labels.team)" = a ]'

finish
