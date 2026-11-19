# Mail

Reading and sending mail from the terminal with neomutt, on the
desktop-profile hosts, across three accounts and a set of mailing
lists mirrored from gmane.

## Language

**Account**:
A mailbox the user reads: Personal, FreeBSD or Work. An account is
named by its role, not by the address used to log into it.
_Avoid_: profile, server, inbox

**Login address**:
The address used to authenticate to an account's mailbox. It is not
necessarily an address the user sends as (FreeBSD logs in as
garga.bsd@gmail.com but never sends from it).
_Avoid_: username, account address

**Identity**:
A name and From address the user sends as. Each identity belongs to
exactly one account: Personal has rbgarga@gmail.com, FreeBSD has
garga@FreeBSD.org, Work has renato@netgate.com and garga@netgate.com.
_Avoid_: alias, sender, from

**Default identity**:
The identity used for new messages in an account, and for replies to
messages not addressed to any of the account's identities (Work:
renato@netgate.com).
_Avoid_: primary address

**Recipient identity**:
When replying, the identity whose address the original message was
sent to; it takes precedence over the default identity.
_Avoid_: reverse name

**Label**:
A Gmail category a message belongs to; a message can have several,
and each label is seen over IMAP as a folder. Every message is in All
Mail regardless of its labels.
_Avoid_: folder, tag

**Label view**:
A sidebar entry showing the threads of one label, including the
user's own replies to them.
_Avoid_: folder, virtual folder

**Reply copy**:
A copy of a sent reply placed under the label (or INBOX) the replied
message was read from, in addition to Sent, so the reply sits in the
same place as its thread. Replies read from a search or a newsgroup
get no reply copy.
_Avoid_: fcc, sent copy

**Flagged**:
The one per-message marker shared with Gmail (shown there as
Starred), used to mean "to do".
_Avoid_: starred, tag, important

### Message actions

**Archive**:
Removing a message from INBOX; it stays in All Mail and its labels.
_Avoid_: delete, move

**Delete**:
Moving a message to Trash, from which Gmail purges it.
_Avoid_: archive, remove

**Unlabel**:
Removing one label from a message, leaving it everywhere else.
_Avoid_: delete, remove

### Lists

**Newsgroup**:
A mailing list archive on news.gmane.io, mirrored into a local Maildir
and read as a label view, without subscribing to the list. neomutt
never talks NNTP.
_Avoid_: group, feed, list

**List reply**:
A reply to a newsgroup article, always sent by email to the mailing
list's address from the FreeBSD identity, never posted over NNTP.
_Avoid_: followup, post
