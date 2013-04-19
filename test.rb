require_relative 'hikkmemo'

include Hikkmemo

Hikkmemo.run '~/.hikkmemo', {
  :log_to => :console_and_files,
  :prompt => '%b>> ',
  :prompt_color => :red,
  :theme  => :zebra,
  :colors => [:green, :yellow],
  :msg_sz => 150,
  :boards => {
    :codach      => Readers.nullchan('/c/'),
    :programmach => Readers.dvach_hk('/pr/')
  }
}
=begin
Hikkmemo.run '~/.hikkmemo', {
  :log_to => :console_and_files,
  :prompt => '%b>>'
  :theme  => :zebra,
  :colors => [:default, :red]
  :boards => {
    :codach      => Readers.nullchan '/c/',
    :programmach => Readers.dvach_hk '/pr/'
  }
} do
  hook :codach do |msg|
    if msg[:text].upcase.include? ''

    end
  end
end
=end
