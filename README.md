# Reply to individual

This discourse plugin allows Discourse's emails to mimic the GNU/Mailman option "reply_goes_to_list = Poster"

In practice, the plugin does the following:

1. Adds a `Reply-To:` header that exposes the poster's email address
2. Optionally adds a `CC:` header that allows a 'Reply-All' action in a mailing agent to respond back to the Discourse topic

# Contact info and license
* Original author: Tarek Loubani <tarek@tarek.org>
* Fork author: Alan Schmitz <aschmitz@iastate.edu>
* License: aGPLv3
