# reddit
Tiny library to get reddit posts &amp; comments

```ruby

$ ./bin/console
irb(main):027:0> lego = Reddit::Subreddit.new('lego')
irb(main):028:0> puts lego[1]
Behold my stuff!
irb(main):029:0> puts lego[1][0]
And I thought I had a problem.
irb(main):030:0> puts lego[1][0][0]
There is no such thing as too many LEGO. You don’t have a problem
```
