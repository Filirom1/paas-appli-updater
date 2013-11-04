#!/usr/bin/env ruby
 
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'stomp'
require 'mcollective'
require 'pp'
require 'logger'
require 'broker'
require 'node'
require 'rproxy'
require 'config'
require 'paasexceptions'

# A modifier en cas de modif Redhat Openshift
$cartNameTrap='openshift-origin-node'
$actionNameTrapExec='connector-execute'
$actionNameTrapRm='app-destroy'
$actionNameTrapConfigure='configure'
$actionNameTrapAddAlias='add-alias'
$actionNameTrapRmAlias='remove-alias'
$haProxyCartName='haproxy-1.4'
$hookNameSetProxy='set-proxy'
MaxLogSize = 1024000

module Awlpaas
  class ConfigRproxy
    def initialize(appName, nameSpace, uuid, cartridge)
      @appName = appName
      @nameSpace = nameSpace    
      @uuid = uuid
      @cartridge = cartridge
      $paasConfig = Config.instance
      #Config.instance.loadconfig
    end

    def appModify(ipsPorts)
      begin
        broker = Awlpaas::Broker.new(@nameSpace, @appName)
        aliases = broker.listAliases()
        @configAppli = true
        if @cartridge == "Unknown"
          cartridge = broker.showWebCartridge()
        else
          cartridge = @cartridge
          if cartridge != $cartNameTrap # config message of Web gear
            scalable, ipAppNs = broker.isAppScalable()
            if scalable == false
              ipsPorts = Array.new
              ipsPorts.push("#{ipAppNs}:80")
            else
              @configAppli = false # config message of scalable Web gear
            end
          end
        end
        if @configAppli == true
          #node = Awlpaas::Node.new
          #primaryIpPort = node.showAppPrimaryPort(@appName, @nameSpace, @uuid, cartridge)
          #ipsPorts.push(primaryIpPort)
          rproxy = Awlpaas::Rproxy.new
          rproxy.configureAppli("#{@appName}-#{@nameSpace}", "#{$paasConfig.domainName}", ipsPorts, aliases)
        end
        
      rescue AwlpaasBrokerException => be
        raise(AwlpaasBrokerException, "BrokerException ConfigRproxy::appModify #{be.message}, #{be.backtrace.inspect}")
      rescue AwlpaasRproxyException => re
        raise(AwlpaasRproxyException, "RproxyException ConfigRproxy::appModify #{re.message}, #{re.backtrace.inspect}")
      rescue AwlpaasNodeException => ne
        raise(AwlpaasNodeException, "NodeException ConfigRproxy::appModify #{ne.message}, #{ne.backtrace.inspect}")
      end
    end

    def appRemove
      begin
        rproxy = Awlpaas::Rproxy.new
        rproxy.unconfigureAppli("#{@appName}-#{@nameSpace}","#{$paasConfig.domainName}")
      rescue AwlpaasRproxyException => re
        raise(AwlpaasRproxyException, "RproxyException ConfigRproxy::appRemove #{re.message}, #{re.backtrace.inspect}")
      end
    end

    def addAlias
      begin
        rproxy = Awlpaas::Rproxy.new
        rproxy.unconfigureAppli("#{@appName}-#{@nameSpace}","#{$paasConfig.domainName}")
      rescue AwlpaasRproxyException => e
        raise(AwlpaasRproxyException, "RproxyException ConfigRproxy::addAlias #{e.message}, #{e.backtrace.inspect}")
      end
    end

    def rmAlias
      begin
        rproxy = Awlpaas::Rproxy.new
        rproxy.unconfigureAppli("#{@appName}-#{@nameSpace}","#{$paasConfig.domainName}")
      rescue AwlpaasRproxyException => e
        raise(AwlpaasRproxyException, "RproxyException ConfigRproxy::rmAlias #{e.message}, #{e.backtrace.inspect}")
      end
    end
  end

  begin
    Config.instance.loadconfig unless Config.instance.configured
    $paasConfig = Config.instance
    Log = Logger.new("#{$paasConfig.logFile}", 7, MaxLogSize) unless defined? Log
    Log.level = Logger::DEBUG
# Stomp Connection
    connector = Stomp::Connection.open($paasConfig.usernameMcollective, $paasConfig.passwordMcollective, \
        $paasConfig.serveurMcollective, $paasConfig.portMcollective)
    connector.subscribe($paasConfig.topicResponse, :ack => 'client')
    connector.subscribe($paasConfig.topicRepli, :ack => 'client')
  # infinite loop on ESB process Acteur process
    loop do
      msg = connector.receive
