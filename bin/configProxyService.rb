#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

Daemons.run('/usr/local/paas/bin/configProxy.rb')
