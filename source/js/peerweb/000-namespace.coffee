class PeerWebClass
  constructor: ->
    @config = null
    @rtc = null

  initialize: ->
    @config = new PeerWeb.Config()
    @rtc = new PeerWeb.Rtc @config
    @listener = null
    @

  listen: ->
    return if @listener
    @listener = new PeerWeb.Listener @config, @rtc
    @

  connect: (address) ->
    @pusher = new PeerWeb.Pusher address, @config, @rtc
    @

PeerWeb = new PeerWebClass()
window.PeerWeb = PeerWeb

document.addEventListener 'DOMContentLoaded', ->
  PeerWeb.initialize()
  if window.location.hash
    address = window.location.hash.substring 1
    PeerWeb.connect address
  else
    PeerWeb.listen()

