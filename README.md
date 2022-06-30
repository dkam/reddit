# Reddit

## Usage
Tiny library to get Reddit posts &amp; comments

```ruby

$ ./bin/console
irb(main):024:0> lego = Reddit::Subreddit.new('lego')

irb(main):025:0> puts lego.title
LEGO - News from a Studded World

irb(main):026:0> puts lego.public_description
=> "Reports, news, pics, videos, discussions and documentation from a studded world.\n\n/r/lego is about all things LEGO®."

irb(main):027:0> puts lego.over18
false

irb(main):028:0> puts lego[0] # Also - puts lego[0].title
LEGO CON 2022 - Livestream Megathread


irb(main):029:0> puts lego[0].selftext
Welcome to the r/lego discussion MegaThread for LEGO CON 2022!
                                                              
**Where:** www.Lego.com/lego-con                              
**Date:** June 18, 2022 (Today!)                              
                                                              
**Time:** It's over!  You can watch the replay here: https://youtu.be/ZHSnx-smuUA
                                                              
**What Is LEGO CON?** For a summary of what was announced last year, visit our [LEGO CON 2021 Megathread](https://redd.it/o8dct1).
                                                              
This is the thread for discussion of the Lego CON 2022 Live Stream. I'll be recapping the stream below, for those who can't watch the live video.

irb(main):030:0> puts lego[0].url # URL may point to an external URL
https://www.reddit.com/r/lego/comments/vf8ti4/lego_con_2022_livestream_megathread/

irb(main):031:0> puts lego[1][0] # First comment
And I thought I had a problem.
irb(main):032:0> puts lego[1][0][0] # First comment on the first comment
There is no such thing as too many LEGO. You don’t have a problem
```

Check what data is available in the post:

```ruby
lego[0].to_h.keys.join(', ')
=> "approved_at_utc, subreddit, selftext, author_fullname, saved, mod_reason_title, gilded, clicked, title, link_flair_richtext, subreddit_name_prefixed, hidden, pwls, link_flair_css_class, downs, thumbnail_height, top_awarded_type, hide_score, name, quarantine, link_flair_text_color, upvote_ratio, author_flair_background_color, subreddit_type, ups, total_awards_received, media_embed, thumbnail_width, author_flair_template_id, is_original_content, user_reports, secure_media, is_reddit_media_domain, is_meta, category, secure_media_embed, link_flair_text, can_mod_post, score, approved_by, is_created_from_ads_ui, author_premium, thumbnail, edited, author_flair_css_class, author_flair_richtext, gildings, content_categories, is_self, mod_note, created, link_flair_type, wls, removed_by_category, banned_by, author_flair_type, domain, allow_live_comments, selftext_html, likes, suggested_sort, banned_at_utc, view_count, archived, no_follow, is_crosspostable, pinned, over_18, all_awardings, awarders, media_only, link_flair_template_id, can_gild, spoiler, locked, author_flair_text, treatment_tags, visited, removed_by, num_reports, distinguished, subreddit_id, author_is_blocked, mod_reason_by, removal_reason, link_flair_background_color, id, is_robot_indexable, report_reasons, author, discussion_type, num_comments, send_replies, whitelist_status, contest_mode, mod_reports, author_patreon_flair, author_flair_text_color, permalink, parent_whitelist_status, stickied, url, subreddit_subscribers, created_utc, num_crossposts, media, is_video"
```

## Convert Reddit JSON to JSON Feed

Run `ruby jsonfeed.rb`

Then browse to `http://localhost:4567/r/nononoyes`.  Even better, subscribe to it in your feed reader.

## Alternatives

If you're looking for a fully featured client, try [Redd](https://github.com/avinashbot/redd)


# Licence
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
