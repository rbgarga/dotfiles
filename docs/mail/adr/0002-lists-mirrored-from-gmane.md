# Lists mirrored from gmane into Maildir

Mailing lists are read from gmane, but neomutt never talks NNTP: a
small script (`nntp-sync`) mirrors each subscribed group into
`~/Mail/lists/<group>`, notmuch indexes it with the rest of the mail,
and each group is a label view in the sidebar. neomutt's own NNTP
support was ruled out for two reasons. Its search only looks at the
overview headers, so list bodies could not be searched with the rest
of the history. And its Xref handling is lazy: an article cross-posted
to several groups (common with the FreeBSD lists) is only marked read
in the other groups once they are opened, while notmuch merges the
copies by Message-ID and keeps one read state. The cost is a second
sync job, a local copy of every mirrored article, and replies that go
out by email (see List reply in the glossary), never posted to the
group.
