#!/bin/sh

test_description='git rev-list should handle unexpected object types'

. ./test-lib.sh

test_expect_success 'setup well-formed objects' '
	blob="$(printf "foo" | git hash-object -w --stdin)" &&
	tree="$(printf "100644 blob $blob\tfoo" | git mktree)" &&
	commit="$(git commit-tree $tree -m "first commit")"
'

test_expect_success 'setup unexpected non-blob entry' '
	printf "100644 foo\0$(echo $tree | hex2oct)" >broken-tree &&
	broken_tree="$(git hash-object -w --literally -t tree broken-tree)"
'

test_expect_failure 'traverse unexpected non-blob entry (lone)' '
	test_must_fail git rev-list --objects $broken_tree
'

test_expect_success 'traverse unexpected non-blob entry (seen)' '
	test_must_fail git rev-list --objects $tree $broken_tree >output 2>&1 &&
	test_i18ngrep "is not a blob" output
'

test_expect_success 'setup unexpected non-tree entry' '
	printf "40000 foo\0$(echo $blob | hex2oct)" >broken-tree &&
	broken_tree="$(git hash-object -w --literally -t tree broken-tree)"
'

test_expect_success 'traverse unexpected non-tree entry (lone)' '
	test_must_fail git rev-list --objects $broken_tree
'

test_expect_success 'traverse unexpected non-tree entry (seen)' '
	test_must_fail git rev-list --objects $blob $broken_tree >output 2>&1 &&
	test_i18ngrep "is not a tree" output
'

test_expect_success 'setup unexpected non-commit parent' '
	git cat-file commit $commit |
		perl -lpe "/^author/ && print q(parent $blob)" \
		>broken-commit &&
	broken_commit="$(git hash-object -w --literally -t commit \
		broken-commit)"
'

test_expect_success 'traverse unexpected non-commit parent (lone)' '
	test_must_fail git rev-list --objects $broken_commit >output 2>&1 &&
	test_i18ngrep "not a commit" output
'

test_expect_success 'traverse unexpected non-commit parent (seen)' '
	test_must_fail git rev-list --objects $commit $broken_commit \
		>output 2>&1 &&
	test_i18ngrep "not a commit" output
'

test_expect_success 'setup unexpected non-tree root' '
	git cat-file commit $commit |
	sed -e "s/$tree/$blob/" >broken-commit &&
	broken_commit="$(git hash-object -w --literally -t commit \
		broken-commit)"
'

test_expect_success 'traverse unexpected non-tree root (lone)' '
	test_must_fail git rev-list --objects $broken_commit
'

test_expect_failure 'traverse unexpected non-tree root (seen)' '
	test_must_fail git rev-list --objects $blob $broken_commit
'

test_expect_success 'setup unexpected non-commit tag' '
	git tag -a -m "tagged commit" tag $commit &&
	test_when_finished "git tag -d tag" &&
	git cat-file -p tag | sed -e "s/$commit/$blob/" >broken-tag &&
	tag=$(git hash-object -w --literally -t tag broken-tag)
'

test_expect_success 'traverse unexpected non-commit tag (lone)' '
	test_must_fail git rev-list --objects $tag
'

test_expect_success 'traverse unexpected non-commit tag (seen)' '
	test_must_fail git rev-list --objects $blob $tag >output 2>&1 &&
	test_i18ngrep "not a commit" output
'

test_expect_success 'setup unexpected non-tree tag' '
	git tag -a -m "tagged tree" tag $tree &&
	test_when_finished "git tag -d tag" &&
	git cat-file -p tag |
	sed -e "s/$tree/$blob/" >broken-tag &&
	tag=$(git hash-object -w --literally -t tag broken-tag)
'

test_expect_success 'traverse unexpected non-tree tag (lone)' '
	test_must_fail git rev-list --objects $tag
'

test_expect_success 'traverse unexpected non-tree tag (seen)' '
	test_must_fail git rev-list --objects $blob $tag >output 2>&1 &&
	test_i18ngrep "not a tree" output
'

test_expect_success 'setup unexpected non-blob tag' '
	git tag -a -m "tagged blob" tag $blob &&
	test_when_finished "git tag -d tag" &&
	git cat-file -p tag |
	sed -e "s/$blob/$commit/" >broken-tag &&
	tag=$(git hash-object -w --literally -t tag broken-tag)
'

test_expect_failure 'traverse unexpected non-blob tag (lone)' '
	test_must_fail git rev-list --objects $tag
'

test_expect_success 'traverse unexpected non-blob tag (seen)' '
	test_must_fail git rev-list --objects $commit $tag >output 2>&1 &&
	test_i18ngrep "not a blob" output
'

test_done
