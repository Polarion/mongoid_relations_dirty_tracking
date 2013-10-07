# Mongoid::TrackEmbeddedChanges

Mongoid extension for tracking changes on embedded documents

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_track_embedded_changes', github: 'versative/mongoid_track_embedded_changes'

And then execute:

    $ bundle

## Usage

```ruby
class SampleDocument
  include Mongoid::Document
  include Mongoid::TrackEmbeddedChanges

  embeds_one  :foo
  embeds_many :bars

  field :title, type: String
end

doc = SampleDocument.create
doc.foo = Foo.new
doc.bars << Bar.new
doc.title = 'New title'

doc.embedded_changed?   # => true
doc.embedded_changes    # => {"foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040"}], "bars" => [nil, [{"_id"=>"524c35ad1ac1c23084000083"}]]}
doc.changed?            # => true
doc.changes             # => {"title" => [nil, "New title"], "foo" => [nil, {"_id"=>"524c35ad1ac1c23084000040"}], "bars" => [nil, [{"_id"=>"524c35ad1ac1c23084000083"}]]}

doc.save
doc.embedded_changed?   # => false
doc.embedded_changes    # => {}
doc.changed?            # => false
doc.changes             # => {}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