puts msg.inspect
      #  Si connection sur Mcollective
      # msg.type = :reply
      # msg.decode!
      #  payload = msg.payload
      #  body = payload[:body]
      #
      #  On Stomp, manuel decode of message -> psk.rb
      #
      payload = Marshal.load(msg.body)
      body = Marshal.load(payload[:body])
      if  msg.headers["destination"] == $paasConfig.topicResponse

         if  (body.is_a?(Hash) == true) && ((body).has_key?(:data) == true) && \
            ((body[:data]).has_key?(:output) == true) && \
            ((body[:data][:output]).respond_to?('each') == true)
          mcolMsg = body[:data][:output]

          mcolMsg.each do |result| 
            unless result[:job] == nil
              if result[:job][:cartridge] == $cartNameTrap && result[:job][:action] == $actionNameTrapExec &&  \
                result[:job][:args]["--cart-name"] == $haProxyCartName && \
                result[:job][:args]["--hook-name"] == $hookNameSetProxy
                # We extract message at actor level to untouch classes in case of change in Openshift code
                adresses = result[:job][:args]["--input-args"] 
                appName = result[:job][:args]["--input-args"].split(/ /)[0]
                nameSpace = result[:job][:args]["--input-args"].split(/ /)[1]
                uuid = result[:job][:args]["--input-args"].split(/ /)[2]
                ipPort = Array.new
                adresses.each_line do |adress|
                  if adress =~ /.*\|/
                    ipPort.push(adress.sub(/.*\|/, '').chop.chop)
                    # on zappe le dernier ' et l'\n
                  end
                end
                confProxy=ConfigRproxy.new(appName, nameSpace, uuid, "Unknown")
                confProxy.appModify(ipPort)
              end
            end
          end
        end
      end

      if  msg.headers["destination"] == $paasConfig.topicRepli

        if (body.is_a?(Hash) == true) && (body.has_key?(:data) == true) &&
          ((body[:data]).has_key?(:args) == true)

          mcolMsg = body[:data]
          if (mcolMsg.has_key?(:cartridge) == true) && \
              (mcolMsg.has_key?(:action) == true) 
            if mcolMsg[:args]["--with-container-name"] ==  mcolMsg[:args]["--with-app-name"] && \
                mcolMsg[:cartridge] != $cartNameTrap && mcolMsg[:action] == $actionNameTrapConfigure 

              appName =  mcolMsg[:args]["--with-app-name"]
              nameSpace =  mcolMsg[:args]["--with-namespace"]
              uuid =  mcolMsg[:args]["--with-app-uuid"]
              cartridge=  mcolMsg[:cartridge]
              confProxy = ConfigRproxy.new(appName, nameSpace, uuid, cartridge)
              confProxy.appModify("")
            end
            if mcolMsg[:args]["--with-container-name"] ==  mcolMsg[:args]["--with-app-name"] && \
                mcolMsg[:cartridge] == $cartNameTrap && mcolMsg[:action] == $actionNameTrapRm 
              appName =  mcolMsg[:args]["--with-app-name"]
              nameSpace =  mcolMsg[:args]["--with-namespace"]
              uuid =  mcolMsg[:args]["--with-app-uuid"]
              confProxy = ConfigRproxy.new(appName, nameSpace, uuid, "")
              confProxy.appRemove
            end
            if mcolMsg[:action] == $actionNameTrapAddAlias
              appName =  mcolMsg[:args]["--with-app-name"]
              nameSpace =  mcolMsg[:args]["--with-namespace"]
              uuid =  mcolMsg[:args]["--with-app-uuid"]
              #appName =  mcolMsg[:args].split(/ /)[0].gsub(/'/, '')
              #nameSpace =  mcolMsg[:args].split(/ /)[1].gsub(/'/, '')
              #uuid =  mcolMsg[:args].split(/ /)[2].gsub(/'/, '')
              cartridge =  mcolMsg[:cartridge]
              confProxy = ConfigRproxy.new(appName, nameSpace, uuid, cartridge)
              sleep 1 # Broker updates it s conf
              confProxy.appModify("")
            end
            if mcolMsg[:action] == $actionNameTrapRmAlias
              appName =  mcolMsg[:args]["--with-app-name"]
              nameSpace =  mcolMsg[:args]["--with-namespace"]
              uuid =  mcolMsg[:args]["--with-app-uuid"]
              #appName =  mcolMsg[:args].split(/ /)[0].gsub(/'/, '')
              #nameSpace =  mcolMsg[:args].split(/ /)[1].gsub(/'/, '')
              #uuid =  mcolMsg[:args].split(/ /)[2].gsub(/'/, '')
              cartridge=  mcolMsg[:cartridge]
              confProxy = ConfigRproxy.new(appName, nameSpace, uuid, cartridge)
              sleep 1 # Broker updates it s conf
              confProxy.appModify("")
            end
          end
        end
      end
      connector.ack(msg.headers["message-id"])
    end
  rescue AwlpaasBrokerException => be
    Log.debug("ConfigProxy AwlpaasBrokerException: #{be.message}")
    Log.debug("ConfigProxy AwlpaasBrokerException: #{be.backtrace.inspect}")
    retry # non blocking exception
  rescue AwlpaasNodeException => ne
    Log.debug("ConfigProxy AwlpaasNodeException: #{ne.message}")
    Log.debug("ConfigProxy AwlpaasNodeException: #{ne.backtrace.inspect}")
    retry # non blocking exception
  rescue AwlpaasRproxyException => re
    Log.debug("ConfigProxy AwlpaasRproxyException: #{re.message}")
    Log.debug("ConfigProxy AwlpaasRproxyException: #{re.backtrace.inspect}")
    retry # non blocking exception
  rescue AwlpaasException => ee
    Log.debug("ConfigProxy AwlpaasException: #{ee.message}")
    Log.debug("ConfigProxy AwlpaasException: #{ee.backtrace.inspect}")
    retry # non blocking exception
  rescue Exception => e
    STDERR.puts "ConfigProxy: Failed to process data from Stomp: #{$!}"
    Log.error("ConfigProxy: Failed to process data from Stomp: #{$!}")
    Log.error("ConfigProxy: #{e.message}") 
    Log.debug("ConfigProxy: #{e.backtrace.inspect}")
  end

end
