```
  $ sudo apt-get install sqlite3 libsqlite3-dev
  $ sudo gem install hikkmemo
```

```
  $ sudo gedit /usr/local/bin/hikkmemo
```

```ruby
  #!/usr/bin/env ruby
  # -*- coding: utf-8 -*-
  require 'hikkmemo'
  require "unicode_utils/upcase"
  require 'unicode_utils/lowercase_char_q'

  Readers = Hikkmemo::Readers

  Hikkmemo.run '~/.hikkmemo', {
    :log_to => :console,
    :prompt => '/%b/> ',
    :prompt_color => :red,
    :theme  => :zebra,
    :colors => [:green, :yellow],
    :msg_sz => 50,
    :boards => {
      :c    => Readers.nullchan('/c/'),
      :pr   => Readers.dvach_hk('/pr/'),
      :s    => Readers.dobrochan('/s/'),
      :scii => Readers.iichan('/sci/')
    }
  } do
    hook do |post, board|
      msg = UnicodeUtils.upcase(post[:message])
      if ['RUBY', 'РУБИ', 'РАБИ'].any? {|w| msg.include? w }
        notice "Активность рубиняш в #{post[:thread]}-треде (#{board.to_s})."
      end
    end

    hook :c do |post|
      if UnicodeUtils.lowercase_char? post[:message][0]
        notice "Кто-то написал с маленькой буквы в #{post[:thread]}-треде."
      end
    end

    cmd 'мяу' do |args|
      puts "Мур-мур, #{args.reverse.join(' ')}."
    end

    cmd 'kishki' do
      puts @workers
    end
  end
```

```
  $ hikkmemo
```