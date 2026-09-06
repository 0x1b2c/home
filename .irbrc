require 'rubygems'
require 'base64'
require 'irbtools'

Irbtools.start

rails_root = File.basename(Dir.pwd)
IRB.conf[:PROMPT] ||= {}
IRB.conf[:PROMPT][:RAILS] = {
  PROMPT_I: "#{rails_root}> ",
  PROMPT_S: "#{rails_root}* ",
  PROMPT_C: "#{rails_root}? ",
  RETURN: "=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :RAILS

# Called after the irb session is initialized and Rails has
# been loaded (props: Mike Clark).
IRB.conf[:IRB_RC] = proc do
  if defined?(ActiveRecord)
    ActiveRecord::Base.logger = Logger.new($stdout)
    ActiveRecord::Base.instance_eval { alias :[] :find }
  end

  if defined?(Mongoid)
    Mongoid.logger = Logger.new($stdout)
  end

  if defined?(MongoMapper)
    MongoMapper.connection.instance_variable_set(:@logger, Logger.new($stdout))
  end

  if defined?(Rails)
    Rails.logger = Logger.new($stdout)
  end
end

unless defined?(Rails)
  class Integer
    def /(other)
      fdiv(other)
    end
  end
end

# vim: set ft=ruby:
